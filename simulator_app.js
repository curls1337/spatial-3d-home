/**
 * Spatial 3D Home — Mobile App Logic & Simulator State
 * 100% synced with Flutter mobile/lib/ models, RBAC, and seed data.
 * Hardened against DOM XSS, strict RBAC guard for Tenant, 5-Screen commercial flow (Login + 4 Tabs), and real SHA-256 export seal.
 */

function esc(str) {
  if (str === null || str === undefined) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function safeId(str) {
  return String(str ?? '').replace(/[^a-zA-Z0-9_-]/g, '');
}

// Synchronous pure-JS SHA-256 fallback (RFC 6234) when crypto.subtle is unavailable
function sha256Sync(ascii) {
  function rightRotate(value, amount) {
    return (value >>> amount) | (value << (32 - amount));
  }
  const mathPow = Math.pow;
  const maxWord = mathPow(2, 32);
  let result = '';
  const words = [];
  const asciiBitLength = ascii.length * 8;
  const hash = (sha256Sync.h = sha256Sync.h || []);
  const k = (sha256Sync.k = sha256Sync.k || []);
  let primeCounter = k.length;
  const isComposite = {};
  for (let candidate = 2; primeCounter < 64; candidate++) {
    if (!isComposite[candidate]) {
      for (let i = 0; i < 313; i += candidate) isComposite[i] = candidate;
      hash[primeCounter] = (mathPow(candidate, 0.5) * maxWord) | 0;
      k[primeCounter++] = (mathPow(candidate, 1 / 3) * maxWord) | 0;
    }
  }
  const h = hash.slice(0);
  ascii += '\x80';
  while ((ascii.length % 64) - 56) ascii += '\x00';
  for (let i = 0; i < ascii.length; i++) {
    const j = ascii.charCodeAt(i);
    if (j >> 8) return '';
    words[i >> 2] |= j << (((3 - i) % 4) * 8);
  }
  words[words.length] = (asciiBitLength / maxWord) | 0;
  words[words.length] = asciiBitLength;

  for (let j = 0; j < words.length; ) {
    const w = words.slice(j, (j += 16));
    const oldHash = h.slice(0);
    for (let i = 0; i < 64; i++) {
      const w15 = w[i - 15];
      const w2 = w[i - 2];
      const a = h[0];
      const e = h[4];
      const temp1 =
        h[7] +
        (rightRotate(e, 6) ^ rightRotate(e, 11) ^ rightRotate(e, 25)) +
        ((e & h[5]) ^ (~e & h[6])) +
        k[i] +
        (w[i] =
          i < 16
            ? w[i]
            : (w[i - 16] +
                (rightRotate(w15, 7) ^ rightRotate(w15, 18) ^ (w15 >>> 3)) +
                w[i - 7] +
                (rightRotate(w2, 17) ^ rightRotate(w2, 19) ^ (w2 >>> 10))) |
              0);
      const temp2 =
        (rightRotate(a, 2) ^ rightRotate(a, 13) ^ rightRotate(a, 22)) +
        ((a & h[1]) ^ (a & h[2]) ^ (h[1] & h[2]));
      h.unshift((temp1 + temp2) | 0);
      h[4] = (h[4] + temp1) | 0;
      h.pop();
    }
    for (let i = 0; i < 8; i++) h[i] = (h[i] + oldHash[i]) | 0;
  }
  for (let i = 0; i < 8; i++) {
    for (let j = 3; j + 1; j--) {
      const b = (h[i] >> (j * 8)) & 255;
      result += (b < 16 ? 0 : '') + b.toString(16);
    }
  }
  return result;
}

async function computeSha256Hex(payloadStr) {
  try {
    if (typeof window !== 'undefined' && window.crypto && window.crypto.subtle && typeof TextEncoder !== 'undefined') {
      const bytes = new TextEncoder().encode(payloadStr);
      const buf = await window.crypto.subtle.digest('SHA-256', bytes);
      return Array.from(new Uint8Array(buf))
        .map((b) => b.toString(16).padStart(2, '0'))
        .join('');
    }
  } catch {}
  // Fallback UTF-8 encoded ascii string
  const utf8 = unescape(encodeURIComponent(payloadStr));
  return sha256Sync(utf8);
}

const SEED_ROOMS = [
  { id: 'room-living', name: 'Living Room', floor: 1, areaSqm: 42.5, widthM: 6.8, depthM: 6.25, heightM: 3.2, accentColor: '#06B6D4', scanVerified: true, source: 'Apple RoomPlan LiDAR' },
  { id: 'room-studio', name: 'Home Studio', floor: 1, areaSqm: 18.0, widthM: 4.5, depthM: 4.0, heightM: 3.0, accentColor: '#10B981', scanVerified: true, source: 'Apple RoomPlan LiDAR' },
  { id: 'room-bedroom', name: 'Master Bedroom', floor: 2, areaSqm: 28.4, widthM: 5.9, depthM: 4.8, heightM: 3.0, accentColor: '#38BDF8', scanVerified: true, source: 'Apple RoomPlan LiDAR' },
  { id: 'room-kitchen', name: 'Modern Kitchen', floor: 1, areaSqm: 22.1, widthM: 5.2, depthM: 4.25, heightM: 3.0, accentColor: '#F59E0B', scanVerified: false, source: 'Pending Re-scan' },
];

const SEED_ASSETS = [
  {
    id: 'ast-1', roomId: 'room-living', name: 'Sony Bravia 65" OLED TV', category: 'electronics',
    serialNumber: 'SNY-65XR80-9912', purchasePrice: 34000000, currentValuation: 27200000, appraisedValue: 27200000,
    purchaseDate: '2025-04-14', warrantyExpiryDate: '2027-04-14', verificationStatus: 'verified',
    visibilityScope: 'insuranceOnly', conditionGrade: 'Mint', pinX: 1.2, pinY: 1.1, pinZ: 0.3,
    appraisalNote: 'Panel OLED bebas burn-in, garansi resmi aktif.'
  },
  {
    id: 'ast-2', roomId: 'room-living', name: 'Natuzzi Leather Sectional Sofa', category: 'furniture',
    serialNumber: 'NTZ-IT-4410', purchasePrice: 48000000, currentValuation: 43200000, appraisedValue: 43200000,
    purchaseDate: '2024-09-02', warrantyExpiryDate: '2026-10-01', verificationStatus: 'verified',
    visibilityScope: 'allAuthorized', conditionGrade: 'Good', pinX: 3.1, pinY: 0.5, pinZ: 2.4,
    appraisalNote: 'Kulit asli Italia dalam kondisi sangat terawat.'
  },
  {
    id: 'ast-3', roomId: 'room-living', name: 'B&O Beosound Balance Speaker', category: 'electronics',
    serialNumber: 'BO-88412-BAL', purchasePrice: 42500000, currentValuation: 36125000, appraisedValue: null,
    purchaseDate: '2025-11-20', warrantyExpiryDate: '2026-11-29', verificationStatus: 'pending',
    visibilityScope: 'insuranceOnly', conditionGrade: 'Mint', pinX: 4.8, pinY: 0.9, pinZ: 1.1,
    appraisalNote: 'Menunggu verifikasi fisik serial number oleh surveyor.'
  },
  {
    id: 'ast-4', roomId: 'room-studio', name: 'MacBook Pro 16" M3 Max', category: 'electronics',
    serialNumber: 'C02M3X91Q6L', purchasePrice: 64000000, currentValuation: 51200000, appraisedValue: 51200000,
    purchaseDate: '2025-06-10', warrantyExpiryDate: '2027-11-20', verificationStatus: 'verified',
    visibilityScope: 'insuranceOnly', conditionGrade: 'Mint', pinX: 2.0, pinY: 0.8, pinZ: 1.5,
    appraisalNote: 'AppleCare+ aktif hingga 2027; kondisi fisik 99% mulus.'
  },
  {
    id: 'ast-5', roomId: 'room-studio', name: 'Herman Miller Aeron Chair', category: 'furniture',
    serialNumber: 'HM-AER-7730', purchasePrice: 26000000, currentValuation: 23400000, appraisedValue: 23400000,
    purchaseDate: '2025-01-18', warrantyExpiryDate: '2037-01-18', verificationStatus: 'verified',
    visibilityScope: 'allAuthorized', conditionGrade: 'Mint', pinX: 2.1, pinY: 0.5, pinZ: 2.2,
    appraisalNote: 'Garansi resmi 12 tahun Herman Miller.'
  },
  {
    id: 'ast-6', roomId: 'room-bedroom', name: 'LG Dual Inverter Smart AC', category: 'appliances',
    serialNumber: 'LG-AC-55091', purchasePrice: 11500000, currentValuation: 9200000, appraisedValue: null,
    purchaseDate: '2025-03-05', warrantyExpiryDate: '2027-05-20', verificationStatus: 'flagged',
    visibilityScope: 'allAuthorized', conditionGrade: 'Fair', pinX: 2.8, pinY: 2.4, pinZ: 0.2,
    appraisalNote: 'Perlu servis berkala dan pengecekan pipa drainase.',
    tenantConditionNote: 'Ada tetesan kondensasi ringan di cover indoor kanan.'
  },
  {
    id: 'ast-7', roomId: 'room-bedroom', name: 'Rolex Submariner Date (Vault)', category: 'collectibles',
    serialNumber: 'RLX-126610LN', purchasePrice: 185000000, currentValuation: 195000000, appraisedValue: 195000000,
    purchaseDate: '2023-08-12', warrantyExpiryDate: null, verificationStatus: 'verified',
    visibilityScope: 'ownerPrivate', conditionGrade: 'Mint', pinX: 0.7, pinY: 0.4, pinZ: 3.9,
    appraisalNote: 'Nilai pasar terapresiasi +5.4%; disimpan dalam brankas dinding.'
  },
  {
    id: 'ast-8', roomId: 'room-kitchen', name: 'Breville Barista Touch Espresso', category: 'appliances',
    serialNumber: 'BRV-BES880-221', purchasePrice: 22000000, currentValuation: 17600000, appraisedValue: null,
    purchaseDate: '2025-11-24', warrantyExpiryDate: '2026-11-23', verificationStatus: 'pending',
    visibilityScope: 'allAuthorized', conditionGrade: 'Good', pinX: 3.6, pinY: 0.9, pinZ: 0.6,
    appraisalNote: 'Menunggu re-scan area Modern Kitchen.'
  },
];

class AppSimulator {
  constructor() {
    this.role = localStorage.getItem('s3d_role') || 'owner'; // 'owner' | 'inspector' | 'tenant'
    this.isAuthenticated = localStorage.getItem('s3d_auth') === 'true';
    this.tab = 'home'; // 'home' | 'inventory' | 'analytics' | 'profile'
    this.device = 'iphone'; // 'iphone' | 'android'
    this.theme = localStorage.getItem('s3d_theme') || 'dark'; // 'dark' | 'light'
    this.activeRoomId = 'room-living';
    this.searchQuery = '';
    this.roomFilter = 'all';
    this.viewer3D = null;
    this.isScanning = false;
    this.isBiometricPending = false;
    this.loginEmail = 'owner@spatial3dhome.id';
    this.loginPin = '202688';
    this.serverUrl = localStorage.getItem('s3d_server_url') || 'https://webui.5nod.com';
    this.lastExportReport = null;

    this.loadState();
  }

  loadState() {
    try {
      const saved = localStorage.getItem('s3d_assets_v1');
      const parsed = saved ? JSON.parse(saved) : JSON.parse(JSON.stringify(SEED_ASSETS));
      this.assets = Array.isArray(parsed)
        ? parsed.map((a) => ({ ...a, id: safeId(a && a.id) || `ast-${Date.now().toString(36)}` }))
        : JSON.parse(JSON.stringify(SEED_ASSETS));
    } catch {
      this.assets = JSON.parse(JSON.stringify(SEED_ASSETS));
    }
    this.rooms = JSON.parse(JSON.stringify(SEED_ROOMS));
  }

  saveState() {
    try {
      localStorage.setItem('s3d_assets_v1', JSON.stringify(this.assets));
      localStorage.setItem('s3d_role', this.role);
      localStorage.setItem('s3d_auth', this.isAuthenticated ? 'true' : 'false');
      localStorage.setItem('s3d_theme', this.theme);
      localStorage.setItem('s3d_server_url', this.serverUrl);
    } catch {}
  }

  resetDemoData() {
    this.assets = JSON.parse(JSON.stringify(SEED_ASSETS));
    this.searchQuery = '';
    this.roomFilter = 'all';
    this.saveState();
    this.render();
    if (this.isAuthenticated && this.tab === 'home' && this.viewer3D) {
      this.viewer3D.loadData(this.rooms, this.getVisibleAssets());
    }
    showToast('Data demo berhasil di-reset ke baseline Villa Kemang!');
  }

  // Auth & Quick Switch Actions (Layar 1)
  loginWithRole(role) {
    if (!['owner', 'inspector', 'tenant'].includes(role)) return;
    this.role = role;
    this.isAuthenticated = true;
    this.tab = 'home';
    this.saveState();
    this.render();
    setTimeout(() => this.initOrUpdate3D(), 50);
    const names = { owner: 'Owner', inspector: 'Surveyor Asuransi', tenant: 'Penyewa / Tenant' };
    showToast(`🔓 Masuk sebagai ${names[role]}`);
  }

  loginWithForm() {
    const emailEl = document.getElementById('login-email-input');
    const pinEl = document.getElementById('login-pin-input');
    const email = (emailEl ? emailEl.value : this.loginEmail).trim().toLowerCase();
    const pin = (pinEl ? pinEl.value : this.loginPin).trim();

    if (!email || pin.length < 4) {
      showToast('Masukkan email dan PIN Vault minimal 4 digit!', 'error');
      return;
    }
    this.loginEmail = email;
    this.loginPin = pin;

    let detectedRole = 'owner';
    if (email.includes('inspector') || email.includes('surveyor') || email.includes('appraiser')) {
      detectedRole = 'inspector';
    } else if (email.includes('tenant') || email.includes('penyewa') || email.includes('buyer')) {
      detectedRole = 'tenant';
    }
    this.loginWithRole(detectedRole);
  }

  triggerBiometricLogin() {
    if (this.isBiometricPending) return;
    this.isBiometricPending = true;
    this.render();
    setTimeout(() => {
      this.isBiometricPending = false;
      this.loginWithRole(this.role || 'owner');
    }, 650);
  }

  logout() {
    this.isAuthenticated = false;
    this.isScanning = false;
    this.closeModal();
    this.saveState();
    this.render();
    showToast('🔒 Vault dikunci. Anda keluar ke Layar Login.');
  }

  setRole(newRole) {
    if (!['owner', 'inspector', 'tenant'].includes(newRole)) return;
    this.role = newRole;
    this.isAuthenticated = true;
    this.saveState();
    this.render();
    if (this.tab === 'home') {
      setTimeout(() => this.initOrUpdate3D(), 50);
    }
  }

  setTab(newTab) {
    if (!this.isAuthenticated) {
      showToast('Silakan login terlebih dahulu!', 'error');
      return;
    }
    this.tab = newTab;
    this.render();
    if (newTab === 'home') {
      setTimeout(() => this.initOrUpdate3D(), 50);
    }
  }

  setDevice(dev) {
    this.device = dev;
    const frame = document.getElementById('device-frame-container');
    if (frame) {
      frame.className = `device-frame ${dev === 'iphone' ? 'iphone-frame' : 'android-frame'} overflow-hidden flex flex-col shrink-0`;
    }
    document.querySelectorAll('.btn-device-switch').forEach((b) => {
      b.classList.toggle('active', b.dataset.dev === dev);
    });
  }

  setTheme(th) {
    this.theme = th;
    document.body.className = `theme-${th} flex flex-col items-center justify-start py-4 px-3 gap-4`;
    this.saveState();
    this.render();
    if (this.isAuthenticated && this.tab === 'home') {
      setTimeout(() => this.initOrUpdate3D(), 50);
    }
  }

  // RBAC Filters
  getVisibleAssets() {
    if (this.role === 'owner') return this.assets;
    if (this.role === 'inspector') {
      return this.assets.filter((a) => a.visibilityScope !== 'ownerPrivate');
    }
    // Tenant: only allAuthorized
    return this.assets.filter((a) => a.visibilityScope === 'allAuthorized');
  }

  getFilteredAssets() {
    let list = this.getVisibleAssets();
    if (this.roomFilter !== 'all') {
      list = list.filter((a) => a.roomId === this.roomFilter);
    }
    if (this.searchQuery) {
      const q = this.searchQuery.toLowerCase();
      list = list.filter(
        (a) =>
          (a.name && a.name.toLowerCase().includes(q)) ||
          (a.category && a.category.toLowerCase().includes(q)) ||
          (a.serialNumber && a.serialNumber.toLowerCase().includes(q))
      );
    }
    return list;
  }

  formatCurrency(amount) {
    if (this.role === 'tenant') return 'Rp ••••••••';
    return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(amount || 0);
  }

  initOrUpdate3D() {
    if (!this.isAuthenticated || this.tab !== 'home') return;
    const canvas = document.getElementById('spatial-canvas-3d');
    if (!canvas) return;
    if (!this.viewer3D && typeof window.Spatial3DViewer === 'function') {
      this.viewer3D = new window.Spatial3DViewer('spatial-canvas-3d');
    } else if (this.viewer3D && this.viewer3D.canvas !== canvas && typeof window.Spatial3DViewer === 'function') {
      this.viewer3D = new window.Spatial3DViewer('spatial-canvas-3d');
    }
    if (this.viewer3D) {
      this.viewer3D.loadData(this.rooms, this.getVisibleAssets());
      this.viewer3D.setRoom(this.activeRoomId);
    }
  }

  toggleWireframe3D() {
    if (this.viewer3D) {
      const isWire = this.viewer3D.toggleWireframe();
      const badge = document.getElementById('btn-wireframe-toggle');
      if (badge) badge.textContent = isWire ? '🕸️ Wireframe' : '🧊 Shaded';
    }
  }

  switchRoom3D(roomId) {
    this.activeRoomId = roomId;
    if (this.viewer3D) {
      this.viewer3D.setRoom(roomId);
    }
    document.querySelectorAll('.chip-room').forEach((c) => {
      c.classList.toggle('active', c.dataset.room === roomId);
    });
  }

  simulateLidarScan() {
    if (this.role === 'tenant') {
      showToast('Akses ditolak: Role Tenant tidak memiliki izin Scan LiDAR!', 'error');
      return false;
    }
    if (this.isScanning) return false;
    this.isScanning = true;
    const hud = document.getElementById('lidar-scan-hud');
    if (hud) hud.classList.remove('hidden');

    let progress = 0;
    const timer = setInterval(() => {
      progress += 18;
      const bar = document.getElementById('scan-progress-bar');
      const text = document.getElementById('scan-progress-text');
      if (bar) bar.style.width = `${Math.min(100, progress)}%`;
      if (text) text.textContent = `Memetakan Ruang: ${Math.min(100, progress)}% (14.820 vertices on-device)`;

      if (progress >= 100) {
        clearInterval(timer);
        setTimeout(() => {
          this.isScanning = false;
          if (hud) hud.classList.add('hidden');
          showToast('✅ Scan Apple RoomPlan LiDAR selesai! Akurasi 1.2 cm.');
          this.render();
          this.initOrUpdate3D();
        }, 500);
      }
    }, 180);
    return true;
  }

  // CRUD Operations
  openAddAssetModal() {
    if (this.role !== 'owner') {
      showToast('Hanya Owner yang dapat menambah aset spasial baru!', 'error');
      return;
    }
    this.editingAssetId = null;
    document.getElementById('modal-asset-title').textContent = 'Tambah Aset Spasial Baru';
    document.getElementById('form-asset-name').value = '';
    document.getElementById('form-asset-room').value = this.activeRoomId;
    document.getElementById('form-asset-category').value = 'electronics';
    document.getElementById('form-asset-serial').value = '';
    document.getElementById('form-asset-price').value = '';
    document.getElementById('form-asset-grade').value = 'Mint';
    document.getElementById('form-asset-visibility').value = 'insuranceOnly';
    document.getElementById('form-asset-note').value = '';
    document.getElementById('modal-asset-sheet').classList.remove('hidden');
  }

  openEditAssetModal(id) {
    const asset = this.assets.find((a) => a.id === id);
    if (!asset) return;

    if (this.role === 'tenant') {
      this.openTenantReportModal(id);
      return;
    }

    if (this.role === 'inspector') {
      this.openInspectorAppraiseModal(id);
      return;
    }

    this.editingAssetId = id;
    document.getElementById('modal-asset-title').textContent = 'Edit Aset Spasial';
    document.getElementById('form-asset-name').value = asset.name;
    document.getElementById('form-asset-room').value = asset.roomId;
    document.getElementById('form-asset-category').value = asset.category;
    document.getElementById('form-asset-serial').value = asset.serialNumber || '';
    document.getElementById('form-asset-price').value = asset.purchasePrice || '';
    document.getElementById('form-asset-grade').value = asset.conditionGrade || 'Good';
    document.getElementById('form-asset-visibility').value = asset.visibilityScope || 'allAuthorized';
    document.getElementById('form-asset-note').value = asset.appraisalNote || '';
    document.getElementById('modal-asset-sheet').classList.remove('hidden');
  }

  saveAssetFromForm() {
    if (this.role !== 'owner') {
      showToast('Akses ditolak: Hanya Owner yang berhak mengubah master aset.', 'error');
      return;
    }
    const name = document.getElementById('form-asset-name').value.trim();
    if (!name) {
      alert('Nama aset wajib diisi!');
      return;
    }
    const roomId = document.getElementById('form-asset-room').value;
    const category = document.getElementById('form-asset-category').value;
    const serialNumber = document.getElementById('form-asset-serial').value.trim();
    const purchasePrice = Math.max(0, parseFloat(document.getElementById('form-asset-price').value) || 0);
    const conditionGrade = document.getElementById('form-asset-grade').value;
    const visibilityScope = document.getElementById('form-asset-visibility').value;
    const appraisalNote = document.getElementById('form-asset-note').value.trim();

    if (this.editingAssetId) {
      const idx = this.assets.findIndex((a) => a.id === this.editingAssetId);
      if (idx >= 0) {
        this.assets[idx] = {
          ...this.assets[idx],
          name,
          roomId,
          category,
          serialNumber,
          purchasePrice,
          conditionGrade,
          visibilityScope,
          appraisalNote,
          currentValuation: Math.round(purchasePrice * 0.85),
        };
      }
    } else {
      const newAsset = {
        id: `ast-${Date.now().toString(36)}`,
        name,
        roomId,
        category,
        serialNumber,
        purchasePrice,
        conditionGrade,
        visibilityScope,
        appraisalNote,
        currentValuation: Math.round(purchasePrice * 0.9),
        appraisedValue: null,
        purchaseDate: new Date().toISOString().split('T')[0],
        warrantyExpiryDate: new Date(Date.now() + 365 * 86400000).toISOString().split('T')[0],
        verificationStatus: 'pending',
        pinX: 2.0,
        pinY: 1.0,
        pinZ: 1.0,
      };
      this.assets.unshift(newAsset);
    }

    this.saveState();
    this.closeModal();
    this.render();
    if (this.viewer3D) this.viewer3D.loadData(this.rooms, this.getVisibleAssets());
    showToast('Aset berhasil disimpan & terenkripsi lokal AES-256!');
  }

  deleteAsset(id) {
    if (this.role !== 'owner') {
      showToast('Hanya Owner yang berhak menghapus aset', 'error');
      return;
    }
    if (!confirm('Hapus aset ini dari brankas inventaris?')) return;
    this.assets = this.assets.filter((a) => a.id !== id);
    this.saveState();
    this.render();
    if (this.viewer3D) this.viewer3D.loadData(this.rooms, this.getVisibleAssets());
    showToast('Aset dihapus.');
  }

  openInspectorAppraiseModal(id) {
    if (this.role !== 'inspector') return false;
    const asset = this.assets.find((a) => a.id === id);
    if (!asset || asset.visibilityScope === 'ownerPrivate') return false;
    const val = prompt(
      `[Surveyor Asuransi] Masukkan Taksiran Nilai (Appraised Value) untuk:\n${asset.name}`,
      asset.appraisedValue || asset.currentValuation || asset.purchasePrice
    );
    if (val === null) return false;
    const num = parseFloat(val);
    if (isNaN(num) || num < 0) {
      alert('Masukkan angka yang valid (>= 0)');
      return false;
    }
    asset.appraisedValue = num;
    asset.verificationStatus = 'verified';
    asset.appraisalNote = `Diverifikasi fisik oleh Inspector (${new Date().toLocaleDateString('id-ID')})`;
    this.saveState();
    this.render();
    showToast(`✅ Aset ${asset.name} telah diverifikasi!`);
    return true;
  }

  openTenantReportModal(id) {
    const asset = this.assets.find((a) => a.id === id);
    if (!asset || (this.role === 'tenant' && asset.visibilityScope !== 'allAuthorized')) return false;
    const note = prompt(
      `[Catatan Penyewa / Tenant]\nLaporkan kondisi fisik atau kendala untuk:\n${asset.name}`,
      asset.tenantConditionNote || ''
    );
    if (note === null) return false;
    asset.tenantConditionNote = note.trim();
    if (note.trim()) asset.verificationStatus = 'flagged';
    this.saveState();
    this.render();
    showToast('Catatan kondisi berhasil dikirim ke Owner!');
    return true;
  }

  saveServerUrl() {
    if (this.role !== 'owner') {
      showToast('Akses ditolak: Hanya Owner yang dapat mengubah Server URL.', 'error');
      return false;
    }
    const input = document.getElementById('setting-server-url');
    if (!input) return false;
    const nextUrl = input.value.trim();
    if (!/^https?:\/\//i.test(nextUrl)) {
      showToast('URL server harus diawali http:// atau https://', 'error');
      return false;
    }
    this.serverUrl = nextUrl;
    this.saveState();
    showToast('Server URL disimpan!');
    return true;
  }

  closeModal() {
    const sheet = document.getElementById('modal-asset-sheet');
    if (sheet) sheet.classList.add('hidden');
    this.editingAssetId = null;
  }

  // Export Summary (JSON / CSV) with RBAC Guard & real SHA-256 integrity seal
  async exportClaimReport(format = 'json') {
    if (this.role === 'tenant') {
      showToast('Akses ditolak: Role Tenant dilarang mengekspor laporan klaim!', 'error');
      return null;
    }

    const visible = this.getVisibleAssets();
    const generatedAt = new Date().toISOString();
    const corePayload = {
      property: 'Villa Kemang Selatan #14B',
      generatedAt,
      exporterRole: this.role,
      totalAssets: visible.length,
      totalValuation: visible.reduce((sum, a) => sum + (a.appraisedValue ?? a.currentValuation ?? 0), 0),
      assets: visible,
    };

    const sha256Seal = await computeSha256Hex(JSON.stringify(corePayload));
    const data = {
      ...corePayload,
      sha256Seal,
    };
    this.lastExportReport = data;

    const csvCell = (v) => `"${String(v ?? '').replace(/"/g, '""')}"`;

    let blob, filename;
    if (format === 'json') {
      blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
      filename = `Klaim_Asuransi_Spatial3D_${Date.now()}.json`;
    } else {
      const csv = [
        'ID,Nama,Ruangan,Kategori,Serial,Harga Beli,Valuasi,Status,Grade,SHA256_Seal',
        ...visible.map((a) =>
          [
            csvCell(a.id),
            csvCell(a.name),
            csvCell(a.roomId),
            csvCell(a.category),
            csvCell(a.serialNumber || ''),
            Number(a.purchasePrice || 0),
            Number(a.appraisedValue ?? a.currentValuation ?? 0),
            csvCell(a.verificationStatus),
            csvCell(a.conditionGrade),
            csvCell(sha256Seal),
          ].join(',')
        ),
      ].join('\n');
      blob = new Blob([csv], { type: 'text/csv' });
      filename = `Inventaris_Aset_Spatial3D_${Date.now()}.csv`;
    }

    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = filename;
    a.click();
    this.render();
    showToast(`Laporan ${format.toUpperCase()} diekspor! SHA-256: ${sha256Seal.slice(0, 12)}...`);
    return data;
  }

  // Main UI Renderers
  render() {
    const activeEl = document.activeElement;
    const wasSearchFocused = activeEl && activeEl.id === 'inventory-search-input';
    const selStart = wasSearchFocused ? activeEl.selectionStart : null;

    // 1. Top Bar & Bottom Bar visibility based on authentication (Layar 1 vs Tabs 2-5)
    const topHeader = document.getElementById('phone-top-header');
    const bottomWrapper = document.getElementById('phone-bottom-nav-wrapper');
    if (topHeader) topHeader.classList.toggle('hidden', !this.isAuthenticated);
    if (bottomWrapper) bottomWrapper.classList.toggle('hidden', !this.isAuthenticated);

    this.renderHeaderBar();

    // 2. Main Screen Content
    const container = document.getElementById('phone-screen-content');
    if (!container) return;

    if (!this.isAuthenticated) {
      container.innerHTML = this.renderLoginScreen();
      return;
    }

    if (this.tab === 'home') container.innerHTML = this.renderHomeScreen();
    else if (this.tab === 'inventory') container.innerHTML = this.renderInventoryScreen();
    else if (this.tab === 'analytics') container.innerHTML = this.renderAnalyticsScreen();
    else if (this.tab === 'profile') container.innerHTML = this.renderProfileScreen();

    // 3. Floating Bottom Nav
    this.renderBottomNav();

    // Restore search focus on keystroke re-render
    if (wasSearchFocused && this.tab === 'inventory') {
      const input = document.getElementById('inventory-search-input');
      if (input) {
        input.focus();
        if (selStart !== null) input.setSelectionRange(selStart, selStart);
      }
    }
  }

  renderHeaderBar() {
    const roleBadges = {
      owner: { label: '👑 Owner', color: 'bg-indigo-500/20 text-indigo-300 border-indigo-500/40' },
      inspector: { label: '🛡️ Surveyor Asuransi', color: 'bg-emerald-500/20 text-emerald-300 border-emerald-500/40' },
      tenant: { label: '🏠 Penyewa (Masked)', color: 'bg-amber-500/20 text-amber-300 border-amber-500/40' },
    };
    const b = roleBadges[this.role] || roleBadges.owner;
    const el = document.getElementById('app-role-pill');
    if (el) {
      el.className = `px-2.5 py-0.5 rounded-full text-[10px] font-bold border ${b.color}`;
      el.textContent = b.label;
    }
    const authToggle = document.getElementById('btn-auth-toggle');
    if (authToggle) {
      authToggle.textContent = this.isAuthenticated ? '🔓 Logout' : '🔐 FaceID';
    }
  }

  // Layar 1: Login + Biometric FaceID Mock + Quick Role Switcher
  renderLoginScreen() {
    return `
      <div id="screen-login" class="min-h-full flex flex-col justify-between py-6 px-1 space-y-5">
        <!-- Brand Hero -->
        <div class="pt-6 text-center space-y-2.5">
          <div class="w-16 h-16 mx-auto rounded-2xl bg-gradient-to-br from-cyan-400 via-sky-500 to-emerald-500 flex items-center justify-center text-slate-950 font-black text-2xl shadow-xl shadow-cyan-500/25">
            3D
          </div>
          <div>
            <div class="text-[10px] font-mono tracking-widest text-cyan-400 uppercase font-bold">SPATIAL 3D HOME</div>
            <h2 class="text-lg font-black text-white mt-0.5">LiDAR Property &amp; Asset Vault</h2>
            <p class="text-[11px] text-slate-400 mt-1 px-3">Brankas inventaris spasial terenkripsi lokal AES-256-GCM • Zero Raw-Video Upload</p>
          </div>
        </div>

        <!-- Login Credentials & Biometric Gate -->
        <div class="rounded-2xl p-4 bg-slate-900/80 border border-white/10 space-y-3 shadow-xl">
          <div class="space-y-2 text-xs">
            <div>
              <label class="block text-[10px] uppercase font-bold text-slate-400 mb-1">Email Akun Vault</label>
              <input id="login-email-input" type="email" value="${esc(this.loginEmail)}" placeholder="owner@spatial3dhome.id" class="w-full px-3 py-2 rounded-xl bg-slate-950 border border-white/15 text-white text-xs focus:border-cyan-400 focus:outline-none" />
            </div>
            <div>
              <label class="block text-[10px] uppercase font-bold text-slate-400 mb-1">Vault PIN / Passcode</label>
              <input id="login-pin-input" type="password" value="${esc(this.loginPin)}" placeholder="••••••" class="w-full px-3 py-2 rounded-xl bg-slate-950 border border-white/15 text-white text-xs focus:border-cyan-400 focus:outline-none" />
            </div>
          </div>

          <button id="btn-login-submit" onclick="app.loginWithForm()" class="w-full py-2.5 rounded-xl bg-cyan-500 hover:bg-cyan-400 text-slate-950 font-black text-xs shadow-lg shadow-cyan-500/20 cursor-pointer transition">
            🔓 Buka Brankas Spasial
          </button>

          <button id="btn-login-faceid" onclick="app.triggerBiometricLogin()" class="w-full py-2.5 rounded-xl bg-white/5 hover:bg-white/10 border border-cyan-500/30 text-cyan-300 font-bold text-xs flex items-center justify-center gap-2 cursor-pointer transition">
            ${this.isBiometricPending
              ? '<span class="animate-pulse">🧬 Memverifikasi FaceID / Biometrik...</span>'
              : '<span>🛡️</span><span>Masuk dengan FaceID / Biometrik</span>'}
          </button>
        </div>

        <!-- Quick Role Switcher (Demo Evaluator 1-Klik) -->
        <div class="rounded-2xl p-3.5 bg-slate-900/60 border border-white/10 space-y-2">
          <div class="flex items-center justify-between">
            <span class="text-[10px] uppercase font-mono font-bold text-slate-400">Quick Switch Role (Demo Mode)</span>
            <span class="text-[9px] px-1.5 py-0.5 rounded bg-cyan-500/15 text-cyan-300 font-mono">1-Klik</span>
          </div>
          <div class="grid grid-cols-3 gap-2">
            <button data-quick-login="owner" onclick="app.loginWithRole('owner')" class="py-2 rounded-xl bg-indigo-500/20 hover:bg-indigo-500/30 border border-indigo-400/40 text-indigo-200 font-bold text-[11px] cursor-pointer transition">
              👑 Owner
            </button>
            <button data-quick-login="inspector" onclick="app.loginWithRole('inspector')" class="py-2 rounded-xl bg-emerald-500/20 hover:bg-emerald-500/30 border border-emerald-400/40 text-emerald-200 font-bold text-[11px] cursor-pointer transition">
              🛡️ Surveyor
            </button>
            <button data-quick-login="tenant" onclick="app.loginWithRole('tenant')" class="py-2 rounded-xl bg-amber-500/20 hover:bg-amber-500/30 border border-amber-400/40 text-amber-200 font-bold text-[11px] cursor-pointer transition">
              🏠 Tenant
            </button>
          </div>
        </div>

        <div class="text-center text-[10px] text-slate-500 font-mono">
          AES-256-GCM Keychain/Keystore • Offline-First Ready
        </div>
      </div>
    `;
  }

  // Layar 2: Home Executive Dashboard + 3D LiDAR Canvas + Bento KPI
  renderHomeScreen() {
    const visible = this.getVisibleAssets();
    const totalValuation = this.role === 'tenant'
      ? 0
      : visible.reduce((acc, a) => acc + (a.appraisedValue ?? a.currentValuation ?? 0), 0);
    const verifiedCount = visible.filter((a) => a.verificationStatus === 'verified').length;
    const totalAreaSqm = this.rooms.reduce((acc, r) => acc + (r.areaSqm || 0), 0).toFixed(1);
    const canScan = this.role !== 'tenant';

    return `
      <div class="space-y-3.5 pb-20">
        <!-- Hero Property Banner -->
        <div class="rounded-2xl p-3.5 bg-gradient-to-br from-cyan-950/60 via-slate-900 to-slate-950 border border-cyan-500/30 shadow-lg">
          <div class="flex items-center justify-between">
            <div>
              <div class="text-[10px] uppercase font-mono tracking-wider text-cyan-400">Vault Terenkripsi AES-256</div>
              <h2 class="text-sm font-black text-white">Villa Kemang Selatan #14B</h2>
            </div>
            ${canScan ? `
              <button id="btn-scan-baru" onclick="app.simulateLidarScan()" class="px-2.5 py-1.5 rounded-xl bg-cyan-500 hover:bg-cyan-400 text-slate-950 font-bold text-[11px] flex items-center gap-1 shadow-md shadow-cyan-500/20 cursor-pointer">
                <span>📡</span><span>Scan Baru</span>
              </button>
            ` : `
              <span class="px-2.5 py-1 rounded-xl bg-amber-500/15 border border-amber-500/30 text-amber-300 font-bold text-[10px]">
                🔒 View Only
              </span>
            `}
          </div>
        </div>

        <!-- 3D Spatial LiDAR Viewer Section -->
        <div class="rounded-2xl bg-slate-950 border border-cyan-500/40 overflow-hidden relative shadow-xl">
          <div class="flex items-center justify-between px-3 py-2 border-b border-white/10 bg-slate-900/70 text-xs">
            <span class="font-bold text-cyan-300 flex items-center gap-1.5">
              <span class="w-2 h-2 rounded-full bg-cyan-400 animate-pulse"></span>
              <span>LiDAR 3D Mesh</span>
            </span>
            <div class="flex items-center gap-1">
              <button id="btn-wireframe-toggle" onclick="app.toggleWireframe3D()" class="px-2 py-0.5 rounded bg-white/10 text-[10px] text-slate-300 hover:text-white cursor-pointer">
                🕸️ Wireframe
              </button>
              <span class="text-[9px] text-slate-500 font-mono">Drag 360°</span>
            </div>
          </div>

          <div class="relative w-full h-[220px] bg-slate-950">
            <canvas id="spatial-canvas-3d" class="w-full h-full cursor-grab active:cursor-grabbing"></canvas>

            <!-- Scanning Overlay HUD -->
            <div id="lidar-scan-hud" class="hidden absolute inset-0 bg-slate-950/90 backdrop-blur-sm flex flex-col items-center justify-center p-4 space-y-2.5">
              <span class="text-2xl animate-spin">📡</span>
              <div class="w-48 h-2 rounded-full bg-slate-800 overflow-hidden">
                <div id="scan-progress-bar" class="h-full bg-cyan-400 transition-all duration-200" style="width: 0%"></div>
              </div>
              <div id="scan-progress-text" class="text-[11px] font-mono text-cyan-300">Memetakan Ruang...</div>
            </div>
          </div>

          <!-- Room Selector Chips -->
          <div class="flex items-center gap-1.5 p-2 bg-slate-900/60 overflow-x-auto no-scrollbar border-t border-white/5 text-xs">
            ${this.rooms
              .map(
                (r) => `
              <button onclick="app.switchRoom3D('${esc(r.id)}')" data-room="${esc(r.id)}" class="chip-room px-2.5 py-1 rounded-xl text-[10px] font-bold whitespace-nowrap border transition cursor-pointer ${r.id === this.activeRoomId ? 'bg-cyan-500/20 border-cyan-400 text-cyan-300' : 'bg-white/5 border-white/10 text-slate-400'}">
                ${esc(r.name)} (${esc(r.areaSqm)}m²)
              </button>
            `
              )
              .join('')}
          </div>
        </div>

        <!-- Bento KPI Grid 2x2 -->
        <div class="grid grid-cols-2 gap-2.5 text-xs">
          <div class="bento-card p-3 rounded-2xl bg-slate-900/80 border border-white/10">
            <div class="text-[10px] text-slate-400 font-medium">Total Valuasi Aset</div>
            <div class="text-sm font-black text-amber-400 mt-0.5 truncate">${esc(this.formatCurrency(totalValuation))}</div>
            <div class="text-[9px] text-emerald-400 mt-1">${this.role === 'tenant' ? '🔒 Masked untuk Tenant' : '▲ Nilai Taksir Pasar'}</div>
          </div>
          <div class="bento-card p-3 rounded-2xl bg-slate-900/80 border border-white/10">
            <div class="text-[10px] text-slate-400 font-medium">Inventaris Terpetakan</div>
            <div class="text-sm font-black text-white mt-0.5">${visible.length} Aset Fisik</div>
            <div class="text-[9px] text-cyan-400 mt-1">${this.rooms.length} Ruangan (${totalAreaSqm} m²)</div>
          </div>
          <div class="bento-card p-3 rounded-2xl bg-slate-900/80 border border-white/10">
            <div class="text-[10px] text-slate-400 font-medium">Status Verifikasi</div>
            <div class="text-sm font-black text-emerald-300 mt-0.5">${verifiedCount} / ${visible.length} Diverifikasi</div>
            <div class="text-[9px] text-slate-400 mt-1">Surveyor Asuransi</div>
          </div>
          <div class="bento-card p-3 rounded-2xl bg-slate-900/80 border border-white/10">
            <div class="text-[10px] text-slate-400 font-medium">Klaim Asuransi Ready</div>
            <div class="text-sm font-black text-indigo-300 mt-0.5">${this.role === 'tenant' ? 'Mode Sewa' : '100% Sesuai Standar'}</div>
            <div class="text-[9px] text-indigo-400 mt-1">${this.role === 'tenant' ? 'Non-Finansial Handover' : 'SHA-256 Validated'}</div>
          </div>
        </div>

        <!-- Recent Activity Feed -->
        <div class="space-y-2">
          <div class="flex items-center justify-between text-xs px-1">
            <span class="font-bold text-slate-300">Aktivitas Spasial Terkini</span>
            <button onclick="app.setTab('analytics')" class="text-cyan-400 text-[11px] hover:underline cursor-pointer">Lihat Semua ›</button>
          </div>
          <div class="space-y-1.5 text-xs">
            ${this.role !== 'tenant' ? `
              <div class="p-2.5 rounded-xl bg-slate-900/60 border border-white/5 flex items-center justify-between">
                <div class="flex items-center gap-2">
                  <span class="text-base">✅</span>
                  <div>
                    <div class="font-bold text-white text-[11px]">MacBook Pro 16&quot; M3 Max diverifikasi</div>
                    <div class="text-[10px] text-slate-400">Surveyor menyetujui nilai taksir ${esc(this.formatCurrency(51200000))}</div>
                  </div>
                </div>
                <span class="text-[9px] text-slate-500">2 jam lalu</span>
              </div>
            ` : ''}
            <div class="p-2.5 rounded-xl bg-slate-900/60 border border-white/5 flex items-center justify-between">
              <div class="flex items-center gap-2">
                <span class="text-base">⚠️</span>
                <div>
                  <div class="font-bold text-amber-300 text-[11px]">Kondensasi AC dilaporkan Tenant</div>
                  <div class="text-[10px] text-slate-400">Master Bedroom • Perlu pembersihan pipa</div>
                </div>
              </div>
              <span class="text-[9px] text-slate-500">1 hari lalu</span>
            </div>
          </div>
        </div>
      </div>
    `;
  }

  // Layar 3: Asset Inventory CRUD + Search/Filter
  renderInventoryScreen() {
    const list = this.getFilteredAssets();
    const canAdd = this.role === 'owner';

    return `
      <div class="space-y-3 pb-24">
        <!-- Search & Filter Bar -->
        <div class="space-y-2">
          <div class="flex items-center gap-2 px-3 py-2 rounded-xl bg-slate-900 border border-white/10 text-xs">
            <span class="text-slate-400">🔍</span>
            <input id="inventory-search-input" type="text" value="${esc(this.searchQuery)}" oninput="app.searchQuery = this.value; app.render();" placeholder="Cari nama aset, serial number, atau brand..." class="w-full bg-transparent text-white focus:outline-none text-xs" />
          </div>

          <!-- Room Filter Chips -->
          <div class="flex items-center gap-1.5 overflow-x-auto text-xs pb-1">
            <button onclick="app.roomFilter = 'all'; app.render();" class="px-2.5 py-1 rounded-lg text-[10px] font-bold whitespace-nowrap border cursor-pointer ${this.roomFilter === 'all' ? 'bg-cyan-500/20 border-cyan-400 text-cyan-300' : 'bg-white/5 border-white/10 text-slate-400'}">Semua Ruangan</button>
            ${this.rooms
              .map(
                (r) => `
              <button onclick="app.roomFilter = '${esc(r.id)}'; app.render();" class="px-2.5 py-1 rounded-lg text-[10px] font-bold whitespace-nowrap border cursor-pointer ${this.roomFilter === r.id ? 'bg-cyan-500/20 border-cyan-400 text-cyan-300' : 'bg-white/5 border-white/10 text-slate-400'}">
                ${esc(r.name)}
              </button>
            `
              )
              .join('')}
          </div>
        </div>

        <!-- Assets List -->
        <div class="space-y-2">
          ${list.length === 0
            ? `<div class="p-8 text-center text-slate-500 text-xs">Tidak ada aset yang sesuai kriteria pencarian/filter.</div>`
            : list
                .map((a) => {
                  const room = this.rooms.find((r) => r.id === a.roomId) || { name: 'Ruangan' };
                  const statusBadge =
                    a.verificationStatus === 'verified'
                      ? '<span class="px-1.5 py-0.5 rounded bg-emerald-500/20 text-emerald-300 text-[9px] font-bold">✓ Terverifikasi</span>'
                      : a.verificationStatus === 'flagged'
                        ? '<span class="px-1.5 py-0.5 rounded bg-rose-500/20 text-rose-300 text-[9px] font-bold">⚠ Ada Catatan</span>'
                        : '<span class="px-1.5 py-0.5 rounded bg-amber-500/20 text-amber-300 text-[9px] font-bold">⏳ Menunggu Audit</span>';

                  const displayVal = this.role === 'tenant' ? 0 : (a.appraisedValue ?? a.currentValuation ?? 0);
                  const aid = safeId(a.id);

                  return `
              <div class="p-3 rounded-2xl bg-slate-900/80 border border-white/10 space-y-2 hover:border-cyan-500/30 transition">
                <div class="flex items-start justify-between gap-2">
                  <div>
                    <h3 class="font-bold text-white text-xs">${esc(a.name)}</h3>
                    <div class="text-[10px] text-slate-400 mt-0.5 font-mono">📍 ${esc(room.name)} • S/N: ${esc(a.serialNumber || 'N/A')}</div>
                  </div>
                  ${statusBadge}
                </div>

                <div class="flex items-center justify-between pt-1 border-t border-white/5 text-xs">
                  <div>
                    <div class="text-[9px] text-slate-400">Valuasi Terkini</div>
                    <div class="font-black text-amber-400 text-xs">${esc(this.formatCurrency(displayVal))}</div>
                  </div>

                  <div class="flex items-center gap-1.5">
                    ${this.role === 'inspector'
                      ? `
                      <button onclick="app.openInspectorAppraiseModal('${aid}')" class="px-2.5 py-1 rounded-lg bg-emerald-500/20 hover:bg-emerald-500/30 text-emerald-300 font-bold text-[10px] cursor-pointer">
                        🛡️ Verifikasi
                      </button>
                    `
                      : this.role === 'tenant'
                        ? `
                      <button onclick="app.openTenantReportModal('${aid}')" class="px-2.5 py-1 rounded-lg bg-amber-500/20 hover:bg-amber-500/30 text-amber-300 font-bold text-[10px] cursor-pointer">
                        📝 Lapor Kondisi
                      </button>
                    `
                        : `
                      <button onclick="app.openEditAssetModal('${aid}')" class="px-2 py-1 rounded-lg bg-white/5 hover:bg-white/10 text-slate-300 text-[10px] cursor-pointer">Edit</button>
                      <button onclick="app.deleteAsset('${aid}')" class="px-2 py-1 rounded-lg bg-rose-500/10 hover:bg-rose-500/20 text-rose-300 text-[10px] cursor-pointer">✕</button>
                    `}
                  </div>
                </div>

                ${a.tenantConditionNote
                  ? `
                  <div class="p-2 rounded-lg bg-rose-500/10 border border-rose-500/20 text-[10px] text-rose-200">
                    <b>Catatan Tenant:</b> ${esc(a.tenantConditionNote)}
                  </div>
                `
                  : ''}
              </div>
            `;
                })
                .join('')}
        </div>

        <!-- Floating Add Button for Owner -->
        ${canAdd
          ? `
          <button onclick="app.openAddAssetModal()" class="fixed bottom-20 right-8 px-4 py-2.5 rounded-full bg-cyan-500 hover:bg-cyan-400 text-slate-950 font-black text-xs shadow-xl shadow-cyan-500/30 flex items-center gap-2 cursor-pointer transition transform active:scale-95 z-30">
            <span class="text-base font-bold">+</span>
            <span>Tambah Aset</span>
          </button>
        `
          : ''}
      </div>
    `;
  }

  // Layar 4: Spatial Analytics & Valuation Charts
  renderAnalyticsScreen() {
    const visible = this.getVisibleAssets();
    const isMasked = this.role === 'tenant';
    const verifiedCount = visible.filter((a) => a.verificationStatus === 'verified').length;

    return `
      <div class="space-y-4 pb-20 text-xs">
        <div class="rounded-2xl p-4 bg-slate-900/80 border border-white/10 space-y-3">
          <div class="flex items-center justify-between">
            <span class="font-bold text-white text-xs">Valuasi Aset per Ruangan</span>
            <span class="text-[10px] text-cyan-400">Total ${this.rooms.length} Ruang</span>
          </div>

          <div class="space-y-2.5 pt-1">
            ${this.rooms
              .map((r) => {
                const roomAssets = visible.filter((a) => a.roomId === r.id);
                const roomVal = isMasked ? 0 : roomAssets.reduce((sum, a) => sum + (a.appraisedValue ?? a.currentValuation ?? 0), 0);
                const pct = isMasked ? 25 : Math.min(100, Math.round((roomVal / 400000000) * 100));

                return `
                <div class="space-y-1">
                  <div class="flex items-center justify-between text-[11px]">
                    <span class="text-slate-300 font-medium">${esc(r.name)} (${roomAssets.length} aset)</span>
                    <span class="font-mono font-bold text-amber-400">${esc(this.formatCurrency(roomVal))}</span>
                  </div>
                  <div class="w-full h-2 rounded-full bg-slate-800 overflow-hidden">
                    <div class="h-full bg-gradient-to-r from-cyan-500 to-emerald-400" style="width: ${pct}%"></div>
                  </div>
                </div>
              `;
              })
              .join('')}
          </div>
        </div>

        <!-- Depreciation Curve Box -->
        <div class="rounded-2xl p-4 bg-slate-900/80 border border-white/10 space-y-2">
          <div class="font-bold text-white text-xs">Kesiapan Dokumen Klaim Asuransi</div>
          <div class="text-[11px] text-slate-400 leading-relaxed">
            Data aset terenkripsi secara lokal (AES-256-GCM) dengan stempel SHA-256 yang memenuhi standar klaim B2B Asuransi Allianz / Zurich.
          </div>
          <div class="pt-2 flex items-center justify-between text-[11px]">
            <span class="text-emerald-400 font-bold">✓ ${verifiedCount} dari ${visible.length} Bukti Foto Valid</span>
            <span class="text-indigo-400 font-bold">✓ Audit Trail Aktif</span>
          </div>
        </div>
      </div>
    `;
  }

  // Layar 5: Profile, RBAC Switcher, Export (Non-Tenant), Server Config (Owner), & Logout
  renderProfileScreen() {
    const canExport = this.role !== 'tenant';

    return `
      <div class="space-y-4 pb-20 text-xs">
        <!-- Profile Card -->
        <div class="p-4 rounded-2xl bg-gradient-to-br from-slate-900 to-slate-950 border border-white/10 flex items-center gap-3">
          <div class="w-12 h-12 rounded-2xl bg-cyan-500/20 border border-cyan-400/40 flex items-center justify-center text-2xl">
            ${this.role === 'owner' ? '👑' : this.role === 'inspector' ? '🛡️' : '🏠'}
          </div>
          <div>
            <h3 class="font-bold text-white text-sm">Devcurl Spatial Admin</h3>
            <div class="text-[11px] text-cyan-300 font-mono capitalize">Role: ${esc(this.role)}</div>
            <div class="text-[9px] text-slate-500">ID: devcurl-vault-2026</div>
          </div>
        </div>

        <!-- Quick Switch Role Selector inside App -->
        <div class="p-3.5 rounded-2xl bg-slate-900/80 border border-white/10 space-y-2">
          <div class="text-[10px] uppercase font-mono text-slate-400 font-bold">Simulasi Role (RBAC)</div>
          <div class="grid grid-cols-3 gap-2">
            <button onclick="app.setRole('owner')" class="py-2 rounded-xl text-[11px] font-bold border transition cursor-pointer ${this.role === 'owner' ? 'bg-indigo-500/20 border-indigo-400 text-indigo-200' : 'bg-white/5 border-white/10 text-slate-400'}">👑 Owner</button>
            <button onclick="app.setRole('inspector')" class="py-2 rounded-xl text-[11px] font-bold border transition cursor-pointer ${this.role === 'inspector' ? 'bg-emerald-500/20 border-emerald-400 text-emerald-200' : 'bg-white/5 border-white/10 text-slate-400'}">🛡️ Surveyor</button>
            <button onclick="app.setRole('tenant')" class="py-2 rounded-xl text-[11px] font-bold border transition cursor-pointer ${this.role === 'tenant' ? 'bg-amber-500/20 border-amber-400 text-amber-200' : 'bg-white/5 border-white/10 text-slate-400'}">🏠 Tenant</button>
          </div>
        </div>

        <!-- Export Actions (Strictly hidden for Tenant role) -->
        ${canExport
          ? `
          <div id="profile-export-section" class="p-3.5 rounded-2xl bg-slate-900/80 border border-white/10 space-y-2.5">
            <div class="text-[10px] uppercase font-mono text-slate-400 font-bold">Ekspor Berkas &amp; Klaim (SHA-256 Sealed)</div>
            <div class="flex items-center gap-2">
              <button onclick="app.exportClaimReport('json')" class="flex-1 py-2 rounded-xl bg-cyan-500/15 hover:bg-cyan-500/25 border border-cyan-500/30 text-cyan-300 font-bold text-[11px] flex items-center justify-center gap-1.5 cursor-pointer">
                <span>📄</span><span>Export JSON</span>
              </button>
              <button onclick="app.exportClaimReport('csv')" class="flex-1 py-2 rounded-xl bg-amber-500/15 hover:bg-amber-500/25 border border-amber-500/30 text-amber-300 font-bold text-[11px] flex items-center justify-center gap-1.5 cursor-pointer">
                <span>📊</span><span>Export CSV</span>
              </button>
            </div>
            ${this.lastExportReport ? `
              <div id="last-export-sha256" class="p-2 rounded-xl bg-slate-950 border border-emerald-500/30 text-[10px] font-mono text-emerald-300 break-all">
                SHA-256: ${esc(this.lastExportReport.sha256Seal)}
              </div>
            ` : ''}
          </div>
        `
          : `
          <div class="p-3.5 rounded-2xl bg-amber-500/10 border border-amber-500/25 space-y-1">
            <div class="text-[10px] uppercase font-mono text-amber-300 font-bold">🔒 Akses Ekspor Dibatasi (RBAC Tenant)</div>
            <p class="text-[11px] text-slate-300 leading-relaxed">
              Role Tenant tidak diizinkan mengekspor data valuasi finansial maupun berkas klaim asuransi.
            </p>
          </div>
        `}

        <!-- Server Sync URL Setting (Owner Only) -->
        ${this.role === 'owner'
          ? `
          <div class="p-3.5 rounded-2xl bg-slate-900/80 border border-white/10 space-y-2">
            <div class="text-[10px] uppercase font-mono text-slate-400 font-bold">Backend Sync Server URL</div>
            <div class="flex items-center gap-2">
              <input type="text" id="setting-server-url" value="${esc(this.serverUrl)}" class="flex-1 px-3 py-1.5 rounded-xl bg-slate-950 border border-white/15 text-white font-mono text-xs focus:outline-none" />
              <button onclick="app.saveServerUrl();" class="px-3 py-1.5 rounded-xl bg-white/10 hover:bg-white/20 text-white font-bold text-xs cursor-pointer">Simpan</button>
            </div>
          </div>
        `
          : ''}

        <!-- Logout & Lock Vault -->
        <button id="btn-logout-vault" onclick="app.logout()" class="w-full py-2.5 rounded-xl bg-rose-500/15 hover:bg-rose-500/25 border border-rose-500/30 text-rose-300 font-bold text-xs flex items-center justify-center gap-2 cursor-pointer transition">
          <span>🔒</span><span>Keluar &amp; Kunci Vault (Ke Layar Login)</span>
        </button>
      </div>
    `;
  }

  renderBottomNav() {
    const tabs = [
      { id: 'home', icon: '🏠', label: 'Home 3D' },
      { id: 'inventory', icon: '📦', label: 'Inventaris' },
      { id: 'analytics', icon: '📊', label: 'Valuasi' },
      { id: 'profile', icon: '⚙️', label: 'Profil' },
    ];

    const el = document.getElementById('phone-bottom-nav');
    if (!el) return;

    el.innerHTML = tabs
      .map(
        (t) => `
      <button onclick="app.setTab('${t.id}')" data-tab="${t.id}" class="flex flex-col items-center justify-center py-1 flex-1 transition cursor-pointer ${this.tab === t.id ? 'text-cyan-400 font-black' : 'text-slate-400 hover:text-slate-200'}">
        <span class="text-base">${t.icon}</span>
        <span class="text-[9px] mt-0.5">${t.label}</span>
      </button>
    `
      )
      .join('');
  }
}

function showToast(msg, type = 'info') {
  const toast = document.getElementById('simulator-toast');
  if (!toast) return;
  toast.textContent = msg;
  toast.className = `fixed bottom-4 right-4 px-4 py-2 rounded-2xl text-xs font-bold text-white shadow-2xl transition-all duration-300 z-50 whitespace-nowrap ${type === 'error' ? 'bg-rose-600' : 'bg-slate-900/95 border border-cyan-400/50'}`;
  toast.classList.remove('opacity-0', 'pointer-events-none');
  setTimeout(() => {
    toast.classList.add('opacity-0', 'pointer-events-none');
  }, 2800);
}

window.app = new AppSimulator();
window.addEventListener('DOMContentLoaded', () => {
  document.body.className = `theme-${window.app.theme} flex flex-col items-center justify-start py-4 px-3 gap-4`;
  window.app.render();
  if (window.app.isAuthenticated && window.app.tab === 'home') {
    setTimeout(() => window.app.initOrUpdate3D(), 100);
  }
});
