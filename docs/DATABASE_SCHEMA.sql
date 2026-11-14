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
    google_subject VARCHAR(255) UNIQUE,
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
-- 5. KNOWLEDGE EMBEDDINGS TABLE (Multi-source RAG Vectors)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS knowledge_embeddings (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    source_agency VARCHAR(100) NOT NULL, -- e.g., 'FAO', 'USDA', 'UNECE', or a reviewed agronomist
    category VARCHAR(50) NOT NULL,      -- e.g., 'CROP_STORAGE', 'DISEASE_CONTROL', 'QUALITY_STANDARD'
    content_chunk TEXT NOT NULL,
    embedding vector(768) NOT NULL,     -- intfloat/multilingual-e5-base
    embedding_model VARCHAR(100) NOT NULL DEFAULT 'intfloat/multilingual-e5-base',
    source_type VARCHAR(30) NOT NULL DEFAULT 'AGRONOMIST_GUIDE',
    source_url TEXT,
    language VARCHAR(10) NOT NULL DEFAULT 'en',
    country VARCHAR(100),
    region VARCHAR(100),
    crop_name VARCHAR(100),
    publication_date DATE,
    review_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    authority_level VARCHAR(30) NOT NULL DEFAULT 'EXPERT_REVIEWED',
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
