import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../models/app_models.dart';

class _ProjectedPin {
  final AssetItem asset;
  final Offset screenPos;
  final double depth;

  const _ProjectedPin({
    required this.asset,
    required this.screenPos,
    required this.depth,
  });
}

class _ProjectedRoomCenter {
  final Room3D room;
  final Offset screenPos;

  const _ProjectedRoomCenter({
    required this.room,
    required this.screenPos,
  });
}

class Spatial3DCanvas extends StatefulWidget {
  final List<Room3D> rooms;
  final List<AssetItem> assets;
  final String selectedRoomId;
  final UserRole role;
  final SpatialPalette palette;
  final ValueChanged<String> onSelectRoom;
  final ValueChanged<AssetItem> onSelectAsset;
  final VoidCallback onOpenRoomInventory;

  const Spatial3DCanvas({
    super.key,
    required this.rooms,
    required this.assets,
    required this.selectedRoomId,
    required this.role,
    required this.palette,
    required this.onSelectRoom,
    required this.onSelectAsset,
    required this.onOpenRoomInventory,
  });

  @override
  State<Spatial3DCanvas> createState() => _Spatial3DCanvasState();
}

class _Spatial3DCanvasState extends State<Spatial3DCanvas> {
  double _yaw = -0.58;
  double _pitch = 0.52;
  double _zoom = 1.0;
  bool _xrayMode = false;
  AssetItem? _activePinAsset;

  List<_ProjectedPin> _lastProjectedPins = const [];
  List<_ProjectedRoomCenter> _lastRoomCenters = const [];

  void _resetCamera() {
    HapticFeedback.selectionClick();
    setState(() {
      _yaw = -0.58;
      _pitch = 0.52;
      _zoom = 1.0;
      _activePinAsset = null;
    });
  }

  void _handleTapDown(TapDownDetails details, Size size) {
    final tap = details.localPosition;

    _ProjectedPin? nearestPin;
    double nearestDist = 26.0;
    for (final p in _lastProjectedPins) {
      final d = (p.screenPos - tap).distance;
      if (d < nearestDist) {
        nearestDist = d;
        nearestPin = p;
      }
    }

    if (nearestPin != null) {
      HapticFeedback.lightImpact();
      setState(() {
        _activePinAsset = nearestPin!.asset;
      });
      widget.onSelectRoom(nearestPin.asset.roomId);
      return;
    }

    _ProjectedRoomCenter? nearestRoom;
    double roomDist = 56.0;
    for (final rc in _lastRoomCenters) {
      final d = (rc.screenPos - tap).distance;
      if (d < roomDist) {
        roomDist = d;
        nearestRoom = rc;
      }
    }

    if (nearestRoom != null) {
      HapticFeedback.selectionClick();
      setState(() {
        _activePinAsset = null;
      });
      widget.onSelectRoom(nearestRoom.room.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final selectedRoom = widget.rooms.firstWhere(
      (r) => r.id == widget.selectedRoomId,
      orElse: () => widget.rooms.first,
    );
    final roomAssetCount =
        widget.assets.where((a) => a.roomId == selectedRoom.id).length;

    return Container(
      height: 274,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 1.1,
          colors: p.isDark
              ? const [Color(0xFF0F1E2E), Color(0xFF060A12)]
              : const [Color(0xFFE0F2FE), Color(0xFFE2E8F0)],
        ),
        border: Border.all(color: p.cyan.withOpacity(0.28)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                final projection = _computeProjection(size);
                _lastProjectedPins = projection.pins;
                _lastRoomCenters = projection.roomCenters;

                return GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _yaw += details.delta.dx * 0.011;
                      _pitch = (_pitch + details.delta.dy * 0.009).clamp(0.22, 1.18);
                    });
                  },
                  onTapDown: (details) => _handleTapDown(details, size),
                  child: CustomPaint(
                    size: size,
                    painter: _IsometricLidarPainter(
                      rooms: widget.rooms,
                      selectedRoomId: widget.selectedRoomId,
                      yaw: _yaw,
                      pitch: _pitch,
                      zoom: _zoom,
                      xrayMode: _xrayMode,
                      palette: p,
                      projectedPins: projection.pins,
                      activePinId: _activePinAsset?.id,
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: p.glass,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: p.borderSubtle),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.view_in_ar_rounded, size: 14, color: p.cyan),
                        const SizedBox(width: 6),
                        Text(
                          '3D LIDAR • DRAG TO ORBIT',
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _MiniCanvasButton(
                        icon: _xrayMode ? Icons.layers_clear : Icons.layers,
                        tooltip: 'X-Ray',
                        palette: p,
                        active: _xrayMode,
                        onTap: () => setState(() => _xrayMode = !_xrayMode),
                      ),
                      const SizedBox(width: 6),
                      _MiniCanvasButton(
                        icon: Icons.add,
                        tooltip: 'Zoom In',
                        palette: p,
                        onTap: () => setState(() => _zoom = (_zoom + 0.14).clamp(0.7, 1.7)),
                      ),
                      const SizedBox(width: 6),
                      _MiniCanvasButton(
                        icon: Icons.refresh_rounded,
                        tooltip: 'Reset',
                        palette: p,
                        onTap: _resetCamera,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_activePinAsset != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 58,
                child: GestureDetector(
                  onTap: () => widget.onSelectAsset(_activePinAsset!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: p.elevated.withOpacity(0.94),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: p.cyan.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _activePinAsset!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: p.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.role.canViewFinancials
                                    ? '${AppState.formatIdr(_activePinAsset!.effectiveValuation)} • Pin (${_activePinAsset!.pinX}, ${_activePinAsset!.pinY}, ${_activePinAsset!.pinZ})'
                                    : 'Valuasi Disamarkan • Pin (${_activePinAsset!.pinX}, ${_activePinAsset!.pinY}, ${_activePinAsset!.pinZ})',
                                style: TextStyle(
                                  color: p.cyan,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Detail ›',
                          style: TextStyle(
                            color: p.emerald,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: p.glass,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.borderSubtle),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            selectedRoom.scanVerified
                                ? Icons.verified_rounded
                                : Icons.pending_rounded,
                            size: 15,
                            color: selectedRoom.scanVerified ? p.emerald : p.gold,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${selectedRoom.name} • ${selectedRoom.areaSqm.toStringAsFixed(1)} m² • $roomAssetCount Aset',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: p.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: widget.onOpenRoomInventory,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: p.lidarGradient,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Lihat Aset →',
                          style: TextStyle(
                            color: p.ctaForeground,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _ProjectionResult _computeProjection(Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.52);
    final scale = (math.min(size.width, size.height) / 15.5) * _zoom;

    Offset projectPoint(double x, double y, double z) {
      final cosY = math.cos(_yaw);
      final sinY = math.sin(_yaw);
      final x1 = x * cosY - z * sinY;
      final z1 = x * sinY + z * cosY;

      final cosP = math.cos(_pitch);
      final sinP = math.sin(_pitch);
      final y2 = y * cosP - z1 * sinP;
      return Offset(center.dx + x1 * scale, center.dy - y2 * scale);
    }

    double depthOf(double x, double y, double z) {
      final cosY = math.cos(_yaw);
      final sinY = math.sin(_yaw);
      final z1 = x * sinY + z * cosY;
      final cosP = math.cos(_pitch);
      final sinP = math.sin(_pitch);
      return y * sinP + z1 * cosP;
    }

    final pins = <_ProjectedPin>[];
    for (final asset in widget.assets) {
      final room = widget.rooms.firstWhere(
        (r) => r.id == asset.roomId,
        orElse: () => widget.rooms.first,
      );
      final wx = room.offsetX - room.widthM * 0.42 + (asset.pinX % room.widthM);
      final wy = room.offsetY + (asset.pinY.clamp(0.3, room.heightM - 0.3));
      final wz = room.offsetZ - room.depthM * 0.42 + (asset.pinZ % room.depthM);
      pins.add(_ProjectedPin(
        asset: asset,
        screenPos: projectPoint(wx, wy, wz),
        depth: depthOf(wx, wy, wz),
      ));
    }
    pins.sort((a, b) => a.depth.compareTo(b.depth));

    final roomCenters = widget.rooms.map((r) {
      return _ProjectedRoomCenter(
        room: r,
        screenPos: projectPoint(r.offsetX, r.offsetY + 0.5, r.offsetZ),
      );
    }).toList();

    return _ProjectionResult(pins: pins, roomCenters: roomCenters);
  }
}

class _ProjectionResult {
  final List<_ProjectedPin> pins;
  final List<_ProjectedRoomCenter> roomCenters;

  const _ProjectionResult({
    required this.pins,
    required this.roomCenters,
  });
}

class _MiniCanvasButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final SpatialPalette palette;
  final bool active;
  final VoidCallback onTap;

  const _MiniCanvasButton({
    required this.icon,
    required this.tooltip,
    required this.palette,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: active ? palette.cyan.withOpacity(0.24) : palette.glass,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? palette.cyan : palette.borderSubtle,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: active ? palette.cyan : palette.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _IsometricLidarPainter extends CustomPainter {
  final List<Room3D> rooms;
  final String selectedRoomId;
  final double yaw;
  final double pitch;
  final double zoom;
  final bool xrayMode;
  final SpatialPalette palette;
  final List<_ProjectedPin> projectedPins;
  final String? activePinId;

  _IsometricLidarPainter({
    required this.rooms,
    required this.selectedRoomId,
    required this.yaw,
    required this.pitch,
    required this.zoom,
    required this.xrayMode,
    required this.palette,
    required this.projectedPins,
    required this.activePinId,
  });

  Offset _project(double x, double y, double z, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.52);
    final scale = (math.min(size.width, size.height) / 15.5) * zoom;
    final cosY = math.cos(yaw);
    final sinY = math.sin(yaw);
    final x1 = x * cosY - z * sinY;
    final z1 = x * sinY + z * cosY;

    final cosP = math.cos(pitch);
    final sinP = math.sin(pitch);
    final y2 = y * cosP - z1 * sinP;
    return Offset(center.dx + x1 * scale, center.dy - y2 * scale);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = palette.cyan.withOpacity(palette.isDark ? 0.12 : 0.16)
      ..strokeWidth = 0.8;

    for (double g = -8; g <= 8; g += 2.0) {
      canvas.drawLine(
        _project(g, 0, -8, size),
        _project(g, 0, 8, size),
        gridPaint,
      );
      canvas.drawLine(
        _project(-8, 0, g, size),
        _project(8, 0, g, size),
        gridPaint,
      );
    }

    for (final room in rooms) {
      final isSelected = room.id == selectedRoomId;
      final hw = room.widthM * 0.45;
      final hd = room.depthM * 0.45;
      final y0 = room.offsetY;
      final y1 = room.offsetY + room.heightM * 0.65;

      final b0 = _project(room.offsetX - hw, y0, room.offsetZ - hd, size);
      final b1 = _project(room.offsetX + hw, y0, room.offsetZ - hd, size);
      final b2 = _project(room.offsetX + hw, y0, room.offsetZ + hd, size);
      final b3 = _project(room.offsetX - hw, y0, room.offsetZ + hd, size);

      final t0 = _project(room.offsetX - hw, y1, room.offsetZ - hd, size);
      final t1 = _project(room.offsetX + hw, y1, room.offsetZ - hd, size);
      final t2 = _project(room.offsetX + hw, y1, room.offsetZ + hd, size);
      final t3 = _project(room.offsetX - hw, y1, room.offsetZ + hd, size);

      final floorPath = Path()
        ..moveTo(b0.dx, b0.dy)
        ..lineTo(b1.dx, b1.dy)
        ..lineTo(b2.dx, b2.dy)
        ..lineTo(b3.dx, b3.dy)
        ..close();

      final fillPaint = Paint()
        ..color = (isSelected ? room.accentColor : palette.cyan).withOpacity(
          xrayMode ? (isSelected ? 0.12 : 0.04) : (isSelected ? 0.24 : 0.09),
        )
        ..style = PaintingStyle.fill;
      canvas.drawPath(floorPath, fillPaint);

      final edgePaint = Paint()
        ..color = isSelected
            ? room.accentColor
            : (room.scanVerified
                ? palette.cyan.withOpacity(0.55)
                : palette.gold.withOpacity(0.75))
        ..strokeWidth = isSelected ? 2.0 : 1.0
        ..style = PaintingStyle.stroke;

      canvas.drawPath(floorPath, edgePaint);

      if (!xrayMode || isSelected) {
        final roofPath = Path()
          ..moveTo(t0.dx, t0.dy)
          ..lineTo(t1.dx, t1.dy)
          ..lineTo(t2.dx, t2.dy)
          ..lineTo(t3.dx, t3.dy)
          ..close();
        canvas.drawPath(
          roofPath,
          edgePaint..color = edgePaint.color.withOpacity(isSelected ? 0.85 : 0.32),
        );
        canvas.drawLine(b0, t0, edgePaint);
        canvas.drawLine(b1, t1, edgePaint);
        canvas.drawLine(b2, t2, edgePaint);
        canvas.drawLine(b3, t3, edgePaint);
      }

      final labelPos = _project(room.offsetX, y0 + 0.1, room.offsetZ, size);
      final textPainter = TextPainter(
        text: TextSpan(
          text: room.name,
          style: TextStyle(
            color: isSelected ? palette.textPrimary : palette.textSecondary,
            fontSize: isSelected ? 10.5 : 9.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(labelPos.dx - textPainter.width / 2, labelPos.dy - textPainter.height / 2),
      );
    }

    for (final pin in projectedPins) {
      final isActive = pin.asset.id == activePinId;
      Color pinColor;
      switch (pin.asset.verificationStatus) {
        case VerificationStatus.verified:
          pinColor = palette.emerald;
          break;
        case VerificationStatus.pending:
          pinColor = palette.gold;
          break;
        case VerificationStatus.flagged:
          pinColor = palette.danger;
          break;
      }

      canvas.drawCircle(
        pin.screenPos,
        isActive ? 12 : 8.5,
        Paint()..color = pinColor.withOpacity(isActive ? 0.34 : 0.2),
      );
      canvas.drawCircle(
        pin.screenPos,
        isActive ? 6.5 : 4.8,
        Paint()..color = pinColor,
      );
      canvas.drawCircle(
        pin.screenPos,
        isActive ? 6.5 : 4.8,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1.4
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _IsometricLidarPainter oldDelegate) {
    return oldDelegate.yaw != yaw ||
        oldDelegate.pitch != pitch ||
        oldDelegate.zoom != zoom ||
        oldDelegate.xrayMode != xrayMode ||
        oldDelegate.selectedRoomId != selectedRoomId ||
        oldDelegate.activePinId != activePinId ||
        oldDelegate.rooms.length != rooms.length ||
        oldDelegate.projectedPins.length != projectedPins.length ||
        oldDelegate.palette.isDark != palette.isDark;
  }
}
