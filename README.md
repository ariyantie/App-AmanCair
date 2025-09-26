# App-AmanCair


# AmanCair API Blueprint (FastAPI + PostgreSQL)

## 📌 Tujuan
Dokumentasi ini menjelaskan rancangan **API backend** berbasis **FastAPI** yang terhubung dengan **PostgreSQL** menggunakan schema final (users, devices, emergency_contacts, loan_applications, dsb).

---

## 📂 Struktur Project
```
amancair-api/
├─ docker-compose.yml
├─ .env
├─ app/
│  ├─ Dockerfile
│  ├─ requirements.txt
│  ├─ main.py
│  ├─ database.py
│  ├─ models.py
│  ├─ crud.py
│  ├─ routers/
│  │  ├─ users.py
│  │  ├─ devices.py
│  │  └─ emergency.py
```

---

## ⚙️ Dependensi
File `requirements.txt`:
```
fastapi
uvicorn[standard]
sqlmodel
asyncpg
pydantic[email]
python-dotenv
passlib[bcrypt]
python-jose[cryptography]
alembic
```

---

## 🐘 Database (Postgres)
Gunakan schema `danacita_schema_full_final.sql` untuk membuat tabel lengkap (users, devices, addresses, bank_accounts, documents, telemetry, emergency_contacts, dsb).

`.env` contoh:
```
POSTGRES_USER=danacita
POSTGRES_PASSWORD=danacita_pass
POSTGRES_DB=danacita_db
```

---

## 🚀 Docker Compose
```yaml
version: "3.8"
services:
  db:
    image: postgres:15
    restart: always
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-danacita}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-danacita_pass}
      POSTGRES_DB: ${POSTGRES_DB:-danacita_db}
    ports:
      - "5432:5432"

  web:
    build: ./app
    depends_on:
      - db
    environment:
      DATABASE_URL: "postgresql://${POSTGRES_USER:-danacita}:${POSTGRES_PASSWORD:-danacita_pass}@db:5432/${POSTGRES_DB:-danacita_db}"
    ports:
      - "8000:8000"
```

---

## 📦 Model Utama (contoh `models.py`)
```python
class User(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: Optional[str]
    phone: Optional[str]
    email: Optional[str]
    dob: Optional[str]
    gender: Optional[str]
    national_id: Optional[str]  # sensitif
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

class Device(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: Optional[int] = Field(default=None, foreign_key="user.id")
    imei: Optional[str]
    android_id: Optional[str]
    advertising_id: Optional[str]
    sim_serial: Optional[str]
    device_model: Optional[str]
    os_version: Optional[str]
    registered_at: datetime = Field(default_factory=datetime.utcnow)

class EmergencyContact(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: Optional[int] = Field(default=None, foreign_key="user.id")
    contact_name: str
    contact_phone: str
    relation: Optional[str]
    is_primary: bool = False
    created_at: datetime = Field(default_factory=datetime.utcnow)
```

---

## 🔗 Endpoint Utama
### Users
- `POST /users/` → buat user baru  
- `GET /users/{user_id}` → ambil detail user  

### Devices
- `POST /devices/` → daftar perangkat baru  

### Emergency Contacts
- `POST /emergency/{user_id}` → tambah kontak darurat untuk user  
- `GET /emergency/{user_id}` → daftar semua kontak darurat user  

---

## 📝 Contoh Request
### Tambah User
```bash
curl -X POST "http://localhost:8000/users/" \
  -H "Content-Type: application/json" \
  -d '{"name":"Budi","phone":"+628123456789","email":"budi@example.com"}'
```

### Tambah Kontak Darurat
```bash
curl -X POST "http://localhost:8000/emergency/1" \
  -H "Content-Type: application/json" \
  -d '{"contact_name":"Siti","contact_phone":"+628111222333","relation":"spouse","is_primary":true}'
```

### Ambil Semua Kontak Darurat
```bash
curl -X GET "http://localhost:8000/emergency/1"
```

---

## 🔒 Catatan Keamanan
- Enkripsi data sensitif (NIK, IMEI, rekening, dsb).  
- Jangan simpan OTP dalam plain text → gunakan hash + TTL.  
- Gunakan HTTPS + JWT Auth.  
- Tambahkan audit trail (`audit_logs` table).  
- Terapkan Role-Based Access Control (RBAC) dan Row-Level Security (RLS).  

---
