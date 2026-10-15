# Block Internet Access (Flutter)

## Run
```
flutter create . --platforms=android,ios   # generates android/ and ios/ (keeps lib/ and pubspec.yaml)
flutter pub get
flutter run
```

## Structure
- `lib/main.dart` app entry
- `lib/theme.dart` colors and theme
- `lib/screens/splash_screen.dart` start screen (animated, then opens the app)
- `lib/home_shell.dart` navigation bar + state
- `lib/screens/` apps, schedule, settings pages
- `lib/widgets/` shared widgets
- `lib/models/app_item.dart` app model
- `lib/services/block_service.dart` hook for native blocking

## Real blocking
The UI calls `BlockService`. To actually cut internet per app on Android, implement a local
`VpnService` in Kotlin and connect it through a `MethodChannel`.
