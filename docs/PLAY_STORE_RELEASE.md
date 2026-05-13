# Play Store Release Checklist (Playa)

This repo builds Android, but Play Store upload requires a permanent application id, a real release signing key, and compliance checks.

## 1. Set Version

- Update `version:` in `pubspec.yaml` using the `x.y.z+code` format.
- Every Play upload must increment the `+code` value.

## 2. Confirm Application ID

Current Android id: `com.paxpiece.playa`

If this is not the final permanent id, update:

- `android/app/build.gradle.kts` -> `defaultConfig.applicationId`
- Kotlin package paths and package declarations under `android/app/src/main/kotlin`
- Hardcoded MethodChannel names that include the old id

## 3. Configure Release Signing

This repo uses `android/key.properties` for release signing.

- Copy `android/key.properties.example` -> `android/key.properties`
- Fill in your Play upload keystore values
- Do not commit the real `android/key.properties`
- Release builds intentionally fail if `android/key.properties` is missing, so a debug-signed bundle cannot be uploaded by mistake

Generate a durable upload keystore with the JDK `keytool`:

```powershell
keytool -genkeypair -v -keystore ~/playa_upload_keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 9125
```

Keep the keystore and passwords in a secure place. You need the same upload key for future releases unless Google resets it through Play App Signing.

For GitHub Actions release bundles, add these repository secrets:

- `PLAYA_UPLOAD_KEYSTORE_BASE64`: base64-encoded contents of the `.jks` upload keystore
- `PLAYA_UPLOAD_STORE_PASSWORD`
- `PLAYA_UPLOAD_KEY_ALIAS`
- `PLAYA_UPLOAD_KEY_PASSWORD`

## 4. Validate Permissions And Data Safety

- `READ_MEDIA_AUDIO` is used for local library access.
- `POST_NOTIFICATIONS` and foreground service permissions support background playback controls.
- `INTERNET` is used for optional lyrics lookup through LRCLIB (`lrclib.net`).
- Play Console Data safety should match local media access, local playlists/ratings/bookmarks/settings, and online lyrics lookup.
- Keep `PRIVACY_POLICY.md` aligned with the app behavior and reference it from Play Console metadata.

## 5. Keep Metadata Synced

- App name: `Playa`
- Package id: `com.paxpiece.playa`
- Version: keep `pubspec.yaml` synchronized with Play Console release notes.

## 6. Verify Locally

Run the same checks as CI before uploading:

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build appbundle --release
```

The upload bundle is:

- `build/app/outputs/bundle/release/app-release.aab`

## 7. Upload And Test

Upload the AAB to Play Console Internal testing first.

Smoke-test on Android 11-15 devices:

- Library permission and scan
- Playback, queue, seek, shuffle, repeat
- Background notification controls
- Headset/media button controls
- Home-screen widget
- External file "open with"
- Lyrics lookup
- Equalizer behavior on devices that support Android equalizer APIs
