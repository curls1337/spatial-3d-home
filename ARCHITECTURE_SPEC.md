# Architecture Specification (`ARCHITECTURE_SPEC.md`)
## Proyek: Spatial 3D Home & Asset Inventory

- **Dokumen:** `ARCHITECTURE_SPEC.md`
- **Versi:** 1.0.0
- **Tanggal:** 2026-11-11
- **Status:** Final Baseline Arsitektur (Siap Implementasi `team-engineer` & Review `team-qa`)
- **Mode Proyek:** Mode 4 Mobile Cross-Platform (Flutter `.ipa` & `.apk` via GitHub Actions Cloud Build + Interactive Mobile Simulator `index.html` + Offline-First Encrypted Storage & Sync API)
- **Referensi Input:** `BRD_SPEC.md` (v1.0) & `PRD_AC_SPEC.md` (v1.0.0)

---

## 1. Ringkasan Proposal Arsitektur untuk Klien (Eksekutif & Bisnis)

Untuk memenuhi kebutuhan segmen **B2C (Pemilik Rumah)** dan **B2B (Penilai Asuransi & Penyewa/Agen Properti)** tanpa mengorbankan privasi hunian, **Spatial 3D Home & Asset Inventory** dirancang dengan prinsip **On-Device Privacy First, Offline-First, dan Cross-Platform Single Codebase**:

1. **Satu Basis Kode Flutter, Dua Aplikasi Native (`.ipa` & `.apk`) + Simulator Web:**
   - Menggunakan **Flutter (Dart)** sebagai mesin UI dan logika bisnis utama agar tampilan 5 layar komersial di iOS dan Android 100% identik, responsif (`>= 30–60 FPS`), dan efisien biaya pemeliharaan.
   - Untuk demo cepat kepada klien dan pemangku kepentingan di browser tanpa instalasi perangkat, disediakan **Interactive Mobile Simulator (`index.html`)** dengan viewport `390×844px`, *seed data* realistis (`Villa Kemang Selatan #14B`), dan tombol **Quick Role Switcher** (khusus mode demo).
2. **Privasi Mutlak di Perangkat (*Zero Raw-Video Upload*):**
   - Pemindaian LiDAR menggunakan **Apple RoomPlan / ARKit** di iPhone/iPad Pro dan fallback **Google ARCore / Manual 3D Box Builder** di Android/non-LiDAR diproses **100% di dalam ponsel**. Video mentah interior rumah tidak pernah dikirim ke server cloud.
3. **Brankas Data Lokal Terenkripsi (*Offline-First Vault*):**
   - Seluruh denah 3D, foto aset, struk OCR, dan kalkulasi valuasi tersimpan di database lokal terenkripsi **SQLCipher (AES-256)** dan file terenkripsi **AES-256-GCM** dengan kunci di **Apple Secure Enclave / Keychain** dan **Android Keystore**. Aplikasi tetap berfungsi 100% saat *Airplane Mode*.
4. **Zero-Local-SDK Cloud Build Pipeline:**
   - Kompilasi file instalasi **`AppRelease.ipa`** (iOS) dan **`AppRelease.apk`** (Android) dijalankan otomatis di **GitHub Actions** (`macos-latest` & `ubuntu-latest`) tanpa perlu menginstal Android SDK/Xcode di server Linux produksi.

---

## 2. Tech Stack Eksplisit & Struktur Clean Architecture

Arsitektur menerapkan **Clean Architecture** (Dependency Rule: dependensi kode mengalir ke dalam menuju *Domain Entities & Use Cases*; *UI, Native Sensors, SQLCipher, dan REST Sync Client* adalah plugin di lapisan luar).

| Lapisan / Komponen | Teknologi Terpilih | Alasan & Peran Teknis |
| :--- | :--- | :--- |
| **Mobile UI & App Core** | **Flutter 3.x (Dart 3.x)** — Material 3 + Cupertino Adaptive | Satu codebase menghasilkan iOS `.ipa` & Android `.apk` dengan animasi 60 FPS dan konsistensi 5 layar komersial. |
| **State Management** | **Riverpod / ChangeNotifier Clean Provider** | Reaktif, mendukung *dependency injection* untuk *Use Cases*, mudah diuji unit-test tanpa UI, dan instan merender ulang perubahan RBAC/CRUD. |
| **3D Spatial Viewer (Flutter)** | **Custom Interactive Isometric/3D Mesh Canvas (`CustomPainter` / `flutter_3d_controller`)** | Ringan, berjalan offline penuh di iOS/Android tanpa membebani GPU, mendukung rotasi/zoom dan penempatan pin koordinat `(x, y, z)`. |
| **Native 3D & AI Bridge (iOS)** | **Swift 5.9 + Apple RoomPlan + ARKit + VisionKit/CoreML** | Memanfaatkan sensor LiDAR iPhone Pro untuk denah 3D < 90 detik, OCR struk lokal, dan *on-device PII auto-blur*. |
| **Native 3D & AI Bridge (Android)** | **Kotlin 1.9 + Google ARCore Depth API + ML Kit Text Recognition** | Fallback pemetaan kedalaman AR pada Android + OCR lokal, dengan fallback otomatis ke *Manual 3D Box Builder* jika perangkat tanpa ARCore. |
| **Local Encrypted Storage** | **SQLite + SQLCipher (`sqflite_sqlcipher`) & `flutter_secure_storage`** | Enkripsi database *at-rest* AES-256; kunci acak 256-bit disimpan di iOS Keychain / Android Keystore. |
| **Media & 3D Mesh Encryption** | **AES-256-GCM (`cryptography` package)** | Mengenkripsi berkas `.usdz`/`.glb`, foto aset, dan bukti struk pada *app sandbox directory*. |
| **PDF Generator & Integrity** | **`pdf` (Dart native PDF composer) + `crypto` (SHA-256)** | Generasi laporan PDF Klaim Asuransi, Berita Acara Sewa, & Dimensi Renovasi < 5 detik secara offline lengkap dengan *SHA-256 Document Integrity Hash*. |
| **Biometric Gate** | **`local_auth` (Face ID / Touch ID / BiometricPrompt)** | Mengunci aplikasi setelah *idle* (> 5 menit) dan melindungi aksi sensitif (`Server Config`, `Share Link`, `Valuation`). |
| **Optional Sync Backend** | **Node.js 20 LTS (TypeScript) + Fastify / Express + PostgreSQL 16** | API REST delta-sync *idempotent*, manajemen `Share Link`, RBAC server-side guard, dan penyimpanan blob terenkripsi. |
| **CI/CD Mobile Factory** | **GitHub Actions (`ubuntu-latest` + `macos-latest`)** | Zero-Local-Build di Linux; menerbitkan `AppRelease.apk` dan `AppRelease.ipa` ke **GitHub Releases**. |

### 2.1 Struktur Folder Multi-Layer Target Proyek

```text
spatial-3d-home/
├── ARCHITECTURE_SPEC.md               # Dokumen arsitektur ini
├── BRD_SPEC.md                        # Dokumen kebutuhan bisnis & RBAC
├── PRD_AC_SPEC.md                     # Dokumen PRD, MoSCoW, Seed & Gherkin AC
├── .env.example                       # Template seluruh konfigurasi environment
├── .github/
│   └── workflows/
│       └── build-mobile.yml           # Pipeline Zero-Local-Build (.apk + .ipa + Releases)
├── database/
│   ├── schema.sql                     # DDL relasional PostgreSQL 16 (termasuk views rooms_3d & valuations)
│   ├── schema_local_sqlite.sql        # Mirror DDL on-device SQLite/SQLCipher + sync_outbox
│   └── seed.sql                       # Seed data Villa Kemang Selatan #14B (4 rooms, 8 assets)
├── simulator/ (atau index.html)       # Interactive Mobile Simulator (390x844px)
├── backend/                           # Sync & Share-Link API Server (Node.js/TS)
│   ├── src/
│   │   ├── config/                    # Env loader, DB pool, TLS/CORS config
│   │   ├── middlewares/               # requireAuth, requireRole, redactionGuard, auditLogger
│   │   ├── routes/                    # /api/v1/auth, /properties, /assets, /sync, /shares
│   │   ├── controllers/               # HTTP translation -> Use Case DTO
│   │   └── services/                  # Field-level merge, ShareLink TTL/PIN, Audit service
└── mobile/ (root Flutter saat CI)
    ├── pubspec.yaml                   # Dependencies Flutter (tanpa hardcoded secrets)
    ├── ios_bridge/                    # Native Swift Bridge (RoomPlanChannel, SecureVault)
    ├── android_bridge/                # Native Kotlin Bridge (ARCoreChannel, KeystoreVault)
    └── lib/
        ├── main.dart                  # Composition Root (DI wiring, Env guard, Biometric Gate)
        ├── core/
        │   ├── config/                # AppConfig (.env flags, DEMO_MODE guard)
        │   ├── security/              # RbacGuard, CryptoService (AES-256-GCM), BiometricGate
        │   └── utils/                 # Currency formatter, SHA-256 pdf hash, Depreciation math
        ├── models/                    # Domain Entities & DTOs (UserRole, Property, Room3D, Asset, Valuation, SyncQueueItem)
        ├── services/                  # Ports & Adapters:
        │   ├── local_db_service.dart  # SQLCipher Encrypted Local Repository + Seed Data Loader
        │   ├── spatial_bridge_service.dart # Flutter MethodChannel -> iOS RoomPlan / Android ARCore / Mock
        │   ├── valuation_service.dart # Straight-line depreciation & appraisal comparator
        │   ├── pdf_export_service.dart# Offline PDF/JSON/CSV generator + SHA-256 footer
        │   └── sync_service.dart      # Outbox sync_queue, exponential backoff & field-level merge
        ├── screens/                   # 5 Layar Komersial + Guarded Sub-views:
        │   ├── login_screen.dart      # Layar 1: Email/PIN Login + Quick Role Switcher (Demo Only)
        │   ├── dashboard_screen.dart  # Layar 2: Home Bento KPI + 3D Spatial Viewer + Scan Trigger
        │   ├── inventory_screen.dart  # Layar 3: Asset Inventory CRUD + Search/Filter + Bottom Sheet
        │   ├── analytics_screen.dart  # Layar 4: Spatial Analytics & Valuation Charts
        │   └── profile_settings_screen.dart # Layar 5: Profile, Sync, Server Config (Owner), Share & Export
        └── widgets/
            ├── bottom_nav_shell.dart  # Persistent 4-Tab Bottom Navigation Bar
            ├── spatial_3d_canvas.dart # Interactive 3D isometric wireframe & spatial pins (x,y,z)
            ├── asset_form_sheet.dart  # Modal Bottom Sheet (Create/Edit/Verify/Condition Note)
            ├── bento_kpi_card.dart    # Kartu KPI responsif (termasuk privacy mask untuk Tenant)
            └── role_badge_header.dart # Indikator role aktif & status sync offline/online
```

---

## 3. Arsitektur Flutter & Native Bridge (iOS RoomPlan/ARKit & Android ARCore)

### 3.1 Kontrak Pemetaan 5 Layar Komersial & Navigasi RBAC

| Layar | Tab / Rute | Komponen Utama | Perilaku per Role (`OWNER` / `APPRAISER` / `TENANT`) |
| :--- | :--- | :--- | :--- |
| **Layar 1: Login & Quick Role Switcher** | `/login` (Entry) | Form Email+Password/PIN, Biometric Unlock, & Panel Quick Switch Role (hanya jika `ENABLE_DEMO_ROLE_SWITCHER=true`). | Semua role dapat login; `TENANT` juga mendukung login via token *Share Link + PIN 6-digit*. |
| **Layar 2: Home 3D Spatial Dashboard** | Tab 1 (`Home`) | Bento KPI Cards (Total Valuasi, Jumlah Aset, Luas `m²`, % Terverifikasi), *Interactive 3D Spatial Viewer*, tombol *Start 3D Scan*. | `OWNER`: Penuh + Scan baru.<br>`APPRAISER`: Penuh + Audit scan.<br>`TENANT`: Kartu Valuasi di-mask (`Restricted`), tombol Scan disembunyikan. |
| **Layar 3: Asset Inventory CRUD** | Tab 2 (`Inventory`) | Search real-time, Filter Chips (Ruangan/Kategori/Status), FAB `+`, **Modal Bottom Sheet** detail/edit/verifikasi. | `OWNER`: Full CRUD + Delete.<br>`APPRAISER`: Read + Update `appraisedValue`, `verificationStatus`, `appraisalNote` (No Delete).<br>`TENANT`: Read aset `ALL_AUTHORIZED` (harga disembunyikan) + tambah `Condition Note`. |
| **Layar 4: Spatial Analytics** | Tab 3 (`Analytics`) | 3 Grafik: (1) Valuasi per Ruangan, (2) Komposisi Kategori, (3) Depresiasi vs Nilai Beli & Status Garansi. | `OWNER` & `APPRAISER`: Penuh.<br>`TENANT`: Grafik finansial diganti banner *Restricted*, hanya tampil distribusi jumlah barang per ruangan. |
| **Layar 5: Profile, Sync, Share & Server Config** | Tab 4 (`Profile`) | Status Sync Queue, Ekspor PDF/JSON/CSV, Manajemen *Share Link*, `Server Config` (Endpoint/Wi-Fi Only/Enkripsi), Audit Log, Reset Demo & Logout. | `OWNER`: Penuh (termasuk `Server Config` & `Share Link` Revoke).<br>`APPRAISER`: Ekspor PDF Klaim + Sync Prefs (`Server Config` & `Share Link` CRUD disembunyikan).<br>`TENANT`: Unduh Berita Acara Sewa (jika diizinkan) + Logout saja. |

### 3.2 Desain Native Platform Channel (`SpatialScannerBridge`)

Flutter berkomunikasi dengan sensor native melalui `MethodChannel('com.devcurl.spatial3dhome/spatial_scanner')` dan `EventChannel('com.devcurl.spatial3dhome/scan_progress')`:

```text
[Flutter: SpatialBridgeService]
       │
       ├── checkCapabilities() ──► iOS: RoomCaptureSession.isSupported (LiDAR check)
       │                       ──► Android: ArCoreApk.checkAvailability()
       │                       ──► Fallback: Simulator / Manual 3D Box Builder
       │
       ├── startRoomScan(roomMeta)
       │     ├── [iOS LiDAR]  ──► Apple RoomPlan (RoomCaptureViewController)
       │     │                     └─ Rekonstruksi wall/door/window/furniture 100% On-Device
       │     │                     └─ Export USDZ/GLB terkompresi (<= 15-20 MB) + JSON bounding box
       │     ├── [iOS No-LiDAR / Android ARCore] ──► ARCore Depth / Plane Anchor
       │     │                     └─ Hitung panjang x lebar x tinggi -> Generate mesh GLB ringan
       │     └── [Fallback / Simulator] ──► Interactive 3D Box & Pre-baked glTF Room Loader
       │
       ├── runOnDeviceOcr(imagePath)
       │     ├── [iOS]     ──► VNRecognizeTextRequest (Apple Vision, offline)
       │     └── [Android] ──► ML Kit TextRecognition (bundled on-device model)
       │
       └── autoBlurSensitivePii(imagePath)
             └── Deteksi wajah/kartu ID secara lokal (VNDetectFaceRectanglesRequest / ML Kit Face)
                 sebelum foto dienkripsi AES-256-GCM ke sandbox.
```

> **Jaminan Privasi On-Device (NFR-01 / AC-06):** Channel native tidak memiliki akses HTTP/Socket dan tidak pernah mengembalikan frame video mentah ke Dart untuk diunggah. Output *scanner* hanyalah geometri mesh terkompresi (`.usdz`/`.glb`) dan metadata dimensi JSON.

---

## 4. Sistem Enkripsi Lokal, Offline-First Sync & Konflik

### 4.1 Skema Enkripsi Data Lokal (*At-Rest Security*)

1. **Master Key Management (Zero Plaintext Key):**
   - Pada peluncuran pertama, `CryptoKeyManager` membangkitkan kunci acak 256-bit (`CSPRNG`) dan menyimpannya dengan alias `STORAGE_ENCRYPTION_KEY_REF` di **iOS Keychain (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly` / Secure Enclave)** atau **Android Keystore (`EncryptedSharedPreferences` + StrongBox/TEE)**.
   - Kunci **tidak pernah** ditulis ke `.env`, `SharedPreferences` biasa, maupun `localStorage` native.
2. **Database Terenkripsi (SQLCipher — `database/schema_local_sqlite.sql`):**
   - Seluruh tabel lokal (`local_profiles`, `local_sessions`, `properties`, `rooms`, `room_scans`, `assets`, `asset_media`, `asset_appraisals`, `condition_notes`, `share_links_cache`, `export_bundles`, `sync_outbox`, `app_settings`) disimpan di SQLite dengan enkripsi halaman penuh **SQLCipher AES-256-CBC + HMAC-SHA512**.
   - Pada sisi backend (`database/schema.sql`), seluruh entitas relasional meliputi `roles`, `permissions`, `role_permissions`, `users`, `sessions`, `properties`, `property_members`, `rooms`, `room_scans`, `assets`, `asset_media`, `asset_appraisals`, `condition_notes`, `share_links`, `export_bundles`, `server_configs`, `sync_changelog`, `sync_conflicts`, `audit_logs`, serta canonical views `rooms_3d` dan `valuations`.
3. **File Media & Mesh 3D Terenkripsi (AES-256-GCM):**
   - Setiap foto barang, foto struk, dan file `.usdz`/`.glb` dienkripsi per-file menggunakan **AES-256-GCM** (96-bit unique IV/nonce per file + 128-bit auth tag) menjadi berkas `.enc` di direktori privat aplikasi.
4. **Biometric Gate & App Lock (NFR-04):**
   - Setelah aplikasi *idle* > `BIOMETRIC_IDLE_TIMEOUT_SECONDS` (default `300` detik) atau saat membuka modul `Server Config` / `Share Link` / `Valuation`, aplikasi memblokir layar hingga lolos **Face ID / Touch ID / BiometricPrompt** atau PIN lokal (maksimal `MAX_FAILED_UNLOCK_ATTEMPTS=10` percobaan gagal sebelum *cooldown lockout* / opsi wipe opsional).

### 4.2 Arsitektur Offline-First `sync_queue` & Resolusi Konflik

```text
[Mutasi Lokal (Create/Update/Delete)]
   │
   ▼
1. **Commit ke SQLCipher (Atomik) + Insert ke tabel `sync_outbox` (`sync_queue` lokal, dengan `idempotency_key` UUIDv4)**
   │
   ▼
2. SyncWorker memantau konektivitas & `SYNC_WIFI_ONLY_DEFAULT` (berhenti jika `OFFLINE_ONLY_DEFAULT=true`)
   │
   ▼ (Saat Online & Diizinkan)
3. POST /api/v1/sync/push (TLS 1.3 + JWT + Batch Delta + Client-Side Encrypted Blobs)
   │
   ├── HTTP 200 OK ──► Tandai item `SYNCED`
   ├── HTTP 409 Conflict ──► Server & Client terapkan **Field-Level Merge**:
   │      • Field Kepemilikan (`name`, `purchase_price`, `photo`, `pin_x/y/z`, `visibility_scope`) -> Menang versi `OWNER` (`owner_modified_at`).
   │      • Field Penilaian (`appraised_value`, `verification_status`, `inspection_note`) -> Menang versi `APPRAISER` (`appraiser_modified_at`).
   │      • Kedua perubahan digabung tanpa saling menimpa & dicatat di `sync_conflicts` & `audit_logs` (`SYNC_CONFLICT_MERGED`).
   └── Network Error / 5xx ──► Exponential Backoff (5s, 15s, 45s, ... maks `300s`)
```

---

## 5. Desain Autentikasi, RBAC Guard & Kontrak REST API Sync

### 5.1 Mekanisme Autentikasi & Hashing

- **Password Hashing:** Server menggunakan **Argon2id** (memori 64 MiB, iterasi 3, paralelisme 1; fallback `bcrypt` cost 12 jika runtime terbatas).
- **Token Sesi:**
  - `access_token`: **JWT (HS256 / EdDSA)** berumur singkat (`15 menit`) memuat claim `{ sub: userId, role: 'OWNER'|'APPRAISER'|'TENANT', propertyScope: [...], isDemo: bool, jti }`.
  - `refresh_token`: Opaque random 256-bit token yang disimpan di client dalam Keychain/Keystore dan di server sebagai **SHA-256 hash** pada tabel `sessions` (mendukung *token rotation* dan pencabutan sesi instan).
- **Akses Guest / Share Link:** Penerima tautan menerima *Scoped JWT* berdurasi terbatas setelah memvalidasi `token_hash` (+ verifikasi PIN 6-digit jika diaktifkan) pada tabel `share_links`.

### 5.2 Middleware RBAC (`requireAuth` & `requireRole` + Field Redaction)

Setiap rute backend melewati rantai middleware berurutan:
1. `requireAuth`: Memvalidasi signature JWT, masa berlaku, status aktif user, dan bahwa `session_id` belum di-`revoke`.
2. `requireRole(allowedRoles)`: Memeriksa `req.auth.role ∈ allowedRoles`. Jika gagal -> **HTTP `403 Forbidden`** + menulis event `RBAC_DENIED` ke `audit_logs`.
3. `requirePropertyScope`: Memverifikasi kepemilikan (`properties.owner_id == userId`) atau penugasan aktif di `property_members` / `share_links`.
4. `applyVisibilityAndFieldRedaction`:
   - Untuk `TENANT`: Memfilter keluar seluruh aset dengan `visibility_scope IN ('INSURANCE_ONLY', 'OWNER_PRIVATE')` dan menghapus (*redact*) field `purchase_price`, `current_valuation`, `appraised_value`, `warranty_expiry_date`, serta `policy_number_enc` dari JSON respons.
   - Untuk `APPRAISER`: Memfilter keluar aset `OWNER_PRIVATE` (kecuali secara eksplisit disertakan dalam paket klaim oleh `Owner`), serta menolak mutasi field milik `Owner` pada endpoint `PATCH /assets/:assetId`.

### 5.3 Kontrak REST API Lengkap (`/api/v1`)

| Method & Endpoint | Middleware Guard | Request Payload (Ringkas) | Response Sukses & Kode Status | Error / RBAC Guard |
| :--- | :--- | :--- | :--- | :--- |
| `POST /api/v1/auth/login` | Public (Rate-limited) | `{ "email": "...", "password": "...", "deviceId": "...", "platform": "IOS" }` | `200 OK`: `{ "accessToken", "refreshToken", "user": { "id", "role", "permissions" } }` | `401` Kredensial salah; `429` Terlalu banyak percobaan |
| `POST /api/v1/auth/demo-switch` | `ENV: ENABLE_DEMO_ROLE_SWITCHER=true` | `{ "targetRole": "OWNER" \| "APPRAISER" \| "TENANT" }` | `200 OK`: `{ "accessToken", "user": { "isDemo": true, "role": ... } }` | `403` Jika `ENABLE_DEMO_ROLE_SWITCHER=false` (Wajib mati di prod!) |
| `GET /api/v1/auth/me` | `requireAuth` | — | `200 OK`: Profil user, role aktif, daftar `permissions[]` | `401` Token tidak valid / kedaluwarsa |
| `POST /api/v1/auth/logout` | `requireAuth` | `{ "refreshToken": "..." }` | `204 No Content`: Sesi di-revoke di tabel `sessions` | `401` Unauthorized |
| `GET /api/v1/properties/:id/dashboard` | `requireAuth`, `requireRole(['OWNER','APPRAISER','TENANT'])` | Query: `?includeRooms=true` | `200 OK`: `{ "property", "kpi": { "totalValuation"*, "totalAssets", "totalAreaSqm", "verifiedPct" }, "rooms": [...] }` | `403` Bukan anggota properti (*`TENANT`: field valuasi `null/redacted`) |
| `POST /api/v1/properties/:id/scans` | `requireAuth`, `requireRole(['OWNER','APPRAISER'])` | `{ "name", "floorLevel", "scanSource", "areaSqm", "lengthM", "widthM", "heightM", "meshBlobSha256", "boundingBoxJson" }` | `201 Created`: `{ "room": { ... }, "newTotalAreaSqm": 111.0 }` | `403` `TENANT` ditolak; `422` Dimensi negatif / ukuran mesh > 20MB |
| `GET /api/v1/properties/:id/assets` | `requireAuth`, `requireRole(['OWNER','APPRAISER','TENANT'])` | Query: `?roomId=&category=&status=&q=` | `200 OK`: `{ "items": [...], "meta": { "total", "filtered" } }` *(Visibility & Redaction diterapkan)* | `403` Tidak punya akses ke properti |
| `POST /api/v1/properties/:id/assets` | `requireAuth`, `requireRole(['OWNER'])` | `{ "roomId", "name", "category", "serialNumber", "purchasePrice", "currentValuation", "pinX", "pinY", "pinZ", "visibilityScope", "purchaseDate", "warrantyExpiryDate" }` | `201 Created`: `{ "asset": { ... } }` | `403` `APPRAISER` & `TENANT` ditolak; `422` Harga < 0 / warranty < purchaseDate |
| `PATCH /api/v1/assets/:assetId` | `requireAuth`, `requireRole(['OWNER','APPRAISER'])` | `OWNER`: seluruh field aset.<br>`APPRAISER`: hanya `{ "appraisedValue", "verificationStatus", "conditionGrade", "appraisalNote" }` | `200 OK`: `{ "asset": { ... }, "valuationRecordId": "..." }` | `403` Jika `TENANT`, atau jika `APPRAISER` mencoba ubah `purchasePrice` / `name` |
| `POST /api/v1/assets/:assetId/condition-notes` | `requireAuth`, `requireRole(['OWNER','APPRAISER','TENANT'])` | `{ "noteType": "TENANT_CHECKIN_ISSUE", "severity": "MINOR", "comment": "..." }` | `201 Created`: `{ "note": { ... } }` | `403` Jika aset berstatus `OWNER_PRIVATE` / di luar scope |
| `DELETE /api/v1/assets/:assetId` | `requireAuth`, `requireRole(['OWNER'])` | — | `200 OK`: `{ "deleted": true, "mode": "SOFT_ARCHIVE" }` | `403` `APPRAISER` & `TENANT` mutlak ditolak; `409` Jika aset `CLAIMED` (diarsipkan, bukan hard delete) |
| `GET /api/v1/properties/:id/analytics` | `requireAuth`, `requireRole(['OWNER','APPRAISER','TENANT'])` | — | `200 OK`: `{ "valuationByRoom", "categoryBreakdown", "depreciationComparison", "warrantyAlerts" }` | `TENANT`: hanya `roomAssetCounts` & `categoryBreakdown` tanpa nominal mata uang |
| `POST /api/v1/properties/:id/exports/insurance-claim` | `requireAuth`, `requireRole(['OWNER','APPRAISER'])` | `{ "exportType": "INSURANCE_CLAIM" \| "LEASE_HANDOVER" \| "RENOVATION_DIMENSIONS", "format": "PDF" \| "JSON" \| "CSV" }` | `201 Created`: `{ "exportId", "sha256Integrity", "appraiserStamped", "downloadPayload" }` | `403` `TENANT` ditolak untuk `INSURANCE_CLAIM`; `Owner` tidak bisa memalsukan `appraiserStamped=true` |
| `POST /api/v1/properties/:id/share-links` | `requireAuth`, `requireRole(['OWNER'])` | `{ "targetRole": "APPRAISER" \| "TENANT", "allowedRoomIds": [...], "ttlHours": 72, "pin": "123456", "recipientLabel": "..." }` | `201 Created`: `{ "shareId", "shareUrl", "expiresAt" }` | `403` `APPRAISER` & `TENANT` ditolak |
| `DELETE /api/v1/share-links/:shareId` | `requireAuth`, `requireRole(['OWNER'])` | — | `200 OK`: `{ "revokedAt": "..." }` | `403` Non-owner ditolak |
| `GET /api/v1/share-links/resolve/:token` | Public + PIN Check | `{ "pin": "123456" }` (jika ber-PIN) | `200 OK`: `{ "scopedAccessToken", "targetRole", "propertySnapshot" }` | `401` PIN salah; `410 Gone` Jika revoked atau lewat `expiresAt` |
| `PUT /api/v1/server-config` | `requireAuth`, `requireRole(['OWNER'])` | `{ "offlineOnly": bool, "syncWifiOnly": bool, "syncEndpoint": "...", "b2bWebhookUrl": "..." }` | `200 OK`: Konfigurasi sync tersimpan | `403` `APPRAISER` & `TENANT` mutlak ditolak |
| `POST /api/v1/sync/push` & `GET /api/v1/sync/pull` | `requireAuth`, `requireRole(['OWNER','APPRAISER'])` | `push`: `{ "deviceId", "events": [{ "idempotencyKey", "entityType", "entityId", "operation", "payload", "clientUpdatedAt" }] }` | `200 OK`: `{ "applied": [...], "conflictsMerged": [...], "serverDelta": [...] }` | `403` `TENANT` tidak boleh push mutasi; idempotency mencegah duplikasi |

---

## 6. Spesifikasi CI/CD GitHub Actions (Zero-Local-Build di Linux)

Sesuai **ATURAN EMAS (`mobile-github-ci-factory`)**:
- **DILARANG** menginstal Flutter SDK, Android SDK, Gradle, atau Xcode di server Linux lokal.
- Server Linux hanya menulis `pubspec.yaml`, folder `lib/`, aset/native bridge (`ios_bridge/`, `android_bridge/`), dan `.github/workflows/build-mobile.yml`, lalu mendorongnya ke GitHub.
- Seluruh kompilasi berjalan di GitHub Actions Cloud Runner:
  - **Android APK:** runner `ubuntu-latest` (`flutter build apk --release`).
  - **iOS Sideload IPA:** runner `macos-latest` menggunakan **kombinasi wajib bypass code-signing**:
    1. `flutter build ios --config-only --no-codesign`
    2. `xcodebuild build -workspace Runner.xcworkspace -scheme Runner -configuration Release -destination 'generic/platform=iOS' -derivedDataPath build CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGNING_IDENTITY="" DEVELOPMENT_TEAM=""`
    3. Kemas `Payload/Runner.app` ke `Spatial3DHome-v1.ipa`.
- **Anti-Sideload Cache Collision:** Saat merilis versi baru, wajib menaikkan versi di `pubspec.yaml` (`1.0.0+1` -> `1.1.0+2`), mengubah suffix Bundle ID (`com.spatial3dhome.app` -> `.v2`), dan memvariasikan nama artefak `.ipa`.
- **Injeksi Nama Aplikasi & Izin Sensor iOS/Android:** Step workflow menyuntikkan display name `"Spatial 3D Home"`, `NSCameraUsageDescription`, `NSFaceIDUsageDescription` pada `ios/Runner/Info.plist` serta `CAMERA`, `USE_BIOMETRIC`, `INTERNET` pada `android/app/src/main/AndroidManifest.xml`.
- **Implementasi Aktual Pipeline:** Referensi lengkap workflow tersedia pada `.github/workflows/build-mobile.yml` (mencakup job `validate-env-and-schema`, `build-android`, `build-ios`, dan `publish-release`).

### 6.1 Blueprint Workflow `.github/workflows/build-mobile.yml`

*(Untuk diimplementasikan oleh `team-engineer` saat scaffolding repo mobile)*

```yaml
name: Build Spatial 3D Home (iOS IPA & Android APK)

on:
  push:
    branches: [ "main", "master" ]
  workflow_dispatch:

permissions:
  contents: write

jobs:
  build-android:
    name: Build Android APK (Flutter)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'
      - uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          cache: true
      - name: Scaffold Native Android Shell & Inject Manifest Permissions
        run: |
          mkdir -p /tmp/custom_src
          cp -r lib /tmp/custom_src/
          cp pubspec.yaml /tmp/custom_src/
          flutter create --platforms=android --org com.spatial3dhome --project-name spatial_3d_home .
          cp -r /tmp/custom_src/lib/* lib/
          cp /tmp/custom_src/pubspec.yaml pubspec.yaml
          sed -i 's/android:label="[a-z_]*"/android:label="Spatial 3D Home"/' android/app/src/main/AndroidManifest.xml || true
          flutter pub get
      - name: Build Release APK
        run: |
          flutter build apk --release \
            --dart-define=APP_ENV=${{ vars.APP_ENV || 'production' }} \
            --dart-define=ENABLE_DEMO_ROLE_SWITCHER=${{ vars.ENABLE_DEMO_ROLE_SWITCHER || 'false' }}
          cp build/app/outputs/flutter-apk/app-release.apk ./Spatial3DHome-v1.apk
      - uses: actions/upload-artifact@v4
        with:
          name: Android-APK
          path: ./Spatial3DHome-v1.apk

  build-ios:
    name: Build iOS Sideload Unsigned IPA (Flutter)
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          cache: true
      - name: Scaffold Native iOS Shell & Inject Info.plist
        run: |
          mkdir -p /tmp/custom_src
          cp -r lib /tmp/custom_src/
          cp pubspec.yaml /tmp/custom_src/
          flutter create --platforms=ios --org com.spatial3dhome --project-name spatial_3d_home .
          cp -r /tmp/custom_src/lib/* lib/
          cp /tmp/custom_src/pubspec.yaml pubspec.yaml
          sed -i '' 's/<string>$(PRODUCT_NAME)<\/string>/<string>Spatial 3D Home<\/string>/g' ios/Runner/Info.plist || true
          /usr/libexec/PlistBuddy -c "Add :NSCameraUsageDescription string 'Digunakan untuk pemindaian ruangan 3D LiDAR dan foto aset secara on-device.'" ios/Runner/Info.plist || true
          /usr/libexec/PlistBuddy -c "Add :NSFaceIDUsageDescription string 'Digunakan untuk membuka kunci brankas data aset terenkripsi lokal.'" ios/Runner/Info.plist || true
          flutter pub get
      - name: Build Unsigned iOS App via xcodebuild
        run: |
          flutter build ios --config-only --no-codesign \
            --dart-define=APP_ENV=${{ vars.APP_ENV || 'production' }} \
            --dart-define=ENABLE_DEMO_ROLE_SWITCHER=${{ vars.ENABLE_DEMO_ROLE_SWITCHER || 'false' }}
          cd ios
          xcodebuild build \
            -workspace Runner.xcworkspace \
            -scheme Runner \
            -configuration Release \
            -destination 'generic/platform=iOS' \
            -derivedDataPath build \
            CODE_SIGNING_ALLOWED=NO \
            CODE_SIGNING_REQUIRED=NO \
            CODE_SIGNING_IDENTITY="" \
            DEVELOPMENT_TEAM=""
          cd ..
          mkdir -p Payload
          cp -r ios/build/Build/Products/Release-iphoneos/Runner.app Payload/
          zip -r ./Spatial3DHome-v1.ipa Payload
      - uses: actions/upload-artifact@v4
        with:
          name: iOS-IPA
          path: ./Spatial3DHome-v1.ipa

  publish-release:
    name: Publish IPA & APK to GitHub Releases
    needs: [build-android, build-ios]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: Android-APK
          path: ./release-files
      - uses: actions/download-artifact@v4
        with:
          name: iOS-IPA
          path: ./release-files
      - uses: softprops/action-gh-release@v2
        with:
          tag_name: v1.0.${{ github.run_number }}
          name: "Spatial 3D Home v1.0.${{ github.run_number }} (iOS .ipa & Android .apk)"
          body: |
            ## Paket Instalasi Mobile
            - 📱 `Spatial3DHome-v1.ipa` — iOS Unsigned Sideload (AltStore, Sideloadly, ESign, GBox)
            - 🤖 `Spatial3DHome-v1.apk` — Android Release APK
          files: |
            ./release-files/Spatial3DHome-v1.ipa
            ./release-files/Spatial3DHome-v1.apk
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## 7. Architecture Decision Records (ADR)

### ADR-001: Flutter Cross-Platform Single Codebase + Native Platform Channels
- **Status:** Accepted
- **Konteks:** Aplikasi harus tersedia dalam bentuk `.ipa` (iOS) dan `.apk` (Android) dengan 5 layar komersial yang identik, sekaligus membutuhkan akses sensor perangkat keras Apple RoomPlan/LiDAR (iOS) dan ARCore (Android).
- **Keputusan:** Menggunakan **Flutter** untuk seluruh UI, kalkulasi valuasi, enkripsi, dan logika bisnis, dipadukan dengan `MethodChannel` tipis menuju Swift (iOS RoomPlan/ARKit) dan Kotlin (Android ARCore).
- **Konsekuensi:** Menghemat ~50% waktu pengembangan dibanding dua aplikasi native penuh; bridge Swift/Kotlin tetap terisolasi di balik interface `SpatialScannerBridge` sehingga simulator web/non-LiDAR dapat menyuntikkan adapter *mock* tanpa mengubah logika UI.

### ADR-002: Offline-First SQLCipher + AES-256-GCM File Vault + Field-Level Merge
- **Status:** Accepted
- **Konteks:** Pemilik properti sering memindai ruang bawah tanah/properti kosong tanpa sinyal internet dan sangat sensitif terhadap privasi interior rumah. Selain itu, Owner dan Appraiser bisa menyunting aset yang sama secara offline.
- **Keputusan:** Menyimpan seluruh state di **SQLCipher (AES-256)** dan file media/mesh dalam format terenkripsi **AES-256-GCM** dengan kunci di Secure Enclave/Keystore. Sinkronisasi ke server bersifat *opt-in* melalui `sync_queue` ber-`idempotency_key` dan resolusi konflik **Field-Level Merge** (metadata kepemilikan mengikuti `Owner`, nilai taksiran & status audit mengikuti `Appraiser`).
- **Konsekuensi:** 100% fitur inti berjalan saat *Airplane Mode*; konflik sinkronisasi tidak menyebabkan data valuasi atau harga beli tertimpa secara diam-diam.

### ADR-003: Zero-Local-SDK Cloud Build via GitHub Actions Unsigned IPA
- **Status:** Accepted
- **Konteks:** Lingkungan pengembangan berada di host Linux yang tidak memiliki Xcode maupun Android SDK, dan tidak diizinkan memasang SDK mobile secara lokal.
- **Keputusan:** Mendelegasikan seluruh kompilasi `.apk` (`ubuntu-latest`) dan `.ipa` (`macos-latest`) ke GitHub Actions. Untuk bypass kebutuhan Apple Developer Certificate saat fase demo/sideload, iOS dibangun menggunakan `flutter build ios --config-only --no-codesign` diikuti `xcodebuild ... CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO`.
- **Konsekuensi:** Build reproducible dan bersih; pengguna iOS menginstal `.ipa` melalui sideloading (Sideloadly/AltStore/ESign/GBox) dan wajib menghapus versi lama sebelum memperbarui versi baru agar tidak terjadi *cache signature collision*.

### ADR-004: Strict RBAC Guard & Privacy Masking untuk Role `TENANT`
- **Status:** Accepted
- **Konteks:** Penyewa/pembeli (`Tenant/Viewer`) perlu memeriksa denah 3D dan kondisi barang sewa, namun dilarang keras melihat harga beli, total valuasi kekayaan, nomor polis asuransi, maupun mengakses `Server Config`.
- **Keputusan:** Menegakkan *Row-Level Visibility Filtering* (`visibility_scope = 'ALL_AUTHORIZED'`) dan *Field-Level Redaction* baik pada adapter database lokal di Flutter maupun middleware REST API backend, serta menonaktifkan `ENABLE_DEMO_ROLE_SWITCHER` secara compile-time (`--dart-define`) pada build produksi.
- **Konsekuensi:** Risiko kebocoran data finansial pemilik ke penyewa atau *privilege escalation* melalui mode demo dieliminasi pada level data dan UI.

### ADR-005: On-Device PDF Generation dengan SHA-256 Integrity Hash
- **Status:** Accepted
- **Konteks:** Dokumen klaim asuransi dan berita acara sewa harus dapat dibuat secara offline dan memiliki pembuktian integritas bahwa tabel aset & nominal belum dimodifikasi pasca-ekspor.
- **Keputusan:** Menggunakan generator PDF lokal di Dart (`pdf` package) untuk merakit snapshot denah 3D, tabel aset sesuai RBAC, dan stempel `Appraiser Verified` (khusus role `APPRAISER`), lalu menanamkan hash **SHA-256** kanonik dari payload JSON laporan di footer dokumen serta mencatatnya di tabel `export_bundles`.
- **Konsekuensi:** Proses ekspor selesai `< 5 detik` tanpa internet dan setiap PDF dapat diverifikasi keasliannya oleh mitra asuransi.

---

## 8. Analisis Ancaman, Keamanan & Failure Handling

| Ancaman / Risiko | Dampak | Mitigasi Arsitektural |
| :--- | :--- | :--- |
| **Kebocoran Video/Foto Interior ke Cloud** | Pelanggaran privasi penghuni | Pemrosesan RoomPlan/ARCore & OCR berjalan 100% *on-device* tanpa endpoint upload video; opsional auto-blur wajah/ID sebelum penyimpanan lokal. |
| **Ekstraksi Data dari Ponsel Hilang/Rooted** | Pencurian inventaris & nilai aset | SQLCipher AES-256 + AES-256-GCM media + kunci di Secure Enclave/Keystore + Biometric Gate 5 menit idle + lockout 10x gagal. |
| **Privilege Escalation via Quick Switch Role** | `Tenant` mengakses fitur `Owner` | Flag `--dart-define=ENABLE_DEMO_ROLE_SWITCHER=false` di build produksi; backend juga menolak `/auth/demo-switch` (HTTP 403) saat `APP_ENV=production`. |
| **Pemalsuan Stempel Audit oleh Owner** | Fraud klaim asuransi | Field `is_appraiser_signed` (`export_bundles`) dan `appraised_value` hanya dapat ditulis oleh user dengan role `APPRAISER` terautentikasi dan tercatat di `audit_logs` beserta `appraiser_user_id`. |
| **Kegagalan Sensor LiDAR / Perangkat Lama** | Crash saat scan ruangan | Deteksi kapabilitas `checkCapabilities()` saat runtime; otomatis fallback ke ARCore Depth -> Manual 3D Box Builder -> Simulator Mock tanpa crash. |
| **Koneksi Terputus Saat Sync** | Duplikasi aset / kehilangan data | Outbox `sync_outbox` lokal persisten di SQLCipher dengan `idempotency_key` UUIDv4 dan *exponential backoff retry*. |

---

## 9. Spesifikasi Seed Data Baseline (`PRD_AC_SPEC` Bab 5.4 & `UI_SPEC` Bab 3.2)

Untuk memastikan konsistensi antara **Interactive Mobile Simulator (`index.html`)**, **Local SQLCipher Seed**, dan **PostgreSQL `database/seed.sql`**, seluruh implementasi wajib menggunakan baseline seed **"Villa Kemang Selatan #14B"** (Total Beli: `Rp 433.000.000`, Total Valuasi Saat Ini: `Rp 402.925.000`, Verified: `5/8 = 62.5%`):
- **4 Ruangan (`rooms` / view `rooms_3d`, Total `111.0 m²`):**
  1. `Living Room` (`42.5 m²`, Lantai 1, `SCAN_VERIFIED`)
  2. `Home Office / Studio` (`18.0 m²`, Lantai 1, `SCAN_VERIFIED`)
  3. `Master Bedroom` (`28.4 m²`, Lantai 2, `SCAN_VERIFIED`)
  4. `Modern Kitchen` (`22.1 m²`, Lantai 1, `NEEDS_RESCAN`)
- **8 Aset Realistis (`assets`):**
  1. `Sony Bravia 65" OLED TV` (`Living Room`, `ELECTRONICS`, `INSURANCE_ONLY`, `VERIFIED`, Beli `Rp 34.000.000`, Valuasi `Rp 27.200.000`)
  2. `Natuzzi Leather Sectional Sofa` (`Living Room`, `FURNITURE`, `ALL_AUTHORIZED`, `VERIFIED`, Beli `Rp 48.000.000`, Valuasi `Rp 43.200.000`)
  3. `B&O Beosound Balance Speaker` (`Living Room`, `ELECTRONICS`, `INSURANCE_ONLY`, `PENDING`, Beli `Rp 42.500.000`, Valuasi `Rp 36.125.000`)
  4. `MacBook Pro 16" M3 Max` (`Home Office / Studio`, `ELECTRONICS`, `INSURANCE_ONLY`, `VERIFIED`, Beli `Rp 64.000.000`, Valuasi `Rp 51.200.000`)
  5. `Herman Miller Aeron Chair` (`Home Office / Studio`, `FURNITURE`, `ALL_AUTHORIZED`, `VERIFIED`, Beli `Rp 26.000.000`, Valuasi `Rp 23.400.000`)
  6. `LG Dual Inverter Smart AC` (`Master Bedroom`, `APPLIANCES`, `ALL_AUTHORIZED`, `FLAGGED`, Beli `Rp 11.500.000`, Valuasi `Rp 9.200.000`)
  7. `Rolex Submariner / Safe Vault Box` (`Master Bedroom`, `JEWELRY`, `OWNER_PRIVATE`, `VERIFIED`, Beli `Rp 185.000.000`, Valuasi `Rp 195.000.000`)
  8. `Breville Barista Touch Espresso` (`Modern Kitchen`, `APPLIANCES`, `ALL_AUTHORIZED`, `PENDING`, Beli `Rp 22.000.000`, Valuasi `Rp 17.600.000`)
