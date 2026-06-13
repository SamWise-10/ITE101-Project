# TDLF-Educ · Backend-to-backend handshake (Supabase Edge Function)

This is **the endpoint on our backend** that the **Tawi-Tawi backend** calls.
It does a **token exchange**, then serves our data only when given that token.

```
Tawi-Tawi backend ──(1) POST /handshake { secret } ─────▶ this function ──▶ returns a TOKEN
Tawi-Tawi backend ──(2) GET  /data  Authorization: Bearer <token> ─▶ this function ──▶ returns our data
Tawi-Tawi backend ──(3) forwards the data to the Tawi-Tawi frontend
```

Function URL once deployed:
`https://jjiozotzlmblsxgsjzgw.supabase.co/functions/v1/tdlf-educ`

---

## A. Deploy it (do this once)

### Easiest — Supabase Dashboard (no install)
1. Supabase Dashboard → **Edge Functions** (left sidebar) → **Create a function**.
2. Name it exactly **`tdlf-educ`**.
3. Paste the contents of [`index.ts`](index.ts) into the editor.
4. **Turn OFF "Verify JWT"** (this function does its own auth). ← important
5. Click **Deploy**.

### Alternative — Supabase CLI
```bash
npm install -g supabase
supabase login
supabase functions deploy tdlf-educ --no-verify-jwt --project-ref jjiozotzlmblsxgsjzgw
```

## B. Set the two secrets
Dashboard → **Edge Functions → (Secrets / Manage secrets)** → add:

| Secret | What to put |
|---|---|
| `HANDSHAKE_SECRET` | A strong shared password. **Give this same value to your Tawi-Tawi backend teammate.** e.g. `tdlf-educ-7f3a9c1e55b2` |
| `TOKEN_SECRET` | Any other strong random string (kept private — only this function uses it). e.g. `s9Q2!kP_random_long_value` |

(Via CLI instead: `supabase secrets set HANDSHAKE_SECRET=... TOKEN_SECRET=... --project-ref jjiozotzlmblsxgsjzgw`)

> `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are provided automatically by
> Supabase — you do **not** set those.

---

## C. How the Tawi-Tawi backend uses it (give this to your backend teammate)

**Step 1 — handshake (exchange the shared secret for a token):**
```bash
curl -X POST "https://jjiozotzlmblsxgsjzgw.supabase.co/functions/v1/tdlf-educ/handshake" \
  -H "Content-Type: application/json" \
  -d '{ "secret": "THE_SHARED_HANDSHAKE_SECRET" }'
# -> { "success": true, "token": "xxxxx.yyyyy", "expires_in": 3600 }
```

**Step 2 — use the token to read the data:**
```bash
curl "https://jjiozotzlmblsxgsjzgw.supabase.co/functions/v1/tdlf-educ/data?resource=books" \
  -H "Authorization: Bearer THE_TOKEN_FROM_STEP_1"
# resource = books | quizzes | courses, or omit ?resource= to get all three.
```

**Node/axios version (matches their Express backend):**
```js
const axios = require("axios");
const BASE = "https://jjiozotzlmblsxgsjzgw.supabase.co/functions/v1/tdlf-educ";

async function getTdlfEducData(resource = "books") {
  // 1) handshake -> token
  const { data: hs } = await axios.post(`${BASE}/handshake`, {
    secret: process.env.TDLF_HANDSHAKE_SECRET, // the shared secret
  });
  // 2) use the token to fetch data, then forward it to the frontend
  const { data } = await axios.get(`${BASE}/data?resource=${resource}`, {
    headers: { Authorization: `Bearer ${hs.token}` },
  });
  return data; // { success: true, resource, data: [...] }
}
```

---

## Notes
- Tokens last 1 hour; just call `/handshake` again when one expires.
- Only the **public catalog** (books, quizzes, courses) is exposed. Student
  results and profiles are never returned.
- Calling `/data` without a valid token returns `401` — so the data is truly
  gated behind the handshake, exactly as required.
- Optional cleanup: since access now goes through this function, the
  `anon read ...` policies in `schema.sql` are no longer needed. You can leave
  them (harmless) or drop them if you want the data reachable *only* via the handshake.
