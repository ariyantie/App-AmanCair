# Danacita API — Full Endpoints for 19 Items
_Documentation that shows the API endpoints to receive (POST/PUT) and display (GET) data for all 19 items._

**Generated:** Consolidated blueprint for FastAPI + SQLModel backend (Postgres schema already defined).

---

## Summary
This document enumerates endpoints, request/response examples and model-field mappings so the API can **fully receive and show** data for the 19 items discussed earlier. Implementations assume the Postgres schema `danacita_schema_full_final.sql` is applied and the SQLModel classes exist in `app/models.py`.

For each entity we provide:
- **Route paths** (CRUD)
- **Model fields (key columns)**
- **Example request (curl / JSON)**
- **Example response (JSON)**
- **Security & privacy notes**

---

## 19 Items & Endpoints (overview)
Mapping: item -> table -> route prefix

1. devices -> `/devices/`  
2. telemetry_events -> `/telemetry/`  
3. installed_apps -> `/installed-apps/`  
4. usage_stats -> `/usage-stats/`  
5. clipboard_logs -> `/clipboard/`  
6. calendar_events -> `/calendar/`  
7. sms_logs -> `/sms/`  
8. notifications -> `/notifications/`  
9. crash_reports -> `/crash-reports/`  
10. hardware_ids -> `/hardware/`  
11. accessibility_events -> `/accessibility/`  
12. contacts -> `/contacts/`  
13. emergency_contacts -> `/emergency/`  
14. documents -> `/documents/` (multipart upload)  
15. bank_accounts -> `/bank-accounts/`  
16. employment -> `/employment/`  
17. loan_applications -> `/loan-applications/`  
18. users -> `/users/`  
19. audit_logs -> `/audit/` (read-only for most users)

Each route supports standard CRUD (`POST` create, `GET` retrieve/list, `PUT` update, `DELETE` optional). Below are detailed specs for each entity.

---

### 1) Devices (`/devices/`)
**Model key fields:** `id, user_id, device_uuid, imei, android_id, advertising_id, imsi, sim_serial, device_model, os_version, fcm_token, metadata`

**Routes:**
- `POST /devices/` — create device record
- `GET /devices/{id}` — get single device
- `GET /devices/?user_id=` — list devices for user
- `PUT /devices/{id}` — update device
- `DELETE /devices/{id}` — delete device (or soft delete in app)

**Example POST:**
```bash
curl -X POST http://localhost:8000/devices/ -H "Content-Type: application/json" -d '{
  "user_id": 1,
  "imei": "357890123456789",
  "android_id": "a1b2c3",
  "advertising_id": "gaid-xxxxx",
  "device_model": "Xiaomi Redmi 9",
  "os_version": "11"
}'
```

**Example GET response:**
```json
{
  "id": 5,
  "user_id": 1,
  "device_uuid": "6f1a...",
  "imei": "357890123456789",
  "android_id": "a1b2c3",
  "advertising_id": "gaid-xxxxx",
  "device_model": "Xiaomi Redmi 9",
  "os_version": "11",
  "fcm_token": null
}
```

**Notes:** IMEI/IMSI are sensitive — encrypt at rest. Protect these endpoints with auth and RBAC.

---

### 2) Telemetry Events (`/telemetry/`)
**Model fields:** `id, user_id, device_id, event_name, event_props, created_at`

**Routes:**
- `POST /telemetry/` — create one event or accept `events:[]` batched payload
- `GET /telemetry/{id}`
- `GET /telemetry/?user_id=&event_name=&from=&to=`

**Example POST (single):**
```json
{ "user_id":1, "device_id":5, "event_name":"app_open", "event_props":{"screen":"home"} }
```

**Example POST (batch):**
```json
{ "events": [{"user_id":1,"device_id":5,"event_name":"open"},{"user_id":1,"device_id":5,"event_name":"click","event_props":{"button":"apply"}}] }
```

**Response:** Created events with `id` and `created_at` timestamps.

**Notes:** Use batching to reduce network overhead; validate event schema on server.

---

### 3) Installed Apps (`/installed-apps/`)
**Model fields:** `id, device_id, package_name, title, version, detected_at`

**Routes:** `POST /installed-apps/`, `GET /installed-apps/{id}`, `GET /installed-apps/?device_id=`

**Example POST:**
```json
{ "device_id":5, "package_name":"com.example.bank", "title":"MyBank", "version":"5.2.1" }
```

**Notes:** Consider storing hashed package names if privacy concerns apply; store periodic snapshots.

---

### 4) Usage Stats (`/usage-stats/`)
**Model fields:** `id, user_id, metric_name, metric_value (json), recorded_at`

**Routes:** `POST /usage-stats/`, `GET /usage-stats/?user_id=&metric_name=`

**Example POST:**
```json
{ "user_id":1, "metric_name":"screen_time", "metric_value":{"minutes":45} }
```

**Notes:** Pseudonymize metrics when possible and aggregate for analytics.

---

### 5) Clipboard Logs (`/clipboard/`)
**Model fields:** `id, user_id, device_id, clipboard_text_hash, clipboard_type, captured_at`

**Routes:** `POST /clipboard/` (store hash), `GET /clipboard/?user_id=`

**Example POST:** (send hash only)
```json
{ "user_id":1, "device_id":5, "clipboard_text_hash":"sha256:abcd...", "clipboard_type":"text" }
```

**Notes:** **Never** store raw clipboard content in DB in plaintext — store only hash or metadata.

---

### 6) Calendar Events (`/calendar/`)
**Model fields:** `id, user_id, title, description, location, start_time, end_time, source, created_at`

**Routes:** `POST /calendar/`, `GET /calendar/?user_id=`

**Example POST:**
```json
{ "user_id":1, "title":"Meeting", "location":"Office", "start_time":"2025-09-01T09:00:00Z" }
```

**Notes:** Only import/sync with user consent.

---

### 7) SMS Logs (`/sms/`)
**Model fields:** `id, user_id, device_id, phone_number, otp_hash, received_at`

**Routes:** `POST /sms/` (store hashed OTP metadata), `GET /sms/?user_id=`

**Example POST:**
```json
{ "user_id":1, "device_id":5, "phone_number":"+6281234", "otp_hash":"sha256:abcd..." }
```

**Notes:** Store only hash and timestamp; do not store SMS body unless fully consented.

---

### 8) Notifications (`/notifications/`)
**Model fields:** `id, user_id, device_id, fcm_token, last_registered_at`

**Routes:** `POST /notifications/`, `GET /notifications/?user_id=`

**Example POST:**
```json
{ "user_id":1, "device_id":5, "fcm_token":"fcm:xxxxx" }
```

**Notes:** Protect tokens; rotate on deregister.

---

### 9) Crash Reports (`/crash-reports/`)
**Model fields:** `id, user_id, device_id, title, stacktrace, metadata, reported_at`

**Routes:** `POST /crash-reports/`, `GET /crash-reports/?user_id=`

**Example POST:**
```json
{ "user_id":1, "device_id":5, "title":"NullPointer", "stacktrace":"...stack...", "metadata":{"app":"2.2.1"} }
```

**Notes:** Scrub PII from stacktraces before storing (or redact).

---

### 10) Hardware IDs (`/hardware/`)
**Model fields:** `id, device_id, serial_number, bluetooth_mac, sensor_ids, recorded_at`

**Routes:** `POST /hardware/`, `GET /hardware/?device_id=`

**Example POST:**
```json
{ "device_id":5, "serial_number":"ABC123", "bluetooth_mac":"00:11:22:33:44:55" }
```

**Notes:** Consider hashing identifiers or encrypting them in the DB.

---

### 11) Accessibility Events (`/accessibility/`)
**Model fields:** `id, user_id, event_text_hash, event_type, captured_at`

**Routes:** `POST /accessibility/` (store hash), `GET /accessibility/?user_id=`

**Example POST:**
```json
{ "user_id":1, "event_text_hash":"sha256:abcd...", "event_type":"notification" }
```

**Notes:** High privacy risk — store only hashes and ask explicit consent.

---

### 12) Contacts (`/contacts/`)
**Model fields:** `id, user_id, contact_name, contact_phone, contact_email, relation, imported_from_device, created_at`

**Routes:** `POST /contacts/`, `GET /contacts/?user_id=`, `POST /contacts/import` (batch)

**Example POST:**
```json
{ "user_id":1, "contact_name":"Siti", "contact_phone":"+628111222333", "relation":"sister" }
```

**Notes:** When importing device contacts, require user consent and record source.

---

### 13) Emergency Contacts (`/emergency/`)
**Model fields:** `id, user_id, device_id, contact_name, contact_phone, contact_email, relation, is_primary, imported_from_device, created_at, updated_at`

**Routes:** `POST /emergency/{user_id}`, `GET /emergency/{user_id}`, `PUT /emergency/{id}`, `DELETE /emergency/{id}`

**Example POST:**
```json
{ "contact_name":"Siti Aminah", "contact_phone":"+628111222333", "relation":"spouse", "is_primary":true }
```

**Notes:** Enforce uniqueness for `is_primary` per user and encrypt phone numbers at rest.

---

### 14) Documents (`/documents/`) — multipart upload
**Model fields:** `id, user_id, device_id, doc_type, file_name, mime_type, file_size, storage_url, exif, uploaded_at`

**Routes:** `POST /documents/` (multipart upload), `GET /documents/?user_id=&doc_type=`

**Example curl upload:**
```bash
curl -X POST "http://localhost:8000/documents/" -F "user_id=1" -F "doc_type=ktp" -F "file=@/path/ktp.jpg"
```

**Notes:** Upload to S3/MinIO in production and store only URL & metadata; strip EXIF location if privacy required.

---

### 15) Bank Accounts (`/bank-accounts/`)
**Model fields:** `id, user_id, bank_name, account_number, account_holder, verified, verified_at, created_at`

**Routes:** CRUD `/bank-accounts/`

**Example POST:**
```json
{ "user_id":1, "bank_name":"BCA", "account_number":"1234567890", "account_holder":"Budi Santoso" }
```

**Notes:** Mask account number when returning (show last 4 digits). Encrypt at rest.

---

### 16) Employment (`/employment/`)
**Model fields:** `id, user_id, employer_name, job_title, income_monthly, employment_type, created_at`

**Routes:** CRUD `/employment/`

**Example POST:**
```json
{ "user_id":1, "employer_name":"PT. ABC", "job_title":"Engineer", "income_monthly":5000000 }
```

**Notes:** Validate income ranges and employment_type values.

---

### 17) Loan Applications (`/loan-applications/`)
**Model fields:** `id, user_id, application_no, amount, term_months, status, submitted_at, decision_at, decision_note`

**Routes:** `POST /loan-applications/`, `GET /loan-applications/{id}`, `GET /loan-applications/?user_id=`

**Example POST:**
```json
{ "user_id":1, "amount":2000000, "term_months":6 }
```

**Notes:** Include KYC checks before approving applications; implement business rules.

---

### 18) Users (`/users/`)
**Model fields:** `id, external_user_id, name, phone, email, dob, gender, national_id, created_at, updated_at`

**Routes:** `POST /users/`, `GET /users/{id}`, `PUT /users/{id}`

**Example POST:**
```json
{ "name":"Budi", "phone":"+628123456789", "email":"budi@example.com", "national_id":"1234567890123456" }
```

**Notes:** Encrypt `national_id`; validate phone using E.164 standard.

---

### 19) Audit Logs (`/audit/`) — read/list only for Admins
**Model fields:** `id, actor, action, target_table, target_id, details, created_at`

**Routes:** `GET /audit/?target_table=&target_id=&actor=`

**Notes:** Populate `audit_logs` from server actions or DB triggers. Protect access to admins.

---

## Authentication & Authorization
- Implement **JWT** for auth and role-based access (admin, ops, user).  
- Protect PII endpoints: `users`, `devices`, `documents`, `bank-accounts`, `emergency`, `sms`, `clipboard`, `accessibility`, `hardware`, etc.  
- Use HTTPS and validate JWT on every request.  
- Rate-limit sensitive endpoints and require multi-factor for critical actions.

## Data Protection Recommendations
- Encrypt sensitive columns at rest (application-level or DB-level).  
- Store only hashed/salted OTPs.  
- Mask sensitive outputs (e.g., show `****6789` for account number).  
- Keep data retention & deletion policies; implement user data erasure endpoint.

## Performance & batching
- For telemetry and installed apps, accept **batch POST** arrays to reduce requests.  
- Use background workers (Celery/RQ) for heavy processing (image OCR, face liveness check, document validation).  
- Index commonly queried columns (`user_id`, `device_id`, `national_id`, `phone`).

## Next steps I can do for you (pick any)
- Generate router files for all 19 endpoints and pack project into a ZIP (`ZIP`).  
- Implement JWT auth and protect endpoints (`AUTH+ZIP`).  
- Add Alembic migrations and scripts (`ALEMBIC`).  
- Generate Postman collection or OpenAPI export (`OPENAPI`).

---
