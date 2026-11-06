# AgroNexus Backend — Startup Guide & Testing Log

**Author**:  Tchouela Eunice  Quetsia (Registration No: ICTU20241869)
**Date**: September 2026
**Backend**: Spring Boot 3.3.2 · Java 21 · Maven 3.9.9

---

## 📋 Prerequisites

Before running the backend, ensure the following are installed on your machine:

| Tool | Required Version | How to Check |
|------|-----------------|--------------|
| Java (JDK) | 21 or higher | `java -version` |
| Apache Maven | 3.9+ | `mvn --version` |
| Internet connection | Required | For Supabase cloud DB |

> **Confirmed on this machine**: Java 21.0.12.1 (Eclipse Adoptium), Maven 3.9.9 ✅

---

## 🔐 Registration Verification Configuration

Registration creates a pending account and starts separate email and phone verification challenges. Configure delivery before enabling the flow:

```powershell
$env:VERIFICATION_DELIVERY_MODE = "disabled" # fail-closed default
```

Supported modes are:

* `disabled`: no code is delivered; use this default when a provider is not configured.
* `console`: prints development codes to the backend logs; local development only.
* A production provider mode can be added when email/SMS credentials and an adapter are configured.

OTP codes expire after ten minutes, are single-use, and allow five attempts. National identity numbers are hashed before persistence. Account activation remains blocked until the required email, phone, identity, and biometric verification states are complete. Web biometric checks and unavailable desktop GPS/biometric providers fail closed rather than simulating success.

Start the backend with the chosen mode:

```powershell
$env:VERIFICATION_DELIVERY_MODE = "console"
mvn spring-boot:run
```

Do not commit provider credentials, database passwords, JWT secrets, or development OTPs to this document or the repository.

---

## 📂 Backend Folder Structure

```
AGRONEXUS/
└── backend/
    ├── pom.xml                                  ← Maven build file (all dependencies)
    └── src/main/
        ├── java/com/agronexus/api/
        │   ├── AgroNexusApplication.java        ← Main Spring Boot entry point
        │   ├── controller/
        │   │   └── AuthController.java          ← Register & Login endpoints
        │   ├── entity/
        │   │   ├── User.java
        │   │   ├── Product.java
        │   │   ├── Order.java
        │   │   ├── TelemetryLog.java
        │   │   └── Role.java                    ← RBAC enum (FARMER, BUYER…)
        │   ├── repository/
        │   │   ├── UserRepository.java
        │   │   ├── OrderRepository.java
        │   │   └── ProductRepository.java
        │   ├── security/
        │   │   ├── JwtService.java              ← JWT token generation & validation
        │   │   ├── JwtAuthFilter.java           ← HTTP request JWT interceptor
        │   │   └── SecurityConfig.java          ← Spring Security rules
        │   └── service/
        │       └── EscrowEngineService.java     ← MTN/Orange Money escrow logic
        └── resources/
            └── application.yml                  ← DB, JPA, JWT configuration
```

---

## ▶️ How to Run the Backend

### Step 1 — Open a terminal and navigate to the backend folder

```powershell
cd "C:\Users\lenovo p14s\Music\AGRONEXUS\backend"
```

---

### Step 2 — Compile the project (verify zero Java errors)

```powershell
mvn compile
```

**Expected output:**
```
[INFO] BUILD SUCCESS
[INFO] Total time: ~8s
```

> ✅ Confirmed working on 11 September 2026.

---

### Step 3 — Start the Spring Boot server

```powershell
set JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot
set PATH=%JAVA_HOME%\bin;%PATH%
mvn spring-boot:run
```

**What happens when this runs:**
- Downloads any missing Maven dependencies (first run only, needs internet)
- Compiles all Java source files
- Connects to the Supabase PostgreSQL cloud database
- Runs `ddl-auto: update` — auto-creates/updates your DB tables
- Starts Tomcat embedded web server on **port 8080**

**Expected success message:**
```
INFO --- Started AgroNexusApplication in X.XXX seconds
```

Once you see that, your API is live at: `http://localhost:8080`

---

### Step 4 — Test the API

**Register a farmer (PowerShell):**
```powershell
Invoke-WebRequest -Uri "http://localhost:8080/api/v1/auth/register" `
  -Method POST -ContentType "application/json" `
  -Body '{"name":"Test Farmer","email":"farmer@test.com","password":"pass123","role":"FARMER"}'
```

**Login and get a JWT token:**
```powershell
Invoke-WebRequest -Uri "http://localhost:8080/api/v1/auth/login" `
  -Method POST -ContentType "application/json" `
  -Body '{"email":"farmer@test.com","password":"pass123"}'
```

---

## 🔐 Available API Endpoints (Built So Far)

| Method | Endpoint | Auth Required | Description |
|--------|----------|--------------|-------------|
| `POST` | `/api/v1/auth/register` | No | Register new user |
| `POST` | `/api/v1/auth/login` | No | Login → returns signed JWT |
| `POST` | `/api/v1/products` | Yes (FARMER) | List a new produce item |
| `GET`  | `/api/v1/products` | Yes | Browse produce listings |
| `POST` | `/api/v1/orders/create` | Yes (BUYER) | Create a purchase order |
| `POST` | `/api/v1/telemetry` | Yes (SYSTEM) | Submit IoT sensor data |
| `POST` | `/api/v1/ai/query` | Yes | Ask AI advisory question |

> Endpoints marked **Yes** require: `Authorization: Bearer <token>` in the HTTP header.

---

## ⚠️ Errors Encountered During Testing (11 September 2026)

### Error 1 — ClassNotFoundException: PostgisDialect

**When**: First `mvn spring-boot:run` attempt.

**Full error:**
```
Caused by: java.lang.ClassNotFoundException:
  org.hibernate.spatial.dialect.postgis.PostgisDialect
```

**Root cause:**
The `application.yml` had this line (inherited from an older Hibernate 5 pattern):
```yaml
jpa:
  database-platform: org.hibernate.spatial.dialect.postgis.PostgisDialect
```
The class `PostgisDialect` was **deleted in Hibernate 6**. Our project uses Spring Boot 3.3.2 which ships with Hibernate 6.5.2.

**Fix applied — removed the old property and added the correct Hibernate 6 dialect:**
```yaml
# BEFORE (Hibernate 5 — broken):
jpa:
  database-platform: org.hibernate.spatial.dialect.postgis.PostgisDialect

# AFTER (Hibernate 6 — correct):
jpa:
  properties:
    hibernate:
      dialect: org.hibernate.dialect.PostgreSQLDialect
```

---

### Error 2 — Unable to determine Dialect without JDBC metadata

**When**: Second attempt (after fixing Error 1).

**Full error:**
```
Caused by: org.hibernate.HibernateException: Unable to determine Dialect without
  JDBC metadata (please set 'jakarta.persistence.jdbc.url' or 'hibernate.dialect')
```

**Root cause:**
`hibernate-spatial` initialises its **spatial type contributors** very early during startup — before the JDBC connection pool is open. Without an explicit `hibernate.dialect` property, the bootstrap process fails because it cannot auto-detect the dialect.

**Fix applied — added `dialect` property inside `properties.hibernate`:**
```yaml
properties:
  hibernate:
    dialect: org.hibernate.dialect.PostgreSQLDialect   # This line resolves it
    format_sql: true
```

---

### Error 3 — PSQLException: Connection failure

**When**: Third attempt (after fixing Errors 1 & 2).

**Full error:**
```
Caused by: org.postgresql.util.PSQLException: The connection attempt failed.
Caused by: java.net.UnknownHostException: the configured database host
```

**Diagnosis:**
```powershell
# DNS resolves correctly to an IPv6 address ✅
Test-NetConnection localhost -Port 5434
# → Returns IPv6: 2a05:d018:175d:b600:a27c:8f30:521f:96b3
```

**Root cause:**
The backend must be able to reach the PostgreSQL server configured in `application.yml`. For the local setup, PostgreSQL is expected at `localhost:5434`.

**Fix — Configure the local PostgreSQL connection:**
1. Confirm PostgreSQL is running and listening on port `5434`.
2. Confirm the `agronexus` database exists.
3. Set `DB_PASS` to the local PostgreSQL password before starting the backend.

---

## 📊 Testing Session Summary

| Attempt | Command | Outcome |
|---------|---------|---------|
| 1 | `mvn compile` | ✅ BUILD SUCCESS — all 14 Java files compiled cleanly |
| 2 | `mvn spring-boot:run` | ❌ Error 1: PostgisDialect class not found |
| 3 | Fix → `mvn spring-boot:run` | ❌ Error 2: Dialect unresolvable before JDBC is open |
| 4 | Fix → `mvn spring-boot:run` | ❌ Error 3: IPv6 routing failure (UnknownHostException) |
| 5 | Fix → `mvn spring-boot:run` | ✅ **SERVER STARTED SUCCESSFULLY (Port 8080)** |

---

## 🗂️ Final application.yml (After All Fixes)

```yaml
server:
  port: ${PORT:8080}
  servlet:
    context-path: /

spring:
  application:
    name: agronexus-backend

  datasource:
    url: ${DB_URL:jdbc:postgresql://localhost:5434/agronexus}
    username: ${DB_USER:postgres}
    password: ${DB_PASS:}
    driver-class-name: org.postgresql.Driver

  jpa:
    hibernate:
      ddl-auto: update
    show-sql: false
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect
        format_sql: true

agronexus:
  jwt:
    secret: ${JWT_SECRET:9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b}
    expiration-ms: 86400000  # 24 Hours
```

---

---

## 🔜 Current Status & Active Next Implementation Steps

| # | Task | Status | Description |
|---|------|---|-------------|
| 1 | Auth Endpoints (`/auth/register`, `/auth/login`) | ✅ Completed | JWT authentication and refresh token rotation working. |
| 2 | Produce Controller (`/api/v1/products`) | ✅ Scaffolding Built | Product creation and PostGIS radial search (`/nearby`) working. |
| 3 | Escrow Controller (`/api/v1/escrow/order`) | ✅ Scaffolding Built | Order entity & Mobile Money deposit fee formulas working. |
| 4 | Telemetry Controller (`/api/v1/telemetry/log`) | ✅ Scaffolding Built | REST IoT sensor data ingestion & threshold checking working. |
| 5 | AI Assistant Controller (`/api/v1/ai/query`) | ✅ Prototype Built | Rule-based agricultural guardrails working. |
| 6 | **Farmer Listing Query Endpoint** | ⏳ Active Next Step | Add `GET /api/v1/products/my-listings` to `ProductController.java`. |
| 7 | **Frontend Checkout Connection** | ⏳ Active Next Step | Connect Flutter produce order screen to `/api/v1/escrow/order`. |
| 8 | **Transporter Workflow Execution** | ⏳ Active Next Step | Build Transporter dashboard UI & order state machine transitions (`PENDING` $\rightarrow$ `DELIVERED`). |
| 9 | **Vector RAG Pipeline** | ⏳ Active Next Step | Ingest FAO/USDA documents into `pgvector` for LLM top-$k$ similarity queries. |
