# Business Requirements Document (BRD) & Matriks RBAC
## Aplikasi: Spatial 3D Home & Asset Inventory (iOS & Android Cross-Platform + Mobile Simulator)

**Versi Dokumen:** 1.1  
**Tanggal:** 11 November 2026  
**Target Platform:** Mode 4 Mobile — Flutter Cross-Platform (`iOS .ipa` dengan Apple RoomPlan/LiDAR + `Android .apk` dengan ARCore fallback + *Interactive Mobile Simulator*)  
**Horizon Produk:** Era 2026–2030  
**Penyusun:** Business Analyst (`team-business-analyst`)  
**Dokumen Terkait:** `/home/devcurl/workspace-webui/spatial-3d-home/PRD_AC_SPEC.md` (selaras untuk Persona, 5-Screen Flow, & Acceptance Criteria)

---

## 0. Klasifikasi Informasi: FACT vs ASSUMPTION vs PROPOSAL

Sesuai standar tata kelola kebutuhan bisnis, seluruh poin dalam dokumen ini diklasifikasikan sebagai berikut:

| Kategori | Penjelasan & Cakupan | Status Persetujuan |
| :--- | :--- | :--- |
| **FACT** | Kebutuhan inti dari pemilik: aplikasi mobile iOS (`.ipa`) dan Android (`.apk`) + *Interactive Mobile Simulator* menggunakan Flutter untuk pemindaian ruangan 3D (memanfaatkan LiDAR/AR iPhone), pembuatan denah 3D ruangan, dokumentasi aset properti beserta nilai taksiran untuk kebutuhan asuransi, sewa, dan renovasi; dengan cakupan 3 role utama (`Homeowner/Owner`, `Insurance Appraiser/Inspector`, `Tenant/Buyer`) dan prioritas privasi *on-device*, enkripsi lokal, serta *offline-first sync*. | Terkonfirmasi dari brief pemilik |
| **ASSUMPTION** | 1. Perangkat iOS non-LiDAR dan Android menggunakan fallback ARKit/ARCore *depth estimation* atau input dimensi manual berbasis 3D *bounding box*.<br>2. Simulator interaktif memakai aset ruangan 3D *pre-baked* (glTF/USDZ mock) agar alur pemindaian, pin aset, dan ekspor PDF dapat diuji tanpa perangkat LiDAR fisik.<br>3. Penilaian depresiasi menggunakan rumus standar garis lurus (*straight-line*) atau persentase kondisi default sebelum divalidasi oleh *Appraiser*. | Perlu konfirmasi Owner/Architect |
| **PROPOSAL** | 1. Mekanisme *Quick Switch Role* pada mode Simulator/Demo untuk memudahkan presentasi B2C & B2B.<br>2. Penambahan *Cryptographic Hash / Timestamp Verification* pada PDF klaim asuransi & berita acara serah-terima sewa.<br>3. Redaksi otomatis (*auto-blur*) wajah/plat/dokumen sensitif secara *on-device* sebelum sinkronisasi atau ekspor. | Menunggu persetujuan Pemilik |

---

## 1. Ringkasan Eksekutif, Masalah Bisnis & Proposisi Nilai

### 1.1 Latar Belakang & Masalah Bisnis
Proses dokumentasi aset properti dan kondisi fisik ruangan saat ini masih terfragmentasi. Baik pemilik rumah individu maupun pelaku industri properti/asuransi menghadapi kendala struktural:
1. **Bukti Kepemilikan & Kondisi Tidak Terstruktur:** Foto barang, faktur pembelian, dan kartu garansi tersimpan terpisah di galeri ponsel, email, atau laci fisik tanpa konteks lokasi ruangan yang pasti.
2. **Sengketa Klaim Asuransi:** Saat terjadi kebakaran, banjir, atau pencurian, pemilik kesulitan membuktikan posisi eksak, spesifikasi, dan nilai wajar barang; sementara pihak asuransi memerlukan waktu lama untuk survei fisik dan verifikasi manual.
3. **Sengketa Serah-Terima Sewa (*Check-in / Check-out*):** Pemilik properti dan penyewa kerap berselisih mengenai kerusakan eksisting vs kerusakan baru karena foto 2D konvensional tidak merekam dimensi spasial dan kelengkapan seluruh sudut ruangan.
4. **Inakurasi Perencanaan Renovasi:** Kontraktor atau pemilik rumah harus mengukur ulang dimensi dinding, bukaan pintu/jendela, dan posisi furnitur eksisting secara manual.
5. **Risiko Privasi Cloud:** Banyak aplikasi inventaris mengunggah foto interior rumah dan video mentah ke cloud tanpa pemrosesan lokal, menimbulkan kekhawatiran kebocoran privasi hunian pribadi.

### 1.2 Proposisi Nilai (*Value Proposition*)

#### A. Segmen B2C — Pemilik Rumah (*Homeowner*) & Kolektor Aset
- **Digital Twin Hunian dalam Hitungan Menit:** Memindai ruangan menggunakan LiDAR/AR untuk menghasilkan denah 3D akurat tanpa meteran manual.
- **Katalog Aset Spasial (*3D Spatial Pinning*):** Setiap barang (elektronik, furnitur, karya seni, perhiasan, perkakas) ditambatkan langsung pada koordinat `(x, y, z)` di dalam model 3D ruangan, lengkap dengan foto, nomor seri, struk pembelian, dan tanggal kedaluwarsa garansi.
- **Kesiapan Klaim & Renovasi Sekali Klik:** Menghasilkan laporan valuasi total aset (harga beli vs nilai taksiran saat ini) dan peta dimensi ruangan siap pakai untuk klaim asuransi, kredit properti, atau RAB renovasi.
- **Privasi Total (*On-Device First*):** Video/point-cloud mentah ruangan diproses di perangkat dan tidak pernah keluar dari ponsel tanpa izin eksplisit pemilik.

#### B. Segmen B2B — Perusahaan Asuransi (*Appraiser/Adjuster*) & Agen/Manajer Properti
- **Audit Klaim Jarak Jauh & Terverifikasi:** Penilai asuransi menerima tautan aman atau paket laporan terverifikasi untuk meninjau aset 3D, membandingkan kondisi sebelum-sesudah kejadian, serta menyetujui atau menyesuaikan nilai taksiran secara teraudit.
- **Berita Acara Serah-Terima Sewa Digital:** Agen/pemilik dan penyewa meninjau kondisi awal unit dan daftar inventaris terpasang (*furnished inventory*) pada model 3D yang sama sebelum serah-terima kunci.
- **Efisiensi Biaya Survei:** Mengurangi kunjungan lapangan berulang (*re-inspection*) hingga >50% melalui dokumen PDF terstandar dan tautan berbagi berbatas waktu.

### 1.3 Indikator Keberhasilan Bisnis (KPI)

| ID KPI | Metrik | Target Keberhasilan (Fase Peluncuran & Adopsi) |
| :--- | :--- | :--- |
| **KPI-01** | Waktu pemindaian & generasi denah 3D per ruangan | ≤ 90 detik untuk ruangan ukuran standar (4x5 m) via iPhone LiDAR. |
| **KPI-02** | Waktu pencatatan 1 aset (Pin 3D + Foto + Estimasi Nilai) | ≤ 30 detik per item menggunakan template kategori & OCR struk lokal. |
| **KPI-03** | Ketersediaan fungsionalitas inti dalam mode offline | 100% fitur Scan, Asset CRUD, Kalkulasi Valuasi, dan Draft PDF berjalan tanpa koneksi internet. |
| **KPI-04** | Kecepatan ekspor Laporan PDF Klaim/Sewa | ≤ 5 detik untuk properti berisi hingga 100 aset beserta thumbnail & denah 3D. |
| **KPI-05** | Tingkat adopsi verifikasi B2B (Appraiser/Tenant Link) | ≥ 80% tautan berbagi dibuka dan diverifikasi tanpa perlu registrasi akun penuh bagi penerima tamu (*Guest/Tenant viewer*). |

---

## 2. Definisi Role & Matriks Hak Akses (RBAC Matrix)

### 2.1 Deskripsi Role Pengguna

1. **`Homeowner / Owner` (Pemilik Rumah / Pemilik Properti)**
   - **Peran Bisnis:** Pemilik utama akun dan pengelola tunggal hak kepemilikan data properti. Berwenang penuh memindai ruangan, mengelola seluruh aset, mengatur valuasi awal, mengonfigurasi server/enkripsi lokal, serta menerbitkan dan mencabut tautan berbagi untuk pihak ketiga.
2. **`Insurance Appraiser / Inspector` (Penilai Asuransi / Inspektor Properti — B2B)**
   - **Peran Bisnis:** Mitra eksternal terotorisasi (adjuster asuransi, surveyor, atau inspektor properti) yang diberi akses terbatas pada properti/klaim tertentu. Dapat meninjau model 3D, memverifikasi keberadaan & kondisi aset, menambahkan catatan audit/nilai taksiran resmi (*appraised value*), serta mengekspor PDF laporan inspeksi/klaim, **tanpa** hak menghapus aset milik Owner atau mengubah konfigurasi server milik Owner.
3. **`Tenant / Buyer` (atau `Tenant / Viewer` — Penyewa / Calon Pembeli / Anggota Keluarga)**
   - **Peran Bisnis:** Pihak penyewa saat serah-terima unit (*move-in / move-out*), anggota keluarga, atau calon pembeli properti yang diberi akses *read-mostly* melalui undangan atau *Share Link*. Hanya dapat melihat denah ruangan 3D, daftar inventaris properti yang diizinkan, mengekspor salinan serah-terima PDF (bila diizinkan Owner), dan mengajukan catatan kondisi/kerusakan (*Condition / Inspection Remark*) saat check-in/check-out — tidak dapat mengubah valuasi, menghapus aset, maupun mengakses pengaturan server.

> **PROPOSAL — Mekanisme `Quick Switch Role` (Mode Simulator / Demo):**  
> Pada *Interactive Mobile Simulator* dan mode demonstrasi, tersedia panel **Quick Switch Role** di pojok atas/pengaturan demo yang memungkinkan pengguna langsung berpindah perspektif antara `Homeowner/Owner`, `Insurance Appraiser/Inspector`, dan `Tenant/Buyer (Viewer)` tanpa logout berulang. Pada mode produksi (*production build*), fitur ini dinonaktifkan melalui flag `.env` (`ENABLE_DEMO_ROLE_SWITCHER=false`) dan penegakan otorisasi dilakukan ketat oleh *Role Guard* di client maupun server sync.

### 2.2 Matriks RBAC Lengkap per Modul & Aksi

Legenda Izin:
- **C** = Create (Buat baru)
- **R** = Read (Lihat / Baca)
- **U** = Update (Ubah / Sunting)
- **D** = Delete (Hapus)
- **X** = Execute / Trigger aksi khusus (Ekspor / Generate / Config)
- **—** = Tidak Diizinkan (*Forbidden / Hidden by Role Guard*)

| Modul & Fitur | `Homeowner / Owner` | `Insurance Appraiser / Inspector` | `Tenant / Buyer` | Aturan Guard & Pembatasan Scope |
| :--- | :--- | :--- | :--- | :--- |
| **1. Scan 3D Room** | | | | |
| - Pindai Ruangan Baru (LiDAR / AR / Simulator) | **C, R, U, D** | **R** *(Opsional: **C** hanya untuk scan verifikasi komparasi klaim jika diizinkan Owner)* | **R** *(View 3D Walkthrough)* | `Owner` memiliki kendali penuh mesh & dimensi. `Appraiser` & `Tenant` hanya dapat merotasi/zoom/ukur dimensi *read-only* pada model 3D yang dibagikan. |
| - Edit Denah, Label Ruangan & Dimensi | **U** | **—** | **—** | Perubahan geometri denah hanya oleh `Owner`. |
| - Hapus Scan Ruangan | **D** | **—** | **—** | Menghapus ruangan memicu peringatan jika masih ada aset tertaut. |
| **2. Asset CRUD** | | | | |
| - Tambah & Pin Aset ke Koordinat 3D `(x,y,z)` | **C** | **—** | **—** | Hanya `Owner` yang dapat mendaftarkan aset baru ke inventaris. |
| - Lihat Daftar Aset, Foto, Serial & Lokasi 3D | **R** *(Semua aset)* | **R** *(Aset dalam cakupan klaim/polis)* | **R** *(Hanya aset berlabel `Included in Lease/Sale`, aset privat disembunyikan)* | *Row-Level & Visibility Filter*: Aset privat/brankas bertanda `Private/Hidden` disembunyikan dari `Tenant/Buyer`. |
| - Ubah Metadata Aset (Nama, Kategori, Harga Beli, Garansi) | **U** | **—** | **—** | `Appraiser` tidak boleh mengubah klaim harga beli asli dari Owner. |
| - Verifikasi Kondisi, Catatan Inspeksi & Nilai Taksiran Resmi (*Appraised Value*) | **R** | **C, R, U** *(Pada field `Appraisal Note`, `Verified Status`, `Appraised Value`)* | **C** *(Terbatas pada `Tenant Check-in Remark` / lapor cacat kondisi)* | Perubahan nilai oleh `Appraiser` tercatat di *Audit Trail* (tidak menimpa `Purchase Price` asli). |
| - Hapus Aset | **D** | **—** | **—** | Penghapusan bersifat *soft-delete* terlebih dahulu (arsip 30 hari) untuk menjaga jejak audit jika pernah masuk laporan. |
| **3. Valuation Export PDF** | | | | |
| - Hitung & Lihat Ringkasan Valuasi Total Properti | **R** | **R** *(Sesuai scope properti ditugaskan)* | **—** *(Nilai taksiran asuransi disembunyikan dari Tenant/Buyer)* | `Tenant/Buyer` hanya melihat daftar kelengkapan barang & kondisi fisik, bukan nilai finansial/asuransi pemilik. |
| - Generate & Unduh PDF Laporan Klaim Asuransi | **X, R** | **X, R** *(Dengan stempel `Appraiser Verified`)* | **—** | PDF menyertakan denah 3D snapshot, tabel aset, timestamp, dan hash verifikasi. |
| - Generate & Unduh PDF Berita Acara Sewa / Properti | **X, R** | **R** | **X, R** *(Hanya daftar kondisi serah-terima unit)* | Dokumen sewa tidak memuat nominal nilai garansi/asuransi pribadi pemilik. |
| - Generate & Unduh Paket Dimensi Renovasi (PDF/Dimension Summary) | **X, R** | **—** | **R** *(Jika mode `Buyer` diaktifkan)* | Berisi ukuran dinding, luas lantai, dan daftar *fixed fixtures*. |
| **4. Share Link** | | | | |
| - Buat Tautan Berbagi (*Share Link*) Terenkripsi & Atur TTL / PIN | **C, R, U, D** | **—** | **—** | Hanya `Owner` yang dapat membuat, memperpanjang, atau mencabut (*revoke*) tautan. |
| - Akses Konten via Share Link (Read/Inspect) | **R** | **R** *(Scope Inspector)* | **R** *(Scope Tenant/Buyer)* | Tautan memiliki `scope_role`, `expires_at`, dan batas akses (PIN opsional). |
| - Revoke / Cabut Akses Share Link Seketika | **X (D)** | **—** | **—** | Pencabutan berlaku lokal & segera memblokir akses baru saat sinkronisasi. |
| **5. Server Config** | | | | |
| - Konfigurasi Endpoint Sync Server, Port & Mode Offline-Only | **R, U, X** | **—** | **—** | Halaman `Server Config` tersembunyi/terkunci (*403 Role Guard*) bagi `Appraiser` dan `Tenant/Buyer`. |
| - Pengaturan Enkripsi Lokal, Biometrik Lock & Rotasi Kunci | **R, U, X** | **R** *(Hanya kunci sesi lokal miliknya)* | **—** | Pengaturan enkripsi vault properti hanya dikendalikan `Owner`. |
| - Pengaturan Integrasi Webhook / API Asuransi B2B | **R, U, X** | **R** *(Read-only status koneksi B2B)* | **—** | `Owner` menentukan apakah data properti boleh disinkronkan ke server B2B. |
| **6. Auth, Audit & Demo Simulator** | | | | |
| - Login / Biometric Unlock / Manajemen Profil Sendiri | **C, R, U** | **C, R, U** | **C, R, U** | Semua role mengelola sesi lokal masing-masing. |
| - Lihat Audit Trail (Siapa mengakses/menilai/ekspor) | **R** *(Penuh)* | **R** *(Riwayat aksinya sendiri & riwayat klaim)* | **—** | Transparansi penuh bagi `Owner`. |
| - Quick Switch Role (Mode Simulator / Demo) | **X** *(Hanya aktif jika `DEMO_MODE=true`)* | **X** *(Hanya aktif jika `DEMO_MODE=true`)* | **X** *(Hanya aktif jika `DEMO_MODE=true`)* | Dinonaktifkan mutlak pada build produksi untuk mencegah privilege escalation. |

### 2.3 Matriks Akses Layar / Menu Aplikasi

| Nama Layar / Menu | `Homeowner / Owner` | `Insurance Appraiser / Inspector` | `Tenant / Buyer` |
| :--- | :---: | :---: | :---: |
| **Login & Biometric Gate** | Ya | Ya | Ya (atau *Magic/Share Link* + PIN) |
| **Dashboard Properti & Ringkasan Valuasi** | Ya (Penuh) | Ya (Hanya properti berstatus *Assigned Audit*) | Terbatas (Hanya ringkasan kamar & status unit) |
| **3D Room Scanner (LiDAR / AR / Simulator)** | Ya (Scan & Edit) | Tidak (Viewer 3D saja) | Tidak (Viewer 3D saja) |
| **3D Room & Spatial Asset Viewer** | Ya (Edit Pin & Aset) | Ya (Pin *Verification Badge* & Catatan) | Ya (View & Catatan Kondisi *Check-in*) |
| **Katalog Aset & Kalkulator Depresiasi/Garansi** | Ya (CRUD Penuh) | Ya (Baca & Edit *Appraised Value*) | Terbatas (Daftar barang sewa tanpa harga/garansi) |
| **Pusat Ekspor PDF & Share Link** | Ya (Generate, Share, Revoke) | Ya (Generate PDF Klaim saja) | Terbatas (Unduh PDF Serah-Terima saja) |
| **Audit Log & Riwayat Sinkronisasi** | Ya | Terbatas (Log inspeksi sendiri) | Tidak |
| **Server Config & Security Vault Settings** | Ya | Tidak (Disembunyikan) | Tidak (Disembunyikan) |

---

## 3. Alur Proses Bisnis: As-Is vs To-Be

### 3.1 Perbandingan Proses Bisnis As-Is vs To-Be

| Tahap Proses | Kondisi Saat Ini (*As-Is*) | Kondisi Target (*To-Be* dengan Aplikasi) | Dampak Bisnis |
| :--- | :--- | :--- | :--- |
| **1. Pemetaan Ruangan** | Menggunakan meteran fisik, sketsa kertas, atau puluhan foto 2D terpisah yang sulit dibayangkan dimensinya. | **Scan Ruangan 3D (< 90 detik):** iPhone LiDAR / AR menghasilkan model 3D & denah ruangan otomatis dengan ukuran panjang, lebar, tinggi, dan posisi pintu/jendela. | Eliminasi kesalahan ukur manual; siap pakai untuk klaim & renovasi. |
| **2. Pendataan Aset** | Mencatat di spreadsheet/catatan HP tanpa relasi posisi ruangan; struk kertas sering hilang atau pudar. | **Pin Aset 3D:** Pengguna mengetuk titik pada model 3D ruangan, mengambil foto aset & memindai struk/garansi secara lokal (OCR), otomatis tertaut ke koordinat `(x,y,z)`. | Bukti lokasi spasial & kepemilikan tidak terbantahkan. |
| **3. Estimasi Nilai & Garansi** | Menghitung nilai aset secara manual saat musibah sudah terjadi; tidak ada pengingat garansi habis. | **Kalkulator Valuasi & Garansi Otomatis:** Menghitung nilai perolehan vs nilai taksiran terkini (depresiasi per kategori/usia) serta notifikasi garansi lokal sebelum kedaluwarsa. | Kejelasan nilai pertanggungan asuransi & kontrol aset bernilai tinggi. |
| **4. Verifikasi & Ekspor Dokumen** | Mengirim folder ZIP berisi ratusan foto acak via email/WhatsApp ke adjuster asuransi atau penyewa. | **Ekspor PDF Terverifikasi & Share Link Aman:** Satu klik menghasilkan PDF berstruktur (denah 3D, daftar aset, nilai taksiran, hash integritas) atau mengirim *Share Link* khusus role (`Appraiser`/`Tenant`) dengan batas waktu. | Proses klaim & serah-terima sewa jauh lebih cepat dan minim sengketa. |

### 3.2 Alur Proses Bisnis End-to-End (*To-Be* Core Journey)

```
[1. Auth & Role Guard]
   ├── Owner Login (Email/Passkey + FaceID/Biometric Unlock Vault Lokal)
   └── Appraiser / Tenant Login (Akun Terundang / Share Link + PIN)
          │
          ▼
[2. Scan Ruangan 3D] (Owner)
   ├── Cek kapabilitas perangkat:
   │     ├── iPhone LiDAR -> Apple RoomPlan / ARKit LiDAR Scan
   │     ├── Non-LiDAR / Android -> ARCore Depth / Manual 3D Box Builder
   │     └── Interactive Simulator -> Load Pre-baked 3D Room Scene (glTF/USDZ)
   ├── Proses Point-Cloud & Mesh 100% On-Device (Auto-blur wajah/info sensitif opsional)
   └── Simpan Model 3D + Metadata Dimensi ke Local Encrypted DB (Offline-Ready)
          │
          ▼
[3. Pin Aset 3D] (Owner)
   ├── Buka 3D Room Viewer -> Tap titik koordinat (x, y, z) pada ruangan
   ├── Input Detail Aset: Nama, Kategori, Merk/Serial, Tag Visibilitas (Public/Lease/Private)
   ├── Lampirkan Foto Barang & Scan Struk/Kartu Garansi (OCR Lokal)
   └── Simpan Pin Aset -> Terikat ke Room ID & Koordinat 3D
          │
          ▼
[4. Estimasi Nilai & Garansi] (Owner -> Appraiser)
   ├── Sistem hitung Nilai Taksiran Saat Ini (Replacement Cost & Depreciated Value)
   ├── Sistem jadwalkan Pengingat Garansi Lokal (30 hari sebelum expired)
   └── (Opsional B2B) Owner bagikan ke Insurance Appraiser:
         └── Appraiser inspeksi 3D -> Beri Status "Verified" & Appraised Value -> Catat Audit Log
          │
          ▼
[5. Ekspor Klaim / Sewa / Renovasi & Sync]
   ├── Pilih Jenis Ekspor:
   │     ├── Paket Klaim Asuransi PDF (Owner / Appraiser) -> Lengkap dengan valuasi & hash
   │     ├── Paket Serah-Terima Sewa PDF (Owner / Tenant) -> Aset unit & catatan kondisi
   │     └── Paket Dimensi Renovasi PDF (Owner) -> Denah ukuran & fixed fixtures
   ├── Atau Terbitkan Share Link (Scope: Appraiser / Tenant, TTL: 24j–30h, PIN)
   └── Jika Offline -> Masuk Sync Queue; Jika Online -> Delta Sync Terenkripsi ke Server
```

### 3.3 Alur Autentikasi, Session & Role Guard
1. **Local-First Identity & Biometric Vault:**
   - Saat pertama kali menggunakan aplikasi, pengguna (`Owner`) dapat langsung membuat profil lokal (*offline onboarding*) atau masuk menggunakan akun terhubung.
   - Akses ke aplikasi setelah *idle* (> 5 menit) atau saat membuka modul sensitif (`Valuation`, `Server Config`, `Share Link`) wajib melewati **Biometric Gate** (Face ID / Touch ID / Android BiometricPrompt / PIN Lokal).
2. **Enforce Role Guard pada Setiap Rute & Aksi:**
   - Setiap navigasi menu dan pemanggilan layanan lokal/API menyertakan `active_role` dan `access_scope`.
   - Jika `Tenant/Buyer` mencoba memanggil endpoint/aksi `Server Config` atau `Delete Asset`, sistem langsung menolak (*Access Denied*) dan mencatat percobaan ke log keamanan lokal.
3. **Alur Quick Switch Role (Khusus Demo / Interactive Mobile Simulator):**
   - Tersedia hanya bila konfigurasi `ENABLE_DEMO_ROLE_SWITCHER=true`.
   - Memilih role pada switcher mengubah konteks sesi aktif ke profil simulasi (`demo_owner`, `demo_appraiser`, `demo_tenant`) secara instan dan me-render ulang UI sesuai Matriks RBAC tanpa menghapus data simulasi yang sudah dibuat.

---

## 4. Aturan Bisnis & Validasi Data

### 4.1 Aturan Valuasi, Depresiasi & Garansi
1. **Perhitungan Nilai Aset:**
   - Setiap aset memiliki dua metrik nilai utama:
     - `Purchase Price` / `Replacement Cost` (harga beli asli atau biaya penggantian barang baru setara).
     - `Estimated Current Value` (nilai taksiran saat ini setelah depresiasi).
   - **Rumus Depresiasi Default (ASSUMPTION — dapat disesuaikan oleh Owner/Appraiser):**
     $$\text{Estimated Value} = \max\left(\text{Purchase Price} \times \left(1 - r \times \frac{\text{Usia Bulan}}{12}\right),\ \text{Salvage Floor}\right)$$
     - Kategori Elektronik & Gadget: laju depresiasi default $r = 20\%$/tahun, batas bawah (*Salvage Floor*) $= 10\%$.
     - Kategori Furnitur & Peralatan Rumah Tangga: $r = 10\%$/tahun, *Salvage Floor* $= 20\%$.
     - Kategori Koleksi / Karya Seni / Perhiasan: $r = 0\%$ default (mendukung apresiasi/input manual berdasarkan *Appraised Value*).
   - Apabila `Insurance Appraiser` mengisi `Appraised Value`, maka nilai tersebut ditampilkan berdampingan sebagai **Nilai Taksiran Terverifikasi** tanpa menghapus harga beli asli yang diinput `Owner`.
2. **Validasi Garansi:**
   - `Warranty Expiry Date` tidak boleh lebih awal dari `Purchase Date`.
   - Status garansi dihitung otomatis: `Active` (sisa > 30 hari), `Expiring Soon` (sisa 1–30 hari), `Expired` (lewat tanggal), atau `No Warranty`.

### 4.2 Aturan Data Spasial, Aset & Visibility Scope
1. **Integritas Pin 3D:** Setiap aset wajib terhubung ke `room_id` yang valid; jika ruangan dihapus, Owner harus memilih untuk memindahkan aset ke ruangan lain (`Unassigned/Storage`) atau mengarsipkan aset.
2. **Tag Visibilitas Aset (`visibility_scope`):**
   - `ALL_AUTHORIZED`: Terlihat oleh Owner, Appraiser, dan Tenant/Buyer (contoh: AC, lemari built-in, kitchen set).
   - `INSURANCE_ONLY`: Terlihat oleh Owner dan Appraiser, **tersembunyi** dari Tenant/Buyer (contoh: TV pribadi, koleksi pribadi, perhiasan).
   - `OWNER_PRIVATE`: Hanya terlihat oleh Owner; tidak ikut diekspor dalam PDF maupun Share Link kecuali Owner secara eksplisit memilihnya saat membuat laporan klaim.
3. **Status Siklus Hidup Aset (`asset_status`):**
   - `DRAFT` -> `ACTIVE` -> `UNDER_INSPECTION` -> `VERIFIED` -> `CLAIMED` / `ARCHIVED`.
   - Aset berstatus `CLAIMED` atau pernah masuk ke laporan PDF terkunci tidak dapat dihapus permanen (*hard delete*), melainkan hanya diubah menjadi `ARCHIVED` untuk menjaga keutuhan audit asuransi.

### 4.3 Aturan Share Link & Ekspor PDF
1. **Validasi Share Link:**
   - Wajib menentukan `target_role` (`APPRAISER` atau `TENANT_BUYER`), daftar `room_ids` yang dibagikan, serta masa berlaku (`expires_at` minimal 1 jam, maksimal 90 hari).
   - Opsional namun direkomendasikan: proteksi PIN 6 digit dan watermark identitas penerima pada tampilan 3D/PDF.
2. **Validasi Ekspor PDF:**
   - Setiap PDF yang dihasilkan wajib menyertakan: ID Laporan Unik, Timestamp Pembuatan (UTC + Zona Waktu Lokal), Nama Properti, Denah/Tangkapan Layar 3D Ruangan, Tabel Rincian Aset sesuai scope role, dan **SHA-256 Document Integrity Hash** pada footer.

### 4.4 Penanganan Kondisi Tepi (*Edge Cases*)
- **Perangkat Tanpa LiDAR / Android / Simulator:** Aplikasi mendeteksi kapabilitas sensor saat startup. Jika LiDAR tidak tersedia, tombol *Scan 3D* otomatis beralih ke mode *AR Plane & Manual Dimension Builder* (Android/iPhone lama) atau *Interactive 3D Mock Scanner* (Simulator) tanpa error crash.
- **Ruangan Direnovasi (Scan Ulang):** Saat Owner memindai ulang ruangan yang sudah memiliki pin aset, sistem menyimpan versi denah baru (`room_version + 1`) dan menandai aset lama sebagai `Needs Re-pinning` hingga posisinya dikonfirmasi ulang pada denah terbaru.
- **Konflik Sinkronisasi Offline-First:** Jika Owner dan Appraiser menyunting aset yang sama secara offline pada perangkat berbeda, resolusi konflik menggunakan strategi **Field-Level Merge**: perubahan metadata pemilik (`Purchase Price`, `Foto`) dimenangkan oleh `Owner`, sedangkan field penilaian (`Appraised Value`, `Inspection Note`) dimenangkan oleh `Appraiser`, dengan seluruh riwayat tetap dicatat di log konflik.

---

## 5. Kebutuhan Non-Fungsional (Non-Functional Requirements / NFR)

| Kategori NFR | ID | Spesifikasi Kebutuhan Terukur |
| :--- | :--- | :--- |
| **Privasi On-Device** | **NFR-01** | **Zero Raw-Video Upload:** Seluruh pemrosesan *point-cloud*, rekonstruksi mesh ruangan 3D, dan OCR struk/garansi wajib berjalan 100% secara lokal di perangkat (*on-device*). Stream kamera/video mentah dilarang keras dikirim ke server eksternal. |
| **Privasi On-Device** | **NFR-02** | **PII & Sensitive Blur (PROPOSAL):** Foto aset yang diambil dari dalam aplikasi memiliki opsi deteksi wajah/dokumen identitas secara lokal untuk melakukan *auto-blur* sebelum disimpan ke paket ekspor atau sinkronisasi. |
| **Enkripsi Data Lokal** | **NFR-03** | **Database & Media Encryption at Rest:** Basis data lokal (SQLite/SQLCipher) serta file model 3D (`.usdz`/`.glb`) dan foto bukti terenkripsi menggunakan **AES-256-GCM / SQLCipher**. Kunci enkripsi disimpan di **Apple Secure Enclave / iOS Keychain** dan **Android Keystore** — tidak pernah disimpan dalam *plaintext*. |
| **Enkripsi Data Lokal** | **NFR-04** | **App Lock & Secure Wipe:** Akses aplikasi dilindungi Biometric Lock + Fallback PIN lokal. Setelah 10 kali kegagalan autentikasi berturut-turut (jika diaktifkan), tersedia opsi penghapusan kunci lokal atau penguncian sementara (*lockout*). |
| **Offline-First Sync** | **NFR-05** | **100% Offline Capability:** Pemindaian ruangan, navigasi 3D, tambah/edit/pin aset, kalkulasi valuasi, dan generasi PDF lokal wajib berfungsi penuh tanpa koneksi internet. |
| **Offline-First Sync** | **NFR-06** | **Resilient Delta Sync Queue:** Perubahan data saat offline disimpan dalam *outbox sync queue* lokal dengan mekanisme *idempotency key*, *exponential backoff retry*, dan kompresi aset media saat koneksi kembali stabil (Wi-Fi/Seluler sesuai preferensi pengguna di `Server Config`). |
| **Keamanan Transport** | **NFR-07** | **End-to-End & TLS 1.3:** Seluruh komunikasi sinkronisasi ke backend/relay server wajib menggunakan HTTPS/TLS 1.3; payload sensitif yang disinkronkan dapat dienkripsi *client-side* (*zero-knowledge option*) sehingga server hanya menyimpan blob terenkripsi. |
| **Kinerja & Ukuran** | **NFR-08** | **Efisiensi Storage & Rendering:** Ukuran rata-rata mesh 3D terkompresi per ruangan ≤ 15 MB; viewer 3D berjalan stabil pada minimal 30–60 FPS di perangkat target dan *Interactive Mobile Simulator*. |

---

## 6. Kebutuhan Konfigurasi, Variabel `.env` & Integrasi

Meskipun aplikasi berjalan *offline-first*, modul sinkronisasi opsional, *Share Link*, dan integrasi B2B memerlukan konfigurasi yang dapat dikelola melalui `.env` (build/runtime config) dan layar `Server Config` (khusus `Homeowner/Owner`).

### 6.1 Daftar Variabel Lingkungan (`.env` / App Config)

| Nama Variabel | Tipe / Contoh Nilai | Fungsi & Kebutuhan Bisnis |
| :--- | :--- | :--- |
| `APP_ENV` | `production` / `staging` / `demo` | Menentukan environment aktif untuk perilaku logging, keamanan, dan simulator. |
| `APP_BUNDLE_ID_IOS` | `com.spatial3dhome.app` | Identifier bundle aplikasi iOS untuk build `.ipa`, Apple RoomPlan, dan Keychain access group. |
| `APP_PACKAGE_ID_ANDROID` | `com.spatial3dhome.app` | Package ID aplikasi Android untuk build `.apk` dan ARCore/Keystore. |
| `ENABLE_DEMO_ROLE_SWITCHER` | `false` (prod) / `true` (demo/sim) | Mengaktifkan/menonaktifkan tombol **Quick Switch Role** pada UI. |
| `LIDAR_FALLBACK_SIMULATION` | `true` / `false` | Mengizinkan fallback simulasi/AR manual pada perangkat non-LiDAR dan *Interactive Mobile Simulator*. |
| `OFFLINE_ONLY_DEFAULT` | `true` / `false` | Menentukan apakah mode default adalah lokal penuh tanpa sinkronisasi cloud otomatis. |
| `API_BASE_URL` / `SYNC_SERVER_BASE_URL` | `https://sync.spatialhome.example/v1` | Endpoint server sinkronisasi delta untuk multi-device & Share Link (`local` pada mode simulator offline). |
| `SYNC_WIFI_ONLY_DEFAULT` | `true` | Mencegah pengunggahan model 3D/foto besar menggunakan kuota seluler tanpa izin. |
| `LOCAL_ENCRYPTION_ALGO` | `AES-256-GCM` | Standar algoritma enkripsi file media, model 3D, dan DB lokal. |
| `SHARE_LINK_BASE_URL` | `https://view.spatialhome.example/s` | Prefix URL untuk tautan berbagi ke `Appraiser` atau `Tenant/Buyer`. |
| `SHARE_LINK_DEFAULT_TTL_HOURS` | `72` | Masa berlaku default tautan berbagi (dalam jam) sebelum otomatis kedaluwarsa. |
| `PDF_HASH_SALT_MODE` | `SHA256-DEVICE-SIGN` | Metode penandatanganan integritas hash pada PDF Klaim/Sewa. |
| `B2B_INSURANCE_WEBHOOK_URL` | *(opsional)* `https://partner.insure/webhook` | Endpoint opsional bagi `Owner` untuk mengirim paket klaim terverifikasi ke mitra asuransi. |
| `MAX_ROOM_MESH_SIZE_MB` | `20` | Batas maksimum ukuran file mesh 3D terkompresi per ruangan untuk menjaga performa. |
| `DEFAULT_CURRENCY` | `IDR` / `USD` | Mata uang utama untuk input harga beli, depresiasi, dan laporan PDF valuasi. |

### 6.2 Layanan & Kemampuan Platform yang Dibutuhkan
- **iOS Native Bridge (Flutter Platform Channel):** Integrasi **Apple RoomPlan / ARKit** untuk perangkat ber-LiDAR (iPhone Pro/Pro Max & iPad Pro) dan **CoreML / Vision Framework** untuk OCR struk & blur PII *on-device*.
- **Android Native Bridge:** Integrasi **Google ARCore** (*Depth API* / *Sceneform* atau alternatif modern) serta ML Kit *on-device* untuk OCR lokal.
- **Interactive Mobile Simulator:** Renderer 3D ringan lintas platform (Web/Desktop Flutter) dengan paket ruangan 3D contoh (*mock studio/living room*) agar seluruh skenario bisnis dapat diuji secara interaktif.

---

## 7. Matriks Ketertelusuran (*Acceptance Criteria* Terukur)

Setiap aturan bisnis, RBAC, dan NFR di atas terhubung ke *Acceptance Criteria* (AC) berikut sebagai acuan desain arsitektur (`team-architect`), desain UI/UX (`team-ux-ui`), implementasi (`team-engineer`), dan pengujian (`team-qa`):

| ID AC | Referensi Aturan / Modul | Kriteria Penerimaan (*Acceptance Criteria*) yang Terukur |
| :--- | :--- | :--- |
| **AC-01** | RBAC — `Homeowner/Owner` | Role `Owner` dapat menjalankan 100% aksi: Scan/Buat Ruangan, CRUD + Pin Aset 3D, Generate PDF Klaim/Sewa/Renovasi, Buat/Cabut Share Link, dan Mengubah `Server Config`. |
| **AC-02** | RBAC — `Insurance Appraiser` | Role `Appraiser` dapat membuka ruangan & aset yang dibagikan, mengubah status verifikasi serta mengisi `Appraised Value` & `Inspection Note`, dan mengekspor PDF Klaim; namun **ditolak (403/Hidden)** saat mencoba menghapus aset, mengubah `Purchase Price`, membuat Share Link baru, atau membuka `Server Config`. |
| **AC-03** | RBAC — `Tenant/Buyer` | Role `Tenant/Buyer` hanya melihat model 3D dan aset dengan `visibility_scope = ALL_AUTHORIZED`; nominal valuasi/asuransi dan menu `Server Config` tidak tampil; hanya dapat mengunduh PDF Serah-Terima dan mengirim catatan kondisi (*Check-in Remark*). |
| **AC-04** | Quick Switch Role (Demo) | Saat `ENABLE_DEMO_ROLE_SWITCHER=true`, pengguna simulator dapat berpindah antara ketiga role dalam ≤ 2 ketukan dan seluruh visibilitas menu/aksi langsung berubah sesuai tabel RBAC Bab 2.2. Saat `false`, switcher tidak muncul di UI maupun kode rute. |
| **AC-05** | Alur Inti To-Be (Scan -> Pin -> Valuasi -> PDF) | Pengguna dapat menyelesaikan alur end-to-end (memuat/memindai 1 ruangan 3D, menambatkan min. 2 aset pada koordinat 3D, melihat nilai depresiasi otomatis, dan mengekspor 1 file PDF valid lengkap dengan hash SHA-256) dalam mode **Airplane Mode / Offline**. |
| **AC-06** | Privasi On-Device (NFR-01) | Inspeksi lalu lintas jaringan selama proses pemindaian ruangan dan OCR struk membuktikan **0 byte** video mentah atau stream kamera dikirim ke server eksternal. |
| **AC-07** | Enkripsi Data Lokal (NFR-03) | Inspeksi file penyimpanan lokal di perangkat membuktikan database inventaris dan cache media tidak terbaca sebagai *plaintext* (terenkripsi AES-256 / SQLCipher) dan kunci tidak tersimpan di file konfigurasi biasa. |
| **AC-08** | Offline-First Sync & Conflict (NFR-05, NFR-06, 4.4) | Perubahan aset yang dilakukan saat offline masuk ke `sync_queue`, tetap bertahan setelah aplikasi di-restart, dan otomatis tersinkronisasi tanpa duplikasi ketika koneksi kembali aktif; konflik antara edit `Owner` dan `Appraiser` terselesaikan via *Field-Level Merge*. |
| **AC-09** | Share Link Lifecycle | Tautan berbagi yang telah dicabut (*revoked*) atau melewati `expires_at` langsung menolak akses viewer dan menampilkan pesan kedaluwarsa yang jelas. |

---

## 8. Daftar Keputusan yang Memerlukan Persetujuan Pemilik (*Open Decisions*)

Sebelum tahap implementasi penuh oleh `team-architect` dan `team-engineer`, pemilik proyek dimohon mengonfirmasi 3 poin **ASSUMPTION / PROPOSAL** berikut:
1. **Kebijakan Depresiasi Default (Bab 4.1):** Apakah tarif depresiasi garis lurus default (Elektronik 20%/thn, Furnitur 10%/thn, Koleksi 0%) disetujui sebagai nilai awal aplikasi?
2. **Aktifnya Quick Switch Role di Simulator (Bab 2.1):** Apakah fitur *Quick Switch Role* disetujui untuk aktif pada *Interactive Mobile Simulator* dan dimatikan pada build produksi?
3. **Standar Auto-Blur PII On-Device (Bab 5 - NFR-02):** Apakah fitur *auto-blur* wajah/dokumen pada foto aset diaktifkan secara default atau sebagai toggle opsional?
