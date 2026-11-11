/**
 * Spatial 3D Home — WebGL & Interactive 3D Room LiDAR Viewer
 * Built for iPhone 15 Pro & Android Simulator in Faber Staging
 */

class Spatial3DViewer {
  constructor(canvasId) {
    this.canvas = document.getElementById(canvasId);
    this.scene = null;
    this.camera = null;
    this.renderer = null;
    this.roomMesh = null;
    this.gridHelper = null;
    this.pinObjects = [];
    this.activeRoomId = 'room-living';
    this.wireframeMode = true;
    this.isDragging = false;
    this.previousMousePosition = { x: 0, y: 0 };
    this.rotation = { x: 0.35, y: -0.45 };
    this.targetRotation = { x: 0.35, y: -0.45 };
    this.zoom = 1.0;
    this.roomsData = {};
    this.assetsData = [];
    this.onPinClick = null;
    this.animId = null;

    this.init();
  }

  init() {
    if (!this.canvas) return;
    const width = this.canvas.clientWidth || 360;
    const height = this.canvas.clientHeight || 240;

    // Check if Three.js is available via CDN, otherwise fallback to 2.5D Canvas Isometric
    if (typeof THREE !== 'undefined') {
      try {
        this.scene = new THREE.Scene();
        this.camera = new THREE.PerspectiveCamera(45, width / height, 0.1, 100);
        this.camera.position.set(0, 4.5, 9.5);
        this.camera.lookAt(0, 0, 0);

        this.renderer = new THREE.WebGLRenderer({
          canvas: this.canvas,
          antialias: true,
          alpha: true,
        });
        this.renderer.setSize(width, height);
        this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));

        // Soft Ambient + Cyan/Emerald LiDAR directional lights
        const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
        this.scene.add(ambientLight);

        const dirLight = new THREE.DirectionalLight(0x06b6d4, 1.2);
        dirLight.position.set(5, 10, 7);
        this.scene.add(dirLight);

        const rimLight = new THREE.DirectionalLight(0x10b981, 0.8);
        rimLight.position.set(-5, -3, -5);
        this.scene.add(rimLight);

        this.roomGroup = new THREE.Group();
        this.scene.add(this.roomGroup);

        this.bindEvents();
        this.animate();
        return;
      } catch (err) {
        console.warn('Three.js init failed, falling back to 2.5D Canvas:', err);
      }
    }

    // Fallback Canvas mode
    this.initCanvasFallback();
  }

  bindEvents() {
    const el = this.canvas;
    const onStart = (x, y) => {
      this.isDragging = true;
      this.previousMousePosition = { x, y };
    };
    const onMove = (x, y) => {
      if (!this.isDragging) return;
      const deltaX = x - this.previousMousePosition.x;
      const deltaY = y - this.previousMousePosition.y;
      this.targetRotation.y += deltaX * 0.008;
      this.targetRotation.x = Math.max(-0.2, Math.min(1.1, this.targetRotation.x + deltaY * 0.008));
      this.previousMousePosition = { x, y };
    };
    const onEnd = () => {
      this.isDragging = false;
    };

    el.addEventListener('mousedown', (e) => onStart(e.clientX, e.clientY));
    window.addEventListener('mousemove', (e) => onMove(e.clientX, e.clientY));
    window.addEventListener('mouseup', onEnd);

    el.addEventListener('touchstart', (e) => {
      if (e.touches.length === 1) {
        onStart(e.touches[0].clientX, e.touches[0].clientY);
      }
    }, { passive: true });
    window.addEventListener('touchmove', (e) => {
      if (e.touches.length === 1) {
        onMove(e.touches[0].clientX, e.touches[0].clientY);
      }
    }, { passive: true });
    window.addEventListener('touchend', onEnd);
  }

  loadData(rooms, assets) {
    this.roomsData = {};
    for (const r of rooms) this.roomsData[r.id] = r;
    this.assetsData = assets || [];
    this.rebuildRoom3D();
  }

  setRoom(roomId) {
    if (this.roomsData[roomId]) {
      this.activeRoomId = roomId;
      this.rebuildRoom3D();
    }
  }

  toggleWireframe() {
    this.wireframeMode = !this.wireframeMode;
    this.rebuildRoom3D();
    return this.wireframeMode;
  }

  rebuildRoom3D() {
    if (!this.scene || !this.roomGroup) {
      this.drawCanvasFallback();
      return;
    }

    // Clear old objects
    while (this.roomGroup.children.length > 0) {
      const obj = this.roomGroup.children[0];
      this.roomGroup.remove(obj);
      if (obj.geometry) obj.geometry.dispose();
      if (obj.material) {
        if (Array.isArray(obj.material)) obj.material.forEach((m) => m.dispose());
        else obj.material.dispose();
      }
    }
    this.pinObjects = [];

    const room = this.roomsData[this.activeRoomId] || {
      name: 'Living Room',
      widthM: 6.8,
      depthM: 6.2,
      heightM: 3.2,
      accentColor: '#06B6D4',
    };

    const w = room.widthM * 0.7;
    const h = room.heightM * 0.7;
    const d = room.depthM * 0.7;
    const accentHex = parseInt((room.accentColor || '#06B6D4').replace('#', '0x'), 16);

    // 1. Room Floor Grid (LiDAR mesh plane)
    const grid = new THREE.GridHelper(Math.max(w, d) * 1.4, 14, accentHex, 0x1e293b);
    grid.position.y = -h / 2;
    this.roomGroup.add(grid);

    // 2. Room Box Walls (Semi-transparent with glowing edges)
    const boxGeo = new THREE.BoxGeometry(w, h, d);
    const boxMat = new THREE.MeshStandardMaterial({
      color: 0x0c1a29,
      transparent: true,
      opacity: this.wireframeMode ? 0.25 : 0.65,
      roughness: 0.3,
      metalness: 0.5,
      side: THREE.BackSide,
    });
    const boxMesh = new THREE.Mesh(boxGeo, boxMat);
    this.roomGroup.add(boxMesh);

    // Wireframe Edges
    const edges = new THREE.EdgesGeometry(boxGeo);
    const lineMat = new THREE.LineBasicMaterial({
      color: accentHex,
      linewidth: 2,
      transparent: true,
      opacity: 0.85,
    });
    const wireframe = new THREE.LineSegments(edges, lineMat);
    this.roomGroup.add(wireframe);

    // 3. Subtle Furniture Blocks based on room
    const furnColor = 0x1f293d;
    if (this.activeRoomId === 'room-living') {
      // Sofa mesh
      const sofa = new THREE.Mesh(
        new THREE.BoxGeometry(w * 0.45, h * 0.25, d * 0.25),
        new THREE.MeshStandardMaterial({ color: furnColor, roughness: 0.6 })
      );
      sofa.position.set(0, -h / 2 + h * 0.125, d * 0.15);
      this.roomGroup.add(sofa);
      // TV Stand on wall
      const tv = new THREE.Mesh(
        new THREE.BoxGeometry(w * 0.5, h * 0.05, d * 0.08),
        new THREE.MeshStandardMaterial({ color: 0x334155 })
      );
      tv.position.set(0, -h / 2 + h * 0.35, -d * 0.45);
      this.roomGroup.add(tv);
    } else if (this.activeRoomId === 'room-studio') {
      // Desk
      const desk = new THREE.Mesh(
        new THREE.BoxGeometry(w * 0.55, h * 0.08, d * 0.35),
        new THREE.MeshStandardMaterial({ color: furnColor })
      );
      desk.position.set(0, -h / 2 + h * 0.3, 0);
      this.roomGroup.add(desk);
    } else if (this.activeRoomId === 'room-bedroom') {
      // Bed
      const bed = new THREE.Mesh(
        new THREE.BoxGeometry(w * 0.5, h * 0.22, d * 0.6),
        new THREE.MeshStandardMaterial({ color: furnColor })
      );
      bed.position.set(0, -h / 2 + h * 0.11, 0);
      this.roomGroup.add(bed);
    }

    // 4. Asset Pins in this room
    const roomAssets = this.assetsData.filter((a) => a.roomId === this.activeRoomId);
    roomAssets.forEach((asset, idx) => {
      // Relative placement inside room
      const px = ((asset.pinX || 1.0) / (room.widthM || 6.0) - 0.5) * w * 0.8;
      const py = -h / 2 + ((asset.pinY || 1.0) / (room.heightM || 3.0)) * h * 0.8 + 0.15;
      const pz = ((asset.pinZ || 1.0) / (room.depthM || 6.0) - 0.5) * d * 0.8;

      const pinGroup = new THREE.Group();
      pinGroup.position.set(px, py, pz);

      // Glowing Diamond / Octahedron Pin
      const pinGeo = new THREE.OctahedronGeometry(0.18, 0);
      const isVerified = asset.verificationStatus === 'verified';
      const pinColor = isVerified ? 0x10b981 : asset.verificationStatus === 'flagged' ? 0xef4444 : 0xf59e0b;
      const pinMat = new THREE.MeshStandardMaterial({
        color: pinColor,
        emissive: pinColor,
        emissiveIntensity: 0.5,
        roughness: 0.2,
        metalness: 0.8,
      });
      const pinMesh = new THREE.Mesh(pinGeo, pinMat);
      pinGroup.add(pinMesh);

      // Stem line down to floor
      const stemGeo = new THREE.BufferGeometry().setFromPoints([
        new THREE.Vector3(0, 0, 0),
        new THREE.Vector3(0, -(py + h / 2), 0),
      ]);
      const stemMat = new THREE.LineDashedMaterial({
        color: pinColor,
        dashSize: 0.08,
        gapSize: 0.04,
        transparent: true,
        opacity: 0.5,
      });
      const stemLine = new THREE.Line(stemGeo, stemMat);
      stemLine.computeLineDistances();
      pinGroup.add(stemLine);

      pinGroup.userData = { asset };
      this.roomGroup.add(pinGroup);
      this.pinObjects.push(pinGroup);
    });
  }

  animate() {
    this.animId = requestAnimationFrame(() => this.animate());

    // Smooth rotation dampening
    this.rotation.x += (this.targetRotation.x - this.rotation.x) * 0.1;
    this.rotation.y += (this.targetRotation.y - this.rotation.y) * 0.1;

    if (this.roomGroup) {
      this.roomGroup.rotation.x = this.rotation.x;
      this.roomGroup.rotation.y = this.rotation.y;

      // Bobbing animation for pins
      const time = Date.now() * 0.003;
      this.pinObjects.forEach((p, idx) => {
        p.children[0].rotation.y = time * 0.8 + idx;
        p.children[0].position.y = Math.sin(time + idx) * 0.04;
      });
    }

    if (this.renderer && this.scene && this.camera) {
      this.renderer.render(this.scene, this.camera);
    }
  }

  // Graceful Canvas 2.5D Fallback for offline / low-end environments
  initCanvasFallback() {
    this.ctx = this.canvas.getContext('2d');
    this.bindEvents();
    this.drawCanvasFallback();
  }

  drawCanvasFallback() {
    if (!this.ctx) return;
    const ctx = this.ctx;
    const w = this.canvas.width = this.canvas.clientWidth || 360;
    const h = this.canvas.height = this.canvas.clientHeight || 240;

    ctx.clearRect(0, 0, w, h);
    ctx.save();
    ctx.translate(w / 2, h / 2 + 10);

    // Iso floor
    ctx.strokeStyle = '#06B6D4';
    ctx.lineWidth = 1.5;
    ctx.fillStyle = 'rgba(6, 182, 212, 0.06)';

    ctx.beginPath();
    ctx.moveTo(0, -50);
    ctx.lineTo(120, 10);
    ctx.lineTo(0, 70);
    ctx.lineTo(-120, 10);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();

    // Walls
    ctx.strokeStyle = 'rgba(148, 163, 184, 0.4)';
    ctx.strokeRect(-90, -90, 180, 90);

    // Room Label
    ctx.fillStyle = '#F8FAFC';
    ctx.font = 'bold 12px system-ui';
    ctx.textAlign = 'center';
    const room = this.roomsData[this.activeRoomId] || { name: 'Living Room', areaSqm: 42.5 };
    ctx.fillText(`📐 ${room.name} (${room.areaSqm} m²)`, 0, -100);

    // Asset Pins
    const roomAssets = this.assetsData.filter((a) => a.roomId === this.activeRoomId);
    roomAssets.forEach((a, i) => {
      const px = -60 + (i * 35) % 120;
      const py = 10 + (i * 12) % 40;
      ctx.fillStyle = a.verificationStatus === 'verified' ? '#10B981' : '#F59E0B';
      ctx.beginPath();
      ctx.arc(px, py, 5, 0, Math.PI * 2);
      ctx.fill();
      ctx.strokeStyle = '#FFFFFF';
      ctx.lineWidth = 1.5;
      ctx.stroke();
    });

    ctx.restore();
  }

  destroy() {
    if (this.animId) cancelAnimationFrame(this.animId);
  }
}

window.Spatial3DViewer = Spatial3DViewer;
