# AgroNexus Documentation & Deployment Hub

Welcome to the official repository for **AgroNexus: An Integrated Agricultural Management and Information Platform**.

AgroNexus is a comprehensive AgTech ecosystem designed to address post-harvest agricultural value chain inefficiencies in Central Africa and broader regional markets. The platform combines spatial e-commerce, automated escrow payments, cyber-physical IoT telemetry for storage monitoring, verified agronomy advisory, and domain-guarded Retrieval-Augmented Generation (RAG) AI grounded in international agricultural standards (FAO, USDA, UNECE).

---

## 📊 Project Implementation Status & Baseline (~90–95%)

The platform is currently in the **Full-Featured MVP & Integration Stage**:

| Module / Epic | Baseline Implementation Status | Progress |
|---|---|---:|
| 🔐 **Auth & Roles (Epic 1)** | Multi-role registration & login, JWT access/refresh tokens, BCrypt strength 12, strict validation, OTP challenges, hashed national ID, face scan verification flow, and fail-closed biometric/GPS checks. | 95% |
| 🌽 **Produce Catalog & Spatial (Epic 2)** | PostGIS `Point` produce listings (`ProductController.java`), Buyer `ST_DWithin` radial spatial search (5km–100km), `AddProduceScreen` with category/photo management, and dynamic distance calculations. | 90% |
| 💳 **Escrow & Payments (Epic 3)** | `EscrowEngineService` formula, transparent breakdown checkout modal (item cost, transport fee, security deposit buffer), automated 85% Farmer / 15% Transporter disbursement endpoints, and dispute handling. | 90% |
| 🚚 **Transport & Logistics (Epic 4)** | Transporter dashboard with delivery job filtering, OpenStreetMap route planning, `HandoverActionCard` signoff flow, intermediate GPS waypoint tracking, and state machine transitions (`PENDING` $\rightarrow$ `COMPLETED`). | 88% |
| 🌡️ **IoT Storage Telemetry (Epic 5)** | Spring Boot telemetry REST ingestion (`TelemetryController.java`), safety threshold evaluation, real-time alert streaming (`/api/v1/telemetry/alerts/stream`), ESP32 C++ firmware, and Farmer Storage Dashboard. | 92% |
| 🤖 **Domain-Guarded AI (Epic 6)** | AgroAI assistant backend controller (`AgroAIController.java`, `AgroAIService.java`), Flutter screen (`buyer_agroai_screen.dart`), domain guardrail prompt validation, and `pgvector` FAO/USDA context retrieval pipeline. | 90% |
| 👤 **User Profile & Settings (Epic 7)** | Self-service profile editing, identity verification status updates (`AdminController.java`, `AuthController.java`), role switching, and account configuration. | 85% |
| 🎯 **Overall Completion** | **Full-Featured Working System / Production-Ready MVP** | **~90–95%** |

---

## 📚 Documentation Index

### 🎓 1. Academic & Project Deliverables

| File | Description |
| :--- | :--- |
| 📑 [PROJECT_REPORT.md](file:///c:/Users/lenovo%20p14s/Music/AGRONEXUS/docs/PROJECT_REPORT.md) | **Complete Software Engineering & AI Project Report** (Chapters 1–6, Abstract, Declarations, System Architecture, Performance Benchmarks, Appendices). |
| 📄 [PROJECT_SPECIFICATION.md](file:///c:/Users/lenovo%20p14s/Music/AGRONEXUS/docs/PROJECT_SPECIFICATION.md) | Project background, problem statement, research questions, objectives, scope & delimitations. |
| 📋 [REQUIREMENTS.md](file:///c:/Users/lenovo%20p14s/Music/AGRONEXUS/docs/REQUIREMENTS.md) | Functional epics (Epics 1–7), Non-Functional Requirements (NFR1–NFR4), and Requirements Traceability Matrix. |
| 📈 [PRODUCE_LISTING_AND_DASHBOARD_UPDATES.md](file:///c:/Users/lenovo%20p14s/Music/AGRONEXUS/docs/PRODUCE_LISTING_AND_DASHBOARD_UPDATES.md) | Feature status and verification history for the farmer dashboard, produce listing, image capture, and optional IoT linking. |

---

### 🏗️ 2. Technical & Architectural Specifications

| File | Description |
| :--- | :--- |
| 🏗️ [SYSTEM_ARCHITECTURE.md](file:///c:/Users/lenovo%20p14s/Music/AGRONEXUS/docs/SYSTEM_ARCHITECTURE.md) | Architectural layers, UML use cases, data flow diagrams (DFD Level-1), component models, and RBAC authorization matrix. |
| 🌐 [API_SPECIFICATION.md](file:///c:/Users/lenovo%20p14s/Music/AGRONEXUS/docs/API_SPECIFICATION.md) | Complete REST API endpoints specification, JWT authentication flow, escrow state machine transitions, and DTO contracts. |
| 🗄️ [DATABASE_SCHEMA.sql](file:///c:/Users/lenovo%20p14s/Music/AGRONEXUS/docs/DATABASE_SCHEMA.sql) | Production SQL database schema including PostGIS spatial coordinates (`GEOMETRY(Point, 4326)`), pgvector (`vector(1536)`), GiST/HNSW indexes, and constraints. |
| 🔌 [IOT_HARDWARE_SPECIFICATION.md](file:///c:/Users/lenovo%20p14s/Music/AGRONEXUS/docs/IOT_HARDWARE_SPECIFICATION.md) | ESP32 cyber-physical hardware setup, sensor pinouts (DHT22, MQ-135), C++ firmware implementation, and telemetry payload formats. |
| 🤖 [RAG_AI_PIPELINE.md](file:///c:/Users/lenovo%20p14s/Music/AGRONEXUS/docs/RAG_AI_PIPELINE.md) | Domain-guarded RAG AI pipeline, vector embedding ingestion, HNSW cosine search, guardrail execution flow, and FAO/USDA citation rules. |

---

### 🚀 3. Deployment & Cloud Operations

| File | Description |
| :--- | :--- |
| 🚀 [DEPLOYMENT_GUIDE.md](file:///c:/Users/lenovo%20p14s/Music/AGRONEXUS/deployment/DEPLOYMENT_GUIDE.md) | **Production Cloud Deployment Guide** (Supabase + Render + Vercel/Firebase & Docker Compose). |
| ⚡ [supabase_setup.sql](file:///c:/Users/lenovo%20p14s/Music/AGRONEXUS/deployment/supabase_setup.sql) | Production SQL Initialization & Seed Script for Supabase (PostGIS + pgvector). |

---

### 💻 4. Developer Setup & Troubleshooting

| File | Description |
| :--- | :--- |
| ⚙️ [DEVELOPMENT_SETUP_GUIDE.md](file:///c:/Users/lenovo%20p14s/Music/AGRONEXUS/docs/DEVELOPMENT_SETUP_GUIDE.md) | Local Flutter hardware setup (`geolocator`, `local_auth`), state management, local Wi-Fi IP configuration, and Gradle offline build troubleshooting. |
| ☕ [BACKEND_STARTUP_GUIDE.md](file:///c:/Users/lenovo%20p14s/Music/AGRONEXUS/docs/BACKEND_STARTUP_GUIDE.md) | Spring Boot 3.x backend startup guide, Maven build steps, and environment setup. |

---

## 👥 Project Information

- **Project Title**: AgroNexus — An Integrated Agricultural Management and Information Platform
- **Institution**: The ICT University, Yaoundé Campus, Cameroon
- **Department**: Department of Software Engineering and Artificial Intelligence
- **Degree**: Bachelor of Science (B.Sc.) in Software Engineering and Artificial Intelligence
- **Presented By**: Eunice Françoise Tchouela Quetsia (Registration No: ICTU20248912)
