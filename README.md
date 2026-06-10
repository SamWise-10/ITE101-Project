# 📚 TDLF-Educ

A modern, **offline-first education app** built with **Flutter**. Students can download books for offline reading and take quizzes that track their progress; teachers can manage the library, author quizzes, and monitor student scores. The UI uses a custom **"Aurora Glass"** design system (gradient mesh backgrounds, frosted-glass cards) with full light/dark mode support.

> Built for the **ITE101** course. The app runs on Android, Windows, Linux, and macOS from a single codebase.

---

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [How It Works (Architecture)](#how-it-works-architecture)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [1. Clone the repository](#1-clone-the-repository)
  - [2. Install dependencies](#2-install-dependencies)
  - [3. Configure the backend URL](#3-configure-the-backend-url)
  - [4. Run the app](#4-run-the-app)
- [Building a Release Build](#building-a-release-build)
- [Backend API](#backend-api)
- [Project Structure](#project-structure)
- [Data & Persistence](#data--persistence)
- [Configuration Reference](#configuration-reference)
- [Troubleshooting](#troubleshooting)
- [Handy Commands](#handy-commands)
- [Contributing](#contributing)

---

## Features

**For everyone**
- 🔐 **Local authentication** — sign up / sign in with Student, Teacher, or Guest roles. Accounts are stored **on-device** (no server needed to log in).
- 👤 **Rich profile** — username, full name, email, student ID, and grade level. Students see accuracy, stats, achievements, and recent quiz activity.
- 🎨 **Aurora Glass UI** — gradient backgrounds, frosted-glass cards, and a polished light/dark theme that persists across restarts.

**Students**
- 📖 **Books** — browse books, **filter by course**, **search**, **sort** (A–Z / Z–A / by course), and **download for offline reading** (PDF).
- 🧠 **Quizzes** — take True/False and open-ended quizzes, **search** and **filter by type/course**, see your score, pass/fail, and full attempt history.

**Teachers**
- 🛠️ **Manage Books** — add and delete books in the library.
- ✏️ **Manage Quizzes** — author and delete quiz questions per course.
- 📊 **Monitor Students** — review student quiz scores and progress.

> Passing score for quizzes is **75%** (configurable in `lib/config/app_config.dart`).

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework / UI | Flutter (Material 3) |
| Language | Dart |
| State management | [`provider`](https://pub.dev/packages/provider) |
| HTTP client | [`dio`](https://pub.dev/packages/dio) (+ [`http`](https://pub.dev/packages/http)) |
| Local database | [`sqflite`](https://pub.dev/packages/sqflite) (SQLite) |
| Local files / paths | `path`, `path_provider` |
| Open downloaded PDFs | [`open_filex`](https://pub.dev/packages/open_filex) |
| Password hashing | `crypto` (SHA-256) |
| Preferences (theme) | `shared_preferences` |
| Connectivity | `connectivity_plus` |
| Permissions | `permission_handler` |
| IDs | `uuid` |

---

## How It Works (Architecture)

The app is **offline-first** and has two storage layers:

| Data | Where it lives | Needs the backend? |
|---|---|---|
| **User accounts** (signup, login, profile) | Local **SQLite** on the device | ❌ No — fully local |
| **Books & Quizzes** (content) | Fetched from a **REST API**, then cached in SQLite | ✅ Yes, to load/refresh content |
| **Downloaded book PDFs** | App documents directory (`books/<book_id>.pdf`) | Only to download once |
| **Theme (dark/light)** | `shared_preferences` | ❌ No |

This means you can **clone and run the app immediately** — you'll be able to sign up and log in right away. The **Books** and **Quizzes** lists will simply be empty until the backend API is reachable (see [Backend API](#backend-api)).

```
┌─────────────┐      Dio (HTTP)       ┌──────────────┐
│  Flutter    │ ───── books/quizzes ─▶ │  REST API     │
│  app (UI)   │ ◀──────── JSON ─────── │  (your server)│
│             │                        └──────────────┘
│  Providers  │      sqflite
│  (state)    │ ───── users / cache ─▶ ┌──────────────┐
└─────────────┘                        │  SQLite (DB) │
                                       └──────────────┘
```

---

## Prerequisites

Install the following before you start:

1. **Flutter SDK** — stable channel, **3.27 or newer** (this project is developed on **Flutter 3.44 / Dart 3.12**).
   👉 https://docs.flutter.dev/get-started/install
   After installing, add Flutter to your `PATH`:
   - **Windows:** add `C:\path\to\flutter\bin` to *System Properties → Environment Variables → Path*.
   - **macOS / Linux:** add `export PATH="$PATH:/path/to/flutter/bin"` to your `~/.zshrc` or `~/.bashrc`.

2. **Git** — https://git-scm.com/downloads

3. **A target to run on** (pick at least one):
   - **Android** — [Android Studio](https://developer.android.com/studio) with the Android SDK + an emulator (AVD), **or** a physical Android device with USB debugging enabled.
   - **Windows desktop** — Visual Studio with the *"Desktop development with C++"* workload.
   - **macOS / iOS** — Xcode (macOS only).
   - **Linux desktop** — `clang`, `cmake`, `ninja-build`, `libgtk-3-dev`, `pkg-config`.

4. **An editor** — VS Code (with the Flutter & Dart extensions) or Android Studio.

### Verify your setup

```bash
flutter --version      # confirm Flutter is on your PATH
flutter doctor         # checks SDKs, toolchains, devices — fix any ❌
flutter devices        # lists devices/emulators you can run on
```

> ⚠️ **Web is not supported.** The app relies on `sqflite`, which does not run in a browser. Do **not** run with `-d chrome`/`-d edge`.

---

## Getting Started

### 1. Clone the repository

```bash
git clone <YOUR_REPO_URL>
cd tdlfeduc_flutter_apk
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure the backend URL

Open [`lib/config/app_config.dart`](lib/config/app_config.dart) and set `apiBaseUrl` to point at **your** backend. The correct value depends on **where the app runs vs. where the server runs**:

| You're running the app on… | Set `apiBaseUrl` to | Why |
|---|---|---|
| **Android emulator** | `http://10.0.2.2:8000` | `10.0.2.2` is the emulator's alias for your computer's `localhost` |
| **Android physical device** (same Wi-Fi) | `http://<YOUR_PC_LAN_IP>:8000` | e.g. `http://192.168.1.20:8000` — find it with `ipconfig` (Windows) / `ifconfig` (macOS/Linux) |
| **Windows / Linux / macOS desktop** | `http://localhost:8000` | the server is on the same machine |
| **iOS simulator** | `http://localhost:8000` | shares the Mac's network |
| **Physical iOS device** | `http://<YOUR_PC_LAN_IP>:8000` | same as Android physical device |

```dart
// lib/config/app_config.dart
static const String apiBaseUrl = 'http://10.0.2.2:8000'; // ← change this
```

> 💡 **No backend yet?** You can skip this step. The app still runs and you can sign up / log in — only the Books and Quizzes lists will be empty.

### 4. Run the app

List your devices, then run on one of them:

```bash
flutter devices
flutter run -d <device-id>
```

Common examples:

```bash
# Android (emulator must be running, or a phone plugged in)
flutter run -d emulator-5554

# Windows desktop
flutter run -d windows

# macOS desktop
flutter run -d macos

# Linux desktop
flutter run -d linux
```

**Launching an Android emulator from the CLI:**

```bash
flutter emulators                       # list available emulators
flutter emulators --launch <emulator-id>
```

While the app is running, press **`r`** for hot reload, **`R`** for hot restart, and **`q`** to quit.

---

## Building a Release Build

**Android APK** (most common for sharing/testing):

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

Smaller, per-architecture APKs:

```bash
flutter build apk --release --split-per-abi
```

**Android App Bundle** (for the Play Store):

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

**Desktop:**

```bash
flutter build windows   # build/windows/x64/runner/Release/
flutter build macos     # build/macos/Build/Products/Release/
flutter build linux     # build/linux/x64/release/bundle/
```

---

## Backend API

The app talks to a REST API via Dio (base URL = `apiBaseUrl`). **Authentication is NOT part of the API** — it's handled locally. The backend only provides **content** (books, quizzes, courses) and receives quiz results.

### Endpoints used

| Method | Endpoint | Purpose |
|---|---|---|
| `GET` | `/books` | List all books |
| `POST` | `/books` | Add a book (teacher) |
| `DELETE` | `/books/{book_id}` | Delete a book (teacher) |
| `GET` | `/quizzes` | List all quizzes |
| `POST` | `/quizzes` | Add a quiz (teacher) |
| `DELETE` | `/quizzes/{quiz_id}` | Delete a quiz (teacher) |
| `GET` | `/courses` | List courses |
| `GET` | `/students` | List students (teacher view) |
| `POST` | `/quiz-results` | Submit a student's quiz result |

### Expected JSON shapes

`GET /books`, `GET /quizzes`, and `GET /courses` are expected to return a **list wrapping a `data` array**:

```jsonc
// GET /books
[
  {
    "data": [
      {
        "book_id": "book-001",
        "book_name": "Intro to Computing",
        "link": "https://example.com/files/intro.pdf",  // direct PDF URL to download
        "book_picture": "https://example.com/covers/intro.png",
        "course_id": "course-001"
      }
    ]
  }
]
```

```jsonc
// GET /quizzes
[
  {
    "data": [
      {
        "quiz_id": "quiz-001",
        "question": "Is RAM volatile memory?",
        "quiz_type": "true_false",          // "true_false" | "open_ended"
        "correct_answer": "True",
        "reason": "RAM loses its contents when powered off.",
        "course_id": "course-001"
      }
    ]
  }
]
```

```jsonc
// POST /quiz-results  (request body sent by the app)
{
  "student_id": "<uuid>",
  "student_name": "Jane Doe",
  "score": 80.0,
  "total_questions": 5,
  "passed": true,
  "submitted_at": "2026-06-10T09:30:00.000"
}
```

> **Course IDs** referenced by the app are `course-001` … `course-004`, mapping to: *Computer Fundamentals, Basic Mathematics, Science and Technology, English Communication*.

---

## Project Structure

```
tdlfeduc_flutter_apk/
├── lib/
│   ├── main.dart                       # App entry point, providers, routing
│   ├── config/
│   │   └── app_config.dart             # API URL, endpoints, roles, grades, DB version
│   ├── theme/
│   │   └── app_theme.dart              # "Aurora Glass" design system (light + dark themes)
│   ├── widgets/
│   │   ├── aurora_background.dart       # Animated gradient-mesh background
│   │   └── glass.dart                   # Reusable glass cards, gradient buttons/badges
│   ├── providers/                       # State management (ChangeNotifier)
│   │   ├── auth_provider.dart
│   │   ├── book_provider.dart
│   │   ├── quiz_provider.dart
│   │   └── theme_provider.dart
│   ├── screens/
│   │   ├── auth/login_screen.dart       # Login + sign up
│   │   ├── home_screen.dart             # Dashboard + glass bottom nav
│   │   ├── books_screen.dart            # Browse / search / sort / download books
│   │   ├── quiz_screen.dart             # Take quizzes, history, results
│   │   ├── profile_screen.dart          # Profile, stats, achievements
│   │   ├── settings_screen.dart         # Theme + account
│   │   └── teacher/students_screen.dart # Teacher: monitor students
│   └── services/
│       ├── api_service.dart             # REST calls (Dio): books, quizzes, results
│       ├── auth_service.dart            # Local auth (SQLite + SHA-256)
│       └── database_service.dart        # SQLite schema + migrations
├── android/  ios/  windows/  linux/  macos/  web/   # Platform projects
├── pubspec.yaml                         # Dependencies & metadata
└── README.md
```

---

## Data & Persistence

- **Database:** local SQLite file `tdlf_educ.db` in the app's documents directory, **schema version 4**.
- **Tables:** `users`, `books`, `courses`, `quizzes`, `quiz_attempts`.
- **Migrations** run automatically on launch (see `_upgradeDatabase` in [`database_service.dart`](lib/services/database_service.dart)). Bump `databaseVersion` in `app_config.dart` and add an `if (oldVersion < N)` block when you change the schema.
- **Passwords** are hashed with SHA-256 before storage — plaintext is never saved.
- **Downloaded books** are saved as `books/<book_id>.pdf` in the documents directory and opened with the OS default viewer.

> 🧹 **Reset local data during development:** uninstall the app (or *Clear storage* in Android settings). This wipes the SQLite DB and downloaded files so the schema is recreated from scratch.

---

## Configuration Reference

Key constants in [`lib/config/app_config.dart`](lib/config/app_config.dart):

| Constant | Default | Meaning |
|---|---|---|
| `apiBaseUrl` | `http://10.0.19.22:8000` | Backend base URL (change per your environment) |
| `passingScore` | `75.0` | Minimum % to pass a quiz |
| `userRoles` | `Student, Teacher, Guest` | Roles available at signup |
| `gradeLevels` | `Grade 7 … 4th Year College` | Grade options for students |
| `courses` | 4 fixed courses | Course categories |
| `databaseName` | `tdlf_educ.db` | SQLite file name |
| `databaseVersion` | `4` | Schema version (drives migrations) |

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `flutter: command not found` | Flutter isn't on your `PATH`. Re-check [Prerequisites](#prerequisites). |
| `flutter doctor` shows ❌ | Follow its suggestions (accept Android licenses with `flutter doctor --android-licenses`, install missing toolchains). |
| Books/Quizzes are **empty** | The backend isn't reachable. Verify the server is running and `apiBaseUrl` matches your run target (emulator → `10.0.2.2`, physical device → PC's LAN IP). |
| Network calls fail on Android with an `http://` URL | Android blocks cleartext HTTP by default. Ensure `android:usesCleartextTraffic="true"` is set in `android/app/src/main/AndroidManifest.xml`, or use an `https://` backend. |
| Physical device can't reach the server | Phone and PC must be on the **same Wi-Fi**, and your firewall must allow inbound connections on the server's port. |
| Gradle / build errors after pulling | Run `flutter clean && flutter pub get`, then rebuild. |
| Weird DB errors after a schema change | Uninstall the app to recreate the database (see [Data & Persistence](#data--persistence)). |
| App ran on web and broke | Web is unsupported (`sqflite`). Use Android or a desktop target. |
| Dependencies out of date | `flutter pub get` (or `flutter pub upgrade` to bump within constraints). |

---

## Handy Commands

```bash
flutter pub get             # install dependencies
flutter run -d <device>     # run in debug mode
flutter analyze             # static analysis / lint (run before committing)
dart format .               # auto-format the codebase
flutter test                # run unit/widget tests
flutter clean               # clear build artifacts (fixes many build issues)
flutter doctor -v           # detailed environment diagnostics
```

---

## Contributing

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Make your changes, then **run `flutter analyze` and `dart format .`** — keep analysis clean.
3. Test on at least one target (Android emulator or a desktop build).
4. Commit and open a Pull Request describing what changed and why.

**Code conventions**
- State lives in `providers/`; UI in `screens/` and `widgets/`; data/IO in `services/`.
- Reuse the design system: use `AppTheme`, `AppDecoration.of(context)`, and the widgets in `widgets/glass.dart` (`GlassCard`, `GradientButton`, `GradientIconBadge`, `GradientFab`, `GlassPill`) instead of hard-coding colors.
- When changing the database schema, **always** bump `databaseVersion` and add a migration step.

---

_Built with Flutter for ITE101._
