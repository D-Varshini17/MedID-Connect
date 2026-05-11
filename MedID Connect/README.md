# MedID Connect

MedID Connect is an AI-native personal health record and medical identity MVP for India. It includes a Flutter Android/Web app, FastAPI backend, PostgreSQL schema, JWT authentication, CRUD medical records, medications, lab trends, emergency QR, OCR placeholders, consent-based hospital sharing, FHIR R4 exports, HAPI FHIR sandbox sync, and ABDM/ABHA sandbox-ready placeholders.

This is compliance-ready architecture, not certified HIPAA/GDPR/DPDP compliance. Do not use real patient data until legal, security, clinical, and infrastructure audits are complete.

## Architecture

```text
Flutter app
  lib/screens        Mobile-first screens
  lib/services       Dio API clients and secure token storage
  lib/providers      Auth, health data, theme state

FastAPI backend
  backend/app/routes     REST APIs
  backend/app/models     SQLAlchemy PostgreSQL models
  backend/app/services   Auth, OCR, FHIR, consent, ABDM, safety, insights
  backend/alembic        Database migrations

PostgreSQL
  JSONB fields hold FHIR-style payloads and sync-ready structured health data
```

## Key Features

- Signup/login/logout with JWT and bcrypt password hashing
- User profile and emergency contact storage
- Medical records, medications, allergies, observations, and lab trends
- Emergency QR with temporary token, hashed token storage, expiry, revoke, and access logs
- Consent sharing with hashed share tokens, resource selection, expiry, revoke, logs, and public FHIR endpoints
- FHIR R4-style JSON for Patient, Observation, Condition, MedicationRequest, AllergyIntolerance, DiagnosticReport, Immunization, Appointment, and Consent
- HAPI FHIR sandbox provider flow with mock SMART on FHIR connect/callback/sync
- Epic, Oracle Cerner, and ABDM/ABHA sandbox placeholders
- OCR prescription/lab upload placeholder with confirm-before-save medication/observation creation
- Rule-based AI insights with medical disclaimer
- Privacy policy, terms, disclaimer, data export, account deletion placeholders
- Android APK/AAB release configuration and Flutter web build support
- Smart Health Wallet with offline cached emergency card, quick share QR, insurance placeholder, allergies, medicines, conditions, vaccines, and contact summary
- Full-screen NFC/QR Emergency Mode, SOS countdown, mock GPS/emergency messaging, flashlight/siren simulation, and SOS logs
- Smart medicine reminder UI with morning/afternoon/night schedules, taken/missed tracking, adherence chart, and local notification demo
- Wellness tracker for water, sleep, steps, mood, exercise, streaks, and dynamic wellness score
- Family health management, appointment management, document-vault search/favorite/pin, and weekly analytics dashboard

## Practical MVP API Additions

- `GET /api/wallet/summary`
- `GET /api/wellness/score`
- `GET /api/wellness/logs`
- `POST /api/wellness/logs`
- `POST /api/sos/alert`
- `GET /api/sos/alerts`
- `GET /api/product-analytics/summary`

The latest migration adds `wellness_logs`, `sos_alerts`, and `document_flags` tables for final-year-project-ready health tracking, emergency usefulness, and document-vault features.

## Run Backend

```powershell
cd "C:\Users\Varshini\Downloads\MedID Connect\backend"
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
psql -U postgres -c "CREATE DATABASE medid_connect;"
psql -U postgres -c "CREATE USER medid WITH PASSWORD 'medid_password';"
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE medid_connect TO medid;"
alembic upgrade head
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

API docs:

```text
http://localhost:8000/docs
```

Docker option:

```powershell
copy backend\.env.example backend\.env
docker compose up --build
```

## Run Flutter

```powershell
cd "C:\Users\Varshini\Downloads\MedID Connect"
flutter pub get
flutter run --dart-define=MEDID_API_BASE_URL=http://10.0.2.2:8000
```

Flutter web:

```powershell
flutter run -d chrome --dart-define=MEDID_API_BASE_URL=http://localhost:8000
```

## Test MVP Flows

1. Signup/login: open the app, create an account, then backend seeds demo allergies, meds, labs, and records.
2. Medical records: go to Records, add/edit/delete entries.
3. Emergency QR: choose 1h/24h/7d, generate QR, open `/api/emergency/view/{token}`, then revoke.
4. Consent sharing: open Consent & Sharing, generate a doctor link, open the share URL, then check consent logs/revoke.
5. FHIR sandbox import: open Connect Hospital Sandbox, connect HAPI FHIR, then Sync sample data.
6. FHIR viewer: open FHIR Viewer and inspect raw Patient/Bundles.
7. OCR: open OCR Upload, upload a PDF/JPG/PNG, and review placeholder extracted medications/labs.

## Build Release

```powershell
flutter build apk --release
flutter build appbundle --release
```

Outputs:

```text
build/app/outputs/flutter-apk/app-release.apk
build/app/outputs/bundle/release/app-release.aab
```

If Flutter is not on PATH on this machine, use:

```powershell
& "C:\Users\Varshini\Downloads\flutter_windows_3.41.9-stable\flutter\bin\flutter.bat" build apk --release
& "C:\Users\Varshini\Downloads\flutter_windows_3.41.9-stable\flutter\bin\flutter.bat" build appbundle --release
```

## Play Store Checklist

- App name: MedID Connect
- Package: `com.medidconnect.app`
- Final app icon/logo included
- Signed release AAB with production keystore
- HTTPS backend only
- Hosted privacy policy and terms URLs
- Google Play Data Safety form
- Medical disclaimer visible
- Test account for review
- Crash reporting and analytics placeholders wired later
- Backend monitoring, backups, rate limiting, and alerting

## FHIR And ABDM Path

MedID Connect currently acts as a mini FHIR server for patient-controlled export and consented sharing. Real hospital integration later requires SMART on FHIR app registration, provider OAuth credentials, token refresh, patient matching, terminology normalization, and production security review.

ABDM/ABHA is placeholder-only. Real ABDM integration requires sandbox registration, client ID/secret, HIP/HIU role approval, Consent Manager flow, Gateway callbacks, and production approval.
