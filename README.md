# TeraFarm

Urban farming marketplace demo — grow, sell, and connect terrace/rooftop farmers.

This repository has been modernized for a **frictionless local demo**. By default it runs in **demo mode** with in-memory Firebase fakes and seeded sample data (no real Firebase project required).

## Prerequisites

- Flutter **3.44+** (Dart 3.9+)
- JDK **17 or 21** (Android Studio JBR works; JDK 25 is too new for the current Gradle toolchain)
- Android SDK with an emulator or device
- Accept Android licenses if prompted: `flutter doctor --android-licenses`

```bash
flutter doctor
```

## Quick start (demo mode)

```bash
flutter pub get
flutter run --dart-define-from-file=config/demo.json
```

Or simply `flutter run` — `DEMO_MODE` defaults to `true`.

### Demo login

1. Open the app → **Get Started**
2. Tap **Continue as Demo Farmer (DEV)**
3. Signed in as **Arjun Mehta** (`demo@terafarm.app`) with seeded farm, orders, community, and notifications

Logout from **Menu → Log out** or **Account → Logout**.

## Configuration

| Variable | Required for demo? | Description |
|----------|--------------------|-------------|
| `DEMO_MODE` | No (defaults true) | In-memory fakes + seed; never calls Firebase |
| `GEMINI_API_KEY` | No | Optional live plant diagnosis / advice |
| `OPENWEATHER_API_KEY` | No | Optional live weather for plant care |
| `GEMINI_MODEL` | No | Defaults to gemini-2.0-flash |

- `config/demo.json` — demo only
- `config/example.json` — all keys documented
- Copy to `config/local.json` for personal keys (gitignored)

```bash
flutter run --dart-define-from-file=config/local.json
```

Do not commit real API keys. Previously hardcoded Gemini/OpenWeather keys were removed; rotate any keys that were ever committed.

### Real Firebase (optional)

```bash
flutter run --dart-define=DEMO_MODE=false
```

If Firebase init fails, the app falls back to local demo mode.

## Suggested walkthrough

1. Landing → DEV login (DEMO banner visible)
2. Home — search/filter farms; notifications; open a farm
3. Product → Buy Now → confirm order (demo checkout, no payment)
4. Menu → My orders
5. Farm tab — earnings, manage farm, seller Order list
6. Community — Forum, Collab, Leaderboard
7. Shop — add items to cart
8. AI — Tera Care / TeraDoc / Recommend (demo-labeled unless live keys)
9. Account — edit profile, logout, login again

## Feature status

| Feature | Status |
|---------|--------|
| Auth + DEV login | Demo mock (or real Firebase when DEMO_MODE=false) |
| Farms, products, cart, orders | Demo in-memory Firestore |
| Forum groups/channels | Demo Firestore + local image paths |
| Collab requests | Demo Firestore |
| Leaderboard | Local mock data |
| Shop inventory | Local mock → shared cart |
| AI features | Demo responses (optional live Gemini/OpenWeather) |
| Image uploads | Local path in demo; Firebase Storage otherwise |

## Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --dart-define-from-file=config/demo.json
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Gradle / Java errors | `flutter config --jdk-dir="C:\Program Files\Android\Android Studio\jbr"` |
| Android licenses | `flutter doctor --android-licenses` |
| Empty farms after restart | Expected — seed reloads on cold start |
| Live AI | Set keys in config/local.json |

## Architecture

- `lib/services/app_services.dart` — auth/firestore/storage/AI/cart locator
- `lib/demo/demo_seed.dart` — deterministic sample data
- `lib/core/app_config.dart` — compile-time flags

Demo mode never initializes Firebase, so missing credentials cannot crash the walkthrough.