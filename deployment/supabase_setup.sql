-- ==============================================================================
-- AgroNexus Supabase Database Initialization & Cloud Seed Script
-- Compatible with Supabase Postgres + PostGIS + pgvector
-- ==============================================================================

-- 1. Enable PostGIS and pgvector extensions
CREATE EXTENSION IF NOT EXISTS postgis SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS vector SCHEMA extensions;

-- 2. USERS TABLE
CREATE TABLE IF NOT EXISTS public.users (
    id BIGSERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('FARMER', 'BUYER', 'TRANSPORTER', 'AGRONOMIST', 'ADMIN')),
    google_subject VARCHAR(255) UNIQUE,
    phone_number VARCHAR(20),
    is_verified BOOLEAN DEFAULT TRUE,
    location extensions.geometry(Point, 4326),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_location ON public.users USING GIST (location);

-- 3. PRODUCTS TABLE
CREATE TABLE IF NOT EXISTS public.products (
    id BIGSERIAL PRIMARY KEY,
    farmer_id BIGINT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    category VARCHAR(50) NOT NULL,
    description TEXT,
    price_per_unit DECIMAL(10,2) NOT NULL,
    unit_type VARCHAR(20) DEFAULT 'kg',
    available_quantity DOUBLE PRECISION NOT NULL,
    location extensions.geometry(Point, 4326) NOT NULL,
    image_url VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_products_location ON public.products USING GIST (location);
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category);

-- 4. ORDERS & ESCROW TABLE
CREATE TABLE IF NOT EXISTS public.orders (
    id BIGSERIAL PRIMARY KEY,
    order_code VARCHAR(36) UNIQUE NOT NULL,
    buyer_id BIGINT NOT NULL REFERENCES public.users(id),
    product_id BIGINT NOT NULL REFERENCES public.products(id),
    transporter_id BIGINT REFERENCES public.users(id),
    quantity DOUBLE PRECISION NOT NULL,
    item_cost DECIMAL(10,2) NOT NULL,
    transport_fee DECIMAL(10,2) NOT NULL,
    deposit_buffer DECIMAL(10,2) NOT NULL,
    total_escrow_amount DECIMAL(10,2) NOT NULL,
    escrow_status VARCHAR(30) NOT NULL DEFAULT 'HELD_IN_ESCROW' 
        CHECK (escrow_status IN ('PENDING', 'HELD_IN_ESCROW', 'DISPATCHED', 'IN_TRANSIT', 'DELIVERED', 'COMPLETED', 'DISPUTED', 'REFUNDED')),
    delivery_address TEXT NOT NULL,
    destination_location extensions.geometry(Point, 4326),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(escrow_status);

-- 5. TELEMETRY LOGS TABLE
CREATE TABLE IF NOT EXISTS public.telemetry_logs (
    id BIGSERIAL PRIMARY KEY,
    node_id VARCHAR(50) NOT NULL,
    storage_facility_name VARCHAR(100) DEFAULT 'Yaoundé Central Warehouse',
    temperature FLOAT NOT NULL,
    humidity FLOAT NOT NULL,
    gas_level INT NOT NULL,
    is_alert_triggered BOOLEAN DEFAULT FALSE,
    alert_message VARCHAR(255),
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_telemetry_node_recorded ON public.telemetry_logs(node_id, recorded_at DESC);

-- 6. KNOWLEDGE EMBEDDINGS TABLE (FAO/USDA RAG)
CREATE TABLE IF NOT EXISTS public.knowledge_embeddings (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    source_agency VARCHAR(50) NOT NULL,
    category VARCHAR(50) NOT NULL,
    content_chunk TEXT NOT NULL,
    embedding extensions.vector(1536) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_knowledge_embeddings_hnsw 
ON public.knowledge_embeddings USING hnsw (embedding extensions.vector_cosine_ops);

-- 7. DEMO SEED DATA
INSERT INTO public.users (full_name, email, password_hash, role, phone_number, is_verified, location)
VALUES 
('Eunice Tchouela', 'farmer.eunice@agronexus.io', '$2a$12$e5kUv9.eH3W7rN6bZ8gQee8u9G9Z7yW8x.A8u9G9Z7yW8x', 'FARMER', '+237690000001', true, extensions.ST_SetSRID(extensions.ST_MakePoint(11.5021, 3.8480), 4326)),
('Yaoundé Buyer Co.', 'buyer@agronexus.io', '$2a$12$e5kUv9.eH3W7rN6bZ8gQee8u9G9Z7yW8x.A8u9G9Z7yW8x', 'BUYER', '+237690000002', true, extensions.ST_SetSRID(extensions.ST_MakePoint(11.5200, 3.8700), 4326)),
('Express Freight Logistics', 'transporter@agronexus.io', '$2a$12$e5kUv9.eH3W7rN6bZ8gQee8u9G9Z7yW8x.A8u9G9Z7yW8x', 'TRANSPORTER', '+237690000003', true, extensions.ST_SetSRID(extensions.ST_MakePoint(11.5100, 3.8550), 4326)),
('Dr. Agronomist Jean', 'agronomist@agronexus.io', '$2a$12$e5kUv9.eH3W7rN6bZ8gQee8u9G9Z7yW8x.A8u9G9Z7yW8x', 'AGRONOMIST', '+237690000004', true, extensions.ST_SetSRID(extensions.ST_MakePoint(11.5050, 3.8600), 4326)),
('System Admin', 'admin@agronexus.io', '$2a$12$e5kUv9.eH3W7rN6bZ8gQee8u9G9Z7yW8x.A8u9G9Z7yW8x', 'ADMIN', '+237690000005', true, extensions.ST_SetSRID(extensions.ST_MakePoint(11.5021, 3.8480), 4326))
ON CONFLICT (email) DO NOTHING;

INSERT INTO public.products (farmer_id, title, category, description, price_per_unit, unit_type, available_quantity, location)
VALUES
(1, 'Fresh Organic Plantains', 'FRUITS_AND_TUBERS', 'Grade-A plantain bunches harvested fresh from West Region farms.', 450.00, 'kg', 1200.0, extensions.ST_SetSRID(extensions.ST_MakePoint(11.5021, 3.8480), 4326)),
(1, 'Cassava Roots (High Starch)', 'ROOTS_AND_TUBERS', 'Selected white cassava roots ideal for processing and flour.', 250.00, 'kg', 3000.0, extensions.ST_SetSRID(extensions.ST_MakePoint(11.4800, 3.8300), 4326)),
(1, 'Red Maize Grains', 'CEREALS', 'Sun-dried red corn grains stored in moisture-controlled bins.', 320.00, 'kg', 2500.0, extensions.ST_SetSRID(extensions.ST_MakePoint(11.5300, 3.8800), 4326))
ON CONFLICT DO NOTHING;

INSERT INTO public.telemetry_logs (node_id, storage_facility_name, temperature, humidity, gas_level, is_alert_triggered, alert_message)
VALUES
('STORAGE_UNIT_01', 'Yaoundé Cold Storage A', 22.4, 68.5, 210, false, 'Optimal storage conditions maintained'),
('STORAGE_UNIT_01', 'Yaoundé Cold Storage A', 26.8, 79.1, 450, true, 'ALERT: Temperature and Ethylene gas threshold exceeded!')
ON CONFLICT DO NOTHING;
