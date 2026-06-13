# TDLF-Educ → Tawi-Tawi Integration Guide (ITE103)

This explains how to plug **TDLF-Educ** into the **Tawi-Tawi** super-app. The app
was prepared as a **drop-in module**, so this is mostly copy-paste.

There are two parts:
1. **Frontend** — copy this app into the Tawi-Tawi Flutter app as a module.
2. **Backend handshake** — let the Tawi-Tawi backend read this app's public data.

---

## Part 1 · Frontend (Flutter)

The Tawi-Tawi frontend keeps each group's app in
`lib/features/integrates services/<app>/` (see `zentromart/`, `LakbAi/`, …).
TDLF-Educ already exposes a single entry widget — **`TdlfEducApp`** — that boots
itself (Supabase + desktop SQLite), brings its own providers, and renders its own
themed app. So embedding it is 3 steps.

### Step 1 — Copy the code in
Copy **everything inside this project's `lib/`** into:
```
tawi-tawi-frontend/lib/features/integrates services/tdlf_educ/
```
Then **delete** the copied `tdlf_educ/main.dart` (the host has its own `main()`).
All other files use relative imports, so they keep working after the move.

The module's entry file is:
```
.../tdlf_educ/tdlf_educ_app.dart   →  exposes  class TdlfEducApp
```

### Step 2 — Add the dependencies
The host `pubspec.yaml` **already has**: `http`, `provider`, `permission_handler`,
`shared_preferences`, `path_provider`, `sqflite`, `path`, `connectivity_plus`,
`intl`. **Keep the host's versions** for those.

**Add these** (the ones the host doesn't have yet) under `dependencies:`:
```yaml
  supabase_flutter: ^2.14.2
  dio: ^5.3.1
  uuid: ^4.0.0
  crypto: ^3.0.3
  file_picker: ^8.0.0
  open_filex: ^4.3.2
  url_launcher: ^6.3.2
  # desktop SQLite (only needed if the super-app targets Windows/Linux):
  sqflite_common_ffi: ^2.3.0
  sqlite3: ">=2.0.0 <3.0.0"
  sqlite3_flutter_libs: ^0.5.0
```
Then run `flutter pub get`. (If pub reports a version conflict on a shared
package, take the **higher** version — the host's app is the source of truth.)

### Step 3 — Add a launcher tile
In the Tawi-Tawi home/menu screen (`lib/features/main/…` or `lib/features/home/…`),
import the module and open it from a tile/button:
```dart
import 'package:tawi_tawi_frontend/features/integrates services/tdlf_educ/tdlf_educ_app.dart';
// (or a relative import, matching how the other modules are imported)

ListTile(
  leading: const Icon(Icons.school_rounded),
  title: const Text('TDLF-Educ'),
  subtitle: const Text('Books & quizzes — offline learning'),
  onTap: () => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const TdlfEducApp()),
  ),
),
```

That's it. `TdlfEducApp` initializes itself the first time it's opened, so **no
changes to the host `main.dart` are required.** The back button exits cleanly
back to the Tawi-Tawi menu.

> Note: TDLF-Educ uses its own **Supabase** backend (like how zentromart/LakbAi
> bring their own). It works fully on its own — it does **not** depend on the
> Tawi-Tawi backend to function.

---

## Part 2 · Backend handshake (Tawi-Tawi backend → this app's data)

TDLF-Educ's backend is **Supabase**, which already exposes a REST API. After
running the updated `supabase/schema.sql` (it adds 3 read-only `anon` policies),
the central Tawi-Tawi Express backend can fetch this app's **public catalog**
(books, quizzes, courses) using only the **public anon key** — no new server,
no secret keys.

**Endpoints** (base = `https://jjiozotzlmblsxgsjzgw.supabase.co/rest/v1`):
| Data | Request |
|---|---|
| Books | `GET /books?select=*` |
| Quizzes | `GET /quizzes?select=*` |
| Courses | `GET /courses?select=*` |

**Required headers** (anon key is public, safe to share):
```
apikey: <SUPABASE_ANON_KEY>
Authorization: Bearer <SUPABASE_ANON_KEY>
```
(The anon key is in this repo at `lib/config/app_config.dart` → `supabaseAnonKey`.)

**Example — add a TDLF-Educ module in the Tawi-Tawi Express backend** (uses the
`axios` it already depends on):
```js
// src/modules/tdlf_educ/tdlf_educ.service.js
const axios = require("axios");

const BASE = "https://jjiozotzlmblsxgsjzgw.supabase.co/rest/v1";
const KEY = process.env.TDLF_EDUC_ANON_KEY; // paste the anon key into .env

const client = axios.create({
  baseURL: BASE,
  headers: { apikey: KEY, Authorization: `Bearer ${KEY}` },
});

exports.getBooks   = async () => (await client.get("/books?select=*")).data;
exports.getQuizzes = async () => (await client.get("/quizzes?select=*")).data;
exports.getCourses = async () => (await client.get("/courses?select=*")).data;
```
Then expose them in a route (`src/modules/tdlf_educ/tdlf_educ.routes.js`) and
register it in `src/routes/v1/index.js` the same way `auth`/`users` are.

**Privacy:** only public educational content is exposed. Student quiz results and
profiles stay protected (no `anon` policy), so no private data leaks.

> If the Tawi-Tawi team instead wants a single custom endpoint with their own
> auth/JWT, that would be a Supabase **Edge Function** — ask and it can be added.

---

## Quick checklist
- [ ] Copy `lib/` → `tawi-tawi-frontend/lib/features/integrates services/tdlf_educ/`
- [ ] Delete the copied `tdlf_educ/main.dart`
- [ ] Add the dependencies above to the host `pubspec.yaml`, run `flutter pub get`
- [ ] Add a launcher tile that opens `const TdlfEducApp()`
- [ ] Re-run `supabase/schema.sql` in Supabase (adds the `anon` read policies)
- [ ] Share the anon key with the backend team for the handshake
