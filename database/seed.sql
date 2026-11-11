-- ==============================================================================
-- Spatial 3D Home & Asset Inventory — Seed Data (PostgreSQL 16)
-- ==============================================================================
-- Properti Seed : Villa Kemang Selatan #14B (Total Luas: 111.00 m2, 4 Ruangan, 8 Aset)
-- Selaras 1:1   : PRD_AC_SPEC.md (Bab 5.4) & UI_SPEC.md (Bab 3.2)
-- Total Beli    : Rp 433.000.000 | Valuasi Saat Ini: Rp 402.925.000 | Verified: 5/8 (62.5%)
-- Catatan       : Akun demo di bawah hanya aktif jika APP_ENV=demo dan
--                 ENABLE_DEMO_ROLE_SWITCHER=true. Jangan jalankan di produksi.
-- ==============================================================================

BEGIN;

-- 1. Roles
INSERT INTO roles (id, code, display_name, description, is_system) VALUES
    ('11111111-1111-4111-8111-111111111101', 'OWNER',     'Homeowner / Owner',              'Pemilik utama properti & pengelola penuh inventaris, scan 3D, valuasi, share link, dan server config.', TRUE),
    ('11111111-1111-4111-8111-111111111102', 'APPRAISER', 'Insurance Appraiser / Inspector', 'Penilai asuransi / surveyor properti B2B untuk audit kondisi, appraised value, dan ekspor klaim.', TRUE),
    ('11111111-1111-4111-8111-111111111103', 'TENANT',    'Tenant / Buyer (Viewer)',         'Penyewa / pembeli / anggota keluarga dengan akses read-only non-finansial & catatan kondisi.', TRUE)
ON CONFLICT (code) DO NOTHING;

-- 2. Permissions
INSERT INTO permissions (id, code, module, description) VALUES
    ('22222222-2222-4222-8222-222222222201', 'scan_3d:create',          'scan_3d',       'Memindai ruangan 3D baru (LiDAR/AR/Simulator)'),
    ('22222222-2222-4222-8222-222222222202', 'scan_3d:read',            'scan_3d',       'Melihat dan menavigasi model ruangan 3D'),
    ('22222222-2222-4222-8222-222222222203', 'scan_3d:update',          'scan_3d',       'Mengubah label, dimensi, dan denah ruangan'),
    ('22222222-2222-4222-8222-222222222204', 'scan_3d:delete',          'scan_3d',       'Menghapus hasil scan ruangan'),
    ('22222222-2222-4222-8222-222222222205', 'asset:create',            'asset',         'Menambahkan dan menambatkan aset pada koordinat 3D'),
    ('22222222-2222-4222-8222-222222222206', 'asset:read',              'asset',         'Melihat daftar dan detail aset sesuai visibility_scope'),
    ('22222222-2222-4222-8222-222222222207', 'asset:update_metadata',   'asset',         'Mengubah harga beli, kategori, serial, dan foto aset'),
    ('22222222-2222-4222-8222-222222222208', 'asset:appraise',          'asset',         'Memverifikasi status aset dan mengisi appraised_value'),
    ('22222222-2222-4222-8222-222222222209', 'asset:condition_note',    'asset',         'Menambahkan catatan kondisi / check-in remark aset'),
    ('22222222-2222-4222-8222-222222222210', 'asset:delete',            'asset',         'Mengarsipkan / menghapus aset'),
    ('22222222-2222-4222-8222-222222222211', 'valuation:read',          'valuation',     'Melihat ringkasan nilai finansial & depresiasi aset'),
    ('22222222-2222-4222-8222-222222222212', 'export:insurance_claim',  'valuation',     'Mengekspor bundel PDF/JSON/CSV klaim asuransi'),
    ('22222222-2222-4222-8222-222222222213', 'export:lease_handover',   'valuation',     'Mengekspor berita acara serah-terima sewa unit'),
    ('22222222-2222-4222-8222-222222222214', 'share_link:manage',       'share_link',    'Membuat, memperbarui, dan mencabut share link'),
    ('22222222-2222-4222-8222-222222222215', 'server_config:manage',    'server_config', 'Mengelola endpoint sync, enkripsi, dan B2B webhook'),
    ('22222222-2222-4222-8222-222222222216', 'audit:read',              'audit',         'Melihat audit trail aktivitas properti')
ON CONFLICT (code) DO NOTHING;

-- 3. Role-Permissions Mapping
INSERT INTO role_permissions (role_id, permission_id, scope_rule)
SELECT '11111111-1111-4111-8111-111111111101', id, 'FULL' FROM permissions
ON CONFLICT DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id, scope_rule) VALUES
    ('11111111-1111-4111-8111-111111111102', '22222222-2222-4222-8222-222222222201', 'ASSIGNED_ONLY'),
    ('11111111-1111-4111-8111-111111111102', '22222222-2222-4222-8222-222222222202', 'ASSIGNED_ONLY'),
    ('11111111-1111-4111-8111-111111111102', '22222222-2222-4222-8222-222222222206', 'ASSIGNED_ONLY'),
    ('11111111-1111-4111-8111-111111111102', '22222222-2222-4222-8222-222222222208', 'APPRAISAL_FIELDS_ONLY'),
    ('11111111-1111-4111-8111-111111111102', '22222222-2222-4222-8222-222222222209', 'ASSIGNED_ONLY'),
    ('11111111-1111-4111-8111-111111111102', '22222222-2222-4222-8222-222222222211', 'ASSIGNED_ONLY'),
    ('11111111-1111-4111-8111-111111111102', '22222222-2222-4222-8222-222222222212', 'ASSIGNED_ONLY'),
    ('11111111-1111-4111-8111-111111111102', '22222222-2222-4222-8222-222222222216', 'ASSIGNED_ONLY')
ON CONFLICT DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id, scope_rule) VALUES
    ('11111111-1111-4111-8111-111111111103', '22222222-2222-4222-8222-222222222202', 'VISIBILITY_FILTERED'),
    ('11111111-1111-4111-8111-111111111103', '22222222-2222-4222-8222-222222222206', 'VISIBILITY_FILTERED'),
    ('11111111-1111-4111-8111-111111111103', '22222222-2222-4222-8222-222222222209', 'VISIBILITY_FILTERED'),
    ('11111111-1111-4111-8111-111111111103', '22222222-2222-4222-8222-222222222213', 'VISIBILITY_FILTERED')
ON CONFLICT DO NOTHING;

-- 4. Demo Users (Password hashes are placeholder Argon2id digests — replace via seed script in dev)
INSERT INTO users (id, role_id, email, full_name, password_hash, biometric_enabled, is_demo_account, status) VALUES
    ('33333333-3333-4333-8333-333333333301', '11111111-1111-4111-8111-111111111101', 'owner@kemang.spatial.demo',     'Nadia Pratama (Owner)',         '$argon2id$v=19$m=65536,t=3,p=1$DEMO_SALT_PLACEHOLDER$DEMO_HASH_PLACEHOLDER', TRUE, TRUE, 'ACTIVE'),
    ('33333333-3333-4333-8333-333333333302', '11111111-1111-4111-8111-111111111102', 'appraiser@insure.spatial.demo', 'Budi Santoso (Appraiser)',      '$argon2id$v=19$m=65536,t=3,p=1$DEMO_SALT_PLACEHOLDER$DEMO_HASH_PLACEHOLDER', TRUE, TRUE, 'ACTIVE'),
    ('33333333-3333-4333-8333-333333333303', '11111111-1111-4111-8111-111111111103', 'tenant@kemang.spatial.demo',    'Raka Wijaya (Tenant)',          '$argon2id$v=19$m=65536,t=3,p=1$DEMO_SALT_PLACEHOLDER$DEMO_HASH_PLACEHOLDER', FALSE, TRUE, 'ACTIVE')
ON CONFLICT (email) DO NOTHING;

-- 5. Property: Villa Kemang Selatan #14B
INSERT INTO properties (id, owner_user_id, name, address_line, city, country_code, property_type, currency_code, insurance_policy_no, insurer_name) VALUES
    ('44444444-4444-4444-8444-444444444401', '33333333-3333-4333-8333-333333333301',
     'Villa Kemang Selatan #14B', 'Jl. Kemang Selatan VIII No. 14B, Jakarta Selatan', 'Jakarta Selatan', 'ID',
     'RESIDENTIAL_VILLA', 'IDR', 'POL-HOME-2026-88412', 'Asuransi Griya Proteksi Nusantara')
ON CONFLICT (id) DO NOTHING;

INSERT INTO property_members (property_id, user_id, assigned_role, can_export_pdf, invited_by) VALUES
    ('44444444-4444-4444-8444-444444444401', '33333333-3333-4333-8333-333333333301', 'OWNER',     TRUE,  '33333333-3333-4333-8333-333333333301'),
    ('44444444-4444-4444-8444-444444444401', '33333333-3333-4333-8333-333333333302', 'APPRAISER', TRUE,  '33333333-3333-4333-8333-333333333301'),
    ('44444444-4444-4444-8444-444444444401', '33333333-3333-4333-8333-333333333303', 'TENANT',    FALSE, '33333333-3333-4333-8333-333333333301')
ON CONFLICT (property_id, user_id) DO NOTHING;

-- 6. 4 LiDAR-Scanned Rooms (Total Area = 42.5 + 18.0 + 28.4 + 22.1 = 111.0 m2)
INSERT INTO rooms (id, property_id, name, room_type, floor_number, area_sqm, length_m, width_m, height_m, scan_status) VALUES
    ('55555555-5555-4555-8555-555555555501', '44444444-4444-4444-8444-444444444401', 'Living Room',          'LIVING_ROOM', 1, 42.50, 6.80, 6.25, 3.20, 'SCAN_VERIFIED'),
    ('55555555-5555-4555-8555-555555555502', '44444444-4444-4444-8444-444444444401', 'Home Office / Studio', 'OFFICE',      1, 18.00, 4.50, 4.00, 3.00, 'SCAN_VERIFIED'),
    ('55555555-5555-4555-8555-555555555503', '44444444-4444-4444-8444-444444444401', 'Master Bedroom',       'BEDROOM',     2, 28.40, 5.90, 4.80, 3.00, 'SCAN_VERIFIED'),
    ('55555555-5555-4555-8555-555555555504', '44444444-4444-4444-8444-444444444401', 'Modern Kitchen',       'KITCHEN',     1, 22.10, 5.20, 4.25, 3.00, 'NEEDS_RESCAN')
ON CONFLICT (id) DO NOTHING;

-- 7. Room Scans (1 active scan per room)
INSERT INTO room_scans (id, room_id, property_id, scanned_by, scan_version, capture_source, mesh_format, mesh_blob_key, mesh_sha256, mesh_size_bytes, dimensions_json) VALUES
    ('66666666-6666-4666-8666-666666666601', '55555555-5555-4555-8555-555555555501', '44444444-4444-4444-8444-444444444401', '33333333-3333-4333-8333-333333333301', 1, 'APPLE_ROOMPLAN_LIDAR', 'USDZ', 'vault://kemang14b/scans/living_room_v1.usdz.enc',   repeat('a', 64), 4820410, '{"walls":4,"windows":2,"doors":2}'::jsonb),
    ('66666666-6666-4666-8666-666666666602', '55555555-5555-4555-8555-555555555502', '44444444-4444-4444-8444-444444444401', '33333333-3333-4333-8333-333333333301', 1, 'APPLE_ROOMPLAN_LIDAR', 'USDZ', 'vault://kemang14b/scans/home_office_v1.usdz.enc',   repeat('b', 64), 2610880, '{"walls":4,"windows":1,"doors":1}'::jsonb),
    ('66666666-6666-4666-8666-666666666603', '55555555-5555-4555-8555-555555555503', '44444444-4444-4444-8444-444444444401', '33333333-3333-4333-8333-333333333301', 1, 'APPLE_ROOMPLAN_LIDAR', 'USDZ', 'vault://kemang14b/scans/master_bed_v1.usdz.enc',    repeat('c', 64), 3540120, '{"walls":4,"windows":2,"doors":2}'::jsonb),
    ('66666666-6666-4666-8666-666666666604', '55555555-5555-4555-8555-555555555504', '44444444-4444-4444-8444-444444444401', '33333333-3333-4333-8333-333333333301', 1, 'SIMULATOR_PRESET',     'GLB',  'vault://kemang14b/scans/kitchen_v1.glb.enc',        repeat('d', 64), 3120400, '{"walls":4,"windows":1,"doors":1}'::jsonb)
ON CONFLICT (id) DO NOTHING;

UPDATE rooms SET current_scan_id = '66666666-6666-4666-8666-666666666601' WHERE id = '55555555-5555-4555-8555-555555555501';
UPDATE rooms SET current_scan_id = '66666666-6666-4666-8666-666666666602' WHERE id = '55555555-5555-4555-8555-555555555502';
UPDATE rooms SET current_scan_id = '66666666-6666-4666-8666-666666666603' WHERE id = '55555555-5555-4555-8555-555555555503';
UPDATE rooms SET current_scan_id = '66666666-6666-4666-8666-666666666604' WHERE id = '55555555-5555-4555-8555-555555555504';

-- 8. 8 Realistic High-Value Spatial Assets (Total Purchase: Rp 433.000.000, Current Valuation: Rp 402.925.000)
INSERT INTO assets (
    id, property_id, room_id, created_by, name, brand_model, category, serial_number,
    pin_x, pin_y, pin_z, currency_code, purchase_price, current_valuation, appraised_value,
    depreciation_rate_yr, salvage_floor_ratio, purchase_date, warranty_expiry_date,
    condition_grade, visibility_scope, verification_status, asset_status, notes
) VALUES
    ('77777777-7777-4777-8777-777777777701', '44444444-4444-4444-8444-444444444401', '55555555-5555-4555-8555-555555555501', '33333333-3333-4333-8333-333333333301',
     'Sony Bravia 65" OLED TV', 'Sony XR-65A80L', 'ELECTRONICS', 'SN-SONY-65A80L-9021',
     1.200, 1.100, 0.300, 'IDR', 34000000.00, 27200000.00, 27200000.00,
     0.2000, 0.1000, '2025-11-15', '2027-11-15',
     'MINT', 'INSURANCE_ONLY', 'VERIFIED', 'VERIFIED', 'Terpasang pada dinding utama Living Room dengan bracket baja.'),

    ('77777777-7777-4777-8777-777777777702', '44444444-4444-4444-8444-444444444401', '55555555-5555-4555-8555-555555555501', '33333333-3333-4333-8333-333333333301',
     'Natuzzi Leather Sectional Sofa', 'Natuzzi Editions C018', 'FURNITURE', 'NAT-SOFA-2024-441',
     3.100, 0.500, 2.400, 'IDR', 48000000.00, 43200000.00, 43200000.00,
     0.1000, 0.2000, '2024-10-10', '2026-10-10',
     'GOOD', 'ALL_AUTHORIZED', 'VERIFIED', 'VERIFIED', 'Sofa L-shape kulit asli Italia, termasuk inventaris sewa.'),

    ('77777777-7777-4777-8777-777777777703', '44444444-4444-4444-8444-444444444401', '55555555-5555-4555-8555-555555555501', '33333333-3333-4333-8333-333333333301',
     'B&O Beosound Balance Speaker', 'Bang & Olufsen Natural Oak', 'ELECTRONICS', 'BO-BAL-77812',
     4.800, 0.900, 1.100, 'IDR', 42500000.00, 36125000.00, NULL,
     0.2000, 0.1000, '2025-11-29', '2026-11-29',
     'MINT', 'INSURANCE_ONLY', 'PENDING', 'ACTIVE', 'Diletakkan di credenza Living Room; garansi segera kedaluwarsa (18 hari).'),

    ('77777777-7777-4777-8777-777777777704', '44444444-4444-4444-8444-444444444401', '55555555-5555-4555-8555-555555555502', '33333333-3333-4333-8333-333333333301',
     'MacBook Pro 16" M3 Max', 'Apple MacBook Pro 64GB/2TB', 'ELECTRONICS', 'C02ZM993MD6R',
     2.000, 0.800, 1.500, 'IDR', 64000000.00, 51200000.00, 51200000.00,
     0.2000, 0.1000, '2025-11-10', '2027-11-10',
     'MINT', 'INSURANCE_ONLY', 'VERIFIED', 'VERIFIED', 'Workstation utama di Home Office; AppleCare+ aktif.'),

    ('77777777-7777-4777-8777-777777777705', '44444444-4444-4444-8444-444444444401', '55555555-5555-4555-8555-555555555502', '33333333-3333-4333-8333-333333333301',
     'Herman Miller Aeron Chair', 'Aeron Remastered Size B', 'FURNITURE', 'HM-AERON-2024-119',
     2.100, 0.500, 2.200, 'IDR', 26000000.00, 23400000.00, 23400000.00,
     0.1000, 0.2000, '2024-11-12', '2036-11-12',
     'MINT', 'ALL_AUTHORIZED', 'VERIFIED', 'VERIFIED', 'Garansi resmi 12 tahun Herman Miller.'),

    ('77777777-7777-4777-8777-777777777706', '44444444-4444-4444-8444-444444444401', '55555555-5555-4555-8555-555555555503', '33333333-3333-4333-8333-333333333301',
     'LG Dual Inverter Smart AC', 'LG T19EV4 2 PK', 'APPLIANCES', 'LG-AC-504218',
     2.800, 2.400, 0.200, 'IDR', 11500000.00, 9200000.00, NULL,
     0.1000, 0.2000, '2024-11-05', '2027-11-05',
     'FAIR', 'ALL_AUTHORIZED', 'FLAGGED', 'UNDER_INSPECTION', 'Catatan kebocoran kondensasi ringan pada pipa indoor unit.'),

    ('77777777-7777-4777-8777-777777777707', '44444444-4444-4444-8444-444444444401', '55555555-5555-4555-8555-555555555503', '33333333-3333-4333-8333-333333333301',
     'Rolex Submariner / Safe Vault Box', 'Rolex 126610LN + SentrySafe', 'JEWELRY', 'RLX-774019-VAULT',
     0.700, 0.400, 3.900, 'IDR', 185000000.00, 195000000.00, 195000000.00,
     0.0000, 1.0000, '2023-06-20', NULL,
     'MINT', 'OWNER_PRIVATE', 'VERIFIED', 'VERIFIED', 'Aset koleksi pribadi di brankas Master Bedroom; tersembunyi dari Tenant.'),

    ('77777777-7777-4777-8777-777777777708', '44444444-4444-4444-8444-444444444401', '55555555-5555-4555-8555-555555555504', '33333333-3333-4333-8333-333333333301',
     'Breville Barista Touch Espresso', 'Breville BES880BSS', 'APPLIANCES', 'BRV-880-33219',
     3.600, 0.900, 0.600, 'IDR', 22000000.00, 17600000.00, NULL,
     0.1000, 0.2000, '2025-11-23', '2026-11-23',
     'MINT', 'ALL_AUTHORIZED', 'PENDING', 'ACTIVE', 'Menunggu verifikasi ulang setelah Modern Kitchen di-rescan; garansi tersisa 12 hari.')
ON CONFLICT (id) DO NOTHING;

-- 9. Sample Appraisal & Tenant Condition Note
INSERT INTO asset_appraisals (id, asset_id, property_id, appraiser_user_id, previous_valuation, appraised_value, verification_decision, inspection_note) VALUES
    ('88888888-8888-4888-8888-888888888801', '77777777-7777-4777-8777-777777777701', '44444444-4444-4444-8444-444444444401', '33333333-3333-4333-8333-333333333302',
     27200000.00, 27200000.00, 'VERIFIED', 'Nomor seri cocok dengan faktur pembelian dan kondisi panel OLED prima.')
ON CONFLICT (id) DO NOTHING;

INSERT INTO condition_notes (id, asset_id, property_id, author_user_id, author_role_code, note_type, severity, body) VALUES
    ('99999999-9999-4999-8999-999999999901', '77777777-7777-4777-8777-777777777706', '44444444-4444-4444-8444-444444444401', '33333333-3333-4333-8333-333333333303',
     'TENANT', 'DAMAGE_REPORT', 'MINOR', 'Ada rembesan air kondensasi ringan pada sudut kanan indoor unit AC.')
ON CONFLICT (id) DO NOTHING;

-- 10. Default Owner Server Config (Offline-First by Default)
INSERT INTO server_configs (owner_user_id, sync_enabled, wifi_only_sync, auto_blur_pii, biometric_lock_enabled, idle_lock_seconds) VALUES
    ('33333333-3333-4333-8333-333333333301', FALSE, TRUE, TRUE, TRUE, 300)
ON CONFLICT (owner_user_id) DO NOTHING;

COMMIT;
