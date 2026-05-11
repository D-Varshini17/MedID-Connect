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

Health checks:

```text
GET /
GET /health
GET /api/health
```

## Render Deployment

Use these settings on Render.

```text
Root Directory: MedID Connect/backend
Build Command: pip install -r requirements.txt
Start Command: uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

Important: the start command must include `:app`. `uvicorn app.main --host ...` is not a valid ASGI target and can fail during startup.

`runtime.txt` pins Render to Python 3.12.8:

```text
python-3.12.8
```

Required environment variables:

```text
ENVIRONMENT=production
DATABASE_URL=<Render PostgreSQL internal or external URL>
JWT_SECRET_KEY=<long random secret>
BACKEND_PUBLIC_URL=https://<your-render-service>.onrender.com
CORS_ORIGINS=https://<your-frontend-domain>,http://localhost:3000,http://localhost:8000,http://10.0.2.2:8000
```

Optional placeholders:

```text
HAPI_FHIR_BASE_URL=https://hapi.fhir.org/baseR4
EPIC_CLIENT_ID=placeholder
CERNER_CLIENT_ID=placeholder
ABDM_CLIENT_ID=placeholder
ABDM_CLIENT_SECRET=placeholder
GOOGLE_VISION_API_KEY=placeholder
```

Database notes:

- `DATABASE_URL` is read from the environment.
- Legacy `postgres://` URLs are normalized to `postgresql://`.
- Render PostgreSQL URLs get `sslmode=require` automatically when needed.
- Startup logs database errors clearly but keeps the API online so `/`, `/health`, and `/docs` remain reachable while you fix database settings.

After the service is live, run migrations from a Render shell or locally with the same `DATABASE_URL`:

```powershell
alembic upgrade head
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
