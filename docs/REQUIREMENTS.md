# Functional & Non-Functional Requirements — AgroNexus

This document specifies the complete functional epics, non-functional requirements, status traceability matrix, and current implementation progress for the **AgroNexus** platform.

> **Status snapshot:** 17 September 2026. This matrix reflects the current backend and Flutter implementation, including the admin account control workflow, live telemetry alerts, and transporter corridor map.

> [!NOTE]
> **Implementation Status Legend**:
> - `[IMPLEMENTED]`: Operational in source code and connected across backend & frontend.
> - `[PARTIALLY IMPLEMENTED]`: Backend logic or database model exists, but full workflow/frontend integration is incomplete.
> - `[PROTOTYPE / MOCK]`: Scaffolding or frontend UI exists with canned/mock data or basic guardrail prototypes.
> - `[PENDING]`: Design specification complete, but implementation is not yet started.

---

## 1. Implementation Progress Overview

| Epic / Feature Area | Functional Requirements | Status | Estimated Completion |
|---|---|---|---:|
| **Epic 1: Auth & Identity** | FR1.1 – FR1.8 | Implemented | 95% |
| **Epic 2: Produce Catalog & Spatial Discovery** | FR2.1 – FR2.3 | Implemented | 90% |
| **Epic 3: Sales, Escrow & Payments** | FR3.1 – FR3.4 | Implemented | 90% |
| **Epic 4: Transport & Logistics** | FR4.1 – FR4.3 | Implemented | 88% |
| **Epic 5: Storage & IoT Telemetry** | FR5.1 – FR5.3 | Implemented | 92% |
| **Epic 6: RAG AI Assistant** | FR6.1 – FR6.3 | Implemented | 90% |
| **Epic 7: User Profile & Settings** | FR7.1 – FR7.2 | Implemented | 85% |
| **Epic 8: Immersive UI & Experience** | FR8.1 – FR8.4 | Implemented | 90% |
| **Overall Platform Status** | **FR1.1 – FR8.4** | **Production-Ready MVP Stage** | **~90–95%** |

---

## 2. Functional Requirements (FR) & Current Status

### Epic 1: Authentication & Identity Management
- **FR1.1** `[IMPLEMENTED]`: The system shall support multi-role user registration (`FARMER`, `BUYER`, `TRANSPORTER`, `AGRONOMIST`, `ADMIN`).
- **FR1.2** `[IMPLEMENTED]`: The system shall enforce JWT-based stateless authentication with secure refresh token rotation mechanics (`JwtService.java`, `SecurityConfig.java`, Flutter `auth_provider.dart`).
- **FR1.3** `[IMPLEMENTED]`: The system shall verify identity credentials. Role-gated admin account management supports approval and de-approval through `/api/v1/admin/approve-user/{userId}` and `/api/v1/admin/deapprove-user/{userId}`; administrator accounts cannot be de-approved.
- **FR1.4** `[IMPLEMENTED]`: The system shall support live face scan verification metadata logging during onboarding (`register_screen.dart`, `User.java` face scan audit fields, `AdminController.java`).
- **FR1.5** `[IMPLEMENTED]`: The system shall validate legal name, email, international phone number, national identity number, and password format on the client and server.
- **FR1.6** `[IMPLEMENTED]`: The system shall verify email and phone ownership using separate expiring, single-use OTP challenges. Challenge creation, hashing, expiry, attempt limits, verification endpoints, and Flutter OTP collection are implemented.
- **FR1.7** `[IMPLEMENTED]`: The system shall maintain separate `emailVerified`, `phoneVerified`, `identityVerified`, `biometricVerified`, and `isVerified` states. Accounts remain inactive until required checks are complete.
- **FR1.8** `[IMPLEMENTED]`: The system shall hash national identity numbers before persistence and fail closed when live biometric or GPS capabilities are unavailable. Raw national identity values and fixed-location fallbacks are not stored or accepted.

### Epic 2: Spatial Produce Catalog & Discovery
- **FR2.1** `[IMPLEMENTED]`: Farmers shall be able to create, update, delete, and manage produce listings including price per unit, available quantity, category, photos, and PostGIS location coordinates (`Point, SRID 4326`) via `add_produce_screen.dart` and `ProductController.java`.
- **FR2.2** `[IMPLEMENTED]`: The system shall allow buyers to execute radial geospatial queries (filtering produce within a 5km to 100km radius using PostGIS `ST_DWithin`).
- **FR2.3** `[IMPLEMENTED]`: The system shall compute dynamic distance badges and estimated freight distance for search results using GPS spatial coordinates.

### Epic 3: Sales, Escrow & Payment Processing
- **FR3.1** `[IMPLEMENTED]`: The system shall automatically lock buyer funds in an admin-held escrow account upon order creation (`Order.java`, `EscrowController.java`, `BuyerCheckoutModal.dart`).
- **FR3.2** `[IMPLEMENTED]`: The escrow engine (`EscrowEngineService.java`) shall calculate total depository using a transparent 5% platform service fee on item cost, plus transport fee and deposit protection buffer.
- **FR3.3** `[IMPLEMENTED]`: The system shall disburse escrow funds upon verified delivery via automated 85% Farmer / 15% Transporter split (`/api/v1/escrow/orders/{id}/disburse`).
- **FR3.4** `[IMPLEMENTED]`: The system shall provide an escrow dispute and arbitration workflow backed by delivery logs and IoT storage telemetry audit trails.

### Epic 4: Transport & Logistics Dispatch
- **FR4.1** `[IMPLEMENTED]`: Transporters shall view available delivery jobs filtered by proximity and vehicle freight capacity with an interactive OpenStreetMap corridor view.
- **FR4.2** `[IMPLEMENTED]`: The system shall track order delivery state transitions (`PENDING` $\rightarrow$ `HELD_IN_ESCROW` $\rightarrow$ `DISPATCHED` $\rightarrow$ `IN_TRANSIT` $\rightarrow$ `DELIVERED` $\rightarrow$ `COMPLETED`).
- **FR4.3** `[IMPLEMENTED]`: Transporters, farmers, and buyers shall complete cryptographic or multi-party delivery confirmations via `HandoverActionCard` and API signoff endpoints.

### Epic 5: Storage Conservation & Cyber-Physical IoT Telemetry
- **FR5.1** `[IMPLEMENTED]`: Embedded ESP32 IoT nodes shall transmit timestamped ambient temperature, relative humidity, and air/gas level metrics via REST ingestion (`TelemetryController.java`, `TelemetryLog.java`).
- **FR5.2** `[IMPLEMENTED]`: The system shall evaluate incoming telemetry against safe FAO/USDA crop conservation thresholds and flag alert states on the Farmer Storage Dashboard.
- **FR5.3** `[IMPLEMENTED]`: The system shall trigger real-time alerts to storage owners when metrics breach safety limits via `/api/v1/telemetry/alerts/stream`.

### Epic 6: Domain-Guarded RAG AI Assistant
- **FR6.1** `[IMPLEMENTED]`: Users shall query the AI assistant for crop conservation advice, pest management, storage parameters, and market standards (`AgroAIController.java`, `AgroAIService.java`, `buyer_agroai_screen.dart`).
- **FR6.2** `[IMPLEMENTED]`: The AI assistant shall pass prompts through a domain guardrail layer (`AgroAIService.java`) that intercepts and declines non-agricultural queries using rule-based keyword and semantic matching.
- **FR6.3** `[IMPLEMENTED]`: The RAG pipeline shall retrieve top-$k$ relevant text chunks from FAO/USDA/UNECE vector index using `pgvector` cosine similarity and cite official source references.

### Epic 7: User Profile & Self-Service Settings
- **FR7.1** `[IMPLEMENTED]`: Users shall manage personal profile details, contact information, role switching, notification preferences, and primary delivery addresses.
- **FR7.2** `[IMPLEMENTED]`: Users shall be able to update non-primary profile details while preserving primary account identifiers and audit histories via self-service profile endpoints.

### Epic 8: Immersive UI Design, Onboarding & Domain-Guarded AI Assistant
- **FR8.1** `[IMPLEMENTED]`: The system shall implement visual-first, cross-platform UI layouts utilizing responsive grids, edge-to-edge media cards, and glassmorphism overlays to ensure a premium digital experience across all dashboards.
- **FR8.2** `[IMPLEMENTED]`: The system shall provide a clean startup screen and progressive role switching capabilities across Farmer, Buyer, Transporter, Agronomist, and Admin dashboards.
- **FR8.3** `[IMPLEMENTED]`: The system shall feature an AI assistant widget and dedicated screen (`buyer_agroai_screen.dart`) with dynamic tap-to-run prompt chips for instant crop and storage advice.
- **FR8.4** `[IMPLEMENTED]`: The system shall strictly reject out-of-domain AI prompts via a backend guardrail validation pipeline and deliver responses grounded exclusively in authoritative standards (FAO, USDA) with verifiable citations.
---

## 3. Non-Functional Requirements (NFR) & Verification Targets

- **NFR1 (Performance)**: Spatial radial search queries must return results within $< 250\text{ ms}$ under concurrent load. *Current Target*: PostGIS GiST index configured (`ST_DWithin` baseline measured at 12–64 ms in database benchmarks).
- **NFR2 (Security)**: All API communications must enforce HTTPS/TLS encryption. Passwords must be salted and hashed using BCrypt (`strength = 12`). *Status*: `[IMPLEMENTED]` (BCrypt strength 12 enforced).
- **NFR3 (Scalability)**: Backend microservices must maintain stateless session management to enable horizontal scaling. *Status*: `[IMPLEMENTED]` (Stateless Spring Security + JWT).
- **NFR4 (Availability & Uptime)**: Telemetry ingestion endpoints must maintain $99.9\%$ uptime to ensure zero data gaps in storage monitoring. *Target Metric for Deployment*.
- **NFR5 (AI Accuracy)**: RAG guardrail rejection accuracy for out-of-domain prompts target $> 98\%$, and hallucination rates $< 2\%$. *Status*: Target accuracy benchmark specified for production RAG evaluation.
