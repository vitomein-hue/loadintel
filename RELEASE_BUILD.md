# Load Intel - Release Build Guide

## Quick Reference

### Android (Play Store)
```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols/loadintel/android
```
**Output:** `build/app/outputs/bundle/release/app-release.aab`

### iOS (TestFlight/App Store)
```bash
flutter build ipa --release --obfuscate --split-debug-info=build/symbols/loadintel/ios
```
**Output:** `build/ios/ipa/Load Intel.ipa`

---

## Detailed Instructions

### Prerequisites
- Flutter SDK (stable channel)
- Android: Configured signing key in `android/key.properties`
- iOS: Valid provisioning profile and certificate in Xcode

### Android Release Build

1. **Build the app bundle:**
   ```bash
   flutter build appbundle --release --obfuscate --split-debug-info=build/symbols/loadintel/android
   ```

2. **Locate outputs:**
   - AAB: `build/app/outputs/bundle/release/app-release.aab`
   - Symbols: `build/symbols/loadintel/android/`

3. **Upload to Play Console:**
   - Upload the AAB via Play Console
   - **Archive the symbols folder** (required for crash de-obfuscation)

### iOS Release Build

1. **Build the IPA:**
   ```bash
   flutter build ipa --release --obfuscate --split-debug-info=build/symbols/loadintel/ios
   ```

2. **Locate outputs:**
   - IPA: `build/ios/ipa/Load Intel.ipa`
   - Dart symbols: `build/symbols/loadintel/ios/`
   - dSYM files: `build/ios/archive/Runner.xcarchive/dSYMs/`

3. **Upload to TestFlight:**
   - Option A: Use Xcode Organizer
   - Option B: Use Transporter app with the IPA
   - **Archive both symbol directories** (Dart symbols + dSYMs)

---

## Symbol Management

### What are symbol files?

When you build with `--obfuscate`, Flutter scrambles class/function names to reduce app size and make reverse-engineering harder. The `--split-debug-info` flag extracts the "map" needed to decode obfuscated crash stack traces.

### Why archive symbols?

Without the matching symbol files, production crash logs will show obfuscated names like `a.b.c()` instead of `LoadRecipe.fromMap()`, making debugging impossible.

### Symbol Storage Recommendations

1. **Create version-specific archives:**
   ```bash
   # After each build, archive symbols with version number
   cd build/symbols/loadintel
   zip -r ../../../loadintel-symbols-v1.2.3-android.zip android/
   zip -r ../../../loadintel-symbols-v1.2.3-ios.zip ios/
   
   # For iOS, also archive dSYMs
   cd ../../ios/archive/Runner.xcarchive
   zip -r ../../../../loadintel-dsyms-v1.2.3-ios.zip dSYMs/
   ```

2. **Storage options:**
   - Private Git repository (recommended)
   - Secure cloud storage (Google Drive, Dropbox, AWS S3)
   - Local backup drive (ensure redundancy)

3. **Retention policy:**
   - Keep symbols for active versions indefinitely
   - Keep symbols for deprecated versions at least 90 days after sunset
   - Never delete symbols for versions still in production

### De-obfuscating Crash Logs

When you receive an obfuscated crash log from Firebase/Crashlytics:

1. **Save the crash log** to a file (e.g., `crash.txt`)

2. **De-obfuscate using Flutter:**
   ```bash
   # Android crash
   flutter symbolize -i crash.txt -d build/symbols/loadintel/android
   
   # iOS crash
   flutter symbolize -i crash.txt -d build/symbols/loadintel/ios
   ```

3. **Output** will show the original function names and line numbers

---

## Release Configuration

### Android (R8 Shrinking)

The app uses R8 code shrinking and resource shrinking in release builds:
- **ProGuard rules:** `android/app/proguard-rules.pro`
- **Enabled in:** `android/app/build.gradle.kts`
- Rules preserve Flutter framework and plugin classes

### iOS (dSYM Generation)

The iOS project automatically generates dSYM files for release builds:
- **Configuration:** `ios/Runner.xcodeproj/project.pbxproj`
- **Setting:** `DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym"`
- dSYMs are compatible with Flutter's obfuscation

---

## Troubleshooting

### Build fails with "ProGuard rule errors" or "Missing classes detected while running R8"
- Check `android/app/proguard-rules.pro` for syntax errors
- Verify all plugin packages are kept with `-keep` rules
- Google Play Core classes are kept (required by Flutter embedding even if not used)

### Java version warnings during build
- Warnings about "source value 8 is obsolete" are harmless
- These come from some Gradle plugins using old Java versions
- Your app compiles with Java 17 (modern version)

### App crashes immediately after obfuscation
- Check ProGuard rules include all necessary plugin classes
- Test in release mode before submitting: `flutter run --release`

### Crash logs still obfuscated after symbolization
- Ensure you're using symbols from the **exact same build**
- Symbol files are build-specific and not interchangeable between versions

### iOS upload rejected
- Ensure provisioning profile matches bundle identifier
- Check code signing settings in Xcode
- Verify dSYM files are included in the archive

---

## CI/CD Integration

Example GitHub Actions workflow snippet:

```yaml
- name: Build Android Release
  run: |
    flutter build appbundle --release \
      --obfuscate \
      --split-debug-info=build/symbols/loadintel/android

- name: Archive symbols
  run: |
    cd build/symbols/loadintel
    tar -czf loadintel-symbols-${{ github.run_number }}-android.tar.gz android/

- name: Upload symbols artifact
  uses: actions/upload-artifact@v3
  with:
    name: android-symbols
    path: build/symbols/loadintel/*.tar.gz
    retention-days: 90
```

---

## Security Notes

- Symbol files should be kept **private** (not in public repos)
- The `build/symbols/` directory is git-ignored by default
- Store symbols in encrypted/private storage only
- Limit access to symbol archives to development team only
