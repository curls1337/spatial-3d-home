# PRD, MoSCoW & Acceptance Criteria Specification
## Proyek: Spatial 3D Home & Asset Inventory

- **Dokumen:** `PRD_AC_SPEC.md`
- **Versi:** 1.0.0
- **Tanggal:** 2026-11-11
- **Status:** Baseline Siap Review & Implementasi
- **Workspace:** `/home/devcurl/workspace-webui/spatial-3d-home`
- **Target Platform:** Mobile App Komersial (iOS LiDAR / Android ARCore `.ipa` & `.apk`) + Interactive Mobile Simulator (`index.html`)

---

## 1. Visi Produk & Konteks Delivery

### 1.1 Visi Produk
**Spatial 3D Home & Asset Inventory** membantu pemilik properti, penilai asuransi (*inspector/appraiser*), dan penghuni untuk memetakan ruangan rumah menggunakan pemindaian spasial 3D (LiDAR/AR), mencatat inventaris aset beserta nilai valuasi & depresiasinya secara terstruktur, serta mengekspor paket bukti klaim asuransi terverifikasi dalam hitungan menit.

### 1.2 Strategi Dual-Delivery (Mode Hybrid: Simulator Demo Konsumen + Build Native)
1. **Interactive Mobile Simulator (`index.html`):**
   - Berjalan di browser dengan bingkai viewport mobile (`390×844px` + adaptif desktop/mobile), memuat **Seed Data Realistis** secara instan, mendukung **Quick Role Switcher (1-Klik)** pada Layar Login maupun bar simulasi cepat, dan menyimpan mutasi CRUD secara persisten di penyimpanan lokal (*localStorage*) lengkap dengan tombol reset demo.
2. **Native Mobile Build Pipeline (`.ipa` & `.apk`):**
   - Pipeline build terotomasi (berbasis proyek mobile cross-platform + native bridge LiDAR/ARKit & ARCore) dengan manajemen `.env` terpisah untuk lingkungan `demo`, `staging`, dan `production`, tanpa kredensial *hardcoded*.

---

## 2. Pemetaan Persona & Matriks RBAC

| Persona / Role | Deskripsi & Tujuan Utama | Akses Utama | Batasan Ketat (RBAC) |
| :--- | :--- | :--- | :--- |
| **Owner** *(Pemilik Properti)* | Mengelola aset rumah tangga, melakukan scan 3D ruangan baru, memantau valuasi total, dan mengekspor berkas klaim asuransi. | Full CRUD Properti, Ruangan Scan, Aset; Ekspor Klaim Asuransi; Pengaturan Sync & Reset. | Tidak dapat memalsukan stempel *"Verified by Inspector"* secara sepihak pada laporan audit eksternal. |
| **Inspector / Appraiser** *(Surveyor & Penilai)* | Mengaudit keakuratan denah 3D, memverifikasi kondisi fisik & nilai taksiran aset, memberi catatan inspeksi, dan mengekspor laporan appraisal/klaim. | Read seluruh ruangan & aset; Update status verifikasi (`Verified`/`Flagged`), nilai taksiran (*Appraised Value*), dan catatan inspeksi; Ekspor Laporan Audit/Klaim. | **Dilarang** menghapus properti, menghapus aset milik Owner secara permanen, atau mengubah pengaturan kepemilikan akun Owner. |
| **Tenant / Viewer** *(Penyewa / Anggota Keluarga)* | Melihat denah 3D dan daftar aset di unit yang ditempati serta melaporkan kondisi kerusakan ringan untuk ditindaklanjuti Owner. | Read-only denah 3D dan inventaris aset non-finansial; Tambah *Issue/Condition Note* pada aset. | **Dilarang** melakukan Create/Delete aset, melihat data nilai finansial/polis asuransi sensitif, mengubah pengaturan sync, atau mengekspor dokumen klaim asuransi. |

### Matriks Hak Akses per Modul

| Modul / Aksi | Owner | Inspector / Appraiser | Tenant / Viewer |
| :--- | :---: | :---: | :---: |
| Login & Quick Role Switcher | Ya | Ya | Ya |
| Lihat Bento KPI & 3D Spatial Viewer | Penuh (Finansial + Spasial) | Penuh (Finansial + Audit) | Terbatas (Spasial + Jumlah Aset; Nilai Finansial Disamarkan) |
| Trigger 3D LiDAR Scan / Tambah Ruangan | Ya | Ya (Audit Scan) | Tidak |
| Asset Inventory: Create & Delete | Ya | Tidak (Disabled/Hidden) | Tidak (Disabled/Hidden) |
| Asset Inventory: Update Detail Aset | Ya | Hanya Field Appraisal & Status | Hanya Catatan Kondisi (*Condition Report*) |
| Spatial Analytics & Valuation Charts | Penuh | Penuh | Terbatas (Distribusi Ruang; Tanpa Grafik Valuasi/Klaim) |
| Export Insurance Claim Bundle (PDF/JSON/CSV) | Ya | Ya | Tidak (Locked / Hidden) |
| Sync Settings & Reset Demo Data | Ya | Hanya Sync Preferences | Hanya Info Profil & Logout |

---

## 3. Prioritas Fitur (Metode MoSCoW)

### 3.1 Must-Have (M — Wajib 100% Berfungsi pada Rilis Ini)
- **M-01:** Layar 1 — Autentikasi Email/PIN + **Quick Role Switcher (1-Klik)** untuk peran `Owner`, `Inspector/Appraiser`, dan `Tenant/Viewer` dengan manajemen sesi persisten.
- **M-02:** Layar 2 — Home 3D Spatial Scan Dashboard + **Bento KPI Cards** (Total Valuasi Aset, Jumlah Aset Terdata, Luas Area Terpindai m², Persentase Aset Terverifikasi/Terproteksi) + **3D Spatial Viewer interaktif** (rotasi/zoom/pilih ruangan & simulasi LiDAR Scan).
- **M-03:** Layar 3 — Asset Inventory **Full CRUD melalui Modal Bottom Sheet** (daftar aset terkelompok/terfilter, form tambah/ubah aset dengan validasi input, hapus dengan konfirmasi, serta mode verifikasi khusus `Inspector` dan mode restricted `Tenant`).
- **M-04:** Layar 4 — Spatial Analytics & Valuation Charts (grafik valuasi per ruangan, distribusi kategori aset, proyeksi depresiasi vs nilai perolehan, dan ringkasan kesiapan klaim asuransi).
- **M-05:** Layar 5 — Profile, Sync & Export Settings (identitas role aktif, status sinkronisasi cloud/lokal, **Ekspor Paket Klaim Asuransi** format JSON/CSV/Ringkasan Cetak PDF, dan tombol Reset Seed Data pada mode simulator).
- **M-06:** **Seed Data Realistis** (>= 1 properti, >= 4 ruangan hasil scan LiDAR dengan koordinat/dimensi, >= 8 aset bernilai tinggi lengkap dengan serial number, kategori, harga beli, nilai saat ini, status garansi & verifikasi).
- **M-07:** **Interactive Mobile Simulator (`index.html`)** dengan viewport mobile komersial (`390×844px`), navigasi Bottom Tab Bar 4-tab pasca-login, bebas console error, dan responsif.
- **M-08:** **Build Pipeline `.ipa` & `.apk`** yang terdokumentasi dan terverifikasi (konfigurasi build, skema `.env`, signing placeholder aman, dan output/dry-run verification artifact).

### 3.2 Should-Have (S — Nilai Tambah Tinggi)
- **S-01:** Pencarian instan (*real-time search*) berdasarkan nama aset, merek, atau nomor seri pada Layar 3.
- **S-02:** Filter cepat (*chip filter*) per ruangan, kategori aset, dan status verifikasi (`Verified`, `Pending`, `Flagged`).
- **S-03:** Peringatan visual untuk aset yang garansinya kedaluwarsa dalam 30 hari atau belum memiliki nomor seri / foto bukti.
- **S-04:** Offline-first Sync Queue badge yang menampilkan jumlah perubahan lokal yang belum tersinkron ke server.

### 3.3 Could-Have (C — Pelengkap Jika Waktu Tersedia)
- **C-01:** Penggaris ukur virtual (*AR Tape Measure*) antar dua titik pada 3D Spatial Viewer.
- **C-02:** Ekstraksi otomatis metadata struk pembelian (OCR simulasi saat unggah foto nota).
- **C-03:** Multi-property switcher pada header Layar 2 untuk pemilik lebih dari satu unit rumah.

### 3.4 Won't-Have (W — Di Luar Lingkup Rilis Ini / Anti-Scope-Creep)
- **W-01:** Pembayaran premi asuransi atau transaksi *payment gateway* di dalam aplikasi.
- **W-02:** Marketplace jual-beli furnitur atau integrasi e-commerce pihak ketiga.
- **W-03:** Pemrosesan *raw LiDAR point-cloud rendering* berbasis GPU cloud server secara *real-time*.
- **W-04:** Fitur *real-time chat* atau panggilan video antar Owner, Inspector, dan Tenant.

---

## 4. Kontrak Navigasi 5 Layar Komersial & Arsitektur State

### 4.1 Peta Navigasi Utama
1. **Layar 1 — Login & Quick Role Switcher** *(Entry Point)*
   - Berhasil Login / Klik Role -> Masuk ke **Main Shell** (Layar 2 aktif + Persistent Bottom Navigation Bar: `Home`, `Inventory`, `Analytics`, `Profile`).
2. **Layar 2 — Home 3D Spatial Scan Dashboard + Bento KPI** *(Tab 1)*
   - Klik salah satu ruangan pada 3D Viewer -> Menyorot ruangan & menawarkan aksi *"Lihat Aset Ruangan"* (deep-link ke Layar 3 terfilter ruangan tersebut).
   - Klik *"Mulai Scan LiDAR"* -> Membuka simulasi/modul pemindaian ruangan dan menambah ruangan/pembaruan luas ke dashboard.
3. **Layar 3 — Asset Inventory CRUD + Modal Bottom Sheet** *(Tab 2)*
   - Klik FAB `+` / kartu aset -> Membuka **Modal Bottom Sheet** untuk Create, Detail/Update, atau Inspection Verification.
   - Setiap mutasi CRUD langsung memperbarui angka KPI pada Layar 2 dan grafik pada Layar 4.
4. **Layar 4 — Spatial Analytics & Valuation Charts** *(Tab 3)*
   - Menampilkan analitik visual interaktif dengan *timeframe/room selector*.
5. **Layar 5 — Profile + Sync & Export Settings** *(Tab 4)*
   - Mengelola preferensi sinkronisasi, mengekspor paket klaim asuransi, melakukan Switch Role cepat / Reset Demo Data, dan Logout kembali ke Layar 1.

### 4.2 Kebutuhan Non-Fungsional (NFR)
- **Performa:** Transisi antar-tab pada simulator maupun native `< 150ms`; *First Contentful Paint* simulator `< 1.5 detik`; render 3D Spatial Canvas stabil pada `>= 30 FPS` tanpa memblokir *main thread*.
- **Keamanan & Privasi:** Tidak ada kredensial/API key produksi di kode klien; masking nilai finansial & polis asuransi untuk role `Tenant/Viewer`; validasi input ketat (anti-XSS pada catatan/nama aset).
- **Aksesibilitas:** Ukuran target sentuh tombol minimal `44×44px` (standar Apple HIG & Material Design); kontras teks minimal `4.5:1`; dukungan label status teks (bukan hanya warna) untuk indikator verifikasi.
- **Keandalan State:** Seluruh perubahan CRUD bertahan melewati *page reload* (via `localStorage` pada simulator / SQLite lokal pada mobile) dan menyediakan *empty state* serta *error state* yang informatif.

---

## 5. Functional Requirements (FR), Kontrak Endpoint & Konfigurasi `.env`

### 5.1 Daftar Functional Requirements
- **FR-01 (Auth & Quick Switch):** Sistem menyediakan autentikasi berbasis role dan tombol 1-klik Quick Role Switcher (Owner, Inspector/Appraiser, Tenant/Viewer) dengan token sesi terisolasi per role.
- **FR-02 (Bento KPI Engine):** Sistem menghitung secara dinamis: Total Valuasi Saat Ini (IDR/USD terformat konsisten), Total Nilai Perolehan, Jumlah Total Aset, Total Luas Ruang Terpindai (m²), dan Persentase Aset Terverifikasi.
- **FR-03 (3D Spatial Room Mapper):** Sistem menampilkan visualisasi denah/ruangan 3D interaktif (wireframe/isometrik mesh + pin posisi aset) serta alur pemindaian LiDAR baru (dengan fallback mode simulasi jika perangkat tidak memiliki sensor LiDAR).
- **FR-04 (Asset CRUD Bottom Sheet):** Sistem menyediakan formulir Modal Bottom Sheet dengan field: `name` (wajib), `roomId` (wajib), `category` (wajib), `purchasePrice` (numerik >= 0), `currentValuation` (numerik >= 0), `purchaseDate`, `serialNumber`, `condition` (`Mint`, `Good`, `Fair`, `Damaged`), `verificationStatus` (`Pending`, `Verified`, `Flagged`), dan `notes`.
- **FR-05 (RBAC Enforcement):** UI dan layer data menegakkan izin per role secara konsisten (mis. tombol Hapus dan Ekspor Klaim tidak tersedia/tertolak untuk `Tenant`, tombol Hapus Aset tertolak untuk `Inspector`).
- **FR-06 (Analytics Charts):** Sistem merender minimal 3 visualisasi analitik: (1) Valuasi per Ruangan, (2) Komposisi Kategori Aset, (3) Perbandingan Nilai Beli vs Nilai Saat Ini (Depresiasi) & Coverage Asuransi.
- **FR-07 (Insurance Claim Export):** Sistem menghasilkan paket ekspor klaim asuransi terstruktur (`JSON` dan `CSV` yang dapat diunduh langsung + pratinjau ringkasan cetak/PDF) berisi metadata properti, daftar aset terverifikasi, total nilai klaim, dan timestamp/hash verifikasi.
- **FR-08 (Sync & Demo Reset):** Sistem menampilkan status sinkronisasi (`Synced`, `Pending Changes`, `Offline`) dan menyediakan aksi *Reset to Seed Data* agar konsumen/QA dapat mengulang skenario demo kapan saja.

### 5.2 Struktur Endpoint Backend per Role (Standar Produksi / Sync API)

| Method & Endpoint | Akses Role | Deskripsi |
| :--- | :--- | :--- |
| `POST /api/v1/auth/login` | Public | Autentikasi user & mengembalikan JWT + `role` + `permissions`. |
| `POST /api/v1/auth/demo-switch` | Demo Mode Only | Menukar sesi aktif ke persona demo (`owner`, `inspector`, `tenant`). |
| `GET /api/v1/properties/:id/dashboard` | Owner, Inspector, Tenant* | Mengambil ringkasan Bento KPI & daftar ruangan scan (*Tenant: field finansial di-redact*). |
| `POST /api/v1/properties/:id/scans` | Owner, Inspector | Mengunggah hasil scan LiDAR (`.usdz`/mesh metadata + dimensi m²). |
| `GET /api/v1/properties/:id/assets` | Owner, Inspector, Tenant* | Mengambil daftar aset dengan filter `roomId`, `category`, `status`, `q`. |
| `POST /api/v1/properties/:id/assets` | Owner | Membuat entri aset baru. |
| `PATCH /api/v1/assets/:assetId` | Owner, Inspector* | Mengubah data aset (*Inspector hanya field appraisal/verifikasi*). |
| `POST /api/v1/assets/:assetId/condition-notes` | Owner, Inspector, Tenant | Menambahkan catatan kondisi/kerusakan aset. |
| `DELETE /api/v1/assets/:assetId` | Owner | Menghapus aset (soft/hard delete dengan audit log). |
| `GET /api/v1/properties/:id/analytics` | Owner, Inspector, Tenant* | Data agregasi chart valuasi & depresiasi (*Tenant: hanya distribusi fisik*). |
| `POST /api/v1/properties/:id/exports/insurance-claim` | Owner, Inspector | Membuat & mengunduh bundel klaim asuransi (PDF/JSON/CSV). |
| `POST /api/v1/sync/push` & `GET /api/v1/sync/pull` | Owner, Inspector | Sinkronisasi delta perubahan offline-first. |

### 5.3 Variabel Lingkungan (`.env`) yang Dibutuhkan
- `APP_ENV`: `demo` | `staging` | `production`
- `APP_BUNDLE_ID_IOS`: Identifier bundle iOS (mis. `com.spatial3dhome.app`)
- `APP_PACKAGE_ID_ANDROID`: Package ID Android (mis. `com.spatial3dhome.app`)
- `API_BASE_URL`: Base URL layanan sinkronisasi (dikosongkan / `local` pada mode simulator offline)
- `ENABLE_DEMO_ROLE_SWITCHER`: `true` untuk build demo/simulator, wajib `false` pada build produksi komersial
- `LIDAR_FALLBACK_SIMULATION`: `true` untuk mengizinkan simulasi scan pada perangkat non-LiDAR / simulator
- `STORAGE_ENCRYPTION_KEY_REF`: Referensi kunci enkripsi lokal / Keystore / Keychain (tidak pernah diisi nilai rahasia langsung di repo)
- `IOS_TEAM_ID` / `ANDROID_KEYSTORE_PATH`: Variabel CI/CD build pipeline (di-inject melalui secret manager CI, bukan di `.env` Git)

### 5.4 Spesifikasi Seed Data Realistis (Wajib)
Seed data awal harus memuat properti **"Villa Kemang Selatan #14B"** dengan minimal:
- **4 Ruangan Hasil Scan LiDAR:**
  1. `Living Room` (42.5 m², Lantai 1, Scan Verified)
  2. `Home Office / Studio` (18.0 m², Lantai 1, Scan Verified)
  3. `Master Bedroom` (28.4 m², Lantai 2, Scan Verified)
  4. `Modern Kitchen` (22.1 m², Lantai 1, Pending Re-scan)
  *(Total Luas: 111.0 m²)*
- **8 Aset Realistis** dengan atribut lengkap (contoh: *Sony Bravia 65" OLED TV*, *Herman Miller Aeron Chair*, *MacBook Pro 16" M3 Max*, *B&O Beosound Balance Speaker*, *Natuzzi Leather Sectional Sofa*, *Breville Barista Touch Espresso*, *LG Dual Inverter Smart AC*, *Rolex / Safe Vault Box*), lengkap dengan nomor seri, tahun beli, harga perolehan, nilai valuasi saat ini, status garansi, dan status verifikasi (`Verified`, `Pending`, `Flagged`) agar seluruh KPI dan grafik langsung hidup saat pertama kali dibuka.

---

## 6. User Stories per Role

### 6.1 Role: Owner (Pemilik Properti)
- **US-OWN-01 (Layar 1):** Sebagai **Owner**, saya ingin masuk menggunakan akun saya atau memilih tombol Quick Switch "Owner" pada mode demo sehingga saya langsung mendapatkan akses penuh ke seluruh properti dan aset saya.
- **US-OWN-02 (Layar 2):** Sebagai **Owner**, saya ingin melihat Bento KPI (total nilai aset, luas terpindai, jumlah aset, status verifikasi) dan memutar model 3D ruangan di Home Dashboard sehingga saya tahu ringkasan kekayaan aset rumah dalam 1 pandangan.
- **US-OWN-03 (Layar 2):** Sebagai **Owner**, saya ingin memulai pemindaian ruangan LiDAR baru (atau simulasi scan) sehingga ruangan tambahan tercatat luasnya di denah 3D.
- **US-OWN-04 (Layar 3):** Sebagai **Owner**, saya ingin menambah, mengubah, dan menghapus item aset melalui Modal Bottom Sheet yang praktis sehingga inventaris saya selalu mutakhir.
- **US-OWN-05 (Layar 4):** Sebagai **Owner**, saya ingin melihat grafik valuasi per ruangan dan depresiasi nilai aset sehingga saya dapat memperkirakan cakupan polis asuransi rumah yang tepat.
- **US-OWN-06 (Layar 5):** Sebagai **Owner**, saya ingin mengekspor paket klaim asuransi berisi daftar aset terverifikasi dan rincian nilainya ke format JSON/CSV/PDF sehingga pengajuan klaim ke perusahaan asuransi cepat dan bebas penolakan data.

### 6.2 Role: Inspector / Appraiser (Surveyor & Penilai Asuransi)
- **US-INS-01 (Layar 1):** Sebagai **Inspector**, saya ingin beralih ke role Inspector dalam 1 klik atau login khusus penilai sehingga saya dapat melakukan audit tanpa mengubah kepemilikan data Owner.
- **US-INS-02 (Layar 2 & 3):** Sebagai **Inspector**, saya ingin meninjau aset yang berstatus `Pending` atau `Flagged`, memperbarui nilai taksiran (*Appraised Value*), menambahkan catatan inspeksi, dan mengubah statusnya menjadi `Verified` sehingga laporan valuasi sah untuk keperluan asuransi.
- **US-INS-03 (Layar 3):** Sebagai **Inspector**, saya ingin dicegah secara sistem dari aksi menghapus aset atau menghapus properti milik Owner sehingga integritas jejak audit tetap terjaga.
- **US-INS-04 (Layar 4 & 5):** Sebagai **Inspector**, saya ingin melihat rasio aset terverifikasi pada grafik analitik dan mengekspor laporan audit appraisal sehingga proses underwriting asuransi lebih akurat.

### 6.3 Role: Tenant / Viewer (Penyewa / Anggota Keluarga)
- **US-TEN-01 (Layar 1):** Sebagai **Tenant**, saya ingin masuk sebagai Tenant/Viewer sehingga saya dapat melihat daftar inventaris properti yang saya huni.
- **US-TEN-02 (Layar 2 & 4):** Sebagai **Tenant**, saya ingin melihat denah 3D ruangan dan daftar barang yang ada di rumah tanpa melihat harga beli, total valuasi kekayaan Owner, maupun nomor polis asuransi sehingga privasi finansial pemilik terlindungi.
- **US-TEN-03 (Layar 3):** Sebagai **Tenant**, saya ingin menambahkan catatan kondisi (*Condition Note*, mis. "AC kamar utama bocor") pada aset tertentu tanpa bisa menambah atau menghapus aset tersebut sehingga pemilik menerima laporan pemeliharaan dengan jelas.
- **US-TEN-04 (Layar 5):** Sebagai **Tenant**, saya ingin tombol Ekspor Klaim Asuransi dan Reset Sistem disembunyikan atau terkunci pada profil saya sehingga tidak ada ekspor dokumen sensitif tanpa izin.

---

## 7. Acceptance Criteria Terukur (Gherkin: Given / When / Then)

### 7.1 Layar 1: Login + Quick Role Switcher & Session Management
- **AC-L1-01 (Quick Role Switcher 1-Klik):**
  - **Given** pengguna berada di Layar 1 (Login) dalam mode demo/simulator
  - **When** pengguna menekan salah satu tombol Quick Role Switcher (`Owner`, `Inspector`, atau `Tenant`)
  - **Then** sesi aktif langsung dibuat dengan identitas & izin role terpilih dalam `< 300ms`, dan pengguna diarahkan ke Layar 2 dengan badge role terlihat jelas di header.
- **AC-L1-02 (Login Form & Validasi Error State):**
  - **Given** pengguna mengisi email dengan format tidak valid atau password kosong lalu menekan tombol `Masuk`
  - **When** validasi form dijalankan
  - **Then** sistem membatalkan login, menampilkan pesan error spesifik di bawah field terkait, dan tidak mengubah status sesi.
- **AC-L1-03 (Persistensi Sesi & Logout):**
  - **Given** pengguna sudah login sebagai `Inspector`
  - **When** pengguna me-refresh halaman/aplikasi
  - **Then** sesi `Inspector` tetap aktif pada tab terakhir atau Home Dashboard; dan ketika pengguna menekan `Logout` di Layar 5, sesi dihapus dan pengguna kembali ke Layar 1.

### 7.2 Layar 2: Home 3D Spatial Scan Dashboard + Bento KPI
- **AC-L2-01 (Akurasi Bento KPI terhadap Data):**
  - **Given** pengguna login sebagai `Owner` atau `Inspector` dengan 8 aset seed data (total luas 111.0 m²)
  - **When** Layar 2 dirender
  - **Then** Bento KPI menampilkan tepat: jumlah aset (`8`), total luas terpindai (`111.0 m²`), persentase terverifikasi sesuai jumlah status `Verified`, dan total valuasi yang sama persis dengan penjumlahan `currentValuation` seluruh aset.
- **AC-L2-02 (Privacy Masking untuk Role Tenant):**
  - **Given** pengguna login sebagai `Tenant / Viewer`
  - **When** Layar 2 dirender
  - **Then** kartu Bento Total Valuasi Finansial menampilkan status terkunci/tersamar (`Restricted / Hidden for Tenant`), sementara luas ruangan dan jumlah fisik aset tetap terlihat.
- **AC-L2-03 (Interaksi 3D Spatial Viewer & Scan Baru):**
  - **Given** pengguna berada di Layar 2 dan berinteraksi dengan kanvas 3D Spatial Viewer
  - **When** pengguna memutar/mengetuk salah satu ruangan (mis. `Living Room`) atau menekan `Start 3D LiDAR Scan` (sebagai `Owner`)
  - **Then** ruangan terpilih tersorot beserta daftar ringkas aset di dalamnya; atau saat scan diselesaikan, ruangan baru (atau pembaruan timestamp scan) tersimpan dan angka luas m² pada Bento KPI langsung bertambah.
- **AC-L2-04 (Empty State saat Belum Ada Ruangan/Aset):**
  - **Given** seluruh aset dan ruangan dikosongkan
  - **When** Layar 2 dibuka
  - **Then** sistem menampilkan *Empty State* ilustratif beserta CTA `"Mulai Scan Ruangan Pertama"` (untuk Owner) tanpa terjadi crash/NaN pada kalkulasi KPI (KPI bernilai `0`).

### 7.3 Layar 3: Asset Inventory CRUD + Modal Bottom Sheet
- **AC-L3-01 (Create Aset via Modal Bottom Sheet — Owner):**
  - **Given** pengguna login sebagai `Owner` dan berada di Layar 3
  - **When** pengguna menekan tombol `+ Tambah Aset`, mengisi nama aset, memilih ruangan, kategori, dan nilai valuasi valid pada Modal Bottom Sheet, lalu menekan `Simpan`
  - **Then** Modal Bottom Sheet menutup, aset baru muncul di daftar inventaris, bertahan setelah reload, dan total KPI di Layar 2 serta grafik di Layar 4 langsung terbarui.
- **AC-L3-02 (Validasi Input & Error State Modal Bottom Sheet):**
  - **Given** Modal Bottom Sheet dalam kondisi terbuka untuk input aset baru
  - **When** pengguna mengosongkan `Nama Aset` atau memasukkan nilai valuasi negatif (`-50000`) lalu menekan `Simpan`
  - **Then** penyimpanan ditolak, field bermasalah disorot merah dengan pesan error yang jelas, dan data daftar aset tidak berubah.
- **AC-L3-03 (Update & Inspection Verification — Inspector):**
  - **Given** pengguna login sebagai `Inspector` dan membuka detail aset berstatus `Pending` di Modal Bottom Sheet
  - **When** Inspector mengubah `Appraised Value`, mengisi catatan inspeksi, dan menekan `Verify Asset`
  - **Then** status aset berubah menjadi `Verified`, persentase terverifikasi di Bento KPI meningkat, dan tombol `Hapus Aset` tidak muncul/nonaktif untuk Inspector.
- **AC-L3-04 (Delete Aset dengan Konfirmasi — Owner):**
  - **Given** pengguna login sebagai `Owner` dan memilih aksi `Hapus` pada suatu aset
  - **When** pengguna mengonfirmasi dialog penghapusan
  - **Then** aset dihapus dari daftar secara permanen dan nilai total valuasi berkurang sesuai nilai aset tersebut; jika pengguna menekan `Batal`, aset tetap utuh.
- **AC-L3-05 (Search, Filter & Empty Search State):**
  - **Given** pengguna mengetik kata kunci yang tidak cocok dengan aset mana pun (mis. `"XYZ-999"`) pada kolom pencarian Layar 3
  - **When** daftar difilter
  - **Then** sistem menampilkan *Empty State* pencarian dengan pesan `"Tidak ada aset yang cocok"` dan tombol `"Reset Filter"`.

### 7.4 Layar 4: Spatial Analytics & Valuation Charts
- **AC-L4-01 (Render Grafik Konsisten dengan Data Inventaris):**
  - **Given** terdapat minimal 1 aset di inventaris dan pengguna membuka Layar 4 sebagai `Owner` atau `Inspector`
  - **When** grafik dimuat
  - **Then** sistem menampilkan grafik Valuasi per Ruangan, Distribusi Kategori, dan Perbandingan Nilai Beli vs Nilai Saat Ini yang angkanya 100% cocok dengan data aset aktif di Layar 3.
- **AC-L4-02 (Interaksi Filter / Tooltip Grafik):**
  - **Given** grafik Valuasi per Ruangan tampil di Layar 4
  - **When** pengguna mengetuk/hover salah satu bar/segmen ruangan atau mengganti filter kategori
  - **Then** tooltip/ringkasan menampilkan nilai nominal dan persentase kontribusi ruangan tersebut tanpa error JS.
- **AC-L4-03 (Restriksi Analitik Finansial untuk Tenant):**
  - **Given** pengguna login sebagai `Tenant / Viewer` dan membuka Layar 4
  - **When** halaman dirender
  - **Then** grafik nominal valuasi finansial disembunyikan/diganti banner akses terbatas, sedangkan statistik jumlah item per ruangan tetap dapat dilihat.

### 7.5 Layar 5: Profile + Sync & Export Settings
- **AC-L5-01 (Ekspor Paket Klaim Asuransi — Owner & Inspector):**
  - **Given** pengguna login sebagai `Owner` atau `Inspector` dan berada di Layar 5
  - **When** pengguna menekan tombol `Export Insurance Claim (JSON)` atau `Export CSV` atau `Preview Claim Report (PDF/Print)`
  - **Then** sistem menghasilkan file/preview valid yang memuat metadata properti, timestamp ekspor, daftar aset beserta serial number & status verifikasi, serta total nilai klaim yang terhitung akurat.
- **AC-L5-02 (Toggle Sync & Reset Demo Seed Data):**
  - **Given** pengguna mengubah status Auto-Sync atau telah memodifikasi data inventaris
  - **When** pengguna menekan `Reset Demo Data` dan mengonfirmasi
  - **Then** seluruh ruangan dan 8 aset kembali ke kondisi awal Seed Data Realistis dan status sinkronisasi kembali `Synced`.
- **AC-L5-03 (Akses Ditolak Ekspor Klaim untuk Tenant):**
  - **Given** pengguna login sebagai `Tenant / Viewer` di Layar 5
  - **When** melihat bagian Settings & Export
  - **Then** aksi Ekspor Klaim Asuransi dan Reset Demo Data dinonaktifkan/tersembunyi dengan label keterangan hak akses.

### 7.6 Interactive Mobile Simulator (`index.html`)
- **AC-SIM-01 (Viewport & Layout Komersial Mobile):**
  - **Given** `index.html` dibuka pada browser desktop maupun mobile viewport (`390×844px`)
  - **When** seluruh layar diinspeksi
  - **Then** tampilan berada rapi di dalam bingkai aplikasi mobile modern tanpa *horizontal overflow*, tab bar bawah selalu menempel (*sticky*), dan seluruh elemen interaktif memiliki ukuran sentuh memadai (`>= 44px`).
- **AC-SIM-02 (Zero Runtime Error & Role Switcher Instan):**
  - **Given** simulator dibuka dan pengguna menjalankan alur End-to-End di ketiga role (`Owner` -> Create/Edit/Export -> Switch ke `Inspector` -> Verify -> Switch ke `Tenant` -> Cek masking)
  - **When** browser console diperiksa
  - **Then** terdapat `0` uncaught exception / `console.error`, dan transisi antar-layar serta antar-role berlangsung tanpa perlu refresh manual.

### 7.7 Build Pipeline `.ipa` & `.apk`
- **AC-BLD-01 (Konfigurasi Pipeline & Keamanan Secret):**
  - **Given** repositori proyek memiliki konfigurasi build mobile untuk target Android (`.apk`) dan iOS (`.ipa`)
  - **When** skrip/pipeline build dan validator konfigurasi dijalankan
  - **Then** tidak ditemukan secret/signing password hardcoded di file repositori; seluruh variabel lingkungan divalidasi melalui `.env.example` / schema check.
- **AC-BLD-02 (Verifikasi Output / Dry-Run Pipeline `.apk` & `.ipa`):**
  - **Given** lingkungan build disiapkan (atau mode CI/Linux container untuk `.apk` & macOS runner/cloud build config untuk `.ipa`)
  - **When** perintah build / packaging dijalankan
  - **Then** pipeline menghasilkan artefak `.apk` terverifikasi (atau laporan validasi manifest/signing/dry-run build dengan exit code `0` beserta alasan platform spesifik jika macOS Xcode tidak tersedia di host Linux, tanpa memalsukan biner `.ipa`).

---

## 8. Traceability Matrix

| ID Fitur / MoSCoW | Functional Req | User Stories | Layar / Artefak Target | ID Acceptance Criteria |
| :--- | :--- | :--- | :--- | :--- |
| M-01 (Auth & Quick Switch) | FR-01, FR-05 | US-OWN-01, US-INS-01, US-TEN-01 | Layar 1 (`index.html` & App) | AC-L1-01, AC-L1-02, AC-L1-03 |
| M-02 (3D Dashboard & KPI) | FR-02, FR-03 | US-OWN-02, US-OWN-03, US-TEN-02 | Layar 2 | AC-L2-01, AC-L2-02, AC-L2-03, AC-L2-04 |
| M-03 (Asset CRUD Bottom Sheet) | FR-04, FR-05 | US-OWN-04, US-INS-02, US-INS-03, US-TEN-03 | Layar 3 | AC-L3-01 s.d. AC-L3-05 |
| M-04 (Spatial Analytics) | FR-06, FR-05 | US-OWN-05, US-INS-04, US-TEN-02 | Layar 4 | AC-L4-01, AC-L4-02, AC-L4-03 |
| M-05 (Profile, Sync & Export) | FR-07, FR-08 | US-OWN-06, US-INS-04, US-TEN-04 | Layar 5 | AC-L5-01, AC-L5-02, AC-L5-03 |
| M-06 & M-07 (Seed & Simulator) | FR-01..FR-08 | Semua Persona | `index.html` | AC-SIM-01, AC-SIM-02 |
| M-08 (Build `.ipa` / `.apk`) | Config & CI | Release Readiness | Pipeline Build & `.env.example` | AC-BLD-01, AC-BLD-02 |
