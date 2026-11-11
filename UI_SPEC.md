# UI/UX Design System & Commercial Specification (`UI_SPEC.md`)
## Proyek: Spatial 3D Home & Asset Inventory

- **Dokumen:** `UI_SPEC.md`
- **Versi:** 1.0.0
- **Tanggal:** 11 November 2026
- **Penyusun:** UX/UI & Art Direction (`team-ux-ui`)
- **Target Platform:** Cross-Platform Mobile App (Flutter — iOS `.ipa` Apple HIG 17+ & Android `.apk` Material Design 3) + Interactive Mobile Device Simulator (`index.html`)
- **Referensi Sumber:** `BRD_SPEC.md` (v1.1) & `PRD_AC_SPEC.md` (v1.0.0)
- **Workspace:** `/home/devcurl/workspace-webui/spatial-3d-home`

---

## 1. Design Brief (8 Unsur Wajib)

| Unsur | Spesifikasi Desain |
| :--- | :--- |
| **1. Konteks** | Aplikasi inventaris properti spasial 3D berbasis LiDAR/AR *on-device* (B2C & B2B) untuk pemetaan ruangan otomatis, penambatan pin aset `(x, y, z)`, pelacakan garansi & depresiasi valuasi, serta ekspor bukti klaim asuransi / serah-terima sewa terverifikasi dengan *offline-first sync*. |
| **2. Target Pengguna** | 3 Persona dengan RBAC ketat: (1) **Owner** (Pemilik Rumah/Properti — *full CRUD*, scan, server config, share/export), (2) **Inspector / Appraiser** (Surveyor Asuransi B2B — audit 3D, verifikasi kondisi, *appraised value*, ekspor klaim), (3) **Tenant / Buyer** (Penyewa/Calon Pembeli — *read-only* 3D, catatan kerusakan, *financial masking*). |
| **3. Vibe & Estetika** | **Spatial Precision Meets Luxury Asset Vault.** Futuristik namun tepercaya layaknya instrumen arsitektur/LiDAR (Apple RoomPlan, VisionOS HUD) yang dipadukan dengan kejelasan finansial fintech modern (*bento metrics*, angka *tabular*). |
| **4. Referensi (Inspirasi)** | *Apple Measure / RoomPlan* (overlay mesh & garis dimensi presisi), *Linear / Raycast* (surface gelap obsidian berbatas `1px` tajam), *Revolut / Wealthfront* (keterbacaan valuasi & grafik depresiasi), *Apple Wallet / Home* (kartu bento & *floating blur tab bar*). *Catatan: Murni inspirasi pola interaksi/hierarki, bebas salinan aset/branding.* |
| **5. Warna** | **Default: OLED Luxury Dark** (`#090D16` Deep Obsidian, `#111827` Card) dengan aksen **Emerald-Cyan LiDAR** (`#06B6D4` → `#10B981`) dan **Gold Valuation** (`#F59E0B`). **Opsional Toggle: Clean Alabaster Light** (`#F8FAFC` / `#FFFFFF`) untuk kondisi luar ruang/audit siang hari. |
| **6. Tipografi** | **UI Sans:** `SF Pro Display / SF Pro Text` (iOS), `Plus Jakarta Sans / Inter` (Android & Web Simulator). **Monospace & Angka Presisi:** `SF Mono / JetBrains Mono` untuk koordinat 3D `(x, y, z)`, nomor seri, tanggal garansi, nilai mata uang (`font-variant-numeric: tabular-nums`), dan hash SHA-256. |
| **7. Struktur** | Arsitektur **5 Layar Komersial** (*Layar 1: Login/Biometric + Quick Role Switcher*, lalu *Main Shell* dengan **Floating Blur Bottom Tab Bar 4-Tab**: *2. Home 3D Spatial Dashboard*, *3. Asset Inventory CRUD + Bottom Sheet*, *4. Spatial Analytics & Charts*, *5. Profile, Server Config & Export*) dibungkus di dalam **Interactive Mobile Device Simulator** (`iPhone 15 Pro` ↔ `Android Modern`). |
| **8. Hal yang Dihindari** | **DILARANG:** UI 1 layar polos (*single-screen dummy*), komponen XML/AppCompat 2014 kaku, form panjang tanpa *Modal Bottom Sheet*, tombol mati/state kosong tanpa feedback, menyembunyikan angka finansial hanya dengan warna tanpa label teks, dan kebocoran data valuasi pada role `Tenant`. |

---

## 2. Design Tokens Lengkap

### 2.1 Color Tokens — Dual Theme Architecture

#### A. Tema 1: OLED Luxury Dark *(Default)*
| Token Name | Hex / Value | Peran & Penggunaan | Kontras Minimum vs Background |
| :--- | :--- | :--- | :--- |
| `--bg-canvas` | `#090D16` | Latar belakang utama layar (*Deep Obsidian*) | Base |
| `--bg-surface` | `#111827` | Kartu Bento KPI, Asset Card, Chart Container | `border: 1px solid rgba(255,255,255,0.08)` |
| `--bg-elevated` | `#1E293B` | Modal Bottom Sheet, Dropdown, Hover/Pressed Card | `border: 1px solid rgba(255,255,255,0.12)` |
| `--bg-glass` | `rgba(17, 24, 39, 0.78)` | *Floating Blur Bottom Tab Bar*, `UxGlassHudCallout` di atas 3D Canvas (`backdrop-filter: blur(40px) saturate(220%)`, `border-top: 0.5px solid rgba(255,255,255,0.22)`, `inset 0 1px 1px 0 rgba(255,255,255,0.35)`) | - |
| `--bg-3d-viewport` | `radial-gradient(circle at 50% 35%, #0F1E2E 0%, #060A12 100%)` | Kanvas *3D LiDAR Spatial Viewer* dengan grid presisi `#06B6D4` opacity `12%` | - |
| `--accent-lidar-cyan` | `#06B6D4` | Wireframe mesh LiDAR, garis dimensi, pin ruangan aktif, CTA sekunder | `8.00:1` vs `#090D16` |
| `--accent-lidar-emerald` | `#10B981` | Sweep laser scan, status `Verified`, tren positif (`+14.5% ▲`), koneksi `Synced` | `7.66:1` vs `#090D16` |
| `--accent-lidar-gradient` | `linear-gradient(135deg, #06B6D4 0%, #10B981 100%)` | Tombol CTA primer (*Mulai Scan LiDAR*, *Simpan Aset*, *FAB +*), *Active Tab Indicator* | Text tombol `#041218` (`7.49:1–7.83:1`) |
| `--accent-gold` | `#F59E0B` | **Gold Valuation**: Sorotan nominal total valuasi, badge `Appraised Value`, status `Expiring Soon` / `Pending` | `9.05:1` vs `#090D16` |
| `--accent-gold-soft` | `rgba(245, 158, 11, 0.14)` | Latar pill badge valuasi & status `Pending` | Border `rgba(245,158,11,0.35)` |
| `--status-danger` | `#EF4444` | Status `Flagged` / `Expired` / `Damaged`, error input form, tombol *Hapus* | `4.71:1` vs `#111827` |
| `--status-info` | `#38BDF8` | Badge `Owner` / pin aset kategori elektronik | `8.8:1` vs `#111827` |
| `--text-primary` | `#F8FAFC` | Judul layar, nilai KPI utama, nama aset | `18.57:1` vs `#090D16` |
| `--text-secondary` | `#94A3B8` | Subtitle, label metrik, deskripsi ruangan, placeholder input | `7.58:1` vs `#090D16` (`6.92:1` vs `#111827`) |
| `--text-disabled` | `#64748B` | Khusus state `disabled` / garis pembatas non-teks (dilarang untuk teks aktif kecil) | Non-active UI only |
| `--border-subtle` | `rgba(255, 255, 255, 0.08)` | Garis pemisah kartu & input | - |
| `--border-focus` | `#06B6D4` | *Focus ring* keyboard/input (`2px solid #06B6D4`, `outline-offset: 2px`) | - |

#### B. Tema 2: Clean Alabaster Light *(Toggleable via Layar 5 & Simulator Bar)*
| Token Name | Hex / Value | Peran & Penggunaan | Kontras Minimum |
| :--- | :--- | :--- | :--- |
| `--bg-canvas` | `#F8FAFC` | Latar belakang utama layar (*Cool Alabaster*) | Base |
| `--bg-surface` | `#FFFFFF` | Kartu Bento KPI, Asset Card (`box-shadow: 0 8px 24px rgba(15, 23, 42, 0.05)`) | `border: 1px solid #E2E8F0` |
| `--bg-elevated` | `#F1F5F9` | Modal Bottom Sheet inner group, input field background | `border: 1px solid #CBD5E1` |
| `--bg-glass` | `rgba(255, 255, 255, 0.85)` | *Floating Blur Bottom Tab Bar* & HUD pill | `backdrop-filter: blur(20px)` |
| `--bg-3d-viewport` | `radial-gradient(circle at 50% 35%, #E0F2FE 0%, #EFF6FF 65%, #E2E8F0 100%)` | Kanvas *3D Spatial Viewer* mode terang (grid `#0284C7` opacity `14%`) | - |
| `--accent-lidar-cyan` | `#0E7490` | Deep Cyan 700 untuk kontras tinggi di atas `#FFFFFF` | `5.36:1` vs `#FFFFFF` |
| `--accent-lidar-emerald` | `#047857` | Deep Emerald 700 untuk badge `Verified` & tren positif | `5.48:1` vs `#FFFFFF` |
| `--accent-lidar-gradient` | `linear-gradient(135deg, #0E7490 0%, #047857 100%)` | Tombol CTA primer (teks putih `#FFFFFF`, kontras `5.36:1–5.48:1`) | `>= 5.36:1` vs `#FFFFFF` |
| `--accent-gold` | `#B45309` | Rich Amber/Gold untuk nominal & badge `Pending` di mode terang | `5.02:1` vs `#FFFFFF` |
| `--status-danger` | `#DC2626` | Error validasi, status `Flagged`, tombol destructive | `4.83:1` vs `#FFFFFF` |
| `--text-primary` | `#0F172A` | Judul, KPI, nama aset (*Slate 900*) | `17.1:1` vs `#F8FAFC` |
| `--text-secondary` | `#475569` | Subjudul, metadata (*Slate 600*) | `7.2:1` vs `#FFFFFF` |
| `--border-subtle` | `#E2E8F0` | Garis tepi kartu | - |

#### C. Semantic Role Badge Tokens
| Role | Badge Background (Dark / Light) | Badge Text (Dark / Light) | Ikon |
| :--- | :--- | :--- | :--- |
| **Owner** | `rgba(6, 182, 212, 0.16)` / `#ECFEFF` | `#22D3EE` / `#0E7490` | Key / Crown Shield |
| **Inspector / Appraiser** | `rgba(245, 158, 11, 0.16)` / `#FFFBEB` | `#FBBF24` / `#B45309` | Magnifier / Verified Seal |
| **Tenant / Viewer** | `rgba(148, 163, 184, 0.16)` / `#F1F5F9` | `#CBD5E1` / `#475569` | Eye / Home User |

---

### 2.2 Typography Scale & Rules

- **Font Stack:**
  - **Display & Body:** `-apple-system, BlinkMacSystemFont, "SF Pro Display", "Plus Jakarta Sans", "Inter", system-ui, sans-serif`
  - **Mono (Spatial/Serial/Currency/Hash):** `"SF Mono", "JetBrains Mono", ui-monospace, monospace`
- **Numerik Wajib:** Seluruh harga, luas (`m²`), persentase, dan timestamp menggunakan `font-variant-numeric: tabular-nums;` agar kolom angka sejajar presisi dan tidak bergeser saat state berubah.

| Token | Size / Line-Height | Weight | Tracking | Penggunaan |
| :--- | :--- | :--- | :--- | :--- |
| `type-hero-kpi` | `26px / 32px` | `700 (Bold)` | `-0.03em` | Total Valuasi Properti (Layar 2 Hero / Bento) |
| `type-screen-title` | `22px / 28px` | `700 (Bold)` | `-0.02em` | Judul Halaman Utama & Login Header |
| `type-section-title` | `16px / 22px` | `600 (SemiBold)` | `-0.01em` | Header Section (*Bento KPI*, *Asset List*, *Charts*) |
| `type-card-title` | `15px / 20px` | `600 (SemiBold)` | `-0.01em` | Nama Aset, Nama Ruangan 3D |
| `type-body` | `14px / 20px` | `400 (Regular)` | `0em` | Deskripsi, Catatan Inspeksi, Form Input |
| `type-caption` | `12px / 16px` | `500 (Medium)` | `0.01em` | Label Chip, Subtitle Ruangan, Badge Status |
| `type-micro-mono` | `11px / 14px` | `600 (SemiBold)` | `0.03em` | Koordinat `(x:2.4, y:0.8, z:1.2)`, Serial Number, Hash SHA-256 |

---

### 2.3 Spacing, Radii, Elevation & Safe Area Tokens

| Kategori | Token | Nilai | Catatan Penerapan |
| :--- | :--- | :--- | :--- |
| **Spacing** | `space-xs / sm / md / lg / xl` | `4px / 8px / 12px / 16px / 24px` | Padding layar horizontal wajib `16px`; gap Bento Grid `12px`; gap antar section `20px` |
| **Radius** | `radius-card-hero` | `24px` | *3D Spatial Viewer*, *Hero Summary Card*, *Modal Bottom Sheet top corners* (`24px 24px 0 0`) |
| **Radius** | `radius-card` | `20px` | Kartu *Bento KPI 2x2*, *Asset Card*, *Chart Card* (continuous squircle) |
| **Radius** | `radius-control` | `14px` | Input field, tombol utama, kartu *Quick Role Switcher* |
| **Radius** | `radius-pill` | `999px` | Filter chips, status badges, *Floating Blur Bottom Tab Bar* |
| **Touch Target** | `min-tap-size` | `44×44pt` (iOS) / `48×48dp` (Android) | Seluruh tombol, chip filter, pin 3D hit-box, dan tab item |
| **Safe Area iOS** | `safe-top / safe-bottom` | `59px` (Dynamic Island) / `34px` (Home Bar) | Header tidak boleh menabrak Dynamic Island; konten scroll diberi `padding-bottom: 108px` agar tidak tertutup *Floating Tab Bar* |
| **Safe Area Android** | `safe-top / safe-bottom` | `36px` (Punch-hole Status Bar) / `24px` (Gesture Nav) | Adaptif otomatis saat toggle frame ke *Android Modern* |

### 2.4 Motion & Haptic Feedback Map

- **Tab Switching:** Spring fade + subtle horizontal slide (`140ms`, `cubic-bezier(0.22, 1, 0.36, 1)`) + `HapticFeedback.selectionClick()`.
- **Modal Bottom Sheet:** Spring slide-up dari bawah (`260ms`, `damping: 0.85`), backdrop dim `rgba(0,0,0,0.55)` + `HapticFeedback.lightImpact()`.
- **3D Pin Tap / LiDAR Scan Pulse:** Ripple cincin cyan-emerald (`1.2s ease-out infinite`) pada pin ruangan/aset aktif + `HapticFeedback.mediumImpact()` saat scan selesai atau aset tersimpan.
- **Reduced Motion:** Jika `prefers-reduced-motion: reduce`, nonaktifkan pulse/sweep animasi dan gunakan transisi opacity instan (`80ms`).

---

## 3. Arsitektur Navigasi & Seed Data Baseline

### 3.1 Struktur 5 Layar Komersial & Role Guard
```
[Layar 1: Login + Biometric Gate + Quick Role Switcher]
   ├── Auth Sukses / Quick Switch Role (Owner | Inspector | Tenant)
   ▼
[Main App Shell — Persistent Floating Blur Bottom Tab Bar]
   ├── Tab 1: Layar 2 — Home 3D Spatial Dashboard
   │            ├── Interaksi Ruangan 3D -> Deep-link ke Tab 2 (Filtered by Room)
   │            └── CTA "Scan LiDAR" (Owner/Inspector) -> Modal Simulasi Scan 3D
   ├── Tab 2: Layar 3 — Asset Inventory CRUD
   │            ├── Search + Filter Chips (Room, Category, Status)
   │            └── FAB "+" (Owner) / Tap Card -> Modal Bottom Sheet (Create/Edit/Verify/Note)
   ├── Tab 3: Layar 4 — Spatial Analytics & Valuation Charts
   │            └── 3 Chart Interaktif + Audit Timeline (Tenant: Financial Masking)
   └── Tab 4: Layar 5 — Profile, Role Switcher, Theme, Server Config & Export
                ├── Export Center (PDF/CSV/JSON + Share Link — Locked for Tenant)
                ├── Server Endpoint & Vault Security (Owner Only — Hidden/403 for others)
                └── Logout -> Kembali ke Layar 1
```

### 3.2 Seed Data Baseline (`Villa Kemang Selatan #14B`)
Seluruh UI wireframe, angka KPI, chart, dan simulator wajib mengacu pada baseline data realistis berikut (total luas `111.0 m²`, 4 ruangan, 8 aset):

- **Properti:** `Villa Kemang Selatan #14B` (Jakarta Selatan — Status: `Offline-First Vault Encrypted AES-256`)
- **4 Ruangan 3D:**
  1. `Living Room` — `42.5 m²` | Lantai 1 | `Scan Verified` (`6.8m × 6.25m × 3.2m`)
  2. `Home Office / Studio` — `18.0 m²` | Lantai 1 | `Scan Verified` (`4.5m × 4.0m × 3.0m`)
  3. `Master Bedroom` — `28.4 m²` | Lantai 2 | `Scan Verified` (`5.9m × 4.8m × 3.0m`)
  4. `Modern Kitchen` — `22.1 m²` | Lantai 1 | `Pending Re-scan` (`5.2m × 4.25m × 3.0m`)
- **8 Aset Realistis (dengan Koordinat 3D & Tag Visibilitas):**
  1. `Sony Bravia 65" OLED TV` (`Living Room`, Elektronik, Beli `Rp 34.000.000`, Saat ini `Rp 27.200.000`, Garansi `Active`, Status `Verified`, Visibilitas `INSURANCE_ONLY`, Pin `x:1.2, y:1.1, z:0.3`)
  2. `Natuzzi Leather Sectional Sofa` (`Living Room`, Furnitur, Beli `Rp 48.000.000`, Saat ini `Rp 43.200.000`, Garansi `Expired`, Status `Verified`, Visibilitas `ALL_AUTHORIZED`, Pin `x:3.1, y:0.5, z:2.4`)
  3. `B&O Beosound Balance Speaker` (`Living Room`, Elektronik, Beli `Rp 42.500.000`, Saat ini `Rp 36.125.000`, Garansi `Expiring Soon` 18 hari, Status `Pending`, Visibilitas `INSURANCE_ONLY`, Pin `x:4.8, y:0.9, z:1.1`)
  4. `MacBook Pro 16" M3 Max` (`Home Office / Studio`, Elektronik, Beli `Rp 64.000.000`, Saat ini `Rp 51.200.000`, Garansi `Active`, Status `Verified`, Visibilitas `INSURANCE_ONLY`, Pin `x:2.0, y:0.8, z:1.5`)
  5. `Herman Miller Aeron Chair` (`Home Office / Studio`, Furnitur, Beli `Rp 26.000.000`, Saat ini `Rp 23.400.000`, Garansi `Active`, Status `Verified`, Visibilitas `ALL_AUTHORIZED`, Pin `x:2.1, y:0.5, z:2.2`)
  6. `LG Dual Inverter Smart AC` (`Master Bedroom`, Elektronik/Fixture, Beli `Rp 11.500.000`, Saat ini `Rp 9.200.000`, Garansi `Active`, Status `Flagged` — catatan kebocoran ringan, Visibilitas `ALL_AUTHORIZED`, Pin `x:2.8, y:2.4, z:0.2`)
  7. `Rolex Submariner / Safe Vault Box` (`Master Bedroom`, Koleksi/Perhiasan, Beli `Rp 185.000.000`, Saat ini `Rp 195.000.000`, Garansi `No Warranty`, Status `Verified`, Visibilitas `OWNER_PRIVATE`, Pin `x:0.7, y:0.4, z:3.9`)
  8. `Breville Barista Touch Espresso` (`Modern Kitchen`, Elektronik, Beli `Rp 22.000.000`, Saat ini `Rp 17.600.000`, Garansi `Expiring Soon` 12 hari, Status `Pending`, Visibilitas `ALL_AUTHORIZED`, Pin `x:3.6, y:0.9, z:0.6`)

*(Ringkasan KPI Kalkulasi Real-Time untuk Owner/Inspector dari 8 aset seed: Total Beli `Rp 433.000.000`, Total Valuasi Saat Ini `Rp 402.925.000`, Jumlah Aset `8`, Luas Terpindai `111.0 m²`, Verified `5/8 = 62.5%` — Untuk Tenant: hanya melihat 4 aset `ALL_AUTHORIZED` tanpa angka nominal).*

---

## 4. Spesifikasi Detail 5 Layar Komersial

### 4.1 Layar 1 — Login, Biometric FaceID/Passkey Mock & Quick Role Switcher

#### A. Tujuan & Hierarki Informasi
Gerbang keamanan *Local-First Encrypted Vault* yang profesional sekaligus menyediakan akses demonstrasi 1-klik (`Quick Role Switcher`) ketika `ENABLE_DEMO_ROLE_SWITCHER=true`.

#### B. Layout Wireframe Teks (Mobile `390×844px`)
```
┌─────────────────────────────────────────┐  <- Safe Area Top (59px iOS / 36px Android)
│  [Dynamic Island / Status Bar 09:41]    │
│                                         │
│     ╭─────────────────────────────╮     │
│     │  [3D Cube Wireframe Icon]   │     │  <- Emerald-Cyan Glow Ring
│     │  SPATIAL 3D HOME            │     │
│     │  LiDAR Property & Asset Vault│    │
│     ╰─────────────────────────────╯     │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ 🔐 AES-256 On-Device Vault Active │  │  <- Privacy Assurance Pill
│  └───────────────────────────────────┘  │
│                                         │
│  Email / ID Properti                    │
│  ┌───────────────────────────────────┐  │
│  │ owner@spatial3dhome.id            │  │  <- Height 48px, Radius 14px
│  └───────────────────────────────────┘  │
│  PIN / Passphrase                       │
│  ┌───────────────────────────────────┐  │
│  │ ••••••••                     [👁️] │  │  <- Toggle Show/Hide Password
│  └───────────────────────────────────┘  │
│  [Error banner inline bila invalid]     │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │     Masuk ke Vault Properti       │  │  <- Primary CTA (Cyan->Emerald)
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │ [FaceID] Buka dengan FaceID/Passkey│ │  <- Biometric Mock Trigger
│  └───────────────────────────────────┘  │
│                                         │
│  ─── QUICK ROLE SWITCHER (DEMO MODE) ── │  <- Tampil hanya jika DEMO=true
│  ┌───────────┐ ┌───────────┐ ┌────────┐ │
│  │ 👑 Owner  │ │ 🛡️ Inspector│ │ 👁️ Tenant│ │ <- 1-Klik Login Instan (<300ms)
│  │ Full CRUD │ │ Audit/App │ │ View   │ │
│  └───────────┘ └───────────┘ └────────┘ │
│                                         │
│  v1.0.0 • Offline-First Ready           │
└─────────────────────────────────────────┘  <- Safe Area Bottom (34px)
```

#### C. Interaksi, Komponen & State Matrix
1. **Biometric FaceID / Passkey Mock:** Menekan tombol Biometric memunculkan *Glass Overlay Sheet* animasi ring cyan (`"Memverifikasi FaceID / Secure Enclave..."` selama `600ms`), lalu otomatis masuk sebagai `Owner` (atau role terakhir yang dipilih).
2. **Quick Role Switcher (AC-L1-01 / AC-04):**
   - **Mode Demo/Simulator (`ENABLE_DEMO_ROLE_SWITCHER=true`):** 3 kartu pill interaktif (`Owner`, `Inspector`, `Tenant`). 1 ketukan langsung menyuntikkan session state role terkait dan berpindah ke Layar 2 dalam `< 300ms`.
   - **Mode Produksi (`false`):** Seluruh blok Quick Role Switcher tidak di-render sama sekali.
3. **States:**
   - **Validation Error (AC-L1-02):** Email tidak berformat valid atau password kosong -> Border input berubah `#EF4444` (`1.5px`), pesan error eksplisit muncul tepat di bawah field (`"Masukkan alamat email yang valid"` / `"PIN atau password wajib diisi"`), fokus keyboard diarahkan ke field error pertama.
   - **Biometric Failed / Fallback:** Menampilkan opsi *"Gunakan PIN Lokal"* setelah gagal verifikasi.
   - **Loading:** Tombol utama menampilkan spinner `18px` + teks `"Membuka Vault..."` dengan `disabled` agar mencegah double-submit.

---

### 4.2 Layar 2 — Home 3D Spatial Dashboard (Tab 1: `Home`)

#### A. Tujuan & Hierarki Informasi
Pusat kendali spasial dan eksekutif: menampilkan **Interactive 3D LiDAR Room Viewer** sebagai *Hero Interactive Canvas*, **Bento KPI 2×2**, **Quick Actions**, dan **Live Activity Feed** tanpa perlu scrolling berlebihan di *above-the-fold*.

#### B. Layout Wireframe Teks
```
┌─────────────────────────────────────────┐
│  [Avatar] Villa Kemang Selatan #14B  [🔔•]│ <- Top App Bar + Role Badge
│           [👑 Owner]  [● Synced]        │    Sync Pill (Synced/Pending/Offline)
├─────────────────────────────────────────┤
│  ┌───────────────────────────────────┐  │
│  │ 3D LIDAR SPATIAL VIEWER   [360° ⟳]│  │  <- Hero Card (Height 248px, Radius 24px)
│  │   ┌─────────┐    ┌────────────┐   │  │
│  │   │Studio   │    │Master Bed  │   │  │  <- Isometric/Perspective 3D Room Mesh
│  │   │18.0 m²  │    │28.4 m²  [📍]│   │  │     Klik ruangan -> Highlight + Chip
│  │   └────┬────┘    └─────┬──────┘   │  │     Klik Pin [📍] -> Tooltip Aset 3D
│  │        │  [📍TV]       │          │  │
│  │   ┌────┴──────────┐ ┌──┴───────┐  │  │
│  │   │Living Room    │ │Kitchen   │  │  │
│  │   │42.5 m² (Active)│ │22.1 m²  │  │  │
│  │   └───────────────┘ └──────────┘  │  │
│  │ [📍 Living Room • 3 Aset | Lihat →]│  │  <- Contextual HUD Pill (Deep-link Tab 2)
│  │ [📷 Mulai Scan LiDAR]  [📏 Ukur]  │  │  <- Scan CTA (Owner/Inspector)
│  └───────────────────────────────────┘  │
│                                         │
│  BENTO KPI OVERVIEW                     │
│  ┌─────────────────┐ ┌────────────────┐ │
│  │ 💰 TOTAL VALUASI│ │ 📦 TOTAL ASET  │ │  <- Grid 2x2 (Gap 12px, Radius 20px)
│  │ Rp 402.925.000  │ │ 8 Item         │ │     (Tenant: Valuasi -> "🔒 Disamarkan")
│  │ -6.9% vs Beli   │ │ 4 Ruangan      │ │
│  └─────────────────┘ └────────────────┘ │
│  ┌─────────────────┐ ┌────────────────┐ │
│  │ 📐 LUAS TERPINDAI│ │ ✅ TERVERIFIKASI│ │
│  │ 111.0 m²        │ │ 62.5% (5/8)    │ │
│  │ 3 Verified Scan │ │ 1 Flagged      │ │
│  └─────────────────┘ └────────────────┘ │
│                                         │
│  QUICK ACTIONS                          │
│  (📷 Scan)  (➕ Aset)  (📄 Ekspor) (🔗 Share)│ <- 4 Squircle 56×56px
│                                         │
│  LIVE ACTIVITY & AUDIT FEED             │
│  • [Verified] MacBook Pro 16" • 2j lalu │
│  • [Expiring] B&O Speaker (18 hari)     │
│                                         │
│  ╭───────────────────────────────────╮  │
│  │  🏠Home  📦Invent  📊Stats  👤Prof │  │  <- Floating Blur Bottom Tab Bar
│  ╰───────────────────────────────────╯  │
└─────────────────────────────────────────┘
```

#### C. Spesifikasi Komponen & Interaksi 3D Spatial Viewer
1. **3D Room Canvas Controls:**
   - **Drag / Swipe:** Orbit rotasi 3D (pitch `15°–75°`, yaw `0°–360°`).
   - **Pinch / Tombol `+` `-` / `Reset ⟳`:** Zoom `0.7x–2.0x` & reset sudut pandang isometrik default.
   - **Tap Ruangan:** Menyorot wireframe ruangan dengan glow `#06B6D4`, menampilkan pill HUD di bagian bawah kanvas berisi nama ruangan, luas `m²`, jumlah aset di dalamnya, dan tombol `"Lihat Aset →"` yang otomatis membuka Layar 3 dengan filter ruangan aktif.
   - **Tap Pin Aset 3D `(x, y, z)`:** Menampilkan mini *VisionOS Glass Tooltip* berisi nama aset, status badge, dan (jika bukan Tenant) nilai taksiran.
   - **Tombol `Mulai Scan LiDAR`:** Membuka modal simulasi pemindaian ruangan 3D (animasi laser sweep cyan-emerald `2.5 detik` + progres mesh `0% → 100%`), menawarkan penambahan ruangan baru (mis. `Guest Bedroom 16.5 m²`) atau pembaruan scan ruangan (`Pending Re-scan` -> `Scan Verified`) dan langsung memperbarui KPI luas `m²`. Pada perangkat non-LiDAR, otomatis menampilkan label *"AR Depth / Guided Box Fallback"*.
2. **State Matrix per Role (Layar 2):**
   - **Owner:** Seluruh KPI, pin aset (termasuk `OWNER_PRIVATE`), tombol `Mulai Scan LiDAR`, dan semua 4 Quick Actions aktif (`Scan`, `+ Aset`, `Ekspor PDF`, `Share Link`).
   - **Inspector / Appraiser:** Seluruh KPI finansial terlihat (kecuali aset `OWNER_PRIVATE` yang tidak dibagikan dalam klaim). Quick Actions berubah menjadi: `Audit Scan`, `Cek Pending`, `Ekspor Klaim`, `Log Audit`.
   - **Tenant / Viewer:** Kartu Bento `Total Valuasi` & `Terverifikasi` menampilkan status masking terkunci (`🔒 Restricted for Tenant` + label `"Privasi Finansial Pemilik Dilindungi"`). Luas `111.0 m²` dan jumlah aset `ALL_AUTHORIZED` (`4 Item`) tetap tampil. Tombol `Mulai Scan LiDAR`, `+ Aset`, `Ekspor Klaim`, dan `Share Link` disembunyikan/diganti CTA tunggal `"Lapor Kondisi Barang"`.
3. **Empty / Loading / Error / Offline States:**
   - **Loading Skeleton:** Shimmer pada 4 kartu Bento + radial pulse pada kanvas 3D (`"Mendekripsi Mesh Spasial Lokal..."`).
   - **Empty State (AC-L2-04):** Jika 0 ruangan & 0 aset, kanvas menampilkan wireframe placeholder putus-putus + ilustrasi LiDAR + CTA `"Mulai Scan Ruangan Pertama"` (Owner), dan seluruh KPI bernilai `0` (bukan `NaN`/`undefined`).
   - **Non-LiDAR Fallback State:** Pada Android/iPhone tanpa LiDAR atau simulator web, tampilkan badge netral `"Mode AR Depth / Simulator 3D"` tanpa error crash.
   - **Offline & Conflict Banner (AC-08):** Jika offline, badge header berubah menjadi pill amber `● Offline Vault (2 Pending Sync)` — seluruh interaksi 3D & KPI tetap 100% responsif. Jika terjadi *Field-Level Merge* antara edit `Owner` dan `Appraiser`, tampilkan chip info `"Tersinkron (Merge: Harga Owner + Nilai Appraiser)"` dengan tautan ke riwayat log.

---

### 4.3 Layar 3 — Asset Inventory CRUD & Modal Bottom Sheet (Tab 2: `Inventory`)

#### A. Tujuan & Hierarki Informasi
Katalog inventaris lengkap dengan pencarian real-time, filter multi-dimensi, visualisasi kartu aset kaya metadata (garansi, valuasi, kondisi, pin koordinat), dan eksekusi CRUD penuh melalui **Modal Bottom Sheet**.

#### B. Layout Wireframe Teks
```
┌─────────────────────────────────────────┐
│  Inventaris Aset          [8 Item • ▾]  │ <- Header + Active Room Filter Chip
│  ┌───────────────────────────────────┐  │
│  │ 🔍 Cari nama, merek, atau serial… │  │ <- Real-time Search Input (Clear [×])
│  └───────────────────────────────────┘  │
│  [Semua] [Living Room] [Studio] [Bedroom]│ <- Horizontal Scroll Room Chips
│  [All Status] [✅ Verified] [⏳ Pending] │ <- Secondary Status/Category Chips
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ [💻] MacBook Pro 16" M3 Max  [✅Ver]│  │ <- Asset Card (Radius 20px)
│  │      Home Office • S/N: C02M3X91  │  │    Monospace Serial & Pin Coords
│  │      Garansi: Active (2027)       │  │    Warranty Pill
│  │      Beli: Rp 64jt → Kini: Rp 51.2jt│ │   Gold Valuation (Hidden for Tenant)
│  │      Pin: (2.0, 0.8, 1.5)  [Edit ›]│ │
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │ [🔊] B&O Beosound Balance   [⏳Pend]│  │
│  │      Living Room • S/N: BO-88412  │  │
│  │      ⚠️ Garansi Habis 18 Hari Lagi │  │ <- Expiring Soon Amber Warning
│  │      Kini: Rp 36.125.000   [Verify]│ │ <- Contextual CTA for Inspector
│  └───────────────────────────────────┘  │
│                                         │
│                                  ╭───╮  │
│                                  │ + │  │ <- FAB "+ Tambah Aset" (Owner Only)
│  ╭───────────────────────────────┴───╯  │
│  │  🏠Home  📦Invent  📊Stats  👤Prof │  │
│  ╰───────────────────────────────────╯  │
└─────────────────────────────────────────┘
```

#### C. Spesifikasi Modal Bottom Sheet (Create / Edit / Verify / Condition Note)
Modal Bottom Sheet memiliki drag handle (`36×4px`), `max-height: 88%`, scrollable body, dan sticky footer action bar:
1. **Header Sheet:** Judul kontekstual (`Tambah Aset Baru` / `Edit Detail Aset` / `Verifikasi Appraisal` / `Lapor Kondisi Tenant`) + badge Ruangan & Koordinat 3D `(x, y, z)`.
2. **Fields & Validasi:**
   - `Nama Aset` *(wajib, min 2 karakter)* — error inline merah jika kosong.
   - `Ruangan (roomId)` *(wajib, dropdown/pill selector dari ruangan hasil scan)*.
   - `Kategori` *(wajib: Elektronik, Furnitur, Koleksi/Perhiasan, Fixture)*.
   - `Nomor Seri & Foto Bukti / OCR Struk (Mock)` — tombol *"Scan Struk (On-Device OCR)"* mengisi otomatis nominal & tanggal beli.
   - `Harga Beli (Purchase Price)` & `Valuasi Saat Ini (Current Valuation)` — numerik `>= 0`; input negatif ditolak (`"Nilai tidak boleh negatif"`). Tombol bantu `"Hitung Depresiasi Otomatis"` menggunakan rumus garis lurus BRD 4.1.
   - `Tanggal Beli` & `Tanggal Garansi Berakhir` — validasi `warrantyExpiry >= purchaseDate`.
   - `Kondisi Fisik` (`Mint`, `Good`, `Fair`, `Damaged`) & `Visibility Scope` (`ALL_AUTHORIZED`, `INSURANCE_ONLY`, `OWNER_PRIVATE`).
   - `Appraisal Fields` *(khusus Inspector)*: `Appraised Value` & `Inspection Note` + tombol aksi `Verify Asset` / `Flag Issue` (tidak menimpa `Purchase Price` asli).
   - `Tenant Condition Note` *(khusus Tenant)*: Field `Catatan Kondisi / Kerusakan` + tombol `Kirim Laporan Kondisi`.
3. **State Matrix per Role (Layar 3):**
   - **Owner:** Melihat semua 8 aset; memiliki **FAB `+`**, edit seluruh metadata, dan tombol **`Hapus Aset`** (dengan dialog konfirmasi; aset berstatus `CLAIMED` hanya dapat diarsipkan `ARCHIVED`).
   - **Inspector / Appraiser:** Melihat aset `ALL_AUTHORIZED` & `INSURANCE_ONLY` (`OWNER_PRIVATE` disembunyikan); FAB `+` dan tombol `Hapus Aset` **disembunyikan/tertolak**; field `Purchase Price` & `Nama` berstatus *read-only*, hanya `Appraised Value`, `Verification Status`, dan `Inspection Note` yang dapat diedit.
   - **Tenant / Viewer:** Hanya melihat 4 aset `ALL_AUTHORIZED`; seluruh field harga beli, valuasi, garansi finansial, dan polis disembunyikan; FAB `+` dan tombol `Hapus` tidak ada; mengetuk kartu hanya membuka *Condition Note Bottom Sheet*.
4. **Empty & Error Search States (AC-L3-05):**
   - Pencarian tanpa hasil menampilkan ikon radar kosong + teks `"Tidak ada aset yang cocok dengan filter saat ini"` + tombol `"Reset Filter"` (`min-height: 44px`).

---

### 4.4 Layar 4 — Spatial Analytics & Valuation Charts (Tab 3: `Analytics`)

#### A. Tujuan & Hierarki Informasi
Menyajikan kesehatan portofolio aset properti secara visual untuk persiapan klaim asuransi, pemantauan depresiasi, dan riwayat audit/inspeksi.

#### B. Layout Wireframe Teks
```
┌─────────────────────────────────────────┐
│  Analitik Spasial & Valuasi             │
│  [Semua Ruangan ▾] [Bulan Ini | Tahun]  │ <- Timeframe & Scope Filter
├─────────────────────────────────────────┤
│  1. VALUASI & DISTRIBUSI PER RUANGAN    │
│  ┌───────────────────────────────────┐  │
│  │ Master Bedroom   ██████████ 204jt │  │ <- Interactive Horizontal Bar Chart
│  │ Living Room      █████      106jt │  │    Tap bar -> Tooltip detail % & item
│  │ Studio/Office    ████        74jt │  │
│  │ Modern Kitchen   █           17jt │  │
│  └───────────────────────────────────┘  │
│                                         │
│  2. KOMPOSISI KATEGORI ASET             │
│  ┌───────────────────────────────────┐  │
│  │   ╭─────╮   ● Koleksi     48.4%   │  │ <- Donut / Segmented Ring Chart
│  │   │ 402 │   ● Elektronik  35.1%   │  │    Center label: Total / Item count
│  │   │  jt │   ● Furnitur    16.5%   │  │
│  │   ╰─────╯                         │  │
│  └───────────────────────────────────┘  │
│                                         │
│  3. DEPRESIASI VS HARGA PEROLEHAN       │
│  ┌───────────────────────────────────┐  │
│  │ Harga Beli   : Rp 433.000.000     │  │ <- Dual Comparison Bar + Readiness
│  │ Nilai Kini   : Rp 402.925.000     │  │    Insurance Claim Readiness: 62.5%
│  │ Selisih Net  : -6.9% (Apresiasi   │  │    [Warning: 3 Aset Belum Verified]
│  │                Koleksi Menahan)   │  │
│  └───────────────────────────────────┘  │
│                                         │
│  4. RIWAYAT INSPEKSI & GARANSI          │
│  • 11 Nov: Scan LiDAR Master Bedroom OK │
│  • 10 Nov: Flag AC Kamar Utama (Tenant) │
│                                         │
│  ╭───────────────────────────────────╮  │
│  │  🏠Home  📦Invent  📊Stats  👤Prof │  │
│  ╰───────────────────────────────────╯  │
└─────────────────────────────────────────┘
```

#### C. Interaksi & State Matrix per Role (Layar 4)
1. **Tooltip & Cross-Filtering:** Mengetuk bar ruangan atau segmen kategori memunculkan *floating tooltip* berisi nominal IDR eksak, persentase kontribusi (`%`), dan jumlah item. Semua angka dihitung dinamis dari state aktif Layar 3 (setiap CRUD di Layar 3 langsung mengubah chart).
2. **State Matrix per Role:**
   - **Owner & Inspector:** Melihat ketiga grafik finansial penuh (`Valuasi per Ruangan`, `Komposisi Kategori`, `Depresiasi vs Harga Beli`), `Claim Readiness Score`, dan `Riwayat Inspeksi`.
   - **Tenant / Viewer (AC-L4-03):** Grafik nominal valuasi finansial dan depresiasi **disembunyikan** dan diganti dengan banner informatif `"Analitik Valuasi Finansial Dibatasi untuk Role Tenant"`. Tenant tetap dapat melihat **Grafik Distribusi Jumlah Barang per Ruangan** (mis. Living Room: 1 item, Studio: 1 item, Master Bedroom: 1 item, Kitchen: 1 item) dan **Ringkasan Catatan Kondisi** miliknya.
3. **Empty Chart State:** Jika seluruh aset dihapus (0 item), setiap container grafik menampilkan state nol yang bersih (`"Belum ada data aset untuk dianalisis"`) tanpa error div-by-zero atau canvas rusak.

---

### 4.5 Layar 5 — Profile, Role Switcher, Theme Toggle, Server Endpoint & Export (Tab 4: `Profile`)

#### A. Tujuan & Hierarki Informasi
Pusat manajemen identitas, demo role switcher, tema tampilan, konfigurasi server *offline-first*, dan ekspor dokumen klaim/serah-terima terverifikasi.

#### B. Layout Wireframe Teks
```
┌─────────────────────────────────────────┐
│  Profil & Pengaturan Sistem             │
├─────────────────────────────────────────┤
│  ┌───────────────────────────────────┐  │
│  │ [AR] Andi Pratama   [👑 Owner]    │  │ <- Profile Card
│  │      Villa Kemang Selatan #14B    │  │
│  │  Quick Switch (Demo Mode Only):   │  │
│  │  [Owner*] [Inspector] [Tenant]    │  │ <- Hanya tampil saat DEMO=true
│  └───────────────────────────────────┘  │
│                                         │
│  EKSPOR LAPORAN & SHARE LINK            │
│  ┌───────────────────────────────────┐  │
│  │ 📄 Preview Laporan Klaim (PDF)  › │  │ <- Membuka Modal Print/PDF + Hash
│  │ 📊 Unduh Data Klaim (CSV)       › │  │    (Locked/Hidden untuk Tenant)
│  │ 🧾 Unduh Paket JSON Terstruktur › │  │
│  │ 🔗 Kelola Share Link (2 Aktif)  › │  │ <- Owner Only (TTL, PIN, Revoke)
│  └───────────────────────────────────┘  │
│                                         │
│  TAMPILAN & KEAMANAN LOKAL              │
│  ┌───────────────────────────────────┐  │
│  │ 🌗 Tema Aplikasi  [OLED Dark ⇄]   │  │ <- Toggle Dark <-> Alabaster Light
│  │ 🔐 Biometric App Lock        [ON] │  │
│  │ 🛡️ Auto-Blur PII On-Device   [ON] │  │
│  └───────────────────────────────────┘  │
│                                         │
│  SERVER ENDPOINT & SINKRONISASI         │ <- Owner Only (Hidden/403 utk others)
│  ┌───────────────────────────────────┐  │
│  │ Sync Mode: [Offline-First ▾]      │  │
│  │ Endpoint URL:                     │  │
│  │ ┌───────────────────────────────┐ │  │
│  │ │ https://sync.spatialhome.ex/v1│ │  │ <- Tersimpan di LocalStorage/Prefs
│  │ └───────────────────────────────┘ │  │
│  │ Hanya Sync via Wi-Fi        [ON]  │  │
│  │ [🔄 Sinkronkan Sekarang] (0 Queue)│  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ ♻️ Reset Data Demo ke Seed Awal   │  │ <- Owner / Demo Simulator
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │ 🚪 Keluar (Logout)                │  │ <- Kembali ke Layar 1
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

#### C. Spesifikasi Ekspor, Share Link & RBAC Guard (Layar 5)
1. **Export Insurance Claim Bundle (AC-L5-01):**
   - **PDF Preview / Print Modal:** Menampilkan dokumen siap cetak berisi Header Properti `"Villa Kemang Selatan #14B"`, Tanggal/Timestamp UTC+Lokal, Snapshots 3D Ruangan, Tabel Aset terverifikasi (Nama, Ruangan, S/N, Harga Beli, Nilai Taksiran, Status Verifikasi), Total Nilai Klaim, Stempel `Appraiser Verified` (bila sudah diverifikasi Inspector), dan **SHA-256 Integrity Hash** di footer.
   - **CSV & JSON Download:** Langsung memicu unduhan file `spatial3d-claim-villa-kemang-<timestamp>.csv` / `.json` valid.
2. **Share Link Lifecycle & Revoke UI (AC-09):**
   - Form pembuatan tautan (`Owner` only): pilih `target_role` (`APPRAISER` / `TENANT_BUYER`), ruang lingkup ruangan, `TTL` (`1j` s.d. `90 hari`), serta proteksi PIN 6-digit opsional.
   - Daftar tautan aktif dilengkapi tombol **`Revoke`** (cabut akses seketika). Jika tautan yang dicabut atau kedaluwarsa dibuka pada mode viewer, sistem menampilkan layar blokir bersih: **`🔒 Tautan Berbagi Tidak Berlaku / Telah Dicabut oleh Pemilik`** dengan kode status `410/403`.
3. **State Matrix per Role (Layar 5):**
   - **Owner:** Akses penuh seluruh bagian (Export PDF/CSV/JSON, Share Link Manager dengan opsi TTL `24j–90h` + PIN 6 digit + Revoke, Server Endpoint URL, Wi-Fi Only toggle, Reset Demo Data).
   - **Inspector / Appraiser:** Dapat mengekspor Laporan Audit/Klaim (`PDF/CSV/JSON`) dengan watermark *Inspector*; **Bagian `Server Endpoint Settings` & `Share Link Manager` disembunyikan** (`403 Role Guard`) — hanya tampil kartu ringkas status koneksi lokal (`Read-only Sync Status`).
   - **Tenant / Viewer:** Bagian **Ekspor Klaim Asuransi, Share Link Manager, Server Endpoint Settings, dan Reset Demo Data disembunyikan/terkunci** dengan label jelas (`"Akses Ekspor Klaim & Pengaturan Server Hanya untuk Owner"`). Tenant hanya melihat Profil, Theme Toggle, opsi `Unduh Daftar Kondisi Sewa (Non-Finansial)` (opsional bila diizinkan), dan `Logout`.

---

## 5. Spesifikasi Interactive Mobile Device Simulator (`index.html`)

Karena aplikasi native `.ipa` tidak dapat dijalankan langsung di browser web, `index.html` berfungsi sebagai **Interactive Dual-Device Simulator** yang mempresentasikan pengalaman 1:1 dengan implementasi Flutter/SwiftUI/Material 3.

### 5.1 Tata Letak Workspace Simulator (Desktop ≥ 1024px vs Mobile < 768px)
- **Desktop / Tablet Layout (Split Stage):**
  - **Sisi Kiri / Tengah (`60%`):** **Mobile Device Frame Stage** terpusat dengan *ambient radial backdrop* lembut.
  - **Sisi Kanan (`40%`, max `420px`):** **Simulator Control & Sideload Guide Panel** (tidak menimpa layar aplikasi di dalam ponsel!).
- **Mobile Browser Layout (`< 768px`):** Bingkai ponsel otomatis mengisi layar penuh (*edge-to-edge*) dengan *Floating Simulator Pill* kecil di bagian paling atas untuk mengganti Role/Tema/Frame atau membuka drawer panduan sideload.

### 5.2 Dual-Device Frame Spec (Toggle 1-Klik)
1. **Frame Mode A — iPhone 15 Pro (Apple HIG iOS 17+):**
   - Dimensi viewport internal: `390×844px`, bezel titanium gelap (`12px`), outer corner radius `54px`, inner screen radius `44px`.
   - **Dynamic Island:** Pill hitam `120×34px` di top-center (`top: 11px`) lengkap dengan ikon indikator *LiDAR Active* (titik hijau/cyan berkedip halus saat scan 3D berlangsung).
   - **Status Bar iOS:** Waktu `09:41` di kiri, Signal + Wi-Fi + Battery di kanan.
   - **Home Indicator:** Pill `134×5px` di bottom-center (`bottom: 8px`).
   - **Tab Bar Style:** *Floating Glass Pill* melayang `12px` di atas Home Indicator dengan efek blur `.ultraThinMaterial`.
2. **Frame Mode B — Android Modern (Material Design 3 / Pixel Flagship):**
   - Dimensi viewport internal: `390×844px`, bezel matte graphite (`10px`), outer corner radius `36px`, inner screen radius `28px`.
   - **Punch-Hole Camera:** Lingkaran kamera depan `16×16px` di top-center (`top: 12px`).
   - **Status Bar Android:** Waktu + ikon notifikasi di kiri, 5G + Battery di kanan.
   - **Navigation:** Material 3 *Anchored Navigation Bar* dengan *pill indicator* (`64×32px`) di belakang ikon tab aktif + Android Gesture Handle (`108×4px`).

### 5.3 Panel Kontrol Simulator & Panduan Sideload `.ipa` / `.apk`
Panel di samping bingkai perangkat wajib memuat:
1. **Device Frame Switcher:** Segmented control `📱 iPhone 15 Pro (iOS 17)` ↔ `🤖 Android Modern (M3)`.
2. **Quick Role Switcher:** 3 tombol instan `👑 Owner` | `🛡️ Inspector` | `👁️ Tenant` (sinkron dua arah dengan switcher di dalam layar HP).
3. **Theme Switcher:** `🌙 OLED Luxury Dark` ↔ `☀️ Clean Alabaster Light`.
4. **Build Status & Artifact Release Card:**
   - Menampilkan status pipeline CI/CD GitHub Actions (`.github/workflows/build-mobile.yml`), versi build, commit tag, dan tautan unduhan artefak `.ipa` (iOS) serta `.apk` (Android).
5. **Panduan Sideload Terstruktur (Collapsible Accordion):**
   - **Cara Instal `.apk` di Android:**
     1. Unduh file `spatial-3d-home-release.apk` dari GitHub Releases / Artifacts.
     2. Aktifkan *"Install unknown apps"* pada Pengaturan Android untuk browser/file manager.
     3. Ketuk file `.apk` untuk memasang, atau via komputer: `adb install -r spatial-3d-home-release.apk`.
     4. Verifikasi SHA-256 checksum sebelum membuka aplikasi.
   - **Cara Sideload `.ipa` di iPhone / iPad (Tanpa App Store):**
     1. Unduh file `spatial-3d-home.ipa` dari GitHub Releases / CI Artifact.
     2. **Opsi A (AltStore / Sideloadly via Mac/PC):** Hubungkan iPhone via kabel USB, buka *Sideloadly* atau *AltStore*, masukkan Apple ID (developer gratis berlaku 7 hari, atau akun Apple Developer berbayar 1 tahun), lalu drag-and-drop `.ipa`.
     3. **Opsi B (TestFlight / Ad-Hoc Enterprise):** Jika menggunakan UDID terdaftar atau TestFlight internal, buka tautan undangan TestFlight langsung di iOS.
     4. Buka `Settings → General → VPN & Device Management`, pilih profil sertifikat developer, lalu ketuk **Trust**.
     5. *Catatan Sensor LiDAR:* Fitur *Apple RoomPlan LiDAR* aktif penuh di iPhone 12 Pro ke atas / iPad Pro; perangkat non-LiDAR otomatis memakai *AR Depth / Manual Box Fallback*.

### 5.4 Spesifikasi Engine & Visual 3D Simulator (`3D Spatial Room & LiDAR Sim`)
Untuk menjamin simulator 3D berjalan stabil (`30–60 FPS`) dan **100% offline-resilient** tanpa bergantung CDN eksternal:
1. **Engine Render Lintas-Perangkat:** Proyeksi 3D perspektif/isometrik berbasis WebGL / HTML5 Canvas 2D berakselerasi GPU dengan transformasi matriks rotasi (`yaw`, `pitch`), *Z-depth sorting*, dan *hit-testing* koordinat `(x, y, z)` ke ruang layar 2D.
2. **Pencahayaan & Material Arsitektural (3D Studio Spec):**
   - *Ambient + Directional Key/Rim Lighting*: Permukaan lantai Lantai 1 (`y = 0`) vs Lantai 2 (`y = +3.2m`, *Master Bedroom*) dibedakan oleh elevasi spasial dan intensitas bayangan lembut; garis tepi dinding memakai *rim highlight* `#06B6D4` (`#0E7490` di tema terang) dengan isi bidang kaca-teknis semi-transparan (`opacity: 0.08–0.14`).
   - *Mat-Grid Blueprint:* Grid lantai `1m × 1m` untuk memberi skala dimensi nyata (`42.5 m²`, `18.0 m²`, `28.4 m²`, `22.1 m²`).
   - *Pin Aset 3D `(x, y, z)`:* Marker vertikal mengambang dengan cincin denyut status (`#10B981` Verified, `#FBBF24` Pending, `#EF4444` Flagged) dan *hit-area* minimal `44×44px`.
3. **`UxGlassHudCallout` (VisionOS Frosted Glass Callout):**
   - Saat pin aset atau ruangan diketuk, tampilkan kartu *Liquid Glass* (`backdrop-filter: blur(40px) saturate(220%)`, `border-top: 0.5px solid rgba(255,255,255,0.22)`) yang terhubung oleh garis penunjuk (*SVG leader-line* `1.5px`) langsung ke proyeksi pin 3D, berisi nama item/ruangan, dimensi atau valuasi (tersamar untuk Tenant), dan tombol aksi cepat (`Lihat Aset` / `Detail`).
4. **Simulasi LiDAR Sweep & Jaminan Privasi On-Device (`AC-06`):**
   - Menekan `Mulai Scan LiDAR` membuka overlay *3D Mesh Scanner* dengan animasi garis sapuan laser cyan-emerald (`2.4 detik`), penghitung poligon/akurasi (`Vertices: 14,820 • ±1.2 cm`), serta badge permanen **`🛡️ On-Device Processing • 0 Byte Raw Video Uploaded`**.
   - Setelah scan selesai, status ruangan `Modern Kitchen` dapat ditingkatkan ke `Scan Verified` atau ruangan baru ditambahkan (mis. `Guest Bedroom 16.5 m²`), yang langsung memperbarui total luas `m²` pada Bento KPI Layar 2.
5. **Konfigurasi PWA Mobile Safari & Anti Rubber-Band (`ios-liquid-glass-pwa`):**
   - Meta viewport wajib: `viewport-fit=cover, maximum-scale=1.0, user-scalable=no` dan `apple-mobile-web-app-status-bar-style="black-translucent"`.
   - Kontainer utama menerapkan `overflow-x: hidden; overscroll-behavior-x: none; touch-action: pan-y;` (sementara kanvas 3D menangkap `touch-action: none` khusus saat gestur orbit 3D aktif).

---

## 6. Checklist Aksesibilitas, Ergonomi & Traceability AC

### 6.1 Accessibility, Keyboard/Focus & Mobile Layout Checklist
- [x] **Contrast Ratio:** Seluruh teks utama & label aksi di tema *OLED Dark* maupun *Alabaster Light* memenuhi rasio kontras minimal `>= 4.5:1` (`>= 3:1` untuk teks besar/ikon).
- [x] **Color-Blind Safe Status:** Status verifikasi & garansi tidak hanya mengandalkan warna (Hijau/Kuning/Merah), melainkan selalu disertai ikon dan label teks (`Verified`, `Pending`, `Flagged`, `Expiring Soon`).
- [x] **Touch Target & Ergonomi:** Minimal `44×44px` pada seluruh tab, chip filter, pin 3D, dan tombol bottom sheet; jarak antar tombol destruktif dan tombol simpan minimal `12px` untuk mencegah *mis-tap*.
- [x] **Keyboard & Focus Order:** Di simulator web, seluruh tombol, input, chip, dan modal bottom sheet dapat dinavigasi dengan `Tab` / `Shift+Tab` + `Escape` untuk menutup modal, dengan *focus ring* jelas `2px solid #06B6D4`.
- [x] **No Horizontal Overflow:** Lebar kontainer terkunci rapi di dalam viewport `390px`; daftar chip menggunakan horizontal scroll container terisolasi (`overflow-x: auto; scrollbar-width: none`).

### 6.2 Matriks Keterlacakan ke Acceptance Criteria (`BRD_SPEC` & `PRD_AC_SPEC`)
| Bagian di `UI_SPEC.md` | Referensi AC Terpenuhi |
| :--- | :--- |
| Section 4.1 (Layar 1 Login, Biometric & Quick Role Switch) | `AC-04`, `AC-L1-01`, `AC-L1-02`, `AC-L1-03` |
| Section 4.2 (Layar 2 3D Viewer, Scan LiDAR, Bento KPI, Tenant Masking, Conflict Banner) | `AC-01`, `AC-03`, `AC-05`, `AC-08`, `AC-L2-01` s.d. `AC-L2-04` |
| Section 4.3 (Layar 3 Asset CRUD Bottom Sheet, Inspector Verify, Tenant Note) | `AC-01`, `AC-02`, `AC-03`, `AC-L3-01` s.d. `AC-L3-05` |
| Section 4.4 (Layar 4 Spatial Analytics & Valuation Charts, Tenant Masking) | `AC-05`, `AC-L4-01` s.d. `AC-L4-03` |
| Section 4.5 (Layar 5 Export PDF/CSV/JSON, Share Link Revoke, Server Config Guard, Reset) | `AC-01`, `AC-02`, `AC-03`, `AC-09`, `AC-L5-01` s.d. `AC-L5-03` |
| Section 5 & 5.4 (Interactive Simulator iPhone 15 Pro / Android M3, 3D Engine & Sideload Guide) | `AC-06`, `AC-SIM-01`, `AC-SIM-02`, `AC-BLD-01`, `AC-BLD-02` |
