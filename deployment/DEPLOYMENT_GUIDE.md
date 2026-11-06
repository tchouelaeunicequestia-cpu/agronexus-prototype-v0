# AgroNexus Production & Cloud Deployment Guide

This guide provides step-by-step instructions for deploying the **AgroNexus** platform using both **Free Cloud Services** (Supabase + Render + Vercel/Firebase) and **Self-Hosted Containerized Deployment** (Docker Compose).

---

## 🏗️ Architecture & Deployment Topology

```
+-----------------------------------------------------------------------------------+
|                               FRONTEND LAYER                                      |
|    Flutter Web App hosted on Vercel / Firebase Hosting / Netlify (Free Tier)      |
+-----------------------------------------------------------------------------------+
                                       |
                                       | HTTPS / REST / WebSockets
                                       v
+-----------------------------------------------------------------------------------+
|                               BACKEND LAYER                                       |
|      Spring Boot 3.x REST API container deployed on Render.com (Free Tier)        |
+-----------------------------------------------------------------------------------+
                                       |
                   +-------------------+-------------------+
                   |                                       |
                   v                                       v
+------------------------------------+   +------------------------------------+
|          DATABASE LAYER            |   |          CYBER-PHYSICAL IOT        |
|    Supabase PostgreSQL Database    |   |     ESP32 Hardware Telemetry       |
|  (PostGIS + pgvector pre-installed)|   |  POSTs directly to Render endpoint |
+------------------------------------+   +------------------------------------+
```

---

## 🟢 Option A: Free Cloud Deployment (Recommended for Project Defense)

### Step 1: Database Setup — Local PostgreSQL
1. Open pgAdmin and connect to your local PostgreSQL server on port `5434`.
2. Use the database named `agronexus`.
3. Open [`deployment/supabase_setup.sql`](file:///c:/Users/lenovo%20p14s/Music/AGRONEXUS/deployment/supabase_setup.sql) in pgAdmin's Query Tool and execute it.
4. This script enables the required PostgreSQL extensions, creates the application tables, indexes, and seed data.
5. Configure the backend with:
   - `DB_URL`: `jdbc:postgresql://localhost:5434/agronexus`
   - `DB_USER`: `postgres`
   - `DB_PASS`: your local PostgreSQL password

---

### Step 2: Backend Service Deployment — Render.com (Free Tier)
1. Push your AgroNexus codebase to GitHub.
2. Sign up at [render.com](https://render.com) and click **New +** $\rightarrow$ **Web Service**.
3. Connect your GitHub repository.
4. Render will automatically detect [`deployment/render.yaml`](file:///c:/Users/lenovo%20p14s/Music/AGRONEXUS/deployment/render.yaml) or [`deployment/Dockerfile.backend`](file:///c:/Users/lenovo%20p14s/Music/AGRONEXUS/deployment/Dockerfile.backend).
5. Add the following **Environment Variables** in Render:
   - `SPRING_PROFILES_ACTIVE`: `prod`
   - `DB_URL`: `jdbc:postgresql://localhost:5434/agronexus`
   - `DB_USER`: `postgres`
   - `DB_PASS`: your local PostgreSQL password
   - `JWT_SECRET`: `<generate-strong-256bit-secret-key>`
   - `SPRING_AI_OPENAI_API_KEY`: `<your-openai-api-key>` (for RAG embeddings)
6. Click **Deploy Web Service**. Render will build the Spring Boot JAR inside the Docker container and assign a HTTPS URL:  
   `https://agronexus-backend.onrender.com`

---

### Step 3: Frontend Deployment — Vercel / Firebase / Netlify
1. Build the Flutter Web application release bundle:
   ```bash
   flutter build web --release --dart-define=API_BASE_URL=https://agronexus-backend.onrender.com/api/v1
   ```
2. Deploy the generated output folder `build/web`:
   - **Vercel**: Run `vercel --prod` inside `build/web`.
   - **Firebase Hosting**: Run `firebase deploy --only hosting`.
   - **Netlify**: Drag & drop the `build/web` folder to Netlify admin dashboard.
3. Your web frontend is now live at `https://agronexus.vercel.app` (or similar domain).

---

### Step 4: Hardware Node Configuration — ESP32 Telemetry
Update the ESP32 C++ firmware configuration in [`docs/IOT_HARDWARE_SPECIFICATION.md`](file:///c:/Users/lenovo%20p14s/Music/AGRONEXUS/docs/IOT_HARDWARE_SPECIFICATION.md):
```cpp
const char* serverEndpoint = "https://agronexus-backend.onrender.com/api/v1/telemetry";
```
Flash the code to your ESP32 board using Arduino IDE or PlatformIO. The hardware node will now stream storage metrics directly to the cloud backend.

---

## 🐳 Option B: Self-Hosted Deployment (Docker Compose)

For local testing, offline demonstrations, or VPS deployment (AWS EC2, DigitalOcean, Hetzner), use the included 1-command Docker Compose setup.

### Prerequisites
- Docker Engine $\ge 24.0$
- Docker Compose $\ge 2.20$

### Execution Steps
1. Navigate to the project root directory:
   ```bash
   cd c:\Users\lenovo p14s\Music\AGRONEXUS
   ```
2. Copy the environment file template:
   ```bash
   cp deployment/.env.example deployment/.env
   ```
3. Launch the containerized stack:
   ```bash
   docker-compose -f deployment/docker-compose.yml up -d --build
   ```
4. Verify running services:
   ```bash
   docker-compose -f deployment/docker-compose.yml ps
   ```

### Access URLs
- **Web Frontend**: [http://localhost:8080](http://localhost:8080)
- **Backend REST API**: [http://localhost:8081/api/v1](http://localhost:8081/api/v1)
- **Swagger API Docs**: [http://localhost:8081/swagger-ui.html](http://localhost:8081/swagger-ui.html)
- **PostgreSQL Database**: `localhost:5432` (`agronexus_db`)
- **MQTT Telemetry Broker**: `localhost:1883`

---

## 🔒 Post-Deployment Security Checklists
- [x] Change all default passwords in `deployment/.env`.
- [x] Ensure `JWT_SECRET` is at least 64 characters long.
- [x] Verify SSL/TLS HTTPS certificates on Render and Supabase.
- [x] Verify CORS permissions restrict allowed origins to your frontend deployment domain.
