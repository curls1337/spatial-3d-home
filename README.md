# 🏠 Spatial 3D Home & Asset Inventory (iOS LiDAR + Android ARCore)

Aplikasi mobile lintas platform (**Flutter Cross-Platform** untuk iOS `.ipa` & Android `.apk` + **Interactive Web Simulator 3D**) untuk pemetaan ruangan 3D *on-device* menggunakan sensor **Apple RoomPlan / LiDAR** & **ARCore**, penambatan pin aset `(x, y, z)`, pelacakan garansi & depresiasi valuasi otomatis, serta ekspor dokumen bukti klaim asuransi / serah-terima sewa.

---

## ✨ Fitur Utama (Arsitektur 5 Layar Komersial)

1. **Layar Login + FaceID & Quick Role Switcher (RBAC)**
   - **Owner (`👑 Pemilik`):** Akses penuh CRUD ruangan & aset, kelola aset privat (*Vault*), konfigurasi server sync, dan ekspor paket klaim asuransi.
   - **Inspector (`🛡️ Surveyor Asuransi B2B`):** Verifikasi fisik, penetapan nilai taksir (*appraised value*), catatan audit, dan ekspor laporan tervalidasi SHA-256 (tanpa izin hapus).
   - **Tenant (`🏠 Penyewa / Pembeli`):** Akses baca denah 3D dan inventaris ruangan, pelaporan catatan kerusakan (*condition note*), dengan **Financial Masking** ketat (nilai uang dan aset privat disembunyikan).
2. **Home 3D Spatial Scan Dashboard**
   - Pemindaian ruangan *on-device* (*Zero Raw-Video Upload*) via `Apple RoomPlan` (iOS 16+/17+) dan fallback `ARCore` / *Guided 3D Builder* (Android).
   - Kanvas 3D Interaktif lengkap dengan toggle Wireframe, selector 4 ruangan (`111.0 m²`), Bento KPI 2×2, dan Live Activity feed.
3. **Asset Inventory CRUD + Modal Bottom Sheet**
   - Pencarian instan, filter per ruangan/kategori, manajemen garansi, dan formulir *Bottom Sheet* untuk tambah/edit aset serta verifikasi/catatan kondisi.
4. **Spatial Analytics & Valuation Charts**
   - Grafik valuasi aset per ruangan, estimasi depresiasi garis lurus (*straight-line depreciation*), dan indikator kesiapan klaim asuransi.
5. **Profile, Server Endpoint & Export SHA-256**
   - Pengaturan tema **OLED Luxury Dark** ↔ **Clean Alabaster Light**, endpoint sinkronisasi server opsional, serta ekspor laporan JSON/CSV/PDF.

---

## 📂 Struktur Proyek

```text
spatial-3d-home/
├── .github/workflows/build-mobile.yml   # GitHub Actions Cloud Build (.ipa & .apk -> Releases)
├── mobile/
│   ├── pubspec.yaml                     # Manifest Flutter & dependensi
│   ├── lib/                             # Seluruh kode UI & Clean Architecture (5 Layar)
│   ├── ios_bridge/AppDelegate.swift     # Native Apple RoomPlan LiDAR & Keychain Vault Bridge
│   ├── android_bridge/                  # Native Kotlin ARCore & Keystore Bridge
│   └── test/widget_test.dart            # Unit & RBAC tests
├── database/
│   ├── schema.sql                       # DDL PostgreSQL/Backend Sync
│   ├── schema_local_sqlite.sql          # Skema brankas lokal terenkripsi
│   └── seed.sql                         # Data awal Villa Kemang Selatan #14B
├── index.html & simulator_*.js          # Interactive 3D Mobile Simulator untuk browser
├── .env.example                         # Template konfigurasi environment aman
├── BRD_SPEC.md, PRD_AC_SPEC.md          # Spesifikasi Bisnis & Acceptance Criteria
└── ARCHITECTURE_SPEC.md, UI_SPEC.md     # Dokumen Arsitektur & Design System
```

---

## 🛠️ Cara Build `.ipa` (iOS) & `.apk` (Android) via GitHub Actions

Server Linux lokal tidak perlu menginstal Xcode atau Android SDK. Seluruh kompilasi berjalan otomatis di cloud runner GitHub Actions (`macos-latest` untuk `.ipa` dan `ubuntu-latest` untuk `.apk`):

1. Push repositori ini ke GitHub (`main` branch).
2. Buka tab **Actions** pada repo GitHub Anda — workflow **`Build Mobile App (iOS IPA & Android APK)`** akan berjalan otomatis (atau jalankan manual via **Run workflow**).
3. Setelah status build selesai (hijau), buka menu **Releases** di sisi kanan repo GitHub untuk mengunduh:
   - **`Spatial3DHome-v1.ipa`** → Install di iPhone via **GBox / ESign / AltStore / Sideloadly**.
   - **`Spatial3DHome-v1.apk`** → Install langsung di perangkat Android.

*(Catatan Penting Sideload iOS: Jika Anda mengupdate ke versi baru di kemudian hari, hapus terlebih dahulu aplikasi versi lama di Home Screen iPhone sebelum menginstal `.ipa` baru agar cache container tidak bentrok).*
