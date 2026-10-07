# REST API Specification — AgroNexus

This document defines the RESTful backend endpoints, authentication headers, request/response DTO schemas, HTTP status codes, and implementation status for the **AgroNexus** backend microservices.

---

## 1. Authentication & Security Headers

All endpoints (except public `/api/v1/auth/*`) require a Bearer JSON Web Token (JWT) in the Authorization header:

```http
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

---

## 2. Implemented API Endpoints Reference

### 🔐 2.1 Authentication (`AuthController.java`)

#### `POST /api/v1/auth/register`
- **Access**: Public
- **Description**: Validates and creates a pending user account, stores only a hash of the national ID, records biometric evidence status, and issues email and phone verification challenges.
- **Success Response**: Returns a `message` explaining that email and phone verification must be completed before sign-in; roles requiring approval also mention administrative vetting.
- **Request Body**:
```json
{
  "fullName": "Eunice Tchouela",
  "email": "user@example.com",
  "password": "StrongPassword123",
  "phoneNumber": "+237600000000",
  "nationalId": "CNI-123456",
  "biometricVerified": true,
  "role": "FARMER",
  "latitude": 3.848,
  "longitude": 11.5021
}
```

#### `POST /api/v1/auth/login`
- **Access**: Public
- **Description**: Authenticates user credentials and returns JWT access token, refresh token, and a user-facing success `message`.

#### `POST /api/v1/auth/refresh`
- **Access**: Public
- **Description**: Exchanges a valid refresh token for a new JWT access token.

#### `POST /api/v1/auth/verify`
- **Access**: Public
- **Description**: Verifies one email or phone OTP. Codes expire after ten minutes, are single-use, and are limited to five attempts.
- **Request Body**:
```json
{
  "email": "user@example.com",
  "channel": "EMAIL",
  "code": "123456"
}
```

#### `POST /api/v1/auth/resend-verification`
- **Access**: Public
- **Description**: Issues a replacement email or phone verification challenge. Production delivery requires a configured email/SMS provider.
- **Request Body**:
```json
{
  "email": "user@example.com",
  "channel": "PHONE"
}
```

---

### 🌽 2.2 Produce Catalog & Spatial Search (`ProductController.java`)

#### `POST /api/v1/products`
- **Access**: `FARMER`, `ADMIN`
- **Description**: Creates a new produce listing with PostGIS location coordinates (`Point`, SRID 4326).
- **Request Body**:
```json
{
  "farmerId": 1,
  "title": "Fresh Yellow Maize",
  "category": "Grains",
  "description": "High yield yellow corn harvested in Mbalmayo",
  "pricePerUnit": 450.00,
  "unitType": "kg",
  "availableQuantity": 500.0,
  "latitude": 3.5167,
  "longitude": 11.5000,
  "imageUrl": "https://example.com/maize.jpg"
}
```

#### `GET /api/v1/products/nearby`
- **Access**: Authenticated users (`BUYER`, `FARMER`, etc.)
- **Query Parameters**:
  - `latitude` (double, required): Buyer GPS latitude.
  - `longitude` (double, required): Buyer GPS longitude.
  - `radiusMeters` (double, default 50000): Radial search distance in meters.
- **Description**: PostGIS `ST_DWithin` spatial query returning produce listings within specified radius.

*Planned / Pending Endpoint*: `GET /api/v1/products/my-listings` (Farmers query their own products).

---

### 💳 2.3 Sales & Escrow Financial Engine (`EscrowController.java`)

#### `POST /api/v1/escrow/order`
- **Access**: `BUYER`, `ADMIN`
- **Description**: Creates an order, calculates a transparent platform service fee equal to 5% of the item cost, and generates an order notification. Self-pickup locks immediately; freight delivery waits for transporter quote approval.
- **Official Escrow Wallets**:
  - **Orange Money Escrow Wallet**: `+237694002750`
  - **MTN Mobile Money Escrow Wallet**: `+237651305141`
- **Request Body**:
```json
{
  "buyerId": 2,
  "productId": 1,
  "quantity": 200.0,
  "transportFee": 5000.00,
  "isSelfPickup": false,
  "deliveryAddress": "Bastos, Yaoundé, Cameroon"
}
```

For freight delivery, the order is created as `TRANSPORT_QUOTE_PENDING` and no funds
are locked yet. A transporter submits a quote through
`POST /api/v1/escrow/order/{orderCode}/quote`; the buyer then approves it through
`POST /api/v1/escrow/order/{orderCode}/approve-quote`. Only after approval does
the order transition to `HELD_IN_ESCROW` with its final escrow total.

Dashboard quote queues:

- `GET /api/v1/transporter/quote-requests` returns delivery orders waiting for a
  transporter quote.
- `GET /api/v1/escrow/buyer/orders` returns the authenticated buyer's quoted
  orders awaiting approval.

#### `POST /api/v1/escrow/disburse/{orderCode}`
- **Access**: `BUYER`, `ADMIN`
- **Description**: Updates order escrow status to `COMPLETED` and prepares fund disbursement (85% Farmer / 15% Transporter or 100% Farmer for Self-Pickup).

---

### 🚚 2.4 Transport & Handover Delivery (`OrderController.java`)

#### `POST /api/v1/orders/{id}/farmer-signoff`
- **Access**: `FARMER`, `ADMIN`
- **Description**: Signs off farmer dispatch, updating order delivery status and triggering intermediate transport assignment.

#### `POST /api/v1/orders/{id}/transporter-confirm`
- **Access**: `TRANSPORTER`, `ADMIN`
- **Description**: Confirms transporter freight pickup and begins route tracking.

#### `POST /api/v1/orders/{id}/transporter-deliver`
- **Access**: `TRANSPORTER`, `ADMIN`
- **Description**: Confirms physical delivery at buyer destination and flags order ready for escrow release.

#### `POST /api/v1/orders/{id}/waypoint`
- **Access**: `TRANSPORTER`, `ADMIN`
- **Description**: Appends live intermediate GPS waypoint coordinates for real-time delivery tracking.

---

### 🌡️ 2.5 IoT Telemetry Ingestion (`TelemetryController.java`)

#### `POST /api/v1/telemetry`
- **Access**: Authenticated device/client
- **Description**: Ingests sensor data (temperature, humidity, gas level), checks safety thresholds, and stores telemetry log.

#### `GET /api/v1/telemetry/node/{nodeId}`
- **Access**: Authenticated users
- **Description**: Retrieves latest 50 telemetry readings for a specific storage node.

#### `GET /api/v1/telemetry/alerts/stream`
- **Access**: `AGRONOMIST`
- **Description**: Server-Sent Events (SSE) stream delivering real-time storage environmental threshold breaches and decay risk warnings.

#### Agronomist telemetry and equipment requests
- `GET /api/v1/telemetry/nodes` — Agronomist role; returns each discovered node's latest telemetry record.
- `GET /api/v1/telemetry/actuator-commands` — Agronomist role; lists saved equipment requests, newest first.
- `POST /api/v1/telemetry/nodes/{nodeId}/commands` — Agronomist role; saves a pending request only. It does not contact or switch hardware.

```json
{
  "action": "AERATION_START"
}
```

Supported actions are `AERATION_START` and `UV_DECONTAMINATION`. A successful request returns `201 Created` with `status: "PENDING_DEVICE"` and a creation timestamp. Unknown nodes return `404`; unsupported actions return `400`.

---

### 🤖 2.6 Domain-Guarded AI Assistant (`AgroAIController.java`)

#### `POST /api/v1/ai/query`
- **Access**: Authenticated users
- **Description**: Applies the agricultural-domain keyword guard, then keyword-matches against published Agronomist guides. Matching guide text and source metadata are returned without LLM generation or vector search.
- **Request Body**:
```json
{
  "query": "How should maize be stored after harvest?"
}
```

---

### 🌾 2.7 Agronomist guides (`AgronomistController.java`)

All routes require an authenticated Agronomist role.

- `GET /api/v1/agronomist/metrics` — returns counts derived from telemetry records and distinct node IDs. No placeholder metrics are supplied.
- `GET /api/v1/agronomist/guides` — lists saved guides and their `DRAFT`/`PUBLISHED` status.
- `POST /api/v1/agronomist/guides` — creates a draft from `title`, `sourceAgency`, `category`, and `content`. The server always stores a new guide as `DRAFT`.
- `POST /api/v1/agronomist/guides/{guideId}/publish` — publishes an existing guide; returns `404` when the guide does not exist.

The AI query endpoint searches only published guides using keyword matching. It returns `groundingMode: "PUBLISHED_GUIDE_KEYWORD_MATCH"` and guide titles/agencies as citations when there is a match, or `status: "NO_SOURCE"` when there is not. Vector embeddings and generated answers are not implemented.

### 👤 2.8 Admin & Self-Service User Management (`AdminController.java`, `AuthController.java`)

#### `GET /api/v1/admin/users`
- **Access**: `ADMIN`
- **Description**: Lists all registered platform users with verification status, face scan audit metadata, and account roles.

#### `PUT /api/v1/admin/approve-user/{userId}`
- **Access**: `ADMIN`
- **Description**: Approves pending user accounts, unlocking full trading and dispatch capabilities.

#### `PUT /api/v1/admin/deapprove-user/{userId}`
- **Access**: `ADMIN`
- **Description**: Suspends/de-approves non-admin user accounts.

#### `PUT /api/v1/users/profile`
- **Access**: Authenticated users
- **Description**: Self-service endpoint updating contact details, profile photo, and secondary settings while preserving primary user identity and audit history.
