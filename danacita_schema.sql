
-- Danacita reconstructed schema (Postgres)
-- Filename: /mnt/data/danacita_schema.sql
-- Generated: automated by assistant
-- Note: This schema is a blueprint. Adjust column sizes/types/indexes per actual needs & privacy policies.

-- Enable extensions commonly useful
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- users: core user profile created at registration
CREATE TABLE IF NOT EXISTS users (
    id                  BIGSERIAL PRIMARY KEY,
    external_user_id    UUID DEFAULT uuid_generate_v4() UNIQUE, -- server-assigned opaque id
    name                TEXT,
    phone               TEXT UNIQUE, -- normalized (E.164) recommended
    email               TEXT,
    dob                 DATE,
    gender              VARCHAR(16),
    national_id         TEXT, -- KTP / NIK
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- device registrations: device identifiers and tokens
CREATE TABLE IF NOT EXISTS devices (
    id                  BIGSERIAL PRIMARY KEY,
    user_id             BIGINT REFERENCES users(id) ON DELETE SET NULL,
    device_uuid         UUID DEFAULT uuid_generate_v4() NOT NULL UNIQUE, -- internal id
    imei                TEXT,        -- encrypted at rest in production
    android_id          TEXT,
    advertising_id      TEXT,        -- GAID
    imsi                TEXT,        -- subscriber id (sensitive)
    sim_serial          TEXT,
    device_model        TEXT,
    device_brand        TEXT,
    os_version          TEXT,
    app_version         TEXT,
    fcm_token           TEXT,
    registered_at       TIMESTAMP WITH TIME ZONE DEFAULT now(),
    last_seen_at        TIMESTAMP WITH TIME ZONE,
    metadata            JSONB,       -- arbitrary device metadata
    CONSTRAINT devices_null_check CHECK (imei IS NOT NULL OR android_id IS NOT NULL OR advertising_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_devices_user_id ON devices(user_id);
CREATE INDEX IF NOT EXISTS idx_devices_imei ON devices(imei);

-- addresses: multiple addresses per user
CREATE TABLE IF NOT EXISTS addresses (
    id                  BIGSERIAL PRIMARY KEY,
    user_id             BIGINT REFERENCES users(id) ON DELETE CASCADE,
    type                VARCHAR(32), -- home, work, billing
    address_line        TEXT,
    city                TEXT,
    province            TEXT,
    postal_code         TEXT,
    country             TEXT DEFAULT 'ID',
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- bank accounts / payment methods
CREATE TABLE IF NOT EXISTS bank_accounts (
    id                  BIGSERIAL PRIMARY KEY,
    user_id             BIGINT REFERENCES users(id) ON DELETE CASCADE,
    bank_name           TEXT,
    account_number      TEXT,
    account_holder      TEXT,
    verified            BOOLEAN DEFAULT FALSE,
    verified_at         TIMESTAMP WITH TIME ZONE,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_bank_accounts_user ON bank_accounts(user_id);

-- employment / income info
CREATE TABLE IF NOT EXISTS employment (
    id                  BIGSERIAL PRIMARY KEY,
    user_id             BIGINT REFERENCES users(id) ON DELETE CASCADE,
    employer_name       TEXT,
    job_title           TEXT,
    income_monthly      NUMERIC(14,2), -- currency handled in application logic
    employment_type     VARCHAR(64), -- salary, self-employed, etc.
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- documents / uploads (selfie, ktp, bank proof)
CREATE TABLE IF NOT EXISTS documents (
    id                  BIGSERIAL PRIMARY KEY,
    user_id             BIGINT REFERENCES users(id) ON DELETE CASCADE,
    device_id           BIGINT REFERENCES devices(id) ON DELETE SET NULL,
    doc_type            VARCHAR(64), -- ktp, selfie, bank_statement, invoice
    file_name           TEXT,
    mime_type           TEXT,
    file_size           BIGINT,
    storage_url         TEXT, -- CDN URL or object key
    exif                JSONB, -- optional EXIF metadata (gps, datetime) if present
    uploaded_at         TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_documents_user ON documents(user_id);

-- contacts (address book imported if permission granted)
CREATE TABLE IF NOT EXISTS contacts (
    id                  BIGSERIAL PRIMARY KEY,
    user_id             BIGINT REFERENCES users(id) ON DELETE CASCADE,
    contact_name        TEXT,
    contact_phone       TEXT,
    contact_email       TEXT,
    relation            VARCHAR(64),
    imported_from_device BOOLEAN DEFAULT FALSE,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- telemetry / events (analytics-like)
CREATE TABLE IF NOT EXISTS telemetry_events (
    id                  BIGSERIAL PRIMARY KEY,
    user_id             BIGINT REFERENCES users(id) ON DELETE SET NULL,
    device_id           BIGINT REFERENCES devices(id) ON DELETE SET NULL,
    event_name          TEXT NOT NULL,
    event_props         JSONB,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_telemetry_user_event ON telemetry_events(user_id, event_name);

-- installed apps snapshot (for fingerprinting)
CREATE TABLE IF NOT EXISTS installed_apps (
    id                  BIGSERIAL PRIMARY KEY,
    device_id           BIGINT REFERENCES devices(id) ON DELETE CASCADE,
    package_name        TEXT,
    title               TEXT,
    version             TEXT,
    detected_at         TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- usage stats (optional)
CREATE TABLE IF NOT EXISTS usage_stats (
    id                  BIGSERIAL PRIMARY KEY,
    user_id             BIGINT REFERENCES users(id) ON DELETE CASCADE,
    metric_name         TEXT,
    metric_value        JSONB,
    recorded_at         TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- SMS / OTP logs (store hashes or minimal info; avoid storing OTPs in plain text)
CREATE TABLE IF NOT EXISTS sms_logs (
    id                  BIGSERIAL PRIMARY KEY,
    user_id             BIGINT REFERENCES users(id) ON DELETE SET NULL,
    device_id           BIGINT REFERENCES devices(id) ON DELETE SET NULL,
    phone_number        TEXT,
    otp_hash            TEXT, -- store hash if you must store OTP; do not store plain OTP
    received_at         TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- notifications (push tokens registered / notification records)
CREATE TABLE IF NOT EXISTS notifications (
    id                  BIGSERIAL PRIMARY KEY,
    user_id             BIGINT REFERENCES users(id) ON DELETE SET NULL,
    device_id           BIGINT REFERENCES devices(id) ON DELETE SET NULL,
    fcm_token           TEXT,
    last_registered_at  TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- crash logs / diagnostics (be careful not to include PII in stacktraces)
CREATE TABLE IF NOT EXISTS crash_reports (
    id                  BIGSERIAL PRIMARY KEY,
    user_id             BIGINT REFERENCES users(id) ON DELETE SET NULL,
    device_id           BIGINT REFERENCES devices(id) ON DELETE SET NULL,
    title               TEXT,
    stacktrace          TEXT,
    metadata            JSONB,
    reported_at         TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- hardware identifiers table for additional fingerprints
CREATE TABLE IF NOT EXISTS hardware_ids (
    id                  BIGSERIAL PRIMARY KEY,
    device_id           BIGINT REFERENCES devices(id) ON DELETE CASCADE,
    serial_number       TEXT,
    bluetooth_mac       TEXT,
    sensor_ids          JSONB,
    recorded_at         TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- accessibility event captures (if used) -- caution: privacy risk
CREATE TABLE IF NOT EXISTS accessibility_events (
    id                  BIGSERIAL PRIMARY KEY,
    user_id             BIGINT REFERENCES users(id) ON DELETE SET NULL,
    event_text          TEXT, -- consider hashing or redacting sensitive content
    event_type          TEXT,
    captured_at         TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- audit log for sensitive access
CREATE TABLE IF NOT EXISTS audit_logs (
    id                  BIGSERIAL PRIMARY KEY,
    actor               TEXT, -- system/user/service
    action              TEXT,
    target_table        TEXT,
    target_id           BIGINT,
    details             JSONB,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- loan applications table
CREATE TABLE IF NOT EXISTS loan_applications (
    id                  BIGSERIAL PRIMARY KEY,
    user_id             BIGINT REFERENCES users(id) ON DELETE CASCADE,
    application_no      TEXT UNIQUE,
    amount              NUMERIC(14,2),
    term_months         INTEGER,
    status              VARCHAR(32),
    submitted_at        TIMESTAMP WITH TIME ZONE DEFAULT now(),
    decision_at         TIMESTAMP WITH TIME ZONE,
    decision_note        TEXT
);

-- indexing & example constraints
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_national_id ON users(national_id);

-- NOTE: For production, ensure:
--  - Encryption at rest for sensitive columns (IMEI, IMSI, national_id, account_number)
--  - Access control: least-privilege DB roles
--  - Logging & auditing of data access (audit_logs)
--  - Data retention & deletion mechanisms (GDPR/PDPA compliance)
--  - Tokenization/hashing for OTPs and sensitive ephemeral values
