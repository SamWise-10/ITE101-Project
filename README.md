# 📚 TDLF-Educ

A modern, **offline-first education app** built with **Flutter** and **Supabase**. Students browse and download books (PDF) for offline reading and take quizzes that track their progress; teachers manage the library, author quizzes (5 question types), and monitor students. The UI uses a custom **"Aurora Glass"** design system (gradient-mesh backgrounds, frosted-glass cards) with light/dark mode.

> Built for **ITE101**, and packaged as a **drop-in module** for the **ITE103 Tawi-Tawi** super-app. Runs on **Android, Windows, Linux, and macOS** from a single codebase.

---

## ⚡ TL;DR (get it running in 5 steps)

```bash
git clone <YOUR_REPO_URL>
cd tdlfeduc_flutter_apk
flutter pub get
```
1. Create a free **Supabase** project (or use the one already configured in `lib/config/app_config.dart`).
2. In Supabase → **SQL Editor**, paste & run **`supabase/schema.sql`** (creates tables, policies, the sign-up trigger).
3. *(Optional)* run **`supabase/seed.sql`** to load 10 courses + 20 books + 100 quizzes of example content.
4. In Supabase → **Authentication → Sign In/Providers → Email**, turn **OFF "Confirm email"** (so new accounts can log in immediately).
5. Put your project's **URL + anon key** in `lib/config/app_config.dart`, then `flutter run -d windows` (or your device).

> ⚠️ **Web is NOT supported** (the app uses `sqflite`). Don't run with `-d chrome`/`-d edge`.

Full details below. **Read the [Supabase Setup](#2-set-up-supabase-the-backend) section carefully — 90% of "it doesn't work" issues come from skipping a step there.**

---

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [How It Works (Architecture)](#how-it-works-architecture)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [1. Clone & install](#1-clone--install)
  - [2. Set up Supabase (the backend)](#2-set-up-supabase-the-backend)
  - [3. Point the app at your Supabase project](#3-point-the-app-at-your-supabase-project)
  - [4. Run the app](#4-run-the-app)
- [Roles: Student vs Teacher](#roles-student-vs-teacher)
- [Tawi-Tawi Integration (ITE103)](#tawi-tawi-integration-ite103)
- [Project Structure](#project-structure)
- [Data & Persistence](#data--persistence)
- [Configuration Reference](#configuration-reference)
- [Troubleshooting](#troubleshooting)
- [Handy Commands](#handy-commands)

---

## Features

**Everyone**
- 🔐 **Cloud auth (Supabase)** — sign up / sign in as **Student** or **Teacher**. Sessions persist on-device, so once you've logged in you stay logged in (even offline).
- 👤 **Rich profile** — username, full name, email, student ID, grade level. Students see accuracy, stats, achievements, and recent activity.
- 🎨 **Aurora Glass UI** — gradient backgrounds, frosted-glass cards, persistent light/dark theme.

**Students**
- 📖 **Books** — browse (compact auto-fitting grid), **filter by course**, **search**, **sort**, **download PDFs** for offline reading, and **Discover** more from Open Library.
- 🧠 **Quizzes** — 5 question types: **multiple choice, true/false, fill-in-the-blank, enumeration, open-ended**. Search/filter by type & course, see your score, pass/fail, and history.

**Teachers** (full CRUD)
- 🛠️ **Books** — **add, edit, delete** (tap a book → manage sheet).
- ✏️ **Quizzes** — **add** (all 5 types, with a multiple-choice option editor), **edit**, **delete**.
- 🏷️ **Courses** — add custom course categories (the list is shared across Books & Quizzes).
- 👥 **Directory** — view all teachers and all students with their info; tap a student to see their quiz progress.
- 📊 **Monitor** — student scores and pass rates.

> Passing score is **75%** (configurable: `passingScore` in `lib/config/app_config.dart`).

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework / UI | Flutter (Material 3) |
| Language | Dart |
| **Cloud backend** | **Supabase** — Postgres + Auth + Row Level Security + REST |
| Auth | `supabase_flutter` (email/password) |
| State management | [`provider`](https://pub.dev/packages/provider) |
| Local cache / offline | [`sqflite`](https://pub.dev/packages/sqflite) (+ `sqflite_common_ffi` on desktop) |
| HTTP / PDF download | [`dio`](https://pub.dev/packages/dio) |
| Open PDFs / links | `open_filex`, `url_launcher` |
| Preferences (theme/session) | `shared_preferences` |
| IDs | `uuid` |

---

## How It Works (Architecture)

**Offline-first with a cloud source of truth.** Supabase holds accounts and content; SQLite mirrors content locally so the app keeps working without internet.

| Data | Lives in | Notes |
|---|---|---|
| **Accounts & profiles** | Supabase **Auth** + `profiles` table | Session cached on-device → stays logged in offline |
| **Books / Quizzes / Courses** | Supabase tables → cached in **SQLite** | Read with the public **anon key**; teacher writes guarded by **RLS** |
| **Downloaded PDFs** | App documents dir (`books/<id>.pdf`) | Downloaded once, then offline |
| **Theme** | `shared_preferences` | — |

```
┌──────────────┐   supabase_flutter (REST + Auth)   ┌─────────────────────┐
│  Flutter app │ ───────── books/quizzes/auth ─────▶ │  Supabase            │
│  (UI +       │ ◀──────────── JSON / JWT ────────── │  Postgres + Auth+RLS │
│  Providers)  │                                     └─────────────────────┘
│              │   sqflite (write-through cache)     ┌─────────────────────┐
│              │ ──────── books/quizzes/courses ────▶ │  SQLite (offline)    │
└──────────────┘                                     └─────────────────────┘
```

> **Security note:** the **anon key** in `app_config.dart` is a *public* client key — safe to commit. All access control is enforced by **RLS** in `schema.sql`. **Never** put the `service_role` key or your DB password in the app.

---

## Prerequisites

1. **Flutter SDK** — stable, **3.27+** (developed on **Flutter 3.44 / Dart 3.12**). https://docs.flutter.dev/get-started/install
   - Add `…/flutter/bin` to your `PATH`. On Windows, if `flutter` isn't recognised, call it by full path, e.g. `C:\Users\<you>\flutter\bin\flutter.bat run -d windows`.
2. **Git** — https://git-scm.com/downloads
3. **A run target** (at least one):
   - **Windows desktop** — Visual Studio with *"Desktop development with C++"*.
   - **Android** — Android Studio + SDK + an emulator, or a physical device with USB debugging.
   - **macOS/Linux** — Xcode (mac) / `clang cmake ninja-build libgtk-3-dev pkg-config` (linux).
4. **A Supabase account** — free tier is fine: https://supabase.com

Verify:
```bash
flutter --version
flutter doctor      # fix any ❌ before continuing
flutter devices
```

---

## Getting Started

### 1. Clone & install

```bash
git clone <YOUR_REPO_URL>
cd tdlfeduc_flutter_apk
flutter pub get
```

### 2. Set up Supabase (the backend)

> 🟢 **You can reuse the Supabase project already configured** in `app_config.dart` and skip to step 4 — but if you want your **own** backend (recommended for a team), do this:

1. Go to [supabase.com](https://supabase.com) → **New project**. Pick a name + DB password (save the password somewhere; you won't put it in the app).
2. Open **SQL Editor → New query**, paste the **entire contents of [`supabase/schema.sql`](supabase/schema.sql)**, and click **Run**.
   This creates the tables (`profiles`, `books`, `quizzes`, `quiz_results`, `courses`), the **Row Level Security** policies, and the **`handle_new_user` trigger** that auto-creates a profile on sign-up. It's safe to re-run.
3. *(Optional but recommended)* Open another query, paste **[`supabase/seed.sql`](supabase/seed.sql)**, and **Run** to load example content: **10 courses, 20 downloadable public-domain books, 100 quizzes** across all 5 types.
4. **Turn off email confirmation** (so new accounts can sign in right away during development):
   **Authentication → Sign In / Providers → Email → uncheck "Confirm email" → Save.**
5. Get your keys: **Project Settings → API** → copy the **Project URL** and the **anon / public** key.

> 💡 **Why a sign-up trigger?** When a user registers, Supabase Auth creates the user and the trigger copies their details into the `profiles` table. The trigger also **auto-dedupes usernames** (a second "juan" becomes "juan1") so sign-up never fails with a vague *"Database error saving new user."*

### 3. Point the app at your Supabase project

Open [`lib/config/app_config.dart`](lib/config/app_config.dart) and set:

```dart
static const String supabaseUrl     = 'https://YOUR-PROJECT.supabase.co';
static const String supabaseAnonKey = 'YOUR-ANON-PUBLIC-KEY';
```

(The values already in the file point at a working shared project — replace them only if you made your own in step 2.)

### 4. Run the app

```bash
flutter devices
flutter run -d windows          # desktop
flutter run -d <android-id>     # a plugged-in phone / emulator (from `flutter devices`)
```

While running: **`r`** hot reload · **`R`** hot restart · **`q`** quit.

First launch: **sign up** (choose Student or Teacher), then sign in. With the seed loaded, Books and Quizzes are populated immediately.

---

## Roles: Student vs Teacher

| | Student | Teacher |
|---|---|---|
| Browse books / take quizzes | ✅ | ✅ |
| Download books | ✅ | ✅ |i
| Add / edit / delete books | ❌ | ✅ |
| Add / edit / delete quizzes | ❌ | ✅ |
| Add courses | ❌ | ✅ |
| Directory (teachers + students) | ❌ | ✅ |

Teacher write-access is enforced by **RLS** in Supabase, not just hidden in the UI — a student can't modify content even via the API. Pick your role at sign-up (it's stored in your profile).

---

## Tawi-Tawi Integration (ITE103)

This app ships as a **drop-in module** for the Tawi-Tawi super-app. The single entry widget **`TdlfEducApp`** (in [`lib/tdlf_educ_app.dart`](lib/tdlf_educ_app.dart)) boots everything itself (Supabase + desktop SQLite), brings its own providers, and renders its own themed app.

**Full step-by-step is in [`INTEGRATION.md`](INTEGRATION.md).** In short:
- Copy this project's `lib/` into `tawi-tawi-frontend/lib/features/integrates services/TDLF-Educ/` (delete the copied `main.dart`).
- Add the extra dependencies to the host `pubspec.yaml` (`supabase_flutter`, `dio`, `uuid`, `open_filex`, `url_launcher`, and the desktop-SQLite trio). The host needs **Android Gradle Plugin 8.9.1+** (one of our deps pulls `androidx.browser:1.9.0`).
- Open it from a launcher tile **in guest mode** so it skips its own login (the host already authenticates the user):
  ```dart
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const TdlfEducApp(guestMode: true)),
  );
  ```
  A **back button** (and Android system-back) returns to the host. Guests browse content read-only; teachers manage content from the **standalone** app, and it syncs to the embedded one (same Supabase).

### ▶️ Running the Tawi-Tawi host app (for teammates)

The TDLF-Educ module is **already integrated and committed** in the Tawi-Tawi frontend, so you just clone and run it — no copying needed.

> ⚠️ **Android only.** The host super-app uses Firebase/Agora/LiveKit, which don't run on Windows/desktop or web. Use a **physical Android phone** (USB debugging on) or an **Android emulator**. Don't use `-d windows`/`-d chrome`.

1. **Clone the host repo** (the team's central frontend) and enter it:
   ```bash
   git clone https://github.com/unkind-human-being/tawi-tawi-frontend.git
   cd tawi-tawi-frontend
   ```
2. **Get dependencies:**
   ```bash
   flutter pub get
   ```
3. **Plug in an Android phone** (enable *Developer options → USB debugging*, then accept the prompt) or start an emulator. Confirm it's detected:
   ```bash
   flutter devices
   ```
4. **Run it** (use your device id from `flutter devices`):
   ```bash
   flutter run -d <android-device-id>
   ```
   First build takes a few minutes. When it's up, tap the **TDLF-Educ** tile on the Tawi-Tawi home → you'll see our **welcome screen → Continue** → the module (guest mode).

**If the build fails:**
| Error | Fix |
|---|---|
| `... requires Android Gradle plugin 8.9.1` | Already set in the repo. If it reverted, set AGP to **8.9.1** in `android/settings.gradle.kts`. |
| Gradle crash / *"insufficient memory"* on a low-RAM PC (≈8 GB) | Lower the heap in `android/gradle.properties`, e.g. `org.gradle.jvmargs=-Xmx2560m`. **Keep this change local — don't commit it** (it's machine-specific). |
| `flutter: command not found` (Windows) | Use the full path, e.g. `C:\…\flutter\bin\flutter.bat run -d <id>`. |
| Build hangs / device "not found" mid-build | Make sure the phone stays unlocked and connected; re-accept the USB-debugging prompt. |

> Teacher tools (add/edit content, course-scoped monitoring) are used from the **standalone** app; the host opens as a guest by design. Everything syncs through the same Supabase.

---

## Project Structure

```
tdlfeduc_flutter_apk/
├── lib/
│   ├── main.dart                      # Standalone entry → runApp(TdlfEducApp())
│   ├── tdlf_educ_app.dart             # Drop-in module entry (TdlfEducApp, guestMode)
│   ├── config/app_config.dart         # Supabase URL/key, roles, grades, DB version
│   ├── theme/app_theme.dart           # "Aurora Glass" design system
│   ├── widgets/                       # aurora_background.dart, glass.dart
│   ├── providers/                     # auth, book, quiz, course, theme (ChangeNotifier)
│   ├── screens/
│   │   ├── auth/login_screen.dart
│   │   ├── home_screen.dart           # Dashboard + glass nav (bottom on mobile, sidebar on desktop)
│   │   ├── books_screen.dart          # Browse/search/sort/download + teacher CRUD
│   │   ├── quiz_screen.dart           # Take quizzes, history, results + teacher CRUD (5 types)
│   │   ├── profile_screen.dart
│   │   ├── settings_screen.dart
│   │   └── teacher/
│   │       ├── students_screen.dart   # Student progress
│   │       └── directory_screen.dart  # Teachers + students directory
│   └── services/
│       ├── api_service.dart           # Supabase data (books/quizzes/courses/results) + PDF download
│       ├── auth_service.dart          # Supabase auth + profile cache
│       └── database_service.dart      # SQLite schema + migrations (offline cache)
├── supabase/
│   ├── schema.sql                     # ← run this in Supabase first (tables, RLS, trigger)
│   ├── seed.sql                       # ← optional example content (10 courses / 20 books / 100 quizzes)
│   └── functions/                     # Edge Function for the Tawi-Tawi backend handshake
├── INTEGRATION.md                     # Tawi-Tawi integration guide
└── android/ ios/ windows/ linux/ macos/
```

---

## Data & Persistence

- **Cloud:** Supabase Postgres — `profiles`, `books`, `quizzes`, `quiz_results`, `courses`. Access controlled by RLS (see `schema.sql`).
- **Local cache:** SQLite file `tdlf_educ.db`, **schema version 6**. Tables: `users` (legacy/local), `books`, `courses`, `quizzes`, `quiz_attempts`.
- **Migrations** run automatically on launch (`_upgradeDatabase` in [`database_service.dart`](lib/services/database_service.dart)). When you change the local schema, bump `databaseVersion` in `app_config.dart` **and** add an `if (oldVersion < N)` block — and make sure new columns are also added to the `CREATE TABLE` (for fresh installs).
- **Downloaded books** are saved as `books/<book_id>.pdf` and opened with the OS viewer.

> 🧹 **Reset local data:** uninstall the app (or *Clear storage* on Android) to recreate the SQLite DB from scratch.

---

## Configuration Reference

Key constants in [`lib/config/app_config.dart`](lib/config/app_config.dart):

| Constant | Meaning |
|---|---|
| `supabaseUrl` | Your Supabase project URL |
| `supabaseAnonKey` | Public anon key (safe to commit; RLS does the gatekeeping) |
| `passingScore` (`75.0`) | Minimum % to pass a quiz |
| `userRoles` (`Student, Teacher, Guest`) | Roles at sign-up |
| `gradeLevels` | Grade options for students |
| `databaseName` (`tdlf_educ.db`) | SQLite file name |
| `databaseVersion` (`6`) | Local schema version (drives migrations) |
| `apiBaseUrl` | **Legacy** — unused; the app talks to Supabase, not this URL |

---

## Troubleshooting

| Problem | Fix |
|---|---|
| **`{"code":"unexpected_failure","message":"Database error saving new user"}`** on sign-up | The Supabase **`schema.sql` wasn't run** (or an old version was). Run the latest `supabase/schema.sql` — its trigger auto-dedupes usernames. (Older cause: a duplicate `username`.) |
| Sign-up works but you **can't log in** | "Confirm email" is still ON. Turn it OFF: *Authentication → Sign In/Providers → Email*. |
| **Books are empty / "you're offline"** but quizzes show | Your local DB predates the `course_id` fix. Update to the latest code (adds a v6 migration) **or** uninstall to recreate the DB. |
| Books **and** quizzes empty | App can't reach Supabase, or `supabaseUrl`/`supabaseAnonKey` are wrong. Check internet + the keys in `app_config.dart`. |
| `flutter: command not found` (Windows) | Flutter isn't on PATH. Use the full path: `C:\…\flutter\bin\flutter.bat …`, or add it to PATH. |
| Host build fails: *"requires Android Gradle plugin 8.9.1"* | Bump the host's AGP to **8.9.1** in `android/settings.gradle.kts` (our `url_launcher` dep needs it). |
| Gradle daemon crash / *"insufficient memory"* on a low-RAM PC | Lower the heap in `android/gradle.properties` (e.g. `org.gradle.jvmargs=-Xmx2560m`). Keep this change **local** — don't commit a machine-specific heap. |
| App ran on **web** and broke | Web is unsupported (`sqflite`). Use Android or a desktop target. |
| Generic build weirdness after pulling | `flutter clean && flutter pub get`, then rebuild. |

---

## Handy Commands

```bash
flutter pub get             # install dependencies
flutter run -d <device>     # run in debug
flutter analyze             # static analysis (run before committing)
dart format .               # auto-format
flutter clean               # clear build artifacts (fixes many build issues)
flutter doctor -v           # environment diagnostics
```

---

_Built with Flutter + Supabase for ITE101 / ITE103._
## ITD101 and ITD103 Final Project