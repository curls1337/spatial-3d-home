import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../core/spatial_bridge.dart';
import '../data/seed_data.dart';
import '../models/app_models.dart';
import '../widgets/asset_form_sheet.dart';
import '../widgets/role_badge.dart';
import '../widgets/spatial_3d_canvas.dart';

class SpatialHomeScreen extends StatefulWidget {
  final AppState state;
  final SpatialPalette palette;

  const SpatialHomeScreen({
    super.key,
    required this.state,
    required this.palette,
  });

  @override
  State<SpatialHomeScreen> createState() => _SpatialHomeScreenState();
}

class _SpatialHomeScreenState extends State<SpatialHomeScreen> {
  final SpatialBridgeService _bridge = SpatialBridgeService();
  bool _scanning = false;

  Future<void> _openLidarScannerDialog() async {
    if (!widget.state.currentRole.canScanLidar) return;
    HapticFeedback.lightImpact();
    final cap = await _bridge.checkCapabilities();
    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final p = widget.palette;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: p.borderSubtle),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'LiDAR / 3D Room Scanner',
                        style: TextStyle(
                          color: p.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: p.emerald.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'On-Device Only',
                          style: TextStyle(
                            color: p.emerald,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Engine aktif: ${cap.engine} • 0 Byte Raw Video Uploaded.',
                    style: TextStyle(color: p.textSecondary, fontSize: 12.5),
                  ),
                  const SizedBox(height: 16),
                  if (_scanning) ...[
                    LinearProgressIndicator(color: p.cyan, backgroundColor: p.elevated),
                    const SizedBox(height: 10),
                    Text(
                      'Memetakan mesh dinding & furnitur (14,820 vertices • ±1.2 cm)...',
                      style: TextStyle(color: p.cyan, fontSize: 12),
                    ),
                  ] else ...[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: p.lidarGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          setModalState(() => _scanning = true);
                          await _bridge.startRoomScan('Modern Kitchen');
                          await Future<void>.delayed(const Duration(milliseconds: 900));
                          widget.state.completeLidarScan(addNewRoom: false);
                          if (ctx.mounted) {
                            setModalState(() => _scanning = false);
                            Navigator.of(ctx).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: p.ctaForeground,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.radar_rounded),
                        label: const Text(
                          'Verifikasi Scan Modern Kitchen (22.1 m²)',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        setModalState(() => _scanning = true);
                        await _bridge.startRoomScan('Guest Bedroom');
                        await Future<void>.delayed(const Duration(milliseconds: 900));
                        widget.state.completeLidarScan(addNewRoom: true);
                        if (ctx.mounted) {
                          setModalState(() => _scanning = false);
                          Navigator.of(ctx).pop();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: p.textPrimary,
                        side: BorderSide(color: p.borderSubtle),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: Icon(Icons.add_home_work_rounded, color: p.cyan),
                      label: const Text('Tambah Ruangan Baru: Guest Bedroom (16.5 m²)'),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final p = widget.palette;
    final role = s.currentRole;
    final visibleAssets = s.visibleAssets;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      SeedData.propertyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        RoleBadge(role: role, palette: p),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (s.pendingSyncCount == 0 ? p.emerald : p.gold)
                                .withOpacity(0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            s.pendingSyncCount == 0
                                ? '● Vault Synced'
                                : '● ${s.pendingSyncCount} Pending',
                            style: TextStyle(
                              color: s.pendingSyncCount == 0 ? p.emerald : p.gold,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => s.setTab(2),
                icon: Icon(Icons.notifications_none_rounded, color: p.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Spatial3DCanvas(
            rooms: s.rooms,
            assets: visibleAssets,
            selectedRoomId: s.selectedRoomId,
            role: role,
            palette: p,
            onSelectRoom: s.selectRoom,
            onSelectAsset: (asset) => showAssetActionSheet(
              context: context,
              state: s,
              palette: p,
              existingAsset: asset,
            ),
            onOpenRoomInventory: () => s.openInventoryForRoom(s.selectedRoomId),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: s.rooms.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final room = s.rooms[idx];
                final active = room.id == s.selectedRoomId;
                return ChoiceChip(
                  label: Text('${room.name} (${room.areaSqm.toStringAsFixed(1)}m²)'),
                  selected: active,
                  onSelected: (_) => s.selectRoom(room.id),
                  selectedColor: p.cyan.withOpacity(0.22),
                  backgroundColor: p.surface,
                  side: BorderSide(color: active ? p.cyan : p.borderSubtle),
                  labelStyle: TextStyle(
                    color: active ? p.cyan : p.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'BENTO KPI OVERVIEW',
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _BentoCard(
                  palette: p,
                  icon: Icons.account_balance_wallet_rounded,
                  accent: role.canViewFinancials ? p.gold : p.textSecondary,
                  label: 'Total Valuasi',
                  value: role.canViewFinancials
                      ? AppState.formatCompactIdr(s.totalCurrentValuation)
                      : 'Disamarkan',
                  sublabel: role.canViewFinancials
                      ? 'Beli ${AppState.formatCompactIdr(s.totalPurchaseValue)}'
                      : 'Privasi Tenant Dilindungi',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BentoCard(
                  palette: p,
                  icon: Icons.inventory_2_rounded,
                  accent: p.cyan,
                  label: 'Total Aset',
                  value: '${visibleAssets.length} Item',
                  sublabel: '${s.rooms.length} Ruangan 3D',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _BentoCard(
                  palette: p,
                  icon: Icons.square_foot_rounded,
                  accent: p.info,
                  label: 'Luas Terpindai',
                  value: '${s.totalAreaSqm.toStringAsFixed(1)} m²',
                  sublabel: '${s.verifiedRoomsCount}/${s.rooms.length} Scan Verified',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BentoCard(
                  palette: p,
                  icon: Icons.verified_rounded,
                  accent: p.emerald,
                  label: 'Terverifikasi',
                  value: role.canViewFinancials
                      ? '${s.verifiedAssetsPct.toStringAsFixed(1)}%'
                      : 'Authorized',
                  sublabel: '${s.flaggedAssetsCount} Flagged Issue',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'QUICK ACTIONS',
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (role.canScanLidar)
                _QuickActionTile(
                  icon: Icons.radar_rounded,
                  label: 'Scan LiDAR',
                  accent: p.cyan,
                  palette: p,
                  onTap: _openLidarScannerDialog,
                ),
              if (role.canCreateOrDeleteAsset)
                _QuickActionTile(
                  icon: Icons.add_box_rounded,
                  label: '+ Aset',
                  accent: p.emerald,
                  palette: p,
                  onTap: () => showAssetActionSheet(
                    context: context,
                    state: s,
                    palette: p,
                  ),
                ),
              _QuickActionTile(
                icon: Icons.inventory_rounded,
                label: 'Inventaris',
                accent: p.info,
                palette: p,
                onTap: () => s.setTab(1),
              ),
              _QuickActionTile(
                icon: role.canExportClaim
                    ? Icons.picture_as_pdf_rounded
                    : Icons.report_problem_rounded,
                label: role.canExportClaim ? 'Ekspor PDF' : 'Lapor Kondisi',
                accent: p.gold,
                palette: p,
                onTap: () => role.canExportClaim ? s.setTab(3) : s.setTab(1),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'LIVE ACTIVITY & AUDIT FEED',
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 10),
          ...s.activities.take(4).map((act) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: p.borderSubtle),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          act.title,
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          act.subtitle,
                          style: TextStyle(color: p.textSecondary, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      VerificationPill(status: act.status, palette: p),
                      const SizedBox(height: 4),
                      Text(
                        act.timestampLabel,
                        style: TextStyle(color: p.textSecondary, fontSize: 10.5),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  final SpatialPalette palette;
  final IconData icon;
  final Color accent;
  final String label;
  final String value;
  final String sublabel;

  const _BentoCard({
    required this.palette,
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, size: 16, color: accent),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sublabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final SpatialPalette palette;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.borderSubtle),
            ),
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: accent),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
