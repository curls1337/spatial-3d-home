-- ==============================================================================
-- Spatial 3D Home & Asset Inventory — On-Device Local Schema (SQLite / SQLCipher)
-- ==============================================================================
-- Engine      : SQLite 3.45+ with SQLCipher AES-256-CBC/GCM Encryption at Rest
-- Key Storage : iOS Keychain / Secure Enclave & Android Keystore (never plaintext)
-- Mode        : 100% Offline-First + Resilient Delta Sync Outbox
-- ==============================================================================

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS local_profiles (
    id                  TEXT PRIMARY KEY,
    role_code           TEXT NOT NULL CHECK (role_code IN ('OWNER', 'APPRAISER', 'TENANT')),
    email               TEXT NOT NULL UNIQUE,
    full_name           TEXT NOT NULL,
    pin_hash            TEXT,
    biometric_enabled   INTEGER NOT NULL DEFAULT 1,
    is_demo_account     INTEGER NOT NULL DEFAULT 0,
    active_access_token TEXT,                         -- Stored encrypted via SQLCipher
    last_login_at       TEXT,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    updated_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE TABLE IF NOT EXISTS local_sessions (
    id                  TEXT PRIMARY KEY,
    user_id             TEXT NOT NULL REFERENCES local_profiles(id) ON DELETE CASCADE,
    active_role_code    TEXT NOT NULL CHECK (active_role_code IN ('OWNER', 'APPRAISER', 'TENANT')),
    device_id           TEXT NOT NULL,
    is_locked           INTEGER NOT NULL DEFAULT 0,
    last_active_at      TEXT NOT NULL,
    expires_at          TEXT NOT NULL,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE TABLE IF NOT EXISTS properties (
    id                  TEXT PRIMARY KEY,
    owner_user_id       TEXT NOT NULL REFERENCES local_profiles(id) ON DELETE RESTRICT,
    name                TEXT NOT NULL,
    address_line        TEXT,
    city                TEXT,
    currency_code       TEXT NOT NULL DEFAULT 'IDR',
    insurance_policy_no TEXT,
    insurer_name        TEXT,
    version             INTEGER NOT NULL DEFAULT 1,
    sync_status         TEXT NOT NULL DEFAULT 'SYNCED' CHECK (sync_status IN ('SYNCED', 'PENDING', 'CONFLICT')),
    updated_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    archived_at         TEXT
);

CREATE TABLE IF NOT EXISTS rooms (
    id                  TEXT PRIMARY KEY,
    property_id         TEXT NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    name                TEXT NOT NULL,
    room_type           TEXT NOT NULL DEFAULT 'OTHER',
    floor_number        INTEGER NOT NULL DEFAULT 1,
    area_sqm            REAL NOT NULL DEFAULT 0.0 CHECK (area_sqm >= 0),
    length_m            REAL,
    width_m             REAL,
    height_m            REAL,
    current_scan_id     TEXT,
    scan_status         TEXT NOT NULL DEFAULT 'PENDING_SCAN' CHECK (scan_status IN ('PENDING_SCAN', 'SCAN_VERIFIED', 'NEEDS_RESCAN')),
    version             INTEGER NOT NULL DEFAULT 1,
    sync_status         TEXT NOT NULL DEFAULT 'SYNCED' CHECK (sync_status IN ('SYNCED', 'PENDING', 'CONFLICT')),
    updated_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    deleted_at          TEXT
);

CREATE INDEX IF NOT EXISTS idx_local_rooms_property ON rooms(property_id);

CREATE TABLE IF NOT EXISTS room_scans (
    id                  TEXT PRIMARY KEY,
    room_id             TEXT NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    property_id         TEXT NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    scanned_by          TEXT NOT NULL,
    scan_version        INTEGER NOT NULL DEFAULT 1,
    capture_source      TEXT NOT NULL CHECK (capture_source IN ('APPLE_ROOMPLAN_LIDAR', 'ARCORE_DEPTH', 'MANUAL_3D_BOX', 'SIMULATOR_PRESET')),
    mesh_format         TEXT NOT NULL CHECK (mesh_format IN ('USDZ', 'GLB', 'JSON_WIREFRAME')),
    local_encrypted_path TEXT NOT NULL,               -- AES-256-GCM encrypted file inside app sandbox
    mesh_sha256         TEXT NOT NULL,
    mesh_size_bytes     INTEGER NOT NULL CHECK (mesh_size_bytes >= 0 AND mesh_size_bytes <= 20971520),
    dimensions_json     TEXT NOT NULL DEFAULT '{}',
    is_active           INTEGER NOT NULL DEFAULT 1,
    scanned_at          TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS assets (
    id                      TEXT PRIMARY KEY,
    property_id             TEXT NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    room_id                 TEXT NOT NULL REFERENCES rooms(id) ON DELETE RESTRICT,
    created_by              TEXT NOT NULL,
    name                    TEXT NOT NULL,
    brand_model             TEXT,
    category                TEXT NOT NULL CHECK (category IN ('ELECTRONICS', 'FURNITURE', 'APPLIANCES', 'COLLECTIBLES', 'JEWELRY', 'TOOLS', 'OTHER')),
    serial_number           TEXT,
    pin_x                   REAL NOT NULL DEFAULT 0.0,
    pin_y                   REAL NOT NULL DEFAULT 0.0,
    pin_z                   REAL NOT NULL DEFAULT 0.0,
    needs_repinning         INTEGER NOT NULL DEFAULT 0,
    currency_code           TEXT NOT NULL DEFAULT 'IDR',
    purchase_price          REAL NOT NULL DEFAULT 0.0 CHECK (purchase_price >= 0),
    current_valuation       REAL NOT NULL DEFAULT 0.0 CHECK (current_valuation >= 0),
    appraised_value         REAL CHECK (appraised_value IS NULL OR appraised_value >= 0),
    depreciation_rate_yr    REAL NOT NULL DEFAULT 0.10,
    salvage_floor_ratio     REAL NOT NULL DEFAULT 0.20,
    purchase_date           TEXT,
    warranty_expiry_date    TEXT,
    condition_grade         TEXT NOT NULL DEFAULT 'GOOD' CHECK (condition_grade IN ('MINT', 'GOOD', 'FAIR', 'DAMAGED')),
    visibility_scope        TEXT NOT NULL DEFAULT 'ALL_AUTHORIZED' CHECK (visibility_scope IN ('ALL_AUTHORIZED', 'INSURANCE_ONLY', 'OWNER_PRIVATE')),
    verification_status     TEXT NOT NULL DEFAULT 'PENDING' CHECK (verification_status IN ('PENDING', 'VERIFIED', 'FLAGGED')),
    asset_status            TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (asset_status IN ('DRAFT', 'ACTIVE', 'UNDER_INSPECTION', 'VERIFIED', 'CLAIMED', 'ARCHIVED')),
    notes                   TEXT,
    version                 INTEGER NOT NULL DEFAULT 1,
    sync_status             TEXT NOT NULL DEFAULT 'SYNCED' CHECK (sync_status IN ('SYNCED', 'PENDING', 'CONFLICT')),
    updated_at              TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    archived_at             TEXT
);

CREATE INDEX IF NOT EXISTS idx_local_assets_room ON assets(room_id);
CREATE INDEX IF NOT EXISTS idx_local_assets_property ON assets(property_id);

CREATE TABLE IF NOT EXISTS asset_media (
    id                  TEXT PRIMARY KEY,
    asset_id            TEXT NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
    media_type          TEXT NOT NULL CHECK (media_type IN ('ASSET_PHOTO', 'RECEIPT_OCR', 'WARRANTY_CARD')),
    local_encrypted_path TEXT NOT NULL,
    sha256_hash         TEXT NOT NULL,
    size_bytes          INTEGER NOT NULL,
    pii_redacted        INTEGER NOT NULL DEFAULT 0,
    ocr_extracted_json  TEXT,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    deleted_at          TEXT
);

CREATE TABLE IF NOT EXISTS asset_appraisals (
    id                      TEXT PRIMARY KEY,
    asset_id                TEXT NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
    appraiser_user_id       TEXT NOT NULL,
    previous_valuation      REAL,
    appraised_value         REAL NOT NULL CHECK (appraised_value >= 0),
    verification_decision   TEXT NOT NULL CHECK (verification_decision IN ('VERIFIED', 'FLAGGED', 'PENDING')),
    inspection_note         TEXT NOT NULL,
    appraised_at            TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS condition_notes (
    id                  TEXT PRIMARY KEY,
    asset_id            TEXT NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
    author_user_id      TEXT NOT NULL,
    author_role_code    TEXT NOT NULL CHECK (author_role_code IN ('OWNER', 'APPRAISER', 'TENANT')),
    note_type           TEXT NOT NULL DEFAULT 'INSPECTION_REMARK',
    severity            TEXT NOT NULL DEFAULT 'INFO',
    body                TEXT NOT NULL,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE TABLE IF NOT EXISTS share_links_cache (
    id                  TEXT PRIMARY KEY,
    property_id         TEXT NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    target_role         TEXT NOT NULL CHECK (target_role IN ('APPRAISER', 'TENANT')),
    recipient_label     TEXT,
    share_url_preview   TEXT NOT NULL,
    expires_at          TEXT NOT NULL,
    revoked_at          TEXT,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE TABLE IF NOT EXISTS export_bundles (
    id                  TEXT PRIMARY KEY,
    property_id         TEXT NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    actor_role_code     TEXT NOT NULL,
    bundle_type         TEXT NOT NULL,
    export_format       TEXT NOT NULL CHECK (export_format IN ('PDF', 'JSON', 'CSV')),
    total_claimed_value REAL NOT NULL DEFAULT 0.0,
    document_sha256     TEXT NOT NULL,
    local_file_path     TEXT NOT NULL,
    generated_at        TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE TABLE IF NOT EXISTS sync_outbox (
    id                  TEXT PRIMARY KEY,
    idempotency_key     TEXT NOT NULL UNIQUE,
    entity_type         TEXT NOT NULL,
    entity_id           TEXT NOT NULL,
    operation           TEXT NOT NULL CHECK (operation IN ('UPSERT', 'DELETE', 'PATCH_APPRAISAL')),
    payload_json        TEXT NOT NULL,
    retry_count         INTEGER NOT NULL DEFAULT 0,
    next_retry_at       TEXT,
    last_error          TEXT,
    status              TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'IN_FLIGHT', 'FAILED', 'SYNCED')),
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_sync_outbox_pending ON sync_outbox(status, next_retry_at);

CREATE TABLE IF NOT EXISTS app_settings (
    key                 TEXT PRIMARY KEY,
    value_json          TEXT NOT NULL,
    updated_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);
