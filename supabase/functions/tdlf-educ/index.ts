// ════════════════════════════════════════════════════════════════════════
//  TDLF-Educ · Backend-to-backend (b2b) handshake gateway
//  Supabase Edge Function — this is "the endpoint on OUR backend" that the
//  Tawi-Tawi backend talks to.
//
//  Flow:
//    1) POST  /tdlf-educ/handshake     body { "secret": "<shared secret>" }
//                                      -> { token, expires_in }           (token exchange)
//    2) GET   /tdlf-educ/data?resource=books|quizzes|courses
//             header: Authorization: Bearer <token>
//                                      -> { data }                         (token-gated)
//
//  The Tawi-Tawi backend: handshake -> gets a token -> calls /data with it ->
//  forwards the data to the Tawi-Tawi frontend.
//
//  IMPORTANT: deploy this function with JWT verification DISABLED (it does its
//  own auth via the shared secret + the token it issues). See README.md.
// ════════════════════════════════════════════════════════════════════════

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_KEY =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  Deno.env.get("SUPABASE_ANON_KEY") ??
  "";

// Set these as Edge Function secrets (see README). HANDSHAKE_SECRET is shared
// with the Tawi-Tawi backend team; TOKEN_SECRET stays private to this function.
const HANDSHAKE_SECRET = Deno.env.get("HANDSHAKE_SECRET") ?? "";
const TOKEN_SECRET = Deno.env.get("TOKEN_SECRET") ?? "";

const TOKEN_TTL_SECONDS = 3600; // issued tokens are valid for 1 hour
const ALLOWED_RESOURCES = ["books", "quizzes", "courses"];

const encoder = new TextEncoder();

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type, x-handshake-secret",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...CORS_HEADERS },
  });
}

function b64url(bytes: Uint8Array): string {
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function b64urlToBytes(s: string): Uint8Array {
  s = s.replace(/-/g, "+").replace(/_/g, "/");
  while (s.length % 4) s += "=";
  return Uint8Array.from(atob(s), (c) => c.charCodeAt(0));
}

async function sign(data: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(TOKEN_SECRET),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", key, encoder.encode(data));
  return b64url(new Uint8Array(sig));
}

async function issueToken(): Promise<{ token: string; exp: number }> {
  const exp = Math.floor(Date.now() / 1000) + TOKEN_TTL_SECONDS;
  const payload = b64url(encoder.encode(JSON.stringify({ aud: "tawi-tawi", exp })));
  const token = `${payload}.${await sign(payload)}`;
  return { token, exp };
}

async function verifyToken(token: string): Promise<boolean> {
  const parts = token.split(".");
  if (parts.length !== 2) return false;
  const [payload, sig] = parts;
  if ((await sign(payload)) !== sig) return false; // signature check
  try {
    const claims = JSON.parse(new TextDecoder().decode(b64urlToBytes(payload)));
    return (
      claims.aud === "tawi-tawi" &&
      typeof claims.exp === "number" &&
      claims.exp > Math.floor(Date.now() / 1000)
    );
  } catch {
    return false;
  }
}

async function fetchTable(table: string): Promise<unknown> {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}?select=*`, {
    headers: { apikey: SERVICE_KEY, Authorization: `Bearer ${SERVICE_KEY}` },
  });
  if (!res.ok) throw new Error(`Supabase REST ${res.status} for ${table}`);
  return await res.json();
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return json({}, 204);

  const url = new URL(req.url);
  const path = url.pathname.replace(/\/+$/, ""); // trim trailing slash

  try {
    // ── 1) HANDSHAKE: exchange the shared secret for a token ────────────────
    if (req.method === "POST" && path.endsWith("/handshake")) {
      if (!HANDSHAKE_SECRET || !TOKEN_SECRET) {
        return json(
          { success: false, message: "Server not configured (missing secrets)." },
          500,
        );
      }
      let provided = req.headers.get("x-handshake-secret") ?? "";
      if (!provided) {
        try {
          const body = await req.json();
          provided = body?.secret ?? "";
        } catch { /* no body */ }
      }
      if (provided !== HANDSHAKE_SECRET) {
        return json({ success: false, message: "Invalid handshake secret." }, 401);
      }
      const { token, exp } = await issueToken();
      return json({
        success: true,
        token,
        token_type: "Bearer",
        expires_in: TOKEN_TTL_SECONDS,
        expires_at: exp,
      });
    }

    // ── 2) DATA: requires a valid token from the handshake ──────────────────
    if (req.method === "GET" && path.endsWith("/data")) {
      const auth = req.headers.get("Authorization") ?? "";
      const token = auth.startsWith("Bearer ") ? auth.slice(7) : "";
      if (!(await verifyToken(token))) {
        return json(
          { success: false, message: "Missing or invalid token. Call /handshake first." },
          401,
        );
      }

      const resource = url.searchParams.get("resource") ?? "all";
      if (resource === "all") {
        const [books, quizzes, courses] = await Promise.all([
          fetchTable("books"),
          fetchTable("quizzes"),
          fetchTable("courses"),
        ]);
        return json({ success: true, data: { books, quizzes, courses } });
      }
      if (!ALLOWED_RESOURCES.includes(resource)) {
        return json(
          {
            success: false,
            message: `Unknown resource. Use one of: ${ALLOWED_RESOURCES.join(", ")} (or omit for all).`,
          },
          400,
        );
      }
      return json({ success: true, resource, data: await fetchTable(resource) });
    }

    // ── Info / health ───────────────────────────────────────────────────────
    if (req.method === "GET") {
      return json({
        success: true,
        app: "TDLF-Educ",
        message: "Backend-to-backend handshake gateway.",
        usage: {
          handshake: "POST /tdlf-educ/handshake  body { secret }  -> { token }",
          data: "GET /tdlf-educ/data?resource=books|quizzes|courses  header Authorization: Bearer <token>",
        },
      });
    }

    return json({ success: false, message: "Not found." }, 404);
  } catch (e) {
    return json({ success: false, message: "Internal error.", error: String(e) }, 500);
  }
});
