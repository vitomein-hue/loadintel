# Load Intel

Offline-first Flutter app for logging load recipes and range results.

## Setup

1) Install Flutter (stable) and platform toolchains for Android/iOS.
2) Fetch dependencies:

```bash
flutter pub get
```

3) Run the app:

```bash
flutter run
```

## Notes

- Local data is stored in SQLite (sqflite) under the app documents directory.
- Backup/Export files are written to `exports/` inside app documents.
- In-app purchase product id: `loadintel_lifetime` (update in `lib/services/purchase_service.dart` to match store config).
- Camera and photo library permissions are declared in AndroidManifest and iOS Info.plist.
- Generate app icon and splash once after `pub get`:

```bash
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash
```
