-- ==============================================================================
-- Spatial 3D Home & Asset Inventory — Relational Database Schema (PostgreSQL 16)
-- ==============================================================================
-- Engine      : PostgreSQL 16+
-- Encoding    : UTF-8
-- Architecture: Multi-tenant Property Isolation, RBAC, Offline-First Delta Sync,
--               Audit Trail, Share Link Scoped Access, & Encrypted Blob References
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ------------------------------------------------------------------------------
-- Utility Trigger: Auto-update `updated_at` timestamp
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ==============================================================================
-- 1. AUTHENTICATION, RBAC & SESSION MANAGEMENT
-- ==============================================================================

CREATE TABLE roles (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code            VARCHAR(32) NOT NULL UNIQUE,      -- OWNER | APPRAISER | TENANT
    display_name    VARCHAR(100) NOT NULL,
    description     TEXT,
    is_system       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_roles_code CHECK (code IN ('OWNER', 'APPRAISER', 'TENANT'))
);

CREATE TABLE permissions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code            VARCHAR(80) NOT NULL UNIQUE,      -- e.g. 'asset:create', 'server_config:update'
    module          VARCHAR(40) NOT NULL,             -- scan_3d | asset | valuation | share_link | server_config | audit | auth
    description     TEXT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE role_permissions (
    role_id         UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id   UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    scope_rule      VARCHAR(64) NOT NULL DEFAULT 'FULL', -- FULL | ASSIGNED_ONLY | VISIBILITY_FILTERED | APPRAISAL_FIELDS_ONLY
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE users (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_id             UUID NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
    email               VARCHAR(255) NOT NULL UNIQUE,
    full_name           VARCHAR(150) NOT NULL,
    phone_number        VARCHAR(32),
    password_hash       TEXT NOT NULL,                -- Argon2id hash (never plaintext)
    pin_hash            TEXT,                         -- Optional Argon2id 6-digit PIN hash
    biometric_enabled   BOOLEAN NOT NULL DEFAULT FALSE,
    is_demo_account     BOOLEAN NOT NULL DEFAULT FALSE,
    status              VARCHAR(24) NOT NULL DEFAULT 'ACTIVE',
    last_login_at       TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_users_status CHECK (status IN ('ACTIVE', 'LOCKED', 'DISABLED'))
);

CREATE INDEX idx_users_role_id ON users(role_id);
CREATE INDEX idx_users_status ON users(status);

CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE sessions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    active_role_code    VARCHAR(32) NOT NULL,         -- Effective role in session (for demo switcher isolation)
    refresh_token_hash  CHAR(64) NOT NULL UNIQUE,     -- SHA-256 hex of opaque refresh token
    device_id           VARCHAR(128) NOT NULL,
    device_platform     VARCHAR(24) NOT NULL,         -- ios | android | web_simulator
    ip_address          INET,
    user_agent          TEXT,
    is_demo_session     BOOLEAN NOT NULL DEFAULT FALSE,
    expires_at          TIMESTAMPTZ NOT NULL,
    revoked_at          TIMESTAMPTZ,
    revoke_reason       VARCHAR(120),
    last_seen_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_sessions_platform CHECK (device_platform IN ('ios', 'android', 'web_simulator')),
    CONSTRAINT chk_sessions_role CHECK (active_role_code IN ('OWNER', 'APPRAISER', 'TENANT'))
);

CREATE INDEX idx_sessions_user_id ON sessions(user_id);
CREATE INDEX idx_sessions_expires_at ON sessions(expires_at) WHERE revoked_at IS NULL;

-- ==============================================================================
-- 2. PROPERTIES & MEMBER ACCESS SCOPING
-- ==============================================================================

CREATE TABLE properties (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_user_id       UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    name                VARCHAR(160) NOT NULL,
    address_line        TEXT,
    city                VARCHAR(100),
    country_code        CHAR(2) NOT NULL DEFAULT 'ID',
    property_type       VARCHAR(40) NOT NULL DEFAULT 'RESIDENTIAL_HOUSE',
    currency_code       CHAR(3) NOT NULL DEFAULT 'IDR',
    insurance_policy_no VARCHAR(100),                 -- Sensitive: redacted for TENANT
    insurer_name        VARCHAR(120),                 -- Sensitive: redacted for TENANT
    encryption_key_id   VARCHAR(128),                 -- Reference to client E2EE key fingerprint
    version             INTEGER NOT NULL DEFAULT 1,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    archived_at         TIMESTAMPTZ,
    CONSTRAINT chk_properties_currency CHECK (currency_code IN ('IDR', 'USD', 'SGD', 'EUR'))
);

CREATE INDEX idx_properties_owner ON properties(owner_user_id);

CREATE TRIGGER trg_properties_updated_at
BEFORE UPDATE ON properties
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE property_members (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id     UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    assigned_role   VARCHAR(32) NOT NULL,             -- OWNER | APPRAISER | TENANT
    can_export_pdf  BOOLEAN NOT NULL DEFAULT FALSE,
    invited_by      UUID REFERENCES users(id) ON DELETE SET NULL,
    expires_at      TIMESTAMPTZ,
    revoked_at      TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_property_member UNIQUE (property_id, user_id),
    CONSTRAINT chk_pm_role CHECK (assigned_role IN ('OWNER', 'APPRAISER', 'TENANT'))
);

CREATE INDEX idx_property_members_user ON property_members(user_id);

-- ==============================================================================
-- 3. SPATIAL 3D ROOMS & LIDAR / AR SCANS
-- ==============================================================================

CREATE TABLE rooms (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id         UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    name                VARCHAR(120) NOT NULL,
    room_type           VARCHAR(48) NOT NULL DEFAULT 'OTHER', -- LIVING_ROOM | OFFICE | BEDROOM | KITCHEN | STORAGE | OTHER
    floor_number        SMALLINT NOT NULL DEFAULT 1,
    area_sqm            NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    length_m            NUMERIC(8, 2),
    width_m             NUMERIC(8, 2),
    height_m            NUMERIC(8, 2),
    current_scan_id     UUID,                         -- Set after room_scans insert (FK added below)
    scan_status         VARCHAR(32) NOT NULL DEFAULT 'PENDING_SCAN',
    version             INTEGER NOT NULL DEFAULT 1,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMPTZ,
    CONSTRAINT chk_rooms_area CHECK (area_sqm >= 0),
    CONSTRAINT chk_rooms_scan_status CHECK (scan_status IN ('PENDING_SCAN', 'SCAN_VERIFIED', 'NEEDS_RESCAN'))
);

CREATE INDEX idx_rooms_property_id ON rooms(property_id) WHERE deleted_at IS NULL;

CREATE TRIGGER trg_rooms_updated_at
BEFORE UPDATE ON rooms
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE room_scans (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id             UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    property_id         UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    scanned_by          UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    scan_version        INTEGER NOT NULL DEFAULT 1,
    capture_source      VARCHAR(32) NOT NULL,         -- APPLE_ROOMPLAN_LIDAR | ARCORE_DEPTH | MANUAL_3D_BOX | SIMULATOR_PRESET
    mesh_format         VARCHAR(16) NOT NULL DEFAULT 'GLB', -- USDZ | GLB | JSON_WIREFRAME
    mesh_blob_key       TEXT NOT NULL,                -- Encrypted storage key (AES-256-GCM ciphertext; never raw video)
    mesh_sha256         CHAR(64) NOT NULL,
    mesh_size_bytes     BIGINT NOT NULL CHECK (mesh_size_bytes >= 0 AND mesh_size_bytes <= 20971520), -- <= 20 MB (NFR)
    dimensions_json     JSONB NOT NULL DEFAULT '{}'::jsonb, -- walls, doors, windows, bounding box
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    scanned_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_scan_source CHECK (capture_source IN ('APPLE_ROOMPLAN_LIDAR', 'ARCORE_DEPTH', 'MANUAL_3D_BOX', 'SIMULATOR_PRESET')),
    CONSTRAINT chk_mesh_format CHECK (mesh_format IN ('USDZ', 'GLB', 'JSON_WIREFRAME'))
);

CREATE INDEX idx_room_scans_room_id ON room_scans(room_id);
CREATE UNIQUE INDEX uq_room_scans_version ON room_scans(room_id, scan_version);

ALTER TABLE rooms
    ADD CONSTRAINT fk_rooms_current_scan
    FOREIGN KEY (current_scan_id) REFERENCES room_scans(id) ON DELETE SET NULL;

-- ==============================================================================
-- 4. SPATIAL ASSETS, ENCRYPTED MEDIA, APPRAISALS & CONDITION NOTES
-- ==============================================================================

CREATE TABLE assets (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id             UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    room_id                 UUID NOT NULL REFERENCES rooms(id) ON DELETE RESTRICT,
    created_by              UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    name                    VARCHAR(160) NOT NULL,
    brand_model             VARCHAR(120),
    category                VARCHAR(48) NOT NULL,     -- ELECTRONICS | FURNITURE | APPLIANCES | COLLECTIBLES | JEWELRY | TOOLS | OTHER
    serial_number           VARCHAR(120),
    -- 3D Spatial Pin Coordinates (meters relative to room origin)
    pin_x                   NUMERIC(8, 3) NOT NULL DEFAULT 0.000,
    pin_y                   NUMERIC(8, 3) NOT NULL DEFAULT 0.000,
    pin_z                   NUMERIC(8, 3) NOT NULL DEFAULT 0.000,
    needs_repinning         BOOLEAN NOT NULL DEFAULT FALSE,
    -- Financial & Valuation (Owner-controlled purchase price vs Appraiser verified value)
    currency_code           CHAR(3) NOT NULL DEFAULT 'IDR',
    purchase_price          NUMERIC(16, 2) NOT NULL DEFAULT 0.00 CHECK (purchase_price >= 0),
    current_valuation       NUMERIC(16, 2) NOT NULL DEFAULT 0.00 CHECK (current_valuation >= 0),
    appraised_value         NUMERIC(16, 2) CHECK (appraised_value IS NULL OR appraised_value >= 0),
    depreciation_rate_yr    NUMERIC(5, 4) NOT NULL DEFAULT 0.1000 CHECK (depreciation_rate_yr >= 0 AND depreciation_rate_yr <= 1),
    salvage_floor_ratio     NUMERIC(5, 4) NOT NULL DEFAULT 0.2000 CHECK (salvage_floor_ratio >= 0 AND salvage_floor_ratio <= 1),
    purchase_date           DATE,
    warranty_expiry_date    DATE,
    -- Condition, Visibility & Lifecycle Status
    condition_grade         VARCHAR(24) NOT NULL DEFAULT 'GOOD',       -- MINT | GOOD | FAIR | DAMAGED
    visibility_scope        VARCHAR(24) NOT NULL DEFAULT 'ALL_AUTHORIZED', -- ALL_AUTHORIZED | INSURANCE_ONLY | OWNER_PRIVATE
    verification_status     VARCHAR(24) NOT NULL DEFAULT 'PENDING',    -- PENDING | VERIFIED | FLAGGED
    asset_status            VARCHAR(24) NOT NULL DEFAULT 'ACTIVE',     -- DRAFT | ACTIVE | UNDER_INSPECTION | VERIFIED | CLAIMED | ARCHIVED
    notes                   TEXT,
    -- Optimistic concurrency & Field-Level Merge timestamps
    version                 INTEGER NOT NULL DEFAULT 1,
    owner_modified_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    appraiser_modified_at   TIMESTAMPTZ,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    archived_at             TIMESTAMPTZ,
    CONSTRAINT chk_assets_category CHECK (category IN ('ELECTRONICS', 'FURNITURE', 'APPLIANCES', 'COLLECTIBLES', 'JEWELRY', 'TOOLS', 'OTHER')),
    CONSTRAINT chk_assets_condition CHECK (condition_grade IN ('MINT', 'GOOD', 'FAIR', 'DAMAGED')),
    CONSTRAINT chk_assets_visibility CHECK (visibility_scope IN ('ALL_AUTHORIZED', 'INSURANCE_ONLY', 'OWNER_PRIVATE')),
    CONSTRAINT chk_assets_verification CHECK (verification_status IN ('PENDING', 'VERIFIED', 'FLAGGED')),
    CONSTRAINT chk_assets_status CHECK (asset_status IN ('DRAFT', 'ACTIVE', 'UNDER_INSPECTION', 'VERIFIED', 'CLAIMED', 'ARCHIVED')),
    CONSTRAINT chk_assets_warranty_dates CHECK (warranty_expiry_date IS NULL OR purchase_date IS NULL OR warranty_expiry_date >= purchase_date)
);

CREATE INDEX idx_assets_property_id ON assets(property_id) WHERE archived_at IS NULL;
CREATE INDEX idx_assets_room_id ON assets(room_id) WHERE archived_at IS NULL;
CREATE INDEX idx_assets_visibility ON assets(property_id, visibility_scope) WHERE archived_at IS NULL;
CREATE INDEX idx_assets_verification ON assets(property_id, verification_status) WHERE archived_at IS NULL;
CREATE INDEX idx_assets_warranty ON assets(warranty_expiry_date) WHERE warranty_expiry_date IS NOT NULL AND archived_at IS NULL;

CREATE TRIGGER trg_assets_updated_at
BEFORE UPDATE ON assets
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE asset_media (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id            UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
    property_id         UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    uploaded_by         UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    media_type          VARCHAR(24) NOT NULL,         -- ASSET_PHOTO | RECEIPT_OCR | WARRANTY_CARD
    mime_type           VARCHAR(64) NOT NULL,
    blob_key            TEXT NOT NULL,                -- Encrypted object storage reference (never raw camera stream)
    sha256_hash         CHAR(64) NOT NULL,
    size_bytes          INTEGER NOT NULL CHECK (size_bytes > 0 AND size_bytes <= 10485760),
    pii_redacted        BOOLEAN NOT NULL DEFAULT FALSE, -- True if on-device face/doc auto-blur was applied
    ocr_extracted_json  JSONB,                        -- On-device OCR metadata (merchant, date, serial)
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMPTZ,
    CONSTRAINT chk_asset_media_type CHECK (media_type IN ('ASSET_PHOTO', 'RECEIPT_OCR', 'WARRANTY_CARD'))
);

CREATE INDEX idx_asset_media_asset_id ON asset_media(asset_id) WHERE deleted_at IS NULL;

CREATE TABLE asset_appraisals (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id                UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
    property_id             UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    appraiser_user_id       UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    previous_valuation      NUMERIC(16, 2),
    appraised_value         NUMERIC(16, 2) NOT NULL CHECK (appraised_value >= 0),
    verification_decision   VARCHAR(24) NOT NULL,     -- VERIFIED | FLAGGED | PENDING
    inspection_note         TEXT NOT NULL,
    appraised_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_appraisal_decision CHECK (verification_decision IN ('VERIFIED', 'FLAGGED', 'PENDING'))
);

CREATE INDEX idx_asset_appraisals_asset ON asset_appraisals(asset_id, appraised_at DESC);

CREATE TABLE condition_notes (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id            UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
    property_id         UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    author_user_id      UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    author_role_code    VARCHAR(32) NOT NULL,
    note_type           VARCHAR(32) NOT NULL DEFAULT 'INSPECTION_REMARK', -- CHECK_IN | CHECK_OUT | DAMAGE_REPORT | INSPECTION_REMARK
    severity            VARCHAR(16) NOT NULL DEFAULT 'INFO', -- INFO | MINOR | MAJOR | CRITICAL
    body                TEXT NOT NULL,
    resolved_at         TIMESTAMPTZ,
    resolved_by         UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_cn_role CHECK (author_role_code IN ('OWNER', 'APPRAISER', 'TENANT')),
    CONSTRAINT chk_cn_type CHECK (note_type IN ('CHECK_IN', 'CHECK_OUT', 'DAMAGE_REPORT', 'INSPECTION_REMARK')),
    CONSTRAINT chk_cn_severity CHECK (severity IN ('INFO', 'MINOR', 'MAJOR', 'CRITICAL'))
);

CREATE INDEX idx_condition_notes_asset ON condition_notes(asset_id, created_at DESC);

-- ==============================================================================
-- 5. SHARE LINKS, EXPORT BUNDLES & SERVER CONFIG
-- ==============================================================================

CREATE TABLE share_links (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id         UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    created_by          UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    token_hash          CHAR(64) NOT NULL UNIQUE,     -- SHA-256 of share URL token
    target_role         VARCHAR(32) NOT NULL,         -- APPRAISER | TENANT
    recipient_label     VARCHAR(120),                 -- Watermark label (e.g. "PT Asuransi Mandiri - Adjuster")
    allowed_room_ids    UUID[] NOT NULL DEFAULT '{}', -- Empty array = all non-private rooms in property
    pin_hash            TEXT,                         -- Optional Argon2id 6-digit PIN
    can_export_pdf      BOOLEAN NOT NULL DEFAULT TRUE,
    expires_at          TIMESTAMPTZ NOT NULL,
    revoked_at          TIMESTAMPTZ,
    revoked_by          UUID REFERENCES users(id) ON DELETE SET NULL,
    access_count        INTEGER NOT NULL DEFAULT 0,
    last_accessed_at    TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_share_target_role CHECK (target_role IN ('APPRAISER', 'TENANT')),
    CONSTRAINT chk_share_ttl CHECK (expires_at > created_at)
);

CREATE INDEX idx_share_links_property ON share_links(property_id);
CREATE INDEX idx_share_links_active ON share_links(token_hash) WHERE revoked_at IS NULL;

CREATE TABLE export_bundles (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id         UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    generated_by        UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    actor_role_code     VARCHAR(32) NOT NULL,
    bundle_type         VARCHAR(32) NOT NULL,         -- INSURANCE_CLAIM | LEASE_HANDOVER | RENOVATION_DIMENSIONS
    export_format       VARCHAR(16) NOT NULL,         -- PDF | JSON | CSV
    included_asset_ids  UUID[] NOT NULL DEFAULT '{}',
    total_claimed_value NUMERIC(16, 2) NOT NULL DEFAULT 0.00,
    document_sha256     CHAR(64) NOT NULL,            -- Tamper-evidence integrity hash printed in PDF footer
    is_appraiser_signed BOOLEAN NOT NULL DEFAULT FALSE,
    storage_blob_key    TEXT,
    generated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_export_type CHECK (bundle_type IN ('INSURANCE_CLAIM', 'LEASE_HANDOVER', 'RENOVATION_DIMENSIONS')),
    CONSTRAINT chk_export_format CHECK (export_format IN ('PDF', 'JSON', 'CSV'))
);

CREATE INDEX idx_export_bundles_property ON export_bundles(property_id, generated_at DESC);

CREATE TABLE server_configs (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_user_id           UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    sync_enabled            BOOLEAN NOT NULL DEFAULT FALSE,
    wifi_only_sync          BOOLEAN NOT NULL DEFAULT TRUE,
    sync_endpoint_url       TEXT,
    auto_blur_pii           BOOLEAN NOT NULL DEFAULT TRUE,
    b2b_webhook_url         TEXT,
    b2b_webhook_enabled     BOOLEAN NOT NULL DEFAULT FALSE,
    biometric_lock_enabled  BOOLEAN NOT NULL DEFAULT TRUE,
    idle_lock_seconds       INTEGER NOT NULL DEFAULT 300 CHECK (idle_lock_seconds >= 30 AND idle_lock_seconds <= 3600),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_server_configs_updated_at
BEFORE UPDATE ON server_configs
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ==============================================================================
-- 6. OFFLINE-FIRST DELTA SYNC & SECURITY AUDIT TRAIL
-- ==============================================================================

CREATE TABLE sync_changelog (
    seq_id              BIGSERIAL PRIMARY KEY,
    property_id         UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    actor_user_id       UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    actor_role_code     VARCHAR(32) NOT NULL,
    device_id           VARCHAR(128) NOT NULL,
    idempotency_key     VARCHAR(128) NOT NULL UNIQUE,
    entity_type         VARCHAR(32) NOT NULL,         -- PROPERTY | ROOM | ROOM_SCAN | ASSET | APPRAISAL | CONDITION_NOTE | SHARE_LINK
    entity_id           UUID NOT NULL,
    operation           VARCHAR(16) NOT NULL,         -- UPSERT | DELETE | PATCH_APPRAISAL
    payload_json        JSONB NOT NULL,
    client_timestamp    TIMESTAMPTZ NOT NULL,
    server_received_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_sync_entity CHECK (entity_type IN ('PROPERTY', 'ROOM', 'ROOM_SCAN', 'ASSET', 'APPRAISAL', 'CONDITION_NOTE', 'SHARE_LINK')),
    CONSTRAINT chk_sync_op CHECK (operation IN ('UPSERT', 'DELETE', 'PATCH_APPRAISAL'))
);

CREATE INDEX idx_sync_changelog_cursor ON sync_changelog(property_id, seq_id);

CREATE TABLE sync_conflicts (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id         UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    entity_type         VARCHAR(32) NOT NULL,
    entity_id           UUID NOT NULL,
    resolution_strategy VARCHAR(32) NOT NULL DEFAULT 'FIELD_LEVEL_MERGE',
    owner_payload       JSONB,
    appraiser_payload   JSONB,
    merged_payload      JSONB NOT NULL,
    resolved_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE audit_logs (
    id                  BIGSERIAL PRIMARY KEY,
    property_id         UUID REFERENCES properties(id) ON DELETE SET NULL,
    actor_user_id       UUID REFERENCES users(id) ON DELETE SET NULL,
    actor_role_code     VARCHAR(32),
    action              VARCHAR(64) NOT NULL,         -- e.g. 'AUTH_LOGIN', 'RBAC_DENIED', 'ASSET_DELETED', 'PDF_EXPORTED'
    target_type         VARCHAR(32),
    target_id           UUID,
    outcome             VARCHAR(16) NOT NULL,         -- SUCCESS | DENIED | ERROR
    metadata_json       JSONB NOT NULL DEFAULT '{}'::jsonb,
    ip_address          INET,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_audit_outcome CHECK (outcome IN ('SUCCESS', 'DENIED', 'ERROR'))
);

CREATE INDEX idx_audit_logs_property ON audit_logs(property_id, created_at DESC);
CREATE INDEX idx_audit_logs_actor ON audit_logs(actor_user_id, created_at DESC);

-- ==============================================================================
-- 7. CANONICAL DOMAIN VIEWS (rooms_3d & valuations)
-- ==============================================================================

CREATE OR REPLACE VIEW rooms_3d AS
SELECT
    r.id,
    r.property_id,
    r.name,
    r.room_type,
    r.floor_number,
    r.area_sqm,
    r.length_m,
    r.width_m,
    r.height_m,
    r.scan_status,
    r.current_scan_id,
    rs.scan_version,
    rs.capture_source,
    rs.mesh_format,
    rs.mesh_blob_key,
    rs.mesh_sha256,
    rs.mesh_size_bytes,
    rs.dimensions_json,
    rs.scanned_at,
    r.version,
    r.created_at,
    r.updated_at,
    r.deleted_at
FROM rooms r
LEFT JOIN room_scans rs ON rs.id = r.current_scan_id
WHERE r.deleted_at IS NULL;

CREATE OR REPLACE VIEW valuations AS
SELECT
    a.id AS asset_id,
    a.property_id,
    a.room_id,
    a.name AS asset_name,
    a.category,
    a.currency_code,
    a.purchase_price,
    a.current_valuation,
    a.appraised_value,
    COALESCE(a.appraised_value, a.current_valuation) AS effective_valuation,
    a.depreciation_rate_yr,
    a.salvage_floor_ratio,
    a.verification_status,
    aa.id AS latest_appraisal_id,
    aa.appraiser_user_id,
    aa.verification_decision,
    aa.inspection_note,
    aa.appraised_at
FROM assets a
LEFT JOIN LATERAL (
    SELECT ap.*
    FROM asset_appraisals ap
    WHERE ap.asset_id = a.id
    ORDER BY ap.appraised_at DESC
    LIMIT 1
) aa ON TRUE
WHERE a.archived_at IS NULL;
