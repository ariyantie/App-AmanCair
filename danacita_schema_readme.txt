
Danacita DB schema (Postgres)
============================

Files created:
 - /mnt/data/danacita_schema.sql  (DDL to create tables)
 - This README (high level notes)

How to use:
 - Run the SQL in a Postgres instance: psql -f /mnt/data/danacita_schema.sql
 - Adjust column types, encryption, and constraints before production.
 - Implement application-level encryption for PII (national_id, imei, account_number).

Example basic queries:
 - Create user:
   INSERT INTO users (name, phone, email, dob, national_id) VALUES ('Budi', '+6281234', 'budi@example.com', '1990-01-01', '1234567890123456');

 - Register device:
   INSERT INTO devices (user_id, imei, android_id, advertising_id, device_model, os_version, fcm_token) VALUES (1, '35789...', 'a1b2...', 'gaid-...', 'Xiaomi', '11', 'fcm-...');

Privacy & security notes:
 - Do NOT store OTPs in plain text. Use hashing & short TTL.
 - Store PII encrypted with strong key management.
 - Limit DB users that can access PII; use views & app-layer services for minimal data exposure.
