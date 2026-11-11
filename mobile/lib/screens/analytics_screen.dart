import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../models/app_models.dart';
import '../widgets/role_badge.dart';

class AnalyticsScreen extends StatelessWidget {
  final AppState state;
  final SpatialPalette palette;

  const AnalyticsScreen({
    super.key,
    required this.state,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final s = state;
    final p = palette;
    final role = s.currentRole;
    final assets = s.visibleAssets;

    final purchaseTotal = s.totalPurchaseValue;
    final currentTotal = s.totalCurrentValuation;
    final deltaPct = purchaseTotal > 0
        ? ((currentTotal - purchaseTotal) / purchaseTotal) * 100.0
        : 0.0;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
        children: [
          Text(
            'Analitik Spasial & Valuasi',
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Metrik dihitung dinamis dari state inventaris lokal',
            style: TextStyle(color: p.textSecondary, fontSize: 12.5),
          ),
          const SizedBox(height: 16),
          if (!role.canViewFinancials) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: p.gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: p.gold.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline_rounded, color: p.gold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Analitik Valuasi Finansial Dibatasi untuk Role Tenant. Anda hanya melihat distribusi barang yang diizinkan.',
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: p.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role.canViewFinancials
                      ? '1. VALUASI PER RUANGAN'
                      : '1. DISTRIBUSI ITEM PER RUANGAN',
                  style: TextStyle(
                    color: p.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 12),
                if (assets.isEmpty)
                  Text(
                    'Belum ada data aset untuk dianalisis',
                    style: TextStyle(color: p.textSecondary, fontSize: 13),
                  )
                else
                  ...s.rooms.map((room) {
                    final roomAssets =
                        assets.where((a) => a.roomId == room.id).toList();
                    final roomVal = roomAssets.fold<double>(
                        0, (sum, a) => sum + a.effectiveValuation);
                    final maxVal = s.rooms.fold<double>(1, (mx, r) {
                      final rv = assets
                          .where((a) => a.roomId == r.id)
                          .fold<double>(0, (sum, a) => sum + a.effectiveValuation);
                      return math.max(mx, rv);
                    });
                    final ratio = role.canViewFinancials
                        ? (roomVal / maxVal).clamp(0.0, 1.0)
                        : (roomAssets.length / math.max(1, assets.length))
                            .clamp(0.0, 1.0);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                room.name,
                                style: TextStyle(
                                  color: p.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                role.canViewFinancials
                                    ? '${AppState.formatCompactIdr(roomVal)} (${roomAssets.length} item)'
                                    : '${roomAssets.length} item',
                                style: TextStyle(
                                  color: p.cyan,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 8,
                              backgroundColor: p.elevated,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                room.accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          if (role.canViewFinancials) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: p.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '2. DEPRESIASI VS HARGA PEROLEHAN & CLAIM READINESS',
                    style: TextStyle(
                      color: p.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Harga Beli Total',
                          style: TextStyle(color: p.textSecondary, fontSize: 13)),
                      Text(
                        AppState.formatIdr(purchaseTotal),
                        style: TextStyle(
                          color: p.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Nilai Valuasi Kini',
                          style: TextStyle(color: p.textSecondary, fontSize: 13)),
                      Text(
                        AppState.formatIdr(currentTotal),
                        style: TextStyle(
                          color: p.gold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Selisih Net Portofolio',
                          style: TextStyle(color: p.textSecondary, fontSize: 13)),
                      Text(
                        '${deltaPct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: deltaPct >= 0 ? p.emerald : p.gold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Insurance Claim Readiness',
                          style: TextStyle(
                            color: p.textPrimary,
                            fontWeight: FontWeight.w600,
                          )),
                      Text(
                        '${s.verifiedAssetsPct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: p.emerald,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: (s.verifiedAssetsPct / 100).clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: p.elevated,
                      valueColor: AlwaysStoppedAnimation<Color>(p.emerald),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: p.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '3. RIWAYAT INSPEKSI & PERINGATAN GARANSI',
                  style: TextStyle(
                    color: p.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 10),
                ...s.activities.take(5).map((act) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
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
                              Text(
                                act.subtitle,
                                style: TextStyle(
                                  color: p.textSecondary,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        VerificationPill(status: act.status, palette: p),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
