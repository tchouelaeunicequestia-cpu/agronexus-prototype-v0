# System Architecture — AgroNexus

This document outlines the software engineering architecture, UML diagrams, data flow diagrams (DFD), and role-based access control (RBAC) authorization models for the **AgroNexus** ecosystem.

---

## 1. Architectural Overview

AgroNexus employs a layered, microservices-ready software architecture designed for high availability, security, spatial responsiveness, and IoT scalability.

```
+-----------------------------------------------------------------------+
|                         CLIENT LAYER (Flutter)                        |
|        Web Client        |      Mobile Client      |  Desktop Client  |
+-----------------------------------------------------------------------+
                                   | HTTPS / REST / WebSockets / MQTT
                                   v
+-----------------------------------------------------------------------+
|                    API GATEWAY & SECURITY LAYER                       |
|         Spring Security + JWT Authentication + CORS + Rate Limiting   |
+-----------------------------------------------------------------------+
                                   |
         +-------------------------+-------------------------+
         |                                                   |
         v                                                   v
+------------------------------------+  +-------------------------------+
|    APPLICATION & BUSINESS SERVICES  |  |    AI & VECTOR RAG PIPELINE   |
|  - Identity & RBAC Service         |  |  - Spring AI / LLM Client     |
|  - Produce Catalog Service         |  |  - Knowledge Ingestion        |
|  - Escrow Financial Engine         |  |  - Domain Guardrails Engine   |
|  - Logistics Dispatch Engine       |  |  - Cosine Distance RAG Search |
|  - Telemetry Processor & Alerts    |  +-------------------------------+
+------------------------------------+               |
                 |                                   |
                 +-----------------+-----------------+
                                   |
                                   v
+-----------------------------------------------------------------------+
|                         PERSISTENCE LAYER                             |
|          PostgreSQL 16 + PostGIS Spatial + pgvector Embeddings        |
+-----------------------------------------------------------------------+
                                   ^
                                   | MQTT / HTTP Payload
+-----------------------------------------------------------------------+
|                     CYBER-PHYSICAL IOT LAYER                          |
|    ESP32 Microcontroller Nodes + DHT22 (Temp/Hum) + MQ-135 (Gas)     |
+-----------------------------------------------------------------------+
```

---

## 2. Layered Architecture Components

1. **Client Layer (Flutter Cross-Platform)**:
   - Unified single codebase targeting Web, iOS/Android mobile, and Desktop platforms.
   - Material 3 responsive UI components, dynamic distance badges, live IoT telemetry line graphs, and conversational streaming RAG AI interface.

2. **API Gateway & Security Layer (Spring Security)**:
   - Enforces stateless authentication via signed JSON Web Tokens (JWT).
   - Enforces Role-Based Access Control (RBAC) method security annotations (`@PreAuthorize`).
   - Handles CORS configuration, TLS 1.3 encryption, and request rate limiting.

3. **Application & Business Logic Layer**:
   - **Escrow Financial Engine**: Atomic state transitions (`PENDING` -> `HELD_IN_ESCROW` -> `DISPATCHED` -> `COMPLETED` / `DISPUTED`).
   - **Logistics Dispatch Engine**: Freight job availability, distance calculations, driver assignment.
   - **Telemetry Processor**: Real-time sensor threshold parsing (temperature, relative humidity, gas levels) and automated push alert triggers.

4. **AI & Vector Pipeline Layer**:
   - **Target architecture:** uses a Hugging Face multilingual embedding model (`intfloat/multilingual-e5-base`) with PostgreSQL full-text search and `pgvector` hybrid retrieval.
   - The embedding model produces 768-dimensional vectors; the vector index must therefore use `vector(768)`.
   - Pre-filters incoming user queries using domain guardrails to reject non-agricultural inputs.
   - Retrieves and ranks official sources, reviewed agronomist guides, research, live data, and clearly labelled farmer observations using provenance, authority, scope, and freshness metadata.
   - An optional Hugging Face instruction model may synthesize answers only from retrieved passages and must preserve citations. The current MVP still returns matched guide text and does not perform LLM generation or semantic retrieval.

5. **Persistence Layer (PostgreSQL + PostGIS + pgvector)**:
   - Single ACID-compliant database instance handling relational tables, PostGIS 2D spatial geometries (`GEOMETRY(Point, 4326)`), PostgreSQL full-text search, and vector embeddings (`vector(768)`).

6. **Cyber-Physical Layer (ESP32 IoT Nodes)**:
   - Microcontroller hardware reading ambient temperature/humidity via DHT22 and air/gas quality via MQ-135 sensor.
   - Publishes JSON telemetry payloads every 15 seconds over HTTP REST or MQTT.

---

## 3. Data Flow Diagram (Level-1 DFD)

```
[ Farmer ] ----( 1. Create Listing + GPS Location )----> ( 2.0 Catalog Management ) ----> [( DB: products )]
                                                                  |
[ Buyer ]  ----( 3. Radial Distance Filter Query )--------------->+
                                                                  |
[ Buyer ]  ----( 4. Place Order & Escrow Deposit )-----> ( 3.0 Escrow Engine )    ----> [( DB: orders )]
                                                                  |
[ Transporter ]-( 5. Accept Transport Job )------------> ( 4.0 Freight Dispatch )  ----> [( DB: orders )]
                                                                  |
[ ESP32 IoT ]---( 6. Send Storage Sensor Telemetry )---> ( 5.0 IoT Processor )    ----> [( DB: telemetry_logs )]
                                                                  |
[ User ]   ----( 7. Query Advisory Assistant )---------> ( 6.0 Guarded RAG AI )  ----> [( DB: knowledge_embeddings )]
```

---

## 4. Role-Based Access Control (RBAC) Matrix

AgroNexus supports six primary system roles: `FARMER`, `BUYER`, `TRANSPORTER`, `AGRONOMIST`, `ADMIN`, and `SYSTEM`.

| Epic / Action | Farmer | Buyer | Transporter | Agronomist | Admin |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Create Produce Listing** | ✅ | ❌ | ❌ | ❌ | ✅ |
| **Search Catalog (Radial Filter)** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Place Order & Escrow Deposit** | ❌ | ✅ | ❌ | ❌ | ✅ |
| **Accept Freight/Transport Job** | ❌ | ❌ | ✅ | ❌ | ✅ |
| **Update Delivery Status** | ❌ | ❌ | ✅ | ❌ | ✅ |
| **View IoT Telemetry Dashboard** | ✅ | ❌ | ❌ | ✅ | ✅ |
| **Publish Agronomy Guide** | ❌ | ❌ | ❌ | ✅ | ✅ |
| **Query RAG AI Assistant** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Arbitrate Escrow Disputes** | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Manage System Settings** | ✅ | ✅ | ✅ | ✅ | ✅ |
