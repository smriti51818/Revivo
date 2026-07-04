# app/ — Flutter frontend (Riverpod)

The Revivo mobile/web app. One codebase, four role experiences, styled to the Revivo design system
(green, card-based, rounded, pill buttons).

## Layout (planned)
```
app/lib/
├── core/        # theme (design tokens), router, api client, config, models
├── features/
│   ├── auth/    # splash, role select, login, register
│   ├── seller/  # dashboard, add listing, order requests, insights, impact
│   ├── buyer/   # dashboard, product details, orders, order confirmed
│   ├── cook/    # rescue inbox, receive, meals served, impact
│   └── shared/  # impact dashboard, leaderboard, notifications, profile
└── main.dart
```

## Commands
```bash
make app-get         # flutter pub get
make app-run         # run on device/emulator
make app-web         # run in browser
make app-build-apk   # release APK
make analyze         # flutter analyze
```
