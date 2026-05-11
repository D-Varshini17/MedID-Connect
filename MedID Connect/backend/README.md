# MedID Connect Backend

FastAPI backend for MedID Connect with PostgreSQL, SQLAlchemy, Alembic, JWT auth, emergency QR tokens, consent sharing, FHIR R4 exports, provider sandbox sync, OCR placeholders, and rule-based AI insights.

## Setup

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
```

Create PostgreSQL database:

```sql
CREATE DATABASE medid_connect;
CREATE USER medid WITH PASSWORD 'medid_password';
GRANT ALL PRIVILEGES ON DATABASE medid_connect TO medid;
```

Run migrations:

```powershell
alembic upgrade head
```

Start API:

```powershell
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Docs:

```text
http://localhost:8000/docs
```

## Important APIs

- Auth: `/api/auth/signup`, `/api/auth/login`, `/api/auth/me`
- Records: `/api/records`
- Medications: `/api/medications`
- Allergies: `/api/allergies`
- Observations: `/api/observations`, `/api/observations/trends`
- Emergency: `/api/emergency/token`, `/api/emergency/view/{token}`, `/api/emergency/revoke/{token}`
- Consent: `/api/consents`, `/api/share/{share_token}/summary`, `/api/share/{share_token}/fhir/{resource}`
- FHIR: `/api/fhir/Patient/{id}`, `/api/fhir/Observation?patient={id}`, etc.
- Providers: `/api/providers`, `/api/providers/connect/start`, `/api/providers/{id}/sync`
- OCR: `/api/ocr/prescription`, `/api/ocr/lab-report`
- Insights: `/api/insights`

## Security Notes

Passwords are hashed with bcrypt. JWT protects user APIs. Emergency and consent share tokens are hashed before storage. Access logs and audit logs are persisted. Production still needs HTTPS, managed secrets, encryption-at-rest/KMS, Redis/API-gateway rate limiting, monitoring, backups, abuse detection, and formal compliance review.

## ABDM / ABHA

`app/services/abdm_sandbox_service.py` is a placeholder contract only. Real ABDM integration requires sandbox registration, credentials, Gateway onboarding, HIP/HIU role approval, consent callback flows, and production certification.
