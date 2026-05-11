# MedID Connect Flutter App

Flutter Android/Web frontend for MedID Connect.

## Install

```powershell
flutter pub get
```

## Run Android

```powershell
flutter run --dart-define=MEDID_API_BASE_URL=http://10.0.2.2:8000
```

## Run Web

```powershell
flutter run -d chrome --dart-define=MEDID_API_BASE_URL=http://localhost:8000
```

Debug Android defaults to `http://10.0.2.2:8000`. Web defaults to `http://localhost:8000`. Release Android defaults to `https://api.medidconnect.com` unless `MEDID_API_BASE_URL` is supplied.

## Important Files

- API base URL: `lib/services/api_config.dart`
- Secure JWT client: `lib/services/api_client.dart`
- Consent sharing: `lib/screens/consent_sharing_screen.dart`
- FHIR JSON viewer: `lib/screens/fhir_viewer_screen.dart`
- Hospital sandbox: `lib/screens/provider_sandbox_screen.dart`
- OCR upload: `lib/screens/ocr_upload_screen.dart`
- Legal screens: `lib/screens/legal_document_screen.dart`
- Android logo: `android/app/src/main/res/mipmap-*`
- Web logo: `web/icons`

## Release

```powershell
flutter analyze
flutter test
flutter build apk --release
flutter build appbundle --release
flutter build web --release
```

Outputs:

```text
build/app/outputs/flutter-apk/app-release.apk
build/app/outputs/bundle/release/app-release.aab
build/web
```
