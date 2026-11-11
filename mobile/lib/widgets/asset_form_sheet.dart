import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/app_models.dart';

Future<void> showAssetActionSheet({
  required BuildContext context,
  required AppState state,
  required SpatialPalette palette,
  AssetItem? existingAsset,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AssetActionSheet(
      state: state,
      palette: palette,
      existingAsset: existingAsset,
    ),
  );
}

class _AssetActionSheet extends StatefulWidget {
  final AppState state;
  final SpatialPalette palette;
  final AssetItem? existingAsset;

  const _AssetActionSheet({
    required this.state,
    required this.palette,
    this.existingAsset,
  });

  @override
  State<_AssetActionSheet> createState() => _AssetActionSheetState();
}

class _AssetActionSheetState extends State<_AssetActionSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _serialCtrl;
  late TextEditingController _purchaseCtrl;
  late TextEditingController _valuationCtrl;
  late TextEditingController _appraisalCtrl;
  late TextEditingController _noteCtrl;

  late String _roomId;
  late AssetCategory _category;
  late VisibilityScope _visibility;
  late VerificationStatus _status;
  late String _conditionGrade;

  @override
  void initState() {
    super.initState();
    final a = widget.existingAsset;
    _nameCtrl = TextEditingController(text: a?.name ?? '');
    _serialCtrl = TextEditingController(text: a?.serialNumber ?? 'SN-${DateTime.now().millisecond}88');
    _purchaseCtrl = TextEditingController(
      text: a != null ? a.purchasePrice.round().toString() : '18500000',
    );
    _valuationCtrl = TextEditingController(
      text: a != null ? a.currentValuation.round().toString() : '16500000',
    );
    _appraisalCtrl = TextEditingController(
      text: a != null ? a.effectiveValuation.round().toString() : '16500000',
    );
    _noteCtrl = TextEditingController(
      text: widget.state.currentRole == UserRole.tenant
          ? (a?.tenantConditionNote ?? '')
          : (a?.appraisalNote ?? ''),
    );

    _roomId = a?.roomId ?? widget.state.rooms.first.id;
    _category = a?.category ?? AssetCategory.electronics;
    _visibility = a?.visibilityScope ?? VisibilityScope.insuranceOnly;
    _status = a?.verificationStatus ?? VerificationStatus.pending;
    _conditionGrade = a?.conditionGrade ?? 'Mint';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _serialCtrl.dispose();
    _purchaseCtrl.dispose();
    _valuationCtrl.dispose();
    _appraisalCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _runMockOcrReceipt() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_nameCtrl.text.trim().isEmpty) {
        _nameCtrl.text = 'Dyson V15 Detect Vacuum';
      }
      _purchaseCtrl.text = '14900000';
      _valuationCtrl.text = '11920000';
      _serialCtrl.text = 'DYS-V15-2026ID';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OCR On-Device: Nominal struk Rp 14.900.000 terisi otomatis.'),
      ),
    );
  }

  void _submit() {
    final role = widget.state.currentRole;
    final a = widget.existingAsset;

    if (role == UserRole.tenant && a != null) {
      if (_noteCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tulis catatan kondisi terlebih dahulu.')),
        );
        return;
      }
      widget.state.addTenantConditionNote(
        assetId: a.id,
        note: _noteCtrl.text.trim(),
      );
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop();
      return;
    }

    if (role == UserRole.inspector && a != null) {
      final appraised = double.tryParse(_appraisalCtrl.text.trim());
      if (appraised == null || appraised < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nilai taksiran tidak valid atau negatif.')),
        );
        return;
      }
      widget.state.verifyAppraisal(
        assetId: a.id,
        appraisedValue: appraised,
        status: _status,
        note: _noteCtrl.text.trim(),
      );
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop();
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final purchase = double.parse(_purchaseCtrl.text.trim());
    final currentVal = double.parse(_valuationCtrl.text.trim());

    if (a == null) {
      widget.state.addAsset(
        AssetItem(
          id: 'ast-${DateTime.now().millisecondsSinceEpoch}',
          roomId: _roomId,
          name: _nameCtrl.text.trim(),
          category: _category,
          serialNumber: _serialCtrl.text.trim(),
          purchasePrice: purchase,
          currentValuation: currentVal,
          purchaseDate: DateTime.now(),
          warrantyExpiryDate: DateTime.now().add(const Duration(days: 365)),
          verificationStatus: _status,
          visibilityScope: _visibility,
          conditionGrade: _conditionGrade,
          pinX: 2.2,
          pinY: 1.0,
          pinZ: 1.8,
          appraisalNote: _noteCtrl.text.trim(),
        ),
      );
    } else {
      widget.state.updateAsset(
        a.copyWith(
          roomId: _roomId,
          name: _nameCtrl.text.trim(),
          category: _category,
          serialNumber: _serialCtrl.text.trim(),
          purchasePrice: purchase,
          currentValuation: currentVal,
          verificationStatus: _status,
          visibilityScope: _visibility,
          conditionGrade: _conditionGrade,
          appraisalNote: _noteCtrl.text.trim(),
        ),
      );
    }

    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final role = widget.state.currentRole;
    final a = widget.existingAsset;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    String sheetTitle;
    if (role == UserRole.tenant) {
      sheetTitle = 'Lapor Kondisi Barang (Tenant)';
    } else if (role == UserRole.inspector) {
      sheetTitle = 'Verifikasi Appraisal B2B';
    } else {
      sheetTitle = a == null ? 'Tambah Aset ke Ruang 3D' : 'Edit Detail Aset';
    }

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: p.borderSubtle),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.textSecondary.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        sheetTitle,
                        style: TextStyle(
                          color: p.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (role == UserRole.owner)
                      TextButton.icon(
                        onPressed: _runMockOcrReceipt,
                        icon: Icon(Icons.document_scanner_rounded, size: 16, color: p.cyan),
                        label: Text(
                          'OCR Struk',
                          style: TextStyle(color: p.cyan, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (role == UserRole.tenant && a != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: p.elevated,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.name,
                          style: TextStyle(
                            color: p.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Valuasi & harga beli pemilik disamarkan (RBAC Tenant).',
                          style: TextStyle(color: p.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Catatan Kondisi / Kerusakan Barang',
                      hintText: 'Contoh: Engsel pintu agak longgar atau AC menetes',
                    ),
                  ),
                ] else if (role == UserRole.inspector && a != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: p.elevated,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.name,
                          style: TextStyle(
                            color: p.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Harga Beli Pemilik (Read-only): ${AppState.formatIdr(a.purchasePrice)}',
                          style: TextStyle(color: p.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _appraisalCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Nilai Taksiran Appraiser (IDR)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<VerificationStatus>(
                    value: _status,
                    decoration: const InputDecoration(labelText: 'Status Audit'),
                    items: VerificationStatus.values
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _status = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Catatan Inspeksi / Appraisal',
                    ),
                  ),
                ] else ...[
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Aset *'),
                    validator: (val) => (val == null || val.trim().length < 2)
                        ? 'Nama aset minimal 2 karakter'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _roomId,
                    decoration: const InputDecoration(labelText: 'Ruangan 3D'),
                    items: widget.state.rooms
                        .map((r) => DropdownMenuItem(value: r.id, child: Text(r.name)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _roomId = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<AssetCategory>(
                          value: _category,
                          decoration: const InputDecoration(labelText: 'Kategori'),
                          items: AssetCategory.values
                              .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _category = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _serialCtrl,
                          decoration: const InputDecoration(labelText: 'Nomor Seri'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _purchaseCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Harga Beli (Rp)'),
                          validator: (val) {
                            final n = double.tryParse(val?.trim() ?? '');
                            if (n == null || n < 0) return 'Nilai tidak valid';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _valuationCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Valuasi Kini (Rp)'),
                          validator: (val) {
                            final n = double.tryParse(val?.trim() ?? '');
                            if (n == null || n < 0) return 'Nilai tidak valid';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        final pVal = double.tryParse(_purchaseCtrl.text.trim()) ?? 0;
                        final calc = SpatialMath.calculateStraightLineValuation(
                          purchasePrice: pVal,
                          category: _category,
                          purchaseDate: a?.purchaseDate ??
                              DateTime.now().subtract(const Duration(days: 365)),
                        );
                        setState(() {
                          _valuationCtrl.text = calc.round().toString();
                        });
                      },
                      icon: Icon(Icons.calculate_rounded, size: 15, color: p.cyan),
                      label: Text(
                        'Hitung Depresiasi Garis Lurus',
                        style: TextStyle(color: p.cyan, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<VisibilityScope>(
                    value: _visibility,
                    decoration: const InputDecoration(labelText: 'Visibilitas RBAC'),
                    items: VisibilityScope.values
                        .map((v) => DropdownMenuItem(value: v, child: Text(v.displayName)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _visibility = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _noteCtrl,
                    decoration: const InputDecoration(labelText: 'Catatan Kondisi / Klaim'),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (role == UserRole.owner && a != null) ...[
                      OutlinedButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (dCtx) => AlertDialog(
                              backgroundColor: p.surface,
                              title: Text(
                                a.isClaimed ? 'Arsipkan Aset Klaim?' : 'Hapus Aset?',
                                style: TextStyle(color: p.textPrimary),
                              ),
                              content: Text(
                                a.isClaimed
                                    ? 'Aset berstatus CLAIMED akan diarsipkan untuk menjaga jejak audit asuransi.'
                                    : 'Yakin ingin menghapus "${a.name}" dari inventaris?',
                                style: TextStyle(color: p.textSecondary),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(dCtx).pop(false),
                                  child: const Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(dCtx).pop(true),
                                  style: TextButton.styleFrom(foregroundColor: p.danger),
                                  child: Text(a.isClaimed ? 'Arsipkan' : 'Hapus'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && mounted) {
                            widget.state.deleteOrArchiveAsset(a.id);
                            Navigator.of(context).pop();
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: p.danger,
                          side: BorderSide(color: p.danger.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('Hapus'),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: p.lidarGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: p.ctaForeground,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            role == UserRole.tenant
                                ? 'Kirim Laporan Kondisi'
                                : (role == UserRole.inspector
                                    ? 'Simpan Verifikasi Audit'
                                    : (a == null ? 'Simpan Aset ke Brankas' : 'Simpan Perubahan')),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
