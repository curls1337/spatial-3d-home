import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../models/app_models.dart';
import '../widgets/asset_form_sheet.dart';
import '../widgets/role_badge.dart';

class AssetInventoryScreen extends StatefulWidget {
  final AppState state;
  final SpatialPalette palette;

  const AssetInventoryScreen({
    super.key,
    required this.state,
    required this.palette,
  });

  @override
  State<AssetInventoryScreen> createState() => _AssetInventoryScreenState();
}

class _AssetInventoryScreenState extends State<AssetInventoryScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final p = widget.palette;
    final role = s.currentRole;
    final items = s.filteredAssets;

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Inventaris Aset',
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: p.surface,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: p.borderSubtle),
                          ),
                          child: Text(
                            '${items.length} Item',
                            style: TextStyle(
                              color: p.cyan,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchCtrl,
                      onChanged: s.setSearchQuery,
                      decoration: InputDecoration(
                        hintText: 'Cari nama aset, serial, atau ruangan…',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: s.searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  s.setSearchQuery('');
                                },
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: const Text('Semua Ruangan'),
                              selected: s.inventoryRoomFilterId == null,
                              onSelected: (_) => s.setInventoryRoomFilter(null),
                              selectedColor: p.cyan.withOpacity(0.22),
                            ),
                          ),
                          ...s.rooms.map((room) {
                            final selected = s.inventoryRoomFilterId == room.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(room.name),
                                selected: selected,
                                onSelected: (_) => s.setInventoryRoomFilter(
                                  selected ? null : room.id,
                                ),
                                selectedColor: p.cyan.withOpacity(0.22),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ...AssetCategory.values.map((cat) {
                            final selected = s.categoryFilter == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(cat.label),
                                selected: selected,
                                onSelected: (_) =>
                                    s.setCategoryFilter(selected ? null : cat),
                                selectedColor: p.emerald.withOpacity(0.2),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.radar_rounded, size: 48, color: p.textSecondary),
                              const SizedBox(height: 10),
                              Text(
                                'Tidak ada aset yang cocok dengan filter saat ini',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: p.textSecondary, fontSize: 13.5),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: () {
                                  _searchCtrl.clear();
                                  s.resetInventoryFilters();
                                },
                                child: const Text('Reset Filter'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 118),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final asset = items[index];
                          final roomName = s.roomById(asset.roomId)?.name ?? '-';
                          return InkWell(
                            onTap: () => showAssetActionSheet(
                              context: context,
                              state: s,
                              palette: p,
                              existingAsset: asset,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: p.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: p.borderSubtle),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: p.cyan.withOpacity(0.14),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                asset.category.icon,
                                                color: p.cyan,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    asset.name,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: p.textPrimary,
                                                      fontSize: 14.5,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                  Text(
                                                    '$roomName • S/N: ${asset.serialNumber}',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: p.textSecondary,
                                                      fontSize: 11.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      VerificationPill(
                                        status: asset.verificationStatus,
                                        palette: p,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (role.canViewFinancials)
                                        Text(
                                          'Kini: ${AppState.formatIdr(asset.effectiveValuation)}',
                                          style: TextStyle(
                                            color: p.gold,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        )
                                      else
                                        Text(
                                          '🔒 Valuasi Disamarkan (Tenant)',
                                          style: TextStyle(
                                            color: p.textSecondary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      Text(
                                        role == UserRole.tenant
                                            ? 'Lapor Kondisi ›'
                                            : (role == UserRole.inspector
                                                ? 'Verifikasi ›'
                                                : 'Edit ›'),
                                        style: TextStyle(
                                          color: p.cyan,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (role.canViewFinancials &&
                                      asset.warrantyState == WarrantyState.expiringSoon) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      '⚠️ Garansi habis dalam ${asset.warrantyDaysRemaining} hari',
                                      style: TextStyle(
                                        color: p.gold,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  if (asset.tenantConditionNote.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Catatan Kondisi: ${asset.tenantConditionNote}',
                                      style: TextStyle(
                                        color: p.danger,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          if (role.canCreateOrDeleteAsset)
            Positioned(
              right: 16,
              bottom: 94,
              child: FloatingActionButton.extended(
                onPressed: () => showAssetActionSheet(
                  context: context,
                  state: s,
                  palette: p,
                ),
                backgroundColor: p.cyan,
                foregroundColor: p.ctaForeground,
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Tambah Aset',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
