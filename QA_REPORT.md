# Laporan Audit QA & Keamanan Independen (`QA_REPORT.md`)
## Proyek: Spatial 3D Home & Asset Inventory (Mode 4 Mobile + Simulator)

- **Tanggal Audit:** 11 November 2026
- **Auditor:** QA & Security Reviewer (`team-qa-security`)
- **Task ID:** `deleg_8f4c9bac-0`
- **Workspace Target:** `/home/devcurl/workspace-webui/spatial-3d-home`
- **Dokumen Acuan:** `BRD_SPEC.md` (v1.1), `PRD_AC_SPEC.md` (v1.0.0), `ARCHITECTURE_SPEC.md` (v1.0.0), `UI_SPEC.md` (v1.0.0)

---

## Ringkasan Eksekutif & Status Kelulusan

- **Status Kelulusan Akhir:** **`FAIL (PERLU REVISI)`**
- **Ringkasan Temuan Independen:**
  - **4 Temuan HIGH:**
    1. **Stored DOM XSS** pada Simulator Web (`simulator_app.js:563, 593-594, 623, 733`) saat merender input pengguna ke `innerHTML` tanpa escaping — terbukti dieksekusi di Chromium (`window.__xssTriggered === true`).
    2. **RBAC Bypass (Tenant Export & Scan LiDAR)** pada Simulator Web (`simulator_app.js:375-404, 452, 718-725`): role `tenant` masih melihat tombol `Scan Baru`, tombol `Export JSON`/`Export CSV`, dan dapat mengekspor data finansial mentah (`tenantCanTriggerExportDownload: true`).
    3. **Kebocoran Data Finansial pada Activity Feed Tenant** (`simulator_app.js:531-532`): blok *Aktivitas Spasial Terkini* menuliskan nominal `Rp 51.200.000` untuk aset `insuranceOnly` (`MacBook Pro 16" M3 Max`) secara terbuka saat mode `tenant`.
    4. **Auth Mock & Belum Terhubungnya Enkripsi Vault Lokal pada Flutter** (`mobile/lib/screens/login_screen.dart:36-61`, `mobile/lib/core/app_state.dart`): `LoginScreen` meloloskan login tanpa verifikasi password/hash dan `_triggerFaceId()` melewati `SpatialBridgeService.authenticateBiometric()`; `AppState` menyimpan data di RAM (*in-memory only*) tanpa memanggil `SQLCipher` atau `saveVaultData`/`loadVaultData` Keychain/Keystore.
  - **4 Temuan MEDIUM:**
    1. **Validasi Input Harga Negatif Lolos di Simulator** (`simulator_app.js:281-316`, melanggar `AC-L3-02`): input `-50000` tersimpan menjadi `purchasePrice: -50000` dan `currentValuation: -45000`.
    2. **Simulator Web Belum Lengkap 5 Layar & Mengandung Data Statis** (`index.html`, `simulator_app.js:383, 580, 642-688`): tidak ada Layar 1 (Login/Logout), `sha256Seal` hardcoded hash string kosong (`e3b0c442...`), empty search state tanpa tombol `"Reset Filter"`, hanya 1 dari 3 chart analitik dengan pembagi hardcoded `400000000`, serta dialog modal menggunakan `alert()`/`prompt()`/`confirm()` native browser.
    3. **Native Bridge & Backend Sync API Belum Terimplementasi Penuh**: `AppDelegate.swift`, `ARCoreSpatialBridge.kt`, dan `MainActivity.kt` (`authenticateBiometric`) masih stub statis; `RoomPlanBridge.swift` tidak terdaftar di target Xcode; direktori `backend/` belum tersedia di workspace.
    4. **Chart Komposisi Kategori Belum Ada di Flutter Analytics** (`mobile/lib/screens/analytics_screen.dart`): baru menampilkan 2 visualisasi (Valuasi per Ruangan & Depresiasi vs Harga Perolehan) + riwayat inspeksi, belum menampilkan visualisasi komposisi kategori aset (`FR-06`).
  - **3 Temuan LOW:**
    1. **Touch Target `< 44px` di Simulator Web** (`AC-SIM-01`): 21 elemen tombol/chip berukuran tinggi `24px–26px` pada viewport `390×844`.
    2. **Penguatan Pipeline CI/CD** (`.github/workflows/build-mobile.yml:100, 105, 168-171`): `flutter analyze ... || true` menutupi error lint, injeksi permission `CAMERA` & `USE_BIOMETRIC` pada `AndroidManifest.xml` belum ditambahkan di CI, dan `PlistBuddy Add` belum idempotent.
    3. **Inkonsistensi Penamaan Minor & CDN Tanpa SRI**: ruangan #2 bernama `'Home Office / Studio'` di `database/seed.sql:86` vs `'Home Studio'` di `seed_data.dart:27` & `simulator_app.js:8`; `index.html:7-8` memuat skrip CDN tanpa atribut `integrity` (SRI).

---

## 1. Pengujian Acceptance Criteria (`BRD_SPEC` & `PRD_AC_SPEC`)

| ID AC | Kriteria Uji | Status Flutter (`mobile/lib/`) | Status Simulator Web (`simulator_app.js`) | Bukti & Observasi Nyata |
| :--- | :--- | :---: | :---: | :--- |
| **AC-01 / AC-L1** | **Login, Quick Role Switcher & Owner Full Access** | **PASS** *(Static/Mock Auth)* | **FAIL** | Flutter memiliki 5 layar lengkap (`LoginScreen` + `QuickRoleSwitcher` gated `enableDemoRoleSwitcher` + `Logout` di Layar 5). Simulator Web langsung masuk ke Home 3D tanpa Layar 1 Login/Logout (`AC-L1-01..03`). |
| **AC-02 / AC-L3-03** | **RBAC — Inspector / Appraiser** (Appraisal tanpa Delete/ServerConfig) | **PASS** *(Static)* | **PARTIAL FAIL** | Flutter (`app_models.dart:254-255`, `app_state.dart:295-318`) menyaring `ownerPrivate`, memperbarui `appraisedValue` tanpa menimpa `purchasePrice`, dan menolak Delete/ServerConfig. Simulator Web memakai `window.prompt()` dan menimpa `asset.currentValuation` (`line 349`). |
| **AC-03 / AC-L2-02 / AC-L5-03** | **RBAC — Tenant / Viewer** (Hanya `ALL_AUTHORIZED`, Financial Masking, Tolak Export & Scan) | **PASS** *(Static)* | **FAIL** | Flutter memfilter 4 aset `allAuthorized`, mengembalikan valuasi `0`/masked, dan memblokir Export (`profile_settings_screen.dart:43`). Simulator Web membocorkan `Rp 51.200.000` di *Activity Feed* (`line 532`), menampilkan tombol `Scan Baru` (`line 452`), serta mengizinkan `Export JSON/CSV` untuk `tenant` (`line 375, 718`). |
| **AC-04** | **Quick Switch Role Demo Flag** (`ENABLE_DEMO_ROLE_SWITCHER`) | **PASS** *(Static)* | **FAIL** | Flutter mem-gate switcher melalui `AppConfigFlags.enableDemoRoleSwitcher` dan `build-mobile.yml:113-115` set `false` saat `production`. Simulator Web tidak memiliki environment flag guard untuk menonaktifkan switcher di production. |
| **AC-05 / AC-L3-02 / AC-L5-01** | **CRUD Validation, Depresiasi & Ekspor SHA-256** | **PASS** *(Static)* | **FAIL** | Flutter `AssetActionSheet` menolak angka `< 0` dan `PdfExportService` menghitung SHA-256 kanonik (`CryptoService.sha256Hex`). Simulator Web **menerima harga `-50000`** (`line 290`) dan memakai `sha256Seal` hardcoded hash string kosong (`line 383`). |
| **AC-06** | **Privasi On-Device (`Zero Raw-Video Upload`)** | **PASS** *(Static)* | **PASS** | Tidak ada endpoint/HTTP upload kamera atau streaming video di `pubspec.yaml`, `mobile/lib/`, `AppDelegate.swift`, `RoomPlanBridge.swift`, maupun `ARCoreSpatialBridge.kt`. |
| **AC-07** | **Enkripsi Data Lokal AES-256 / SQLCipher** | **FAIL** *(Integration Gap)* | **FAIL** *(Plaintext `localStorage`)* | `schema_local_sqlite.sql` valid (13 tabel terverifikasi di `sqlite3`). Native keystore AES-256-GCM (`MainActivity.kt`) & Keychain (`AppDelegate.swift`) tersedia, tetapi `AppState` Flutter menyimpan data hanya di RAM dan belum memanggil `saveVaultData`/`SQLCipher`. |
| **AC-08** | **Offline-First Sync Queue & Backend API** | **NOT_RUN / PARTIAL** | **NOT_RUN** | Skema `sync_outbox`, `sync_changelog`, dan `sync_conflicts` valid, namun implementasi server `backend/` belum ada di workspace dan `syncNow()` di Flutter baru berupa reset counter in-memory. |
| **AC-09** | **Share Link Lifecycle & Revoke** | **PARTIAL PASS** | **NOT_IMPLEMENTED** | Flutter Owner dapat membuat dan mencabut (`REVOKED (410)`) Share Link di `profile_settings_screen.dart:468-545`, namun belum ada rute/layar resolver untuk validasi PIN & TTL saat membuka link. |
| **AC-SIM-01..02** | **Viewport `390×844`, Zero Console Error & Touch Target** | N/A | **PARTIAL FAIL** | `0` console error dan `0` horizontal overflow pada viewport `390×844` (`docScrollWidth: 390`), tetapi 21 elemen interaktif memiliki tinggi `< 44px`. |

---

## 2. Bukti Pengujian Independen (Evidence Log)

Seluruh pemeriksaan di bawah dieksekusi langsung pada `2026-11-11`:

| Pengujian | Perintah / Aksi Aktual | Exit Code / Hasil Terukur |
| :--- | :--- | :--- |
| **JS Syntax Check** | `node -c simulator_3d.js && node -c simulator_app.js` | `exit_code: 0` — `JS syntax check: OK` |
| **SQLite Local Schema DDL** | `python3` menjalankan `sqlite3.connect(':memory:').executescript(open('database/schema_local_sqlite.sql').read())` | `exit_code: 0` — 13 tabel berhasil dibuat (`app_settings`, `asset_appraisals`, `asset_media`, `assets`, `condition_notes`, `export_bundles`, `local_profiles`, `local_sessions`, `properties`, `room_scans`, `rooms`, `share_links_cache`, `sync_outbox`). |
| **Secret Hygiene Regex Scan** | Pemindaian regex (`BEGIN ... PRIVATE KEY`, `AKIA...`, `sk_live_...`, `ghp_...`) di seluruh berkas non-`.git` + cek `.env.example` | `exit_code: 0` — `Zero hardcoded secrets found.` `.env.example` (131 baris) terverifikasi ada. |
| **YAML & JSON Existence/Syntax** | Validasi `site.json`, `.github/workflows/build-mobile.yml`, `mobile/pubspec.yaml`, `mobile/analysis_options.yaml` via Node/Python | `exit_code: 0` — Semua berkas ada dan non-empty (`site.json` valid JSON). |
| **Flutter Static & Widget Tests** | `cd mobile && dart analyze --fatal-infos` | `dart: command not found` — **`NOT_RUN`** (sesuai ADR-003 Zero-Local-SDK di Linux; perlu verifikasi eksekusi via GitHub Actions). |
| **Browser E2E & Security Probe (Chromium `390×844` & Desktop)** | Serve workspace via `python3 -m http.server 18981`, jalankan skenario otomatis melalui `browser_exec` | - Owner Home: `assetCount: 8`, `totalVal: 402925000`, `docOverflow: false`, `phoneOverflow: false`, `errors: []`<br>- Inspector: `visibleCount: 7`, `hasRolexPrivate: false`, `hasDeleteBtn: false`, `hasServerConfig: false`<br>- Tenant: `homeTextHas51M: true` *(leak)*, `profHasExportBtn: true`, `scanBtnVisibleForTenant: true`, `tenantCanTriggerExportDownload: true`<br>- Negative Price (`-50000`): `afterNegativePriceCount: 9`, `negativePriceSaved: {price: -50000, val: -45000}`<br>- Stored XSS: `xssRenderedRawInDom: true`, `xss_executed: true`<br>- Empty Search & Touch Targets: `hasResetFilterBtn: false`, `smallTouchTargetsCount: 21` (`24px–26px`). |

---

## 3. Hasil Audit Keamanan (OWASP & RBAC)

### 3.1 Temuan Kritis & Tinggi (Critical / High)

1. **[HIGH-01] Stored DOM Cross-Site Scripting (XSS) di Simulator Web**
   - **Lokasi:** `simulator_app.js:563` (`searchQuery`), `593-594` (`a.name`, `room.name`, `a.serialNumber`), `623` (`a.tenantConditionNote`), `733` (`this.serverUrl`).
   - **Input Reproduksi:** Tambah aset dengan nama `<img src=x onerror="window.__xssTriggered=true">`.
   - **Expected vs Actual:** Expected di-escape menjadi teks literal; Actual tag HTML dirender ke `innerHTML` dan mengeksekusi handler `onerror` (`window.__xssTriggered === true`).
   - **Perbaikan:** Tambahkan helper `escapeHtml()` untuk semua interpolasi data dinamis ke `innerHTML`.

2. **[HIGH-02] Broken Access Control (RBAC Bypass Ekspor & Scan LiDAR) pada Simulator Web**
   - **Lokasi:** `simulator_app.js:375-404` (`exportClaimReport`), `452` (`Scan Baru`), `718-725` (`Export JSON`/`Export CSV`).
   - **Expected vs Actual:** Expected `tenant` dilarang mengekspor klaim asuransi dan melakukan scan 3D (`AC-L5-03`); Actual tombol tetap tampil dan `app.exportClaimReport('json')` mengunduh payload JSON berisi nilai finansial aset.
   - **Perbaikan:** Tambahkan guard `if (this.role === 'tenant') return;` pada `exportClaimReport()` dan `simulateLidarScan()`, serta sembunyikan tombolnya di UI saat `role === 'tenant'`.

3. **[HIGH-03] Privacy Masking Leak pada *Activity Feed* Simulator Web**
   - **Lokasi:** `simulator_app.js:531-532`.
   - **Expected vs Actual:** Expected seluruh nominal finansial dan aset non-`allAuthorized` disembunyikan untuk `tenant` (`AC-L2-02`); Actual teks statis `"MacBook Pro 16" M3 Max diverifikasi — Surveyor menyetujui nilai taksir Rp 51.200.000"` tetap terlihat di Home `tenant`.
   - **Perbaikan:** Hasilkan feed aktivitas secara dinamis dari `getVisibleAssets()` dan gunakan `formatCurrency()`.

4. **[HIGH-04] Auth Mock & Persistensi In-Memory Tanpa Enkripsi Aktif di Flutter**
   - **Lokasi:** `mobile/lib/screens/login_screen.dart:36-61`, `mobile/lib/core/app_state.dart`, `mobile/android_bridge/.../MainActivity.kt:31-34`.
   - **Deskripsi:** `_submitForm()` menentukan role hanya dari substring email tanpa verifikasi password/hash, `_triggerFaceId()` langsung login sebagai Owner tanpa memanggil `SpatialBridgeService.authenticateBiometric()`, dan `AppState` belum menyambungkan `SQLCipher` / `saveVaultData` ke Keychain/AndroidKeyStore.
   - **Perbaikan:** Hubungkan `AppState` ke lapisan persistensi SQLCipher/Keychain-Keystore, panggil `authenticateBiometric()` secara nyata (implementasikan `androidx.biometric.BiometricPrompt` di Android), dan batasi login mock hanya saat `ENABLE_DEMO_ROLE_SWITCHER=true`.

### 3.2 Temuan Menengah & Rendah (Medium / Low)

5. **[MEDIUM-01] Validasi Harga Negatif Gagal di Simulator Web (`AC-L3-02`)**
   - **Lokasi:** `simulator_app.js:281-316`. Input `-50000` tersimpan tanpa penolakan.
   - **Perbaikan:** Tolak angka `< 0` atau `NaN` dengan pesan error inline di Modal Bottom Sheet.

6. **[MEDIUM-02] Kesenjangan Kontrak 5 Layar, Analitik & Hash Dummy di Simulator Web**
   - **Lokasi:** `index.html`, `simulator_app.js:383, 580, 642-688`.
   - **Perbaikan:** Tambahkan Layar 1 Login & tombol Logout, hitung SHA-256 secara dinamis via `crypto.subtle.digest`, tambahkan tombol `"Reset Filter"` pada empty search state, lengkapi 3 grafik analitik + banner restriksi Tenant, dan ganti `alert`/`prompt`/`confirm` dengan in-app modal.

7. **[MEDIUM-03] Kesenjangan Analitik Flutter & Native Bridge / Backend Stub**
   - **Lokasi:** `mobile/lib/screens/analytics_screen.dart`, `mobile/ios_bridge/AppDelegate.swift`, `mobile/ios_bridge/RoomPlanBridge.swift`.
   - **Perbaikan:** Tambahkan chart **Komposisi Kategori Aset** di `AnalyticsScreen` (`FR-06`), daftarkan atau bersihkan `RoomPlanBridge.swift` yang orphan di Xcode, dan implementasikan direktori `backend/` saat masuk fase integrasi sync API.

8. **[LOW-01] Touch Target `< 44px`, Pipeline CI/CD & Konsistensi Seed**
   - **Lokasi:** `simulator_app.js:489, 568-571, 615-616`; `.github/workflows/build-mobile.yml:100, 105, 168-171`; `database/seed.sql:86` vs `seed_data.dart:27`.
   - **Perbaikan:** Naikkan ukuran sentuh tombol/chip simulator minimal `44px`; suntikkan permission `CAMERA` & `USE_BIOMETRIC` ke `AndroidManifest.xml` di CI; hapus `|| true` pada `flutter analyze`; buat `PlistBuddy` idempotent; selaraskan nama `'Home Office / Studio'`; dan tambahkan SRI pada script CDN di `index.html`.

---

## 4. Kesimpulan & Rute Tindak Lanjut

- **Verdict:** **`FAIL (PERLU REVISI)`**
- **Rekomendasi Rute:** Kembalikan ke `team-engineer` (atau Orchestrator untuk penjadwalan perbaikan) guna memperbaiki temuan **HIGH-01 s.d. HIGH-04** dan **MEDIUM-01 s.d. MEDIUM-03**, kemudian lakukan re-verifikasi termasuk eksekusi hijau workflow `.github/workflows/build-mobile.yml` (`flutter test`, `.apk`, `.ipa`).
