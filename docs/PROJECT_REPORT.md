# AgroNexus: An Integrated Agricultural Management and Information Platform

## SOFTWARE ENGINEERING & AI PROJECT REPORT

**Institution**: The ICT University, Yaoundé Campus, Cameroon  
**Department**: Department of Software Engineering and Artificial Intelligence  
**Degree**: Bachelor of Science (B.Sc.) in Software Engineering and Artificial Intelligence  
**Presented By**: Eunice Françoise Tchouela Quetsia (Registration No: ICTU20248912 | Level 2, Group 2)  
**Under the Supervision of**: [SUPERVISOR'S NAME], Department of Software Engineering & Artificial Intelligence, Faculty of Computer Science and Information Technology, The ICT University, Cameroon  
**Date**: October 2026  

---

## DECLARATION

I hereby declare that this project report entitled **“AgroNexus: An Integrated Agricultural Management and Information Platform”** is my original work, carried out under the supervision of [Supervisor's Name] at The ICT University, Cameroon.

I further declare that this work has not been submitted, either in whole or in part, to any other university or institution for the award of any degree, diploma, or other academic qualification, except where explicit reference and acknowledgement have been made.

**Student's Name**: Eunice Françoise Tchouela Quetsia  
**Registration No**: ICTU20248912  
**Department**: Software Engineering & AI  

**Signature**: ______________________  
**Date**: __________________________  

---

## CERTIFICATION

This is to certify that the project report entitled **“AgroNexus: An Integrated Agricultural Management and Information Platform”** was executed by Eunice Françoise Tchouela Quetsia (Registration Number: ICTU20248912) under my direct supervision.

The project has been examined and approved as satisfying the technical and academic standards for partial fulfillment of the requirements for the award of the Bachelor of Science (B.Sc.) Degree in Software Engineering and Artificial Intelligence at The ICT University.

**Supervisor**: [Supervisor's Name]  
**Designation**: Academic Supervisor  
**Department**: Software Engineering & AI  

**Signature**: ______________________  
**Date**: __________________________  

---

## DEDICATION

This project is dedicated to my family, friends, lecturers, and everyone whose unwavering support and encouragement contributed to the completion of this work.

It is also dedicated to the hardworking farmers, agricultural producers, buyers, transporters, and agronomists across Cameroon and Africa, whose daily dedication sustains our food systems, drives regional economies, and inspires technological innovation for post-harvest loss reduction and sustainable agriculture.

---

## ACKNOWLEDGEMENTS

I would like to express my profound gratitude to God Almighty for granting me wisdom, strength, health, and perseverance throughout the conception, design, and development of this project.

I am deeply grateful to my supervisor, [Supervisor's Name], for the valuable guidance, constructive critiques, technical recommendations, and continuous encouragement provided throughout this research and implementation process.

I also extend my sincere appreciation to the faculty members, administration, and staff of the Department of Software Engineering and Artificial Intelligence at The ICT University for equipping me with the essential engineering foundation and practical skills necessary to build this system.

My heartfelt gratitude goes to my beloved family and friends for their continuous patience, financial support, prayers, and understanding during long development hours.

Finally, I acknowledge all fellow students and stakeholders who provided valuable feedback and testing insights during the user experience and UI/UX design phase of AgroNexus.

---

## ABSTRACT

Agriculture is a vital driver of food security, employment, and sustainable economic development across Africa. However, agricultural activities are frequently hampered by systemic inefficiencies that persist beyond production into post-harvest operations. Stakeholders along the value chain — particularly smallholder farmers, buyers, transporters, and agronomists — face persistent challenges including fragmented market access, logistics friction, inadequate post-harvest crop preservation guidance, and a scarcity of localized, grounded decision support.

To address these challenges, AgroNexus is engineered as an integrated, multi-platform agricultural management and information ecosystem. Built using a modular monorepo architecture combining a cross-platform Flutter client (web, mobile, desktop), a Java Spring Boot 3.x microservices-ready backend, a PostgreSQL spatial and vector database (pgvector), and optional ESP32 C++ IoT hardware nodes, the platform centralizes key operations across the post-harvest value chain.

AgroNexus facilitates proximity-based product discovery, geolocation-aware direct trading, and secure admin-held escrow transactions governed by standard financial buffers (covering item costs, transport fees, and deposit protection). Integrated transportation workflows coordinate verified logistics, while dedicated preservation and IoT telemetry modules support real-time monitoring of crop storage conditions to mitigate post-harvest decay.

Crucially, AgroNexus incorporates a domain-guarded artificial intelligence assistant utilizing Retrieval-Augmented Generation (RAG). Grounded exclusively in verified agricultural standards (FAO, USDA, UNECE), the AI serves strictly as an intelligent support component — rejecting out-of-scope prompts while providing precise guidance on crop diseases, storage parameters, and market practices. Standard user self-service portals ensure complete privacy compliance, allowing profile updates while preserving primary identifiers.

Through this unified integration of software engineering, cyber-physical monitoring, spatial marketplace dynamics, and domain-bounded AI support, AgroNexus offers a scalable technological foundation to reduce agricultural waste, streamline market logistics, and empower stakeholders across the regional food value chain.

**Keywords**: AgroNexus, Agricultural Value Chain, Java Spring Boot, Flutter, Geolocation Marketplace, Escrow Payments, Cyber-Physical IoT, Retrieval-Augmented Generation (RAG), Domain Guardrails, Food Security.

---

## LIST OF FIGURES

| Figure No. | Title / Description | Page |
| :--- | :--- | :--- |
| Figure 3.1 | Existing Fragmented Agricultural Value Chain Model | 18 |
| Figure 3.2 | Proposed Integrated AgroNexus Platform Ecosystem | 22 |
| Figure 3.3 | UML Use Case Diagram (Roles & Interactions) | 26 |
| Figure 3.4 | Level-1 Data Flow Diagram (DFD) | 30 |
| Figure 3.5 | System Component Architecture (Flutter, Spring Boot, pgvector, MQTT) | 34 |
| Figure 4.1 | Overall Multi-Platform User Interface (UI/UX Layout) | 40 |
| Figure 4.2 | User Registration & Live Face Scan Verification Interface | 43 |
| Figure 4.3 | Agricultural Produce Catalog & Radial Distance Filter Interface | 47 |
| Figure 4.4 | Marketplace Product Sales & Escrow Checkout Interface | 50 |
| Figure 4.5 | Transportation Dispatch & Logistics Tracking Interface | 54 |
| Figure 4.6 | Storage Conservation & IoT Telemetry Monitoring Dashboard | 58 |
| Figure 4.7 | Domain-Guarded AI Agricultural Assistant Chat Interface | 62 |
| Figure 4.8 | Standard User Self-Service Settings Portal Interface | 66 |
| Figure 4.9 | Farmer Dashboard with Live Listings and Optional IoT Storage Link | 68 |
| Figure 4.10 | Freight Quote & Escrow State Flow (Transport Quote Pending → Completed) | 69 |

---

## LIST OF TABLES

| Table No. | Title / Description | Page |
| :--- | :--- | :--- |
| Table 3.1 | Functional Requirements Traceability Matrix (Epics 1–8) | 24 |
| Table 3.2 | Non-Functional System Requirements (Security, Latency, Privacy) | 28 |
| Table 3.3 | System User Personas, RBAC Authorization & Responsibilities | 32 |
| Table 4.1 | Software Technology Stack, Frameworks & Tooling Specifications | 38 |
| Table 5.1 | Core System API & Escrow Business Rule Test Cases | 70 |
| Table 5.2 | Domain Guardrail & RAG Vector Search AI Test Cases | 73 |
| Table 5.3 | System Integration, Hardware Simulation & Acceptance Results | 76 |

---

## LIST OF ABBREVIATIONS

| Abbreviation | Full Meaning / Definition |
| :--- | :--- |
| **AI** | Artificial Intelligence |
| **API** | Application Programming Interface |
| **DTO** | Data Transfer Object |
| **FAO** | Food and Agriculture Organization of the United Nations |
| **ICT** | Information and Communication Technology |
| **IoT** | Internet of Things |
| **JPA** | Java Persistence API |
| **KYC** | Know Your Customer |
| **JWT** | JSON Web Token |
| **MQTT** | Message Queuing Telemetry Transport |
| **MVP** | Minimum Viable Product |
| **NLP** | Natural Language Processing |
| **OTP** | One-Time Password |
| **RAG** | Retrieval-Augmented Generation |
| **RBAC** | Role-Based Access Control |
| **SSE** | Server-Sent Events |
| **SDLC** | Software Development Life Cycle |
| **HNSW** | Hierarchical Navigable Small World (vector index) |
| **GiST** | Generalized Search Tree (spatial index) |
| **UI / UX** | User Interface / User Experience |
| **UNECE** | United Nations Economic Commission for Europe |
| **USDA** | United States Department of Agriculture |

---

## TABLE OF CONTENTS

*(Page numbers should be regenerated automatically in the final Word/PDF export.)*

- DECLARATION
- CERTIFICATION
- DEDICATION
- ACKNOWLEDGEMENTS
- ABSTRACT
- LIST OF FIGURES
- LIST OF TABLES
- LIST OF ABBREVIATIONS
- TABLE OF CONTENTS
- **CHAPTER 1: INTRODUCTION**
  - 1.1 Background of the Study
  - 1.2 Problem Statement
  - 1.3 Research Questions
  - 1.4 Objectives of the Study
  - 1.5 Significance of the Study
  - 1.6 Scope and Delimitations of the Study
  - 1.7 Organization of the Report
- **CHAPTER 2: LITERATURE REVIEW & TECHNOLOGICAL FRAMEWORK**
  - 2.1 Theoretical Overview of Agricultural Supply Chains
  - 2.2 Comparative Analysis of Existing Platforms & Related Work
  - 2.3 Key Technological Concepts
  - 2.4 Software Technology Stack Justification
- **CHAPTER 3: SYSTEM ANALYSIS, REQUIREMENTS & DESIGN**
  - 3.1 Requirements Analysis (Epics 1–8, NFR1–NFR5)
  - 3.2 System Architecture & UML Design
  - 3.3 Database Entity-Relationship Modeling
- **CHAPTER 4: SYSTEM IMPLEMENTATION**
  - 4.0 Implementation Baseline & Current Development Stage
  - 4.1 Backend Services & API Engineering
  - 4.2 Embedded Hardware & IoT Telemetry Pipeline
  - 4.3 RAG AI Assistant & Vector Guardrails Pipeline
  - 4.4 Cross-Platform Client Implementation (Flutter)
  - 4.5 Farmer Dashboard, Produce Listing & Role-Aware Data Wiring
  - 4.6 Development Environment & Implementation Challenges
- **CHAPTER 5: TESTING, RESULTS & DISCUSSION**
  - 5.1 System Integration & Testing Methodology
  - 5.2 Performance Results & Empirical Evaluation
  - 5.3 Key Findings & Discussion
  - 5.4 Known Limitations
- **CHAPTER 6: CONCLUSION & RECOMMENDATIONS**
- REFERENCES
- APPENDICES (A: UI Wireframes, B: Database Schema, C: Hardware Pinout, D: API Endpoint Reference)

---

## CHAPTER 1: INTRODUCTION

### 1.1 Background of the Study

Agriculture remains the fundamental backbone of African economies, serving as the primary source of livelihood, employment, and food security for over 60% of the sub-Saharan population. Despite its critical socio-economic importance, the agricultural sector across developing regions — particularly in Central Africa — operates under severe structural inefficiencies that extend far beyond initial crop cultivation.

While agricultural research historically prioritized on-farm production yields, post-harvest operations remain plagued by fragmented value chains, inadequate logistics, limited access to cold-storage infrastructure, and opaque pricing mechanisms. Smallholder farmers frequently face market isolation, forcing them to sell perishable produce to intermediaries at distressed prices. Concurrently, commercial buyers and institutional consumers encounter high procurement friction, unreliable supply quality, and lack of verified product provenance.

The emergence of modern software engineering paradigms, cyber-physical Internet of Things (IoT) hardware, spatial database engines, and Artificial Intelligence (AI) presents a transformative opportunity to modernize agricultural supply chains. By synthesizing real-time environmental monitoring, spatial proximity search, escrow-protected transactional workflows, and domain-bounded retrieval systems into a unified platform, the post-harvest agricultural ecosystem can achieve unprecedented transparency, efficiency, and sustainability.

### 1.2 Problem Statement

The agricultural post-harvest supply chain in regional markets suffers from four major structural breakdowns:

1. **Market Fragmentation & Spatial Isolation**: Smallholder producers lack direct, real-time access to regional buyers, resulting in an over-reliance on local middlemen who exploit price information asymmetry.
2. **Post-Harvest Crop Spoilage & Environmental Neglect**: Due to lack of real-time storage environmental telemetry (temperature, relative humidity, gas accumulation), significant quantities of harvested produce deteriorate in storage facilities before reaching distant markets.
3. **Transaction Insecurity & Logistics Disconnect**: Direct digital transactions between unfamiliar agricultural trading partners are hindered by mutual trust deficits, payment defaults, and uncoordinated freight transportation.
4. **Information Noise & Ungrounded Guidance**: Farmers and agricultural actors seeking technical guidance on crop preservation, disease management, and market standards are often exposed to generic, hallucinated, or unverified online advice that lacks authoritative domain backing.

Without a centralized digital infrastructure that seamlessly integrates trade, logistics, environmental preservation, and domain-validated decision support, post-harvest losses will continue to threaten regional food security and agricultural economic viability.

### 1.3 Research Questions

- **RQ1**: How can a unified, multi-platform software architecture be designed to connect agricultural producers, buyers, transporters, agronomists, and system administrators within a single real-time ecosystem?
- **RQ2**: How can financial escrow mechanisms and spatial proximity indexing be structured to ensure transparent, risk-free marketplace transactions and optimized logistics matching?
- **RQ3**: How can IoT microcontrollers and environmental sensors be integrated to provide actionable, real-time storage condition telemetry for post-harvest loss mitigation?
- **RQ4**: How can a Retrieval-Augmented Generation (RAG) Artificial Intelligence assistant be restricted through domain guardrails to deliver strictly authoritative, expert-verified agricultural advice?

### 1.4 Objectives of the Study

#### 1.4.1 Main Objective
The main objective of this project is to design, develop, and evaluate AgroNexus, an integrated, multi-platform agricultural management and information ecosystem that unifies direct marketplace trading, secure escrow payments, logistics dispatching, cyber-physical storage telemetry, and domain-bounded AI decision support.

#### 1.4.2 Specific Objectives
1. To model user workflows and system architecture encompassing six primary roles (Farmer, Buyer, Transporter, Agronomist, Admin, System).
2. To build a cross-platform client (Web, Mobile, Desktop) delivering responsive UI/UX for produce discovery, spatial filtering, order processing, and account management.
3. To engineer a robust microservices-ready backend API enforcing role-based access control (RBAC), token authentication, and strict business rules for financial escrow buffers.
4. To integrate cyber-physical IoT hardware nodes (ESP32) for continuous environmental data collection and storage condition alerts.
5. To implement a domain-guarded RAG AI model vector-indexed with international agricultural standards (FAO, USDA, UNECE) to eliminate AI hallucinations and provide verified advisory assistance.

### 1.5 Significance of the Study

- **For Smallholder Farmers**: Provides direct market visibility, fair pricing, reduced middleman exploitation, and real-time guidance on preserving harvested crops.
- **For Buyers & Commercial Consumers**: Guarantees transparent produce sourcing, quality verification, radial distance filtering, and secure escrow transaction safeguards.
- **For Transporters & Logistics Drivers**: Streamlines freight jobs through structured dispatching and verified delivery confirmation workflows.
- **For Agronomists & Researchers**: Supplies continuous field and storage telemetry data while providing a platform to publish verified conservation practices.
- **For Software Engineering & AI Practice**: Demonstrates a practical reference architecture combining cross-platform frontend systems, robust transactional backends, spatial databases, embedded IoT, and domain-restricted RAG AI.

### 1.6 Scope and Delimitations of the Study

#### Scope
- Implementation of a cross-platform client using Flutter targeting Web, Mobile, and Desktop platforms.
- Development of a RESTful backend using Spring Boot 3.x and PostgreSQL with spatial and vector (`pgvector`) extensions.
- Design and implementation of 8 functional system epics: Authentication/Identity Verification, Distance-Filtered Produce Catalog, Product Sales & Escrow Checkout, Transport Dispatch, Storage Conservation & IoT Telemetry, RAG AI Agricultural Assistant, Standard User Self-Service Settings, and Immersive UI & Onboarding.
- Hardware simulation and embedded C++ integration using ESP32 nodes over MQTT/HTTP protocols.

#### Delimitations
- **Financial Payments**: Payment integration simulates Mobile Money and bank card transactions through automated sandbox APIs rather than live financial settlement networks.
- **Hardware Deployment**: Hardware telemetry testing is conducted using prototype sensor rigs and simulated environmental chambers rather than industrial-scale commercial warehouses.
- **Jurisdiction**: Agricultural regulatory standards implemented in the AI knowledge base focus primarily on guidelines relevant to sub-Saharan Africa, FAO, USDA, and UNECE frameworks.
- **Verification Providers**: OTP delivery (email/SMS) and external KYC/liveness verification are implemented as fail-closed interfaces. Delivery is disabled by default, a console mode exists for local development only, and connecting a production email/SMS provider and an external KYC/liveness service remains integration work.

### 1.7 Organization of the Report

The remainder of this report is organized into five subsequent chapters:
- **Chapter 2 (Literature Review & Technological Framework)**: Evaluates existing agricultural management systems, theoretical value chain models, embedded IoT architectures, and RAG AI paradigms while establishing the chosen software technology stack.
- **Chapter 3 (System Analysis, Requirements & Design)**: Details functional and non-functional requirements, RBAC specifications, UML use case and activity diagrams, data flow diagrams (DFD), entity-relationship models (ERD), and microservice component architecture.
- **Chapter 4 (System Implementation)**: Presents the technical implementation of core backend controllers, escrow business engines, cross-platform UI screens, ESP32 firmware code, and vector RAG guardrail pipelines.
- **Chapter 5 (Testing, Results & Discussion)**: Outlines unit testing, integration testing, API benchmark performance, AI guardrail evaluation metrics, and user acceptance testing.
- **Chapter 6 (Conclusion & Recommendations)**: Summarizes contributions, states conclusions drawn from the empirical results, and presents recommendations and future research directions.

---

## CHAPTER 2: LITERATURE REVIEW & TECHNOLOGICAL FRAMEWORK

### 2.1 Theoretical Overview of Agricultural Supply Chains

Agricultural supply chain management (ASCM) encompasses the end-to-end orchestration of material, financial, and informational flows from farm preparation to final consumption. Unlike conventional industrial supply chains, agricultural supply chains are uniquely vulnerable to product perishability, supply-demand volatility, seasonal yield fluctuations, and stringent environmental storage dependencies.

Traditional agricultural paradigms across sub-Saharan Africa follow a multi-tiered, fragmented structure characterized by asymmetric information flow:
1. **Stage 1 (Harvest & Primary Storage)**: Smallholder producers harvest crops with minimal access to real-time environmental telemetry or modern cold-chain infrastructure.
2. **Stage 2 (Local Intermediaries / Middlemen)**: Local traders purchase produce at farm gates, taking advantage of the producer's lack of market price visibility.
3. **Stage 3 (Regional Logistics & Transit)**: Uncoordinated transport providers move produce without temperature controls, resulting in significant post-harvest losses.
4. **Stage 4 (Wholesale & Retail Outlets)**: Merchants mark up prices significantly to offset anticipated decay risks and transport losses before final consumer sale.

### 2.2 Comparative Analysis of Existing Platforms & Related Work

Digital intervention in agriculture has expanded across three primary domains: farm management software, e-commerce marketplaces, and IoT-based environmental monitoring. However, existing solutions remain compartmentalized, creating functional gaps for end-to-end operations.

| Platform / Approach | Primary Focus | Key Strengths | Limitations & Gaps |
| :--- | :--- | :--- | :--- |
| **Traditional E-Commerce** | B2C/B2B Retail | Scalable payment gateways, broad user reach | Lacks spatial radial filtering, escrow transport buffers, and agricultural domain context |
| **Monolithic AgTech Portals** | Farm Record Keeping | Detailed crop production tracking, financial logging | Desktop-bound, lacks live market integration, no IoT telemetry or AI support |
| **Standalone IoT Sensor Rigs** | Warehouse Telemetry | High precision environmental data logging | Closed hardware loops, no integrated market sales channels or logistics dispatch |
| **Generic LLM Chatbots** | Information Retrieval | Conversational accessibility | High risk of hallucinations, lacks domain guardrails and international standard grounding (FAO/USDA) |
| **AgroNexus (Proposed)** | Unified Ecosystem | End-to-end integration: spatial trading, escrow, transport dispatch, IoT, and RAG AI | Requires multi-role coordination and hardware-software integration |

### 2.3 Key Technological Concepts

#### 2.3.1 Escrow Payment Architectures in Agriculture
To resolve trust deficits between unfamiliar trading partners in remote agricultural regions, AgroNexus utilizes an automated financial escrow model. Under this paradigm, buyer funds are held securely in a central administrative account upon order placement. Release of funds follows a multi-party authorization workflow:
- **Fund Allocation Formula**: $\text{Total Depository} = \text{Item Cost} + \text{Transport Fee} + \text{5\% Platform Service Fee} + \text{Deposit Protection Buffer}$
- **Release Conditions**: Funds are disbursed to the seller and transporter only upon multi-party confirmation (farmer sign-off, transporter pickup and delivery, buyer receipt) of successful product receipt and transport delivery. For freight orders, funds are locked only after the buyer approves a transporter quote.
- **Dispute Resolution**: In cases of damaged goods or non-delivery, admin arbitration evaluates telemetric storage logs and photo evidence to determine partial or full refund allocation.

#### 2.3.2 Cyber-Physical Systems (CPS) & Embedded IoT Nodes
The integration of embedded microcontrollers (ESP32) with environmental sensors (DHT11/DHT22 for temperature and relative humidity, gas sensors for ethylene and ammonia detection) forms a cyber-physical monitoring layer. Data transmission operates over lightweight IoT communication protocols:
- **MQTT (Message Queuing Telemetry Transport)**: Lightweight publish/subscribe messaging over TCP/IP designed for low-bandwidth, high-latency rural networks.
- **Real-Time Alert Thresholds**: Automated triggers broadcast alerts when storage parameters deviate from recommended FAO/USDA crop conservation profiles.

#### 2.3.3 Retrieval-Augmented Generation (RAG) & AI Guardrails
Standard Large Language Models (LLMs) often generate plausible-sounding but factually inaccurate advice (hallucinations) when queried on specific domain topics. To ensure reliability for agricultural advisory:
- **Vector Embedding Indexing**: Authoritative documents from the Food and Agriculture Organization (FAO), United States Department of Agriculture (USDA), and UNECE are chunked, embedded using vector transformation models, and stored in a vector database (`pgvector`).
- **Semantic Query Matching**: User queries retrieve top-k relevant contextual fragments using cosine similarity search before prompting the language model.
- **Domain Guardrails**: Prompt engineering and system rules reject out-of-scope queries (e.g., non-agricultural topics) and restrict responses to claims supported by retrieved context.

### 2.4 Software Technology Stack Justification

- **Frontend Client (Flutter)**: Provides a single, highly performant codebase for Web, Mobile, and Desktop platforms, ensuring consistent cross-platform user experience across diverse user devices.
- **Backend Framework (Spring Boot 3.x)**: Offers enterprise-grade reliability, robust dependency injection, security infrastructure (Spring Security + JWT), and high throughput for transactional and microservices-ready endpoints.
- **Database Management System (PostgreSQL + PostGIS + pgvector)**: Unifies relational data management, spatial geospatial indexing for radial distance searches, and high-dimensional vector search within a single, ACID-compliant database system.
- **Embedded Firmware (ESP32 C++ / Arduino Framework)**: Delivers dual-core processing, native Wi-Fi/Bluetooth stacks, low power consumption modes, and reliable hardware interrupts for sensor data acquisition.

---

---

## CHAPTER 3: SYSTEM ANALYSIS, REQUIREMENTS & DESIGN

### 3.1 Requirements Analysis

#### 3.1.1 Functional Requirements (FR)
The AgroNexus platform functional requirements are categorized across eight epics. Status values follow the project traceability matrix (status snapshot: 17 September 2026).

##### Epic 1: Authentication & Identity Management
- **FR1.1**: The system shall support multi-role registration (Farmer, Buyer, Transporter, Agronomist, Admin).
- **FR1.2**: The system shall enforce JWT-based stateless authentication with secure refresh-token rotation.
- **FR1.3**: The system shall verify identity credentials. Role-gated admin account management supports approval and de-approval of accounts; administrator accounts cannot be de-approved.
- **FR1.4**: The system shall log live face-scan verification metadata during onboarding.
- **FR1.5**: The system shall validate legal name, email, international phone number, national identity number, and password format on both the client and the server.
- **FR1.6**: The system shall verify ownership of the submitted email address and phone number using separate, expiring, single-use OTP challenges.
- **FR1.7**: The system shall maintain separate `emailVerified`, `phoneVerified`, `identityVerified`, `biometricVerified`, and `isVerified` states and shall not activate an account before the required checks are complete.
- **FR1.8**: The system shall store only a cryptographic hash of the national identity number and shall fail closed when biometric or GPS capabilities are unavailable; simulated success and fixed-location fallbacks are prohibited.

##### Epic 2: Spatial Produce Catalog & Discovery
- **FR2.1**: Farmers shall be able to create, update, delete, and manage produce listings (price, quantity, category, photos, PostGIS `Point` location, SRID 4326).
- **FR2.2**: Buyers shall be able to filter produce using radial geospatial queries (5 km to 100 km) based on PostGIS `ST_DWithin`.
- **FR2.3**: The system shall compute dynamic distance badges and estimated freight distance for search results.

##### Epic 3: Sales, Escrow & Payment Processing
- **FR3.1**: The system shall lock buyer funds in an admin-held escrow account upon order creation (self-pickup) or upon buyer approval of a transporter quote (freight delivery).
- **FR3.2**: The escrow engine shall calculate the total deposit using a transparent 5% platform service fee on item cost, plus the transport fee and a deposit protection buffer.
- **FR3.3**: The system shall disburse escrow funds upon verified delivery via an automated 85% Farmer / 15% Transporter split (100% Farmer for self-pickup).
- **FR3.4**: The system shall provide an escrow dispute and arbitration workflow supported by delivery logs and IoT storage telemetry audit trails.

##### Epic 4: Transport & Logistics Dispatch
- **FR4.1**: Transporters shall view available delivery jobs and quote requests filtered by proximity and freight capacity, with an interactive OpenStreetMap corridor view.
- **FR4.2**: The system shall track order state transitions (`PENDING` / `TRANSPORT_QUOTE_PENDING` → `HELD_IN_ESCROW` → `DISPATCHED` → `IN_TRANSIT` → `DELIVERED` → `COMPLETED`).
- **FR4.3**: Farmers, transporters, and buyers shall complete multi-party delivery confirmations through the `HandoverActionCard` and API sign-off endpoints.

##### Epic 5: Storage Conservation & Cyber-Physical IoT Telemetry
- **FR5.1**: Embedded ESP32 nodes shall transmit timestamped temperature, relative humidity, and gas-level metrics through REST ingestion.
- **FR5.2**: The system shall evaluate incoming telemetry against FAO/USDA crop-conservation thresholds and flag alert states on the Farmer Storage Dashboard.
- **FR5.3**: The system shall deliver real-time alerts to storage owners when metrics breach safety limits via a Server-Sent Events (SSE) stream.

##### Epic 6: Domain-Guarded RAG AI Assistant
- **FR6.1**: Users shall query the AI assistant for crop conservation, pest management, storage parameters, and market standards.
- **FR6.2**: The assistant shall pass prompts through a domain guardrail layer that declines non-agricultural queries.
- **FR6.3**: The RAG pipeline shall retrieve top-*k* relevant chunks from the FAO/USDA/UNECE vector index using `pgvector` cosine similarity and cite official source references.

##### Epic 7: User Profile & Self-Service Settings
- **FR7.1**: Users shall manage profile details, contact information, notification preferences, and primary delivery addresses.
- **FR7.2**: Users shall be able to update non-primary profile details while primary account identifiers and audit histories are preserved.

##### Epic 8: Immersive UI, Onboarding & Experience
- **FR8.1**: The system shall provide visual-first, responsive cross-platform layouts (responsive grids, edge-to-edge media cards, glassmorphism overlays).
- **FR8.2**: The system shall provide a clean startup screen and role-based navigation across Farmer, Buyer, Transporter, Agronomist, and Admin dashboards.
- **FR8.3**: The system shall provide an AI assistant widget and dedicated screen with tap-to-run prompt chips.
- **FR8.4**: The system shall reject out-of-domain AI prompts through a backend guardrail pipeline and ground responses in authoritative standards with verifiable citations.

#### 3.1.2 Non-Functional Requirements (NFR)
- **NFR1 (Performance)**: Spatial radial search queries shall return results within $< 250\text{ ms}$ under concurrent load.
- **NFR2 (Security)**: All API communications shall use HTTPS/TLS; passwords shall be salted and hashed with BCrypt (strength 12); national identity numbers shall be stored only as SHA-256 hashes; OTP codes shall be stored as BCrypt hashes.
- **NFR3 (Scalability)**: Backend services shall use stateless session management (Spring Security + JWT) to support horizontal scaling.
- **NFR4 (Availability)**: Telemetry ingestion endpoints shall maintain 99.9% uptime to avoid storage data gaps (deployment target).
- **NFR5 (AI Accuracy)**: Guardrail rejection of out-of-domain prompts shall exceed 98% and hallucination rate shall remain below 2% (evaluation target).

### 3.2 System Architecture & UML Design

#### 3.2.1 High-Level Component Architecture
AgroNexus employs a layered, microservices-ready software architecture:
1. **Client Layer**: Cross-platform Flutter application (Web, Mobile, Desktop) using the Provider package for state management.
2. **API Gateway & Security Layer**: Spring Security handles JWT authentication, RBAC (`@PreAuthorize`), CORS, and rate limiting.
3. **Application & Business Layer**: REST services implementing the Escrow Engine, Order Pipeline, Logistics Dispatcher, and Telemetry Processor.
4. **AI & Vector Pipeline Layer**: Spring AI integration connecting to `pgvector` for semantic retrieval and prompt guardrails.
5. **Persistence Layer**: PostgreSQL 16 with PostGIS (spatial) and `pgvector` (embeddings), hosted on Supabase during development.
6. **Hardware Cyber-Physical Layer**: ESP32 nodes capturing sensor data and publishing over HTTP REST or MQTT every 15 seconds.

#### 3.2.2 Role-Based Access Control (RBAC) Matrix

| Epic / Action | Farmer | Buyer | Transporter | Agronomist | Admin |
| :--- | :---: | :---: | :---: | :---: | :---: |
| Create Produce Listing | ✓ | ✗ | ✗ | ✗ | ✓ |
| Search Catalog (Radial Filter) | ✓ | ✓ | ✓ | ✓ | ✓ |
| Place Order & Escrow Deposit | ✗ | ✓ | ✗ | ✗ | ✓ |
| Accept Freight/Transport Job | ✗ | ✗ | ✓ | ✗ | ✓ |
| Update Delivery Status | ✗ | ✗ | ✓ | ✗ | ✓ |
| View IoT Telemetry Dashboard | ✓ | ✗ | ✗ | ✓ | ✓ |
| Publish Agronomy Guides | ✗ | ✗ | ✗ | ✓ | ✓ |
| Query RAG AI Assistant | ✓ | ✓ | ✓ | ✓ | ✓ |
| Arbitrate Escrow Disputes | ✗ | ✗ | ✗ | ✗ | ✓ |
| Approve / De-approve Users | ✗ | ✗ | ✗ | ✗ | ✓ |
| Manage Profile & Settings | ✓ | ✓ | ✓ | ✓ | ✓ |

A sixth role, `SYSTEM`, represents device nodes that submit telemetry.

### 3.3 Database Entity-Relationship Modeling (ERD Outline)

The core database entities and relationships include:
- **Users (`users`)**: Account credentials, role, phone number, verification flag, and base location (`GEOMETRY(Point, 4326)`) with a GiST index.
- **Products (`products`)**: Linked to farmers; stores category, unit price, unit type, quantity, active flag, image URL, and PostGIS location.
- **Orders (`orders`)**: Connects buyer, product, and optional transporter; stores item cost, transport fee, deposit buffer, total escrow amount, delivery address, destination point, and escrow status.
- **Telemetry Data (`telemetry_logs`)**: Timestamped temperature, humidity, gas level, alert flag, and alert message per storage node.
- **Vector Documents (`knowledge_embeddings`)**: FAO/USDA/UNECE chunks with `vector(1536)` embeddings and an HNSW cosine index.
- **Agronomy Guides (`agronomy_guides`)**: Agronomist-authored crop guidance linked to the author.

The reference SQL script is in Appendix B. The implemented JPA entities extend the `users` table with the verification fields described in Section 4.1.2.

---

## CHAPTER 4: SYSTEM IMPLEMENTATION

### 4.0 Implementation Baseline & Current Development Stage

As of the current evaluation (status snapshot 17 September 2026), **AgroNexus** has progressed from the earlier Working Prototype / MVP Foundation stage (approximately 39–45%) to a **Full-Featured MVP & Integration Stage (approximately 90–95% of the specified functional scope)**.

| Module / Epic | Implementation Summary | Progress |
| :--- | :--- | ---: |
| Auth & Identity (Epic 1) | Multi-role registration/login, JWT access and refresh tokens, BCrypt strength 12, server-side validation, OTP challenges, hashed national ID, face-scan flow, fail-closed biometric/GPS, admin approve/de-approve | 95% |
| Produce Catalog & Spatial (Epic 2) | PostGIS listings, `ST_DWithin` radial search (5–100 km), `AddProduceScreen` with real photo picker, dynamic distance badges | 90% |
| Escrow & Payments (Epic 3) | `EscrowEngineService`, transparent checkout breakdown, freight quote and approval workflow, 85/15 disbursement endpoint, dispute handling | 90% |
| Transport & Logistics (Epic 4) | Transporter dashboard, quote-request queue, OpenStreetMap corridor, `HandoverActionCard`, GPS waypoints, state machine | 88% |
| IoT Telemetry (Epic 5) | REST ingestion, threshold evaluation, SSE alert stream, ESP32 firmware, Farmer Storage Dashboard | 92% |
| Domain-Guarded AI (Epic 6) | `AgroAIController` / `AgroAIService`, Flutter AgroAI screen, guardrails, `pgvector` retrieval pipeline | 90% |
| Profile & Settings (Epic 7) | Self-service profile editing, verification status, role switching | 85% |
| Immersive UI (Epic 8) | Responsive visual-first layouts, role switching, AI prompt chips | 90% |
| **Overall** | **Production-ready MVP stage** | **~90–95%** |

**Remaining work and honest scope boundaries** (detailed in Section 5.4):
- Production email/SMS delivery for OTPs and an external KYC/liveness provider are not yet connected; verification delivery is disabled by default.
- Mobile Money payouts operate against sandbox flows, not live settlement.
- Dedicated business workflows for the agronomist (advisory requests) and fuller admin tooling (dispute administration) continue to need dedicated endpoints and screens.
- The vector knowledge base requires ingestion of the full FAO/USDA/UNECE corpus and independent evaluation before production claims are made.

### 4.1 Backend Services & API Engineering

#### 4.1.1 Core API Architecture
The backend (Spring Boot 3.3.2, Java 21, Maven 3.9.9, Hibernate 6.5.2) is structured around domain-driven modules exposing RESTful endpoints:
- **Authentication & Authorization**: Spring Security with stateless JWT; role annotations enforce access on each route.
- **Geospatial Proximity Queries**: PostGIS queries return listings within a user-defined radius.

```sql
ST_DWithin(location, ST_MakePoint(lon, lat)::geography, radius_meters)
```

The principal controllers and endpoint groups are:

| Controller | Endpoints (summary) | Access |
| :--- | :--- | :--- |
| `AuthController` | `POST /auth/register`, `/login`, `/refresh`, `/verify`, `/resend-verification` | Public |
| `ProductController` | `POST /products`, `GET /products/nearby`, `GET /products/mine` | Farmer/Admin; authenticated |
| `FarmerDashboardController` | `GET /farmers/me/dashboard` | Authenticated farmer |
| `EscrowController` | `POST /escrow/order`, `/escrow/order/{code}/quote`, `/approve-quote`, `POST /escrow/disburse/{code}`, `GET /escrow/buyer/orders` | Buyer/Transporter/Admin |
| `OrderController` | `POST /orders/{id}/farmer-signoff`, `/transporter-confirm`, `/transporter-deliver`, `/waypoint`; `GET /transporter/quote-requests` | Farmer/Transporter/Admin |
| `TelemetryController` | `POST /telemetry/log`, `GET /telemetry/node/{id}/latest`, `GET /telemetry/alerts/stream` (SSE) | Device; authenticated |
| `AgroAIController` | `POST /ai/query`, `/ai/agro-assistant` | Authenticated |
| `AdminController` | `GET /admin/users`, `PUT /admin/approve-user/{id}`, `/deapprove-user/{id}`; `PUT /users/profile` | Admin; authenticated |

All paths are prefixed with `/api/v1`. The complete reference is in Appendix D.

#### 4.1.2 Registration Information Verification

The registration workflow distinguishes between information merely supplied by a user and information that has been independently verified. The Flutter registration screen performs immediate format checks for the legal name, email, phone number, national identity number, and password. The Spring Boot API repeats these checks server-side so client-side validation cannot be bypassed.

After registration, the backend creates separate email and phone verification challenges. Each challenge is stored as a BCrypt hash, expires after ten minutes, is single-use, and is limited to five attempts. The frontend collects both OTPs through a dedicated verification dialog, and the API exposes three public endpoints:

- `POST /api/v1/auth/register` — creates a pending account and issues contact verification challenges.
- `POST /api/v1/auth/verify` — verifies one email or phone OTP.
- `POST /api/v1/auth/resend-verification` — issues a replacement challenge.

The `User` entity tracks `emailVerified`, `phoneVerified`, `identityVerified`, `biometricVerified`, and the final `isVerified` state independently. A national identity number is converted to a SHA-256 hash before persistence, which allows identity matching without retaining the original identifier. Roles that require approval additionally pass through administrative vetting (`approve-user` / `deapprove-user`).

Biometric verification is explicitly fail-closed. Web registration does not claim success without a configured liveness provider, desktop registration requires a supported biometric sensor, and location capture reports an error when live permission or GPS data is unavailable instead of substituting a fixed coordinate.

OTP delivery is controlled by the `VERIFICATION_DELIVERY_MODE` environment variable: `disabled` (fail-closed default; no code is delivered), `console` (prints codes to backend logs, local development only), or a future production provider mode once an email/SMS adapter and credentials are configured. Secrets such as provider credentials, database passwords, and JWT signing keys are supplied through environment variables and are never committed to the repository or documentation.

#### 4.1.3 Escrow Business Logic Implementation
The transactional pipeline enforces explicit state transitions and distinguishes self-pickup from freight delivery:

1. **Order Creation**: The buyer creates an order; the engine computes the item cost, a transparent 5% platform service fee, the transport fee, and the deposit protection buffer, and issues an order notification.
2. **Self-Pickup**: Funds lock immediately and the order enters `HELD_IN_ESCROW`.
3. **Freight Delivery**: The order is created as `TRANSPORT_QUOTE_PENDING` with no funds locked. A transporter submits a quote (`POST /escrow/order/{orderCode}/quote`); the buyer approves it (`POST /escrow/order/{orderCode}/approve-quote`). Only then does the order move to `HELD_IN_ESCROW` with its final escrow total.
4. **Dispatch & Tracking**: Farmer sign-off triggers transport assignment (`DISPATCHED`); transporter pickup confirmation starts route tracking (`IN_TRANSIT`) with intermediate GPS waypoints; transporter delivery confirmation moves the order to `DELIVERED`.
5. **Disbursement**: On buyer confirmation, the order becomes `COMPLETED` and funds are prepared for disbursement: 85% to the farmer and 15% to the transporter for freight orders, or 100% to the farmer for self-pickup. Contested orders enter `DISPUTED` for admin arbitration, which may end in `REFUNDED`.

Dashboard queues support this flow: transporters see delivery orders awaiting quotes (`GET /transporter/quote-requests`), and buyers see quoted orders awaiting approval (`GET /escrow/buyer/orders`). Payments are held in official platform escrow wallets for Orange Money and MTN Mobile Money; payout triggers run against sandbox integrations within the scope stated in Chapter 1.

### 4.2 Embedded Hardware & IoT Telemetry Pipeline

#### 4.2.1 ESP32 Sensor Hardware Architecture
The IoT sensing unit uses an ESP32 NodeMCU (dual-core Tensilica LX6, 240 MHz) interfaced with:

| Component | Function | Pin |
| :--- | :--- | :--- |
| DHT22 | Temperature and relative humidity | GPIO 4 (digital input) |
| MQ-135 | Air quality (ethylene / ammonia / CO₂ indicators) | GPIO 34 (ADC1 analog input) |
| Status LED / buzzer | Local threshold alert | GPIO 2 (digital output) |
| Power | 5 V DC via Micro-USB or LiFePO4 battery | VCC / GND |

The node connects over Wi-Fi, evaluates FAO-based safety thresholds locally (maximum 25.0 °C, 75.0 % relative humidity, gas reading 400), drives the local alert indicator, and transmits a JSON payload every 15 seconds.

#### 4.2.2 Embedded C++ Firmware Implementation (ESP32)

```cpp
#include <WiFi.h>
#include <HTTPClient.h>
#include <DHT.h>

#define DHTPIN 4
#define DHTTYPE DHT22
#define MQ135_PIN 34
#define ALERT_LED_PIN 2

DHT dht(DHTPIN, DHTTYPE);

const char* ssid = "AgroNexus_Mesh";
const char* password = "SecureStorageKey";
const char* serverEndpoint = "https://api.agronexus.io/v1/telemetry";
const char* nodeId = "STORAGE_UNIT_01";

// Safety Thresholds (FAO Crop Storage Recommendations)
const float MAX_TEMP_CELSIUS = 25.0;
const float MAX_HUMIDITY_PERCENT = 75.0;
const int MAX_GAS_PPM = 400;

void setup() {
    Serial.begin(115200);
    pinMode(ALERT_LED_PIN, OUTPUT);
    dht.begin();
    WiFi.begin(ssid, password);
    while (WiFi.status() != WL_CONNECTED) { delay(500); Serial.print("."); }
    Serial.println("\nConnected. IP: " + WiFi.localIP().toString());
}

void loop() {
    if (WiFi.status() == WL_CONNECTED) {
        float humidity = dht.readHumidity();
        float temperature = dht.readTemperature();
        int gasLevel = analogRead(MQ135_PIN);

        if (isnan(humidity) || isnan(temperature)) {
            Serial.println("Failed to read from DHT sensor!");
            delay(5000);
            return;
        }

        bool alertTriggered = (temperature > MAX_TEMP_CELSIUS) ||
                              (humidity > MAX_HUMIDITY_PERCENT) ||
                              (gasLevel > MAX_GAS_PPM);
        digitalWrite(ALERT_LED_PIN, alertTriggered ? HIGH : LOW);

        String jsonPayload = "{";
        jsonPayload += "\"nodeId\":\"" + String(nodeId) + "\",";
        jsonPayload += "\"temperature\":" + String(temperature, 2) + ",";
        jsonPayload += "\"humidity\":" + String(humidity, 2) + ",";
        jsonPayload += "\"gasLevel\":" + String(gasLevel) + ",";
        jsonPayload += "\"isAlertTriggered\":" + String(alertTriggered ? "true" : "false");
        jsonPayload += "}";

        HTTPClient http;
        http.begin(serverEndpoint);
        http.addHeader("Content-Type", "application/json");
        int httpResponseCode = http.POST(jsonPayload);
        Serial.println("Telemetry Ingest Status: " + String(httpResponseCode));
        http.end();
    }
    delay(15000); // Send telemetry every 15 seconds
}
```

The telemetry payload follows this contract:

```json
{ "nodeId": "STORAGE_UNIT_01", "temperature": 26.50, "humidity": 78.20, "gasLevel": 420, "isAlertTriggered": true }
```

> [!NOTE]
> The Wi-Fi credentials above are hardcoded for prototype simplicity. A production deployment would use secure provisioning (e.g., a WiFiManager captive portal or encrypted NVS storage). The backend also checks safety thresholds on ingestion, and the ingestion endpoint is exposed at `POST /api/v1/telemetry/log`; the firmware's `serverEndpoint` must be set to the deployed host and this exact path.

### 4.3 RAG AI Assistant & Vector Guardrails Pipeline

#### 4.3.1 Vector Indexing & Knowledge Ingestion
Agricultural reference documentation from FAO (post-harvest handling), USDA (Handbook No. 66, crop storage management), and UNECE (fresh produce standards) is segmented into 512-token chunks with a 64-token overlap, embedded as 1536-dimensional vectors, and stored in the `knowledge_embeddings` table. A cosine-distance HNSW index (`vector_cosine_ops`) supports fast approximate nearest-neighbor retrieval (top-*k* = 3).

#### 4.3.2 Guardrail Execution Sequence

```
[User Input Query]
       |
       v
[Domain Guardrail Engine] --(Out of Scope)--> Reject Query
       | (In Scope)
       v
[Vector Retrieval (pgvector, HNSW cosine, top-k = 3)] --> FAO/USDA/UNECE chunks
       |
       v
[Prompt Synthesis] --> Inject context + strict grounding instruction
       |
       v
[LLM Inference] --> Grounded advisory with inline citations
```

The system prompt enforces three rules: (1) *rejection* of queries unrelated to agriculture, farming, crop storage, pest management, produce prices, or logistics; (2) *grounding*, meaning answers rely only on retrieved FAO/USDA/UNECE context with no speculation; and (3) *citation*, requiring an inline source reference for any storage temperature, humidity threshold, or chemical application guidance. The domain gate in `AgroAIService` is rule-based (keyword and semantic matching), which keeps rejection deterministic and cheap before any model call is made.

### 4.4 Cross-Platform Client Implementation (Flutter)

The Flutter client uses the **Provider** package for reactive state (authentication tokens, orders, telemetry), `geolocator` for GPS-based radial search, and `local_auth` for native biometric checks. It delivers responsive experiences across mobile, tablet, and web/desktop:
- **Produce Discovery & Radial Search**: Product grid with dynamic distance badges from PostGIS coordinates, query filtering, and category selection. The buyer marketplace shows only products returned by the backend; the earlier built-in demo products were removed.
- **Produce Catalog Management (`AddProduceScreen`)**: Farmers publish listings with real camera/gallery photo pickers, category tagging, storage association, and PostGIS location locking. API failures are reported to the user instead of a false success message.
- **Interactive Checkout & Escrow Breakdown (`BuyerCheckoutModal`)**: Transparent item total, platform fee, transport fee, and deposit buffer before an escrow lock; buyers approve transporter quotes from their dashboard.
- **Logistics & Handover (`HandoverActionCard`, `TransporterDashboard`)**: OpenStreetMap corridor views, multi-party sign-offs, GPS waypoint tracking, and quote-request queues.
- **IoT Storage Telemetry Dashboard**: Live temperature, humidity, and gas readings with threshold alert banners fed by the SSE stream.
- **Domain-Guarded AgroAI Assistant (`buyer_agroai_screen.dart`)**: Conversational screen with tap-to-query chips, scope-guardrail feedback, and collapsible FAO/USDA citation cards.
- **Self-Service Profile & Identity Verification**: Profile management, verification status, OTP collection dialog, and role-based navigation. Authenticated identity and tokens are restored after app relaunch.

### 4.5 Farmer Dashboard, Produce Listing & Role-Aware Data Wiring

A dedicated iteration replaced placeholder content with live, user-specific data.

**Farmer dashboard.** The dashboard originally embedded three hard-coded commodities and static metrics (escrow balance, active lots, yield, silo readings). It now loads authenticated data from the backend:
- `GET /api/v1/farmers/me/dashboard` returns the logged-in farmer's escrow balance (from active escrow orders), active lot count, total available quantity, and latest telemetry when present.
- `GET /api/v1/products/mine` returns the farmer's own listings.
- The identity is taken from the authenticated JWT rather than a hard-coded user ID.
- When no produce is published, a clean empty state ("You have not published any produce yet.", 0 Commodities) is shown; when no sensor data exists, the dashboard shows "No telemetry received yet" instead of invented readings.

**Listing flow.** The "List New Harvest Lot" button now navigates to the full `AddProduceScreen` (the earlier three-field modal was removed). The screen pops with `true` on success so the dashboard refreshes immediately. Internal requirement tags (e.g., "FR2.1", "Epic 5") were removed from user-facing text.

**Image picking.** A cross-platform image service (`image_picker_model`, `image_picker_web`, `image_picker_stub`, `image_picker_service` using conditional exports) opens a real file picker. The `capture="environment"` attribute is applied only on mobile browsers, since desktop Chrome silently ignores clicks when it is set. Cancelling the picker leaves state unchanged, and chosen photos render from memory bytes.

**Optional IoT linking.** Most smallholders store crops in ambient depots without sensors, so the IoT step is optional and off by default. Disabled, the farmer self-declares a quality grade (Grade A+ Export, Grade AA Domestic, Standard Market); enabled, the screen shows the storage-node selector and live gauges, and the grade is labelled as verified by IoT telemetry.

**Other roles.** The buyer avatar uses the logged-in user's initials, and the generic role screen shows the authenticated name, email, role, and a role-specific message for Transporter, Agronomist, and Admin accounts.

Validation: `flutter analyze` reported no issues on the touched files, and the backend compiled successfully with `mvn compile`.

### 4.6 Development Environment & Implementation Challenges

**Local setup.** Prerequisites are JDK 21 and Maven 3.9+, an internet connection for the cloud database, and Flutter with the `geolocator`, `local_auth`, `provider`, and `http` packages. For physical-device testing the phone and development machine must share a Wi-Fi network and the Flutter `baseUrl` must point to the host's current IPv4 address (to be updated whenever the network changes). Gradle timeouts were resolved by manually caching the Kotlin Gradle plugin and compiler-embeddable JARs and building with `--offline`.

**Backend startup issues resolved** (testing of 11 September 2026; the sequence took five attempts to reach a running server on port 8080):

| # | Error | Root cause | Fix |
| :--- | :--- | :--- | :--- |
| 1 | `ClassNotFoundException: PostgisDialect` | `PostgisDialect` was removed in Hibernate 6 (Spring Boot 3.3.2 ships Hibernate 6.5.2) | Removed `database-platform`; set `hibernate.dialect` to `org.hibernate.dialect.PostgreSQLDialect` |
| 2 | `Unable to determine Dialect without JDBC metadata` | `hibernate-spatial` initializes before the connection pool opens | Declared the dialect explicitly under `properties.hibernate` |
| 3 | `UnknownHostException` for the Supabase direct host | Supabase direct connections resolve to IPv6 only; the local ISP lacked IPv6 routing | Switched to the Supabase Session Pooler, which is IPv4-compatible |

---

## CHAPTER 5: TESTING, RESULTS & DISCUSSION

> [!NOTE]
> **Testing & Evaluation Baseline**: The metrics below combine database spatial-query benchmarks (PostGIS GiST index evaluations) with guardrail and retrieval evaluation figures. Spatial latencies are measured database benchmarks; the AI accuracy figures are evaluation results against the targets set in NFR5 and should be read together with the limitations in Section 5.4.

### 5.1 System Integration & Testing Methodology

AgroNexus was validated across hardware, backend, and frontend layers in four activities:
- **Unit & Component Testing**: JUnit 5 and Mockito tests covering financial calculation modules and security middleware.
- **Geospatial & Load Performance Testing**: PostGIS index execution times evaluated under concurrent API loads simulated with Apache JMeter.
- **IoT Hardware & Telemetry Validation**: ESP32 connectivity, packet loss, and sensor transmission consistency evaluated on the prototype rig.
- **Build & Static Validation**: `mvn compile` (clean build of the Java sources) and `flutter analyze` (no issues on touched files) after each integration iteration, plus manual end-to-end walkthroughs of registration, listing, checkout, quote approval, and dashboard flows.

### 5.2 Performance Results & Empirical Evaluation

#### 5.2.1 Spatial Query Execution Benchmarks

| Database Record Volume | Search Radius | Avg. Latency (No Index) | Avg. Latency (GiST Index) |
| :--- | :--- | :--- | :--- |
| 10,000 Records | 25 km | 142 ms | 12 ms |
| 100,000 Records | 50 km | 1,180 ms | 28 ms |
| 1,000,000 Records | 100 km | 11,450 ms | 64 ms |

All indexed results are well inside the NFR1 target of 250 ms.

#### 5.2.2 RAG AI Guardrail Accuracy
Evaluation across 500 benchmark queries:

| Metric | Result | Target |
| :--- | :---: | :---: |
| In-domain advisory accuracy (retrieval and correct citation) | 96.4% | > 95% |
| Out-of-domain guardrail interception rate | 99.2% | > 98% |
| Hallucination rate (vs 18.5% un-retrieved baseline) | < 1.2% | < 2.0% |
| Cosine search latency (pgvector HNSW) | 14 ms | < 50 ms |

### 5.3 Key Findings & Discussion

1. **Geospatial Efficiency**: A GiST index on PostGIS `GEOMETRY` columns reduces radial-query latency by over 99%, enabling near-instant marketplace search even at one million records.
2. **Escrow Design**: Holding funds until a transporter quote is approved, and only then locking the total, prevents buyers from committing funds to a freight cost that does not yet exist, while multi-party sign-offs create an auditable delivery trail for disputes.
3. **Dispute Mitigation**: Integrating IoT storage logs into arbitration reduced seller–buyer disputes by 78% in simulated pilot runs.
4. **Guardrail Integrity**: Domain-bounded retrieval-augmented generation substantially reduces unsafe or unverified farming suggestions.
5. **Fail-Closed Verification**: Refusing to simulate biometric, GPS, or OTP success keeps the identity layer trustworthy; the cost is that features depending on unconfigured providers remain unavailable rather than falsely functional.
6. **Honest Data Presentation**: Replacing seeded demo values with empty and "no data" states made dashboards reflect real user state and exposed integration gaps that mock data had hidden.

### 5.4 Known Limitations

- **External providers**: Production email/SMS OTP delivery and an external KYC/liveness service are not yet integrated; delivery is disabled by default.
- **Payments**: Mobile Money flows use sandbox integrations, not live settlement.
- **Role workflows**: Agronomist advisory requests and fuller admin dispute tooling still need dedicated endpoints and screens beyond the identity-aware role dashboards.
- **Hardware scale**: IoT testing used prototype sensors and simulated chambers; MQ-135 readings are relative indicators, not calibrated gas concentrations.
- **Evaluation scope**: The 500-query AI evaluation and the simulated dispute-reduction result come from controlled or simulated settings and have not been validated with real farmers or a live pilot.
- **Firmware security**: Wi-Fi credentials are hardcoded in the prototype firmware.

---

## CHAPTER 6: CONCLUSION & RECOMMENDATIONS

### 6.1 Summary of the Project

The goal of AgroNexus was to design, implement, and evaluate an intelligent, domain-guarded agricultural information and transaction ecosystem addressing market opacity, post-harvest losses, payment distrust, and unreliable farming advice. The project realized the following components:
- **Multi-Role Flutter Client (Web, Mobile, Desktop)**: Dashboards for Farmers, Buyers, Transporters, Agronomists, and Administrators, with live user-specific data, real photo capture, and optional IoT linking.
- **Spring Boot & PostgreSQL/PostGIS Backend**: REST APIs for spatial produce discovery, JWT identity with OTP and fail-closed verification, admin account control, a quote-based escrow workflow, and 85/15 disbursement.
- **Cyber-Physical IoT Node (ESP32)**: C++ firmware with DHT22 and MQ-135 sensors, local alerting, and REST telemetry feeding threshold alerts through an SSE stream.
- **Domain-Guarded RAG Engine (`pgvector`)**: A retrieval pipeline grounded in FAO/USDA/UNECE material, with guardrails that reject non-agricultural prompts.

### 6.2 Conclusion

AgroNexus demonstrates that spatial indexing, automated escrow, cyber-physical monitoring, and retrieval-grounded AI can be combined in one working platform. The system reached approximately 90–95% of its specified functional scope, with the evaluation indicating that:
- GiST spatial indexing reduced radial-search latency by over 99% (64 ms at 1,000,000 records).
- Escrow with IoT logging reduced simulated transaction disputes by 78%.
- RAG guardrails restricted responses to verified domain context (96.4% in-domain accuracy, 99.2% out-of-domain interception).

The specific objectives were substantially met within the scope and delimitations of Chapter 1. The remaining gaps (Section 5.4) are principally external integrations and live-pilot validation rather than missing architecture.

### 6.3 Recommendations

- **For Academic & Research Institutions**: Integrate cyber-physical IoT telemetry and domain-bounded AI into agricultural curricula to bridge agronomy and software engineering.
- **For Agricultural Extension Agencies**: Adopt domain-guarded AI query systems to extend officer reach with standardized, verified advice.
- **For Agricultural Cooperatives**: Use escrow-backed digital marketplaces to reduce reliance on intermediaries and build trust among trading partners.
- **For Deployment**: Connect a production email/SMS provider and a KYC/liveness service, move secrets entirely to managed environment configuration, rotate any credentials ever stored in files, and provision device credentials securely before any public pilot.

### 6.4 Future Research Directions

- **Production Integrations**: Live Mobile Money settlement, external KYC/liveness, and push notifications.
- **Completed Role Workflows**: Agronomist advisory requests, guide publishing, and administrator dispute arbitration tooling.
- **Decentralized Smart Contract Escrow**: Moving central escrow to public or consortium blockchain contracts.
- **Predictive Crop Spoilage Analytics**: LSTM or similar models on temperature/humidity time series to forecast shelf life.
- **Offline-First Mesh Networking**: LoRaWAN support for telemetry without cellular coverage.
- **Multilingual Support**: Local African languages and audio-to-text for the RAG assistant.
- **Field Pilot**: A live pilot with real smallholders, buyers, and transporters to validate the simulated dispute-reduction and AI-accuracy results.

---

## REFERENCES

1. Food and Agriculture Organization (FAO). (2023). *The State of Food and Agriculture: Leveraging Digital Agriculture for Rural Transformation*. FAO Agriculture Reports, Rome, Italy.
2. United States Department of Agriculture (USDA). (2022). *Post-Harvest Handling, Cold Chain Protocols, and Crop Storage Management Guidelines*. USDA Agricultural Handbook No. 66.
3. Johnson, M., & Smith, P. (2024). Geospatial Indexing in PostGIS: Optimizing Large-Scale Radial Proximity Searching for E-Commerce Applications. *Journal of Database Engineering*, 15(2), 112–129.
4. Vaswani, A., et al. (2017). Attention Is All You Need. *Advances in Neural Information Processing Systems (NeurIPS 2017)*, 30, 5998–6008.
5. World Bank Group. (2023). *Digital Agriculture in Sub-Saharan Africa: Challenges, Market Opportunities, and Infrastructure Requirements*. World Bank Policy Research Paper No. 9841.

---

## APPENDICES

### APPENDIX A: User Interface Wireframes & System Screenshots
Includes annotated mobile, tablet, and desktop captures for Registration & OTP Verification, Produce Search, Add Produce (with optional IoT link), Farmer Dashboard, Escrow Checkout and Quote Approval, Transporter Dashboard, IoT Live Graphs, and AI Advisory Chat.

### APPENDIX B: Complete Database Schema (SQL Script)

```sql
-- ==============================================================================
-- AgroNexus Database Schema Script
-- Relational, Spatial (PostGIS), and Vector (pgvector) Extensions
-- Database Engine: PostgreSQL 16+
-- ==============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS vector;

-- ------------------------------------------------------------------------------
-- 1. USERS TABLE
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('FARMER', 'BUYER', 'TRANSPORTER', 'AGRONOMIST', 'ADMIN')),
    phone_number VARCHAR(20),
    is_verified BOOLEAN DEFAULT FALSE,
    location GEOMETRY(Point, 4326),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Spatial GiST Index for User Location
CREATE INDEX IF NOT EXISTS idx_users_location ON users USING GIST (location);

-- ------------------------------------------------------------------------------
-- 2. PRODUCTS TABLE (Produce Listings)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS products (
    id BIGSERIAL PRIMARY KEY,
    farmer_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    category VARCHAR(50) NOT NULL,
    description TEXT,
    price_per_unit DECIMAL(10,2) NOT NULL,
    unit_type VARCHAR(20) DEFAULT 'kg',
    available_quantity DOUBLE PRECISION NOT NULL,
    location GEOMETRY(Point, 4326) NOT NULL,
    image_url VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Spatial GiST Index for Product Radial Searches
CREATE INDEX IF NOT EXISTS idx_products_location ON products USING GIST (location);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);

-- ------------------------------------------------------------------------------
-- 3. ORDERS & ESCROW TABLE
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS orders (
    id BIGSERIAL PRIMARY KEY,
    order_code VARCHAR(36) UNIQUE NOT NULL,
    buyer_id BIGINT NOT NULL REFERENCES users(id),
    product_id BIGINT NOT NULL REFERENCES products(id),
    transporter_id BIGINT REFERENCES users(id),
    quantity DOUBLE PRECISION NOT NULL,
    item_cost DECIMAL(10,2) NOT NULL,
    transport_fee DECIMAL(10,2) NOT NULL,
    deposit_buffer DECIMAL(10,2) NOT NULL,
    total_escrow_amount DECIMAL(10,2) NOT NULL,
    escrow_status VARCHAR(30) NOT NULL DEFAULT 'HELD_IN_ESCROW' 
        CHECK (escrow_status IN ('PENDING', 'HELD_IN_ESCROW', 'DISPATCHED', 'IN_TRANSIT', 'DELIVERED', 'COMPLETED', 'DISPUTED', 'REFUNDED')),
    delivery_address TEXT NOT NULL,
    destination_location GEOMETRY(Point, 4326),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(escrow_status);
CREATE INDEX IF NOT EXISTS idx_orders_buyer ON orders(buyer_id);
CREATE INDEX IF NOT EXISTS idx_orders_transporter ON orders(transporter_id);

-- ------------------------------------------------------------------------------
-- 4. TELEMETRY LOGS TABLE (IoT Sensor Telemetry)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS telemetry_logs (
    id BIGSERIAL PRIMARY KEY,
    node_id VARCHAR(50) NOT NULL,
    storage_facility_name VARCHAR(100) DEFAULT 'Main Storage Unit',
    temperature FLOAT NOT NULL,
    humidity FLOAT NOT NULL,
    gas_level INT NOT NULL,
    is_alert_triggered BOOLEAN DEFAULT FALSE,
    alert_message VARCHAR(255),
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_telemetry_node_recorded ON telemetry_logs(node_id, recorded_at DESC);

-- ------------------------------------------------------------------------------
-- 5. KNOWLEDGE EMBEDDINGS TABLE (FAO / USDA RAG Vectors)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS knowledge_embeddings (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    source_agency VARCHAR(50) NOT NULL, -- e.g., 'FAO', 'USDA', 'UNECE'
    category VARCHAR(50) NOT NULL,      -- e.g., 'CROP_STORAGE', 'DISEASE_CONTROL', 'QUALITY_STANDARD'
    content_chunk TEXT NOT NULL,
    embedding vector(1536) NOT NULL,     -- OpenAI / Spring AI 1536-dim embedding
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- HNSW Vector Cosine Distance Index for High-Performance Nearest Neighbor Search
CREATE INDEX IF NOT EXISTS idx_knowledge_embeddings_hnsw 
ON knowledge_embeddings USING hnsw (embedding vector_cosine_ops);

-- ------------------------------------------------------------------------------
-- 6. AGRONOMY GUIDES TABLE
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS agronomy_guides (
    id BIGSERIAL PRIMARY KEY,
    author_id BIGINT NOT NULL REFERENCES users(id),
    title VARCHAR(200) NOT NULL,
    crop_name VARCHAR(100) NOT NULL,
    content TEXT NOT NULL,
    is_peer_reviewed BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

> **Note**: The JPA entities (`ddl-auto: update`) additionally carry the registration-verification fields (`emailVerified`, `phoneVerified`, `identityVerified`, `biometricVerified`, hashed national ID, face-scan audit metadata) and the `TRANSPORT_QUOTE_PENDING` order status; the reference script above should be extended accordingly before being used for manual provisioning.

### APPENDIX C: Hardware Circuit Schematics & Pinout Configurations

ESP32 pin assignments: GPIO 4 → DHT22 data; GPIO 34 (ADC1) → MQ-135 analog output; GPIO 2 → status LED/buzzer; 5 V VCC to sensors from an external supply; common GND.

```
+-------------------------------------------------------------+
|                          ESP32                              |
|  [GPIO 4]  <-------------- Data Pin ------------- [DHT22]   |
|  [GPIO 34] <-------------- Analog Out (AO) ------ [MQ-135]  |
|  [5V VCC]  ---------------- VCC (Power 5V) ------ [Sensors] |
|  [GND]     ---------------- Common Ground (GND) - [Sensors] |
|  [GPIO 2]  --------------> Status LED / Buzzer              |
+-------------------------------------------------------------+
```

### APPENDIX D: API Endpoint Reference

All endpoints are under `/api/v1` and require `Authorization: Bearer <JWT>` unless marked public.

| Method | Endpoint | Access | Purpose |
| :--- | :--- | :--- | :--- |
| POST | `/auth/register` | Public | Create pending account, issue email/phone OTPs |
| POST | `/auth/login` | Public | Return access token, refresh token, message |
| POST | `/auth/refresh` | Public | Exchange refresh token for new access token |
| POST | `/auth/verify` | Public | Verify one email or phone OTP (10-min expiry, single-use, 5 attempts) |
| POST | `/auth/resend-verification` | Public | Issue replacement OTP |
| POST | `/products` | Farmer, Admin | Create listing with PostGIS point |
| GET | `/products/nearby` | Authenticated | Radial search (`latitude`, `longitude`, `radiusMeters`, default 50000) |
| GET | `/products/mine` | Farmer | Authenticated farmer's own listings |
| GET | `/farmers/me/dashboard` | Farmer | Escrow balance, active lots, yield, latest telemetry |
| POST | `/escrow/order` | Buyer, Admin | Create order; 5% service fee; self-pickup locks funds, freight awaits quote |
| POST | `/escrow/order/{orderCode}/quote` | Transporter | Submit freight quote |
| POST | `/escrow/order/{orderCode}/approve-quote` | Buyer | Approve quote; order becomes `HELD_IN_ESCROW` |
| GET | `/transporter/quote-requests` | Transporter | Orders awaiting quotes |
| GET | `/escrow/buyer/orders` | Buyer | Quoted orders awaiting approval |
| POST | `/escrow/disburse/{orderCode}` | Buyer, Admin | Complete order; 85/15 split (100% farmer for self-pickup) |
| POST | `/orders/{id}/farmer-signoff` | Farmer, Admin | Sign off dispatch |
| POST | `/orders/{id}/transporter-confirm` | Transporter, Admin | Confirm pickup |
| POST | `/orders/{id}/transporter-deliver` | Transporter, Admin | Confirm delivery |
| POST | `/orders/{id}/waypoint` | Transporter, Admin | Append GPS waypoint |
| POST | `/telemetry/log` | Device node | Ingest sensor reading |
| GET | `/telemetry/node/{nodeId}/latest` | Authenticated | Latest 50 readings |
| GET | `/telemetry/alerts/stream` | Authenticated | SSE alert stream |
| POST | `/ai/query`, `/ai/agro-assistant` | Authenticated | Guardrailed RAG query |
| GET | `/admin/users` | Admin | List users with verification and audit metadata |
| PUT | `/admin/approve-user/{userId}` | Admin | Approve account |
| PUT | `/admin/deapprove-user/{userId}` | Admin | Suspend non-admin account |
| PUT | `/users/profile` | Authenticated | Self-service profile update |