# Android Release Signing Guide

Release builds require `android/key.properties`. Without it, `flutter build appbundle --release` fails on purpose.

## 1. Generate Upload Keystore

Run this from a safe location, not inside a public repo:

```powershell
keytool -genkeypair -v -keystore "$env:USERPROFILE\playa_upload_keystore.jks" -alias upload -keyalg RSA -keysize 2048 -validity 9125
```

Save the keystore and passwords somewhere secure. You need them for future updates.

## 2. Create android/key.properties

Copy:

```powershell
Copy-Item android\key.properties.example android\key.properties
```

Edit `android/key.properties`:

```properties
storeFile=C:\\Users\\Green\\playa_upload_keystore.jks
storePassword=your_store_password
keyAlias=upload
keyPassword=your_key_password
```

Do not commit `android/key.properties`.

## 3. Build The Upload Bundle

```powershell
flutter build appbundle --release
```

Upload this file to Play Console Internal testing:

```text
build/app/outputs/bundle/release/app-release.aab
```

## 4. GitHub Actions Secrets

If CI should build release bundles, add these repository secrets:

- `PLAYA_UPLOAD_KEYSTORE_BASE64`
- `PLAYA_UPLOAD_STORE_PASSWORD`
- `PLAYA_UPLOAD_KEY_ALIAS`
- `PLAYA_UPLOAD_KEY_PASSWORD`

Create the base64 value on Windows PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$env:USERPROFILE\playa_upload_keystore.jks"))
```
