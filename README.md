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

## Building for Release (TestFlight / Play Store)

### Android (Play Store AAB)

Build obfuscated release bundle with split debug info:

```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols/loadintel/android
```

The AAB will be at `build/app/outputs/bundle/release/app-release.aab`.

### iOS (TestFlight IPA)

Build obfuscated release IPA with split debug info:

```bash
flutter build ipa --release --obfuscate --split-debug-info=build/symbols/loadintel/ios
```

The IPA will be at `build/ios/ipa/Load Intel.ipa`. dSYM files are in `build/ios/archive/Runner.xcarchive/dSYMs/`.

### Important: Symbol Files for Crash De-obfuscation

- **Symbol files** are generated in `build/symbols/loadintel/{android,ios}/` and are **required** to de-obfuscate crash stack traces from production.
- **Archive these symbols** for each release build (by version) in a secure location.
- Without the matching symbols, obfuscated crash logs will be unreadable.
- Use `flutter symbolize` to decode crashes:
  ```bash
  flutter symbolize -i <obfuscated_stack_trace.txt> -d build/symbols/loadintel/android
  ```

### Storage Recommendations

- Store symbols in version control (private repo) or secure cloud storage
- Naming: `loadintel-symbols-v{version}-{platform}.zip`
- Keep symbols for at least 90 days after releasing a new version

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
