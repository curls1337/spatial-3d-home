import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../data/seed_data.dart';
import '../models/app_models.dart';
import '../services/pdf_export_service.dart';
import '../widgets/role_badge.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final AppState state;
  final SpatialPalette palette;

  const ProfileSettingsScreen({
    super.key,
    required this.state,
    required this.palette,
  });

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  late TextEditingController _serverCtrl;
  String _selectedFormat = 'PDF_PREVIEW';

  @override
  void initState() {
    super.initState();
    _serverCtrl = TextEditingController(text: widget.state.serverUrl);
  }

  @override
  void dispose() {
    _serverCtrl.dispose();
    super.dispose();
  }

  void _showExportSummaryModal({String format = 'PDF_PREVIEW'}) {
    final s = widget.state;
    final p = widget.palette;
    if (!s.currentRole.canExportClaim) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('403 RBAC Guard: Ekspor Klaim Asuransi hanya untuk Owner/Inspector.'),
        ),
      );
      return;
    }

    setState(() => _selectedFormat = format);
    final bundle = PdfExportService.buildBundle(
      rooms: s.rooms,
      visibleAssets: s.visibleAssets,
      actorRole: s.currentRole,
      format: format,
    );

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        title: Text(
          'Laporan Klaim (${bundle.reportId})',
          style: TextStyle(color: p.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (bundle.appraiserStamped ? p.emerald : p.gold).withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  bundle.appraiserStamped
                      ? '✓ Stempel Resmi: Appraiser Verified'
                      : 'Draft Klaim Owner • ${bundle.assetCount} Aset',
                  style: TextStyle(
                    color: bundle.appraiserStamped ? p.emerald : p.gold,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'SHA-256: ${bundle.sha256Integrity}',
                style: TextStyle(
                  color: p.textSecondary,
                  fontSize: 10.5,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: p.elevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  bundle.content,
                  style: TextStyle(
                    color: p.cyan,
                    fontSize: 10.5,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: bundle.content));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Ekspor $_selectedFormat disalin ke clipboard (SHA-256 Verified).'),
                ),
              );
            },
            child: const Text('Salin Output'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showCreateShareLinkDialog() {
    final s = widget.state;
    final p = widget.palette;
    if (!s.currentRole.canManageShareLinks) return;

    final labelCtrl = TextEditingController(text: 'Penilai Asuransi B2B');
    UserRole targetRole = UserRole.inspector;
    int ttlHours = 72;
    bool hasPin = true;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: p.surface,
          title: Text(
            'Buat Share Link Aman',
            style: TextStyle(color: p.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelCtrl,
                decoration: const InputDecoration(labelText: 'Label Penerima'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<UserRole>(
                value: targetRole,
                decoration: const InputDecoration(labelText: 'Scope Role'),
                items: const [
                  DropdownMenuItem(value: UserRole.inspector, child: Text('Inspector / Appraiser')),
                  DropdownMenuItem(value: UserRole.tenant, child: Text('Tenant / Viewer (Masked)')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => targetRole = v);
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: ttlHours,
                decoration: const InputDecoration(labelText: 'Masa Berlaku (TTL)'),
                items: const [
                  DropdownMenuItem(value: 24, child: Text('24 Jam')),
                  DropdownMenuItem(value: 72, child: Text('72 Jam (Default)')),
                  DropdownMenuItem(value: 720, child: Text('30 Hari')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => ttlHours = v);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Proteksi PIN 6-Digit', style: TextStyle(color: p.textPrimary, fontSize: 13)),
                value: hasPin,
                onChanged: (v) => setDialogState(() => hasPin = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                s.createShareLink(
                  targetRole: targetRole,
                  label: labelCtrl.text.trim().isEmpty ? 'Tamu Undangan' : labelCtrl.text.trim(),
                  ttlHours: ttlHours,
                  hasPin: hasPin,
                );
                Navigator.of(ctx).pop();
              },
              child: const Text('Terbitkan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSideloadGuide() {
    final p = widget.palette;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: p.borderSubtle),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Panduan Sideload iOS (.ipa) & Android (.apk)',
              style: TextStyle(
                color: p.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '• iOS (.ipa via GBox / ESign / AltStore / Sideloadly):\n'
              '  1. Unduh Spatial3DHome-v1.ipa dari GitHub Releases.\n'
              '  2. Sign & install melalui AltStore/Sideloadly/GBox/ESign.\n'
              '  3. Buka Settings → General → VPN & Device Management → Trust.\n'
              '  4. Hapus versi lama sebelum install versi baru agar cache tidak bentrok.\n\n'
              '• Android (.apk Direct Install):\n'
              '  1. Unduh Spatial3DHome-v1.apk dari GitHub Releases.\n'
              '  2. Izinkan "Install unknown apps", lalu ketuk file APK.',
              style: TextStyle(color: p.textSecondary, fontSize: 12.5, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final p = widget.palette;
    final role = s.currentRole;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
        children: [
          Text(
            'Profil & Pengaturan Sistem',
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role == UserRole.owner
                              ? 'Nadia Pratama'
                              : (role == UserRole.inspector ? 'Budi Santoso' : 'Raka Wijaya'),
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          SeedData.propertyName,
                          style: TextStyle(color: p.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                    RoleBadge(role: role, palette: p),
                  ],
                ),
                if (AppConfigFlags.enableDemoRoleSwitcher) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Quick Switch Role (Demo Mode)',
                    style: TextStyle(
                      color: p.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: UserRole.values.map((r) {
                      final active = r == role;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: ChoiceChip(
                            label: Center(child: Text(r.label)),
                            selected: active,
                            onSelected: (_) => s.switchRole(r),
                            selectedColor: p.cyan.withOpacity(0.24),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: p.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TAMPILAN & KEAMANAN LOKAL',
                  style: TextStyle(
                    color: p.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('OLED Luxury Dark Mode',
                      style: TextStyle(color: p.textPrimary, fontSize: 14)),
                  subtitle: Text(
                    s.isDarkMode ? 'Aktif: OLED Dark' : 'Aktif: Alabaster Light',
                    style: TextStyle(color: p.textSecondary, fontSize: 12),
                  ),
                  value: s.isDarkMode,
                  onChanged: (_) => s.toggleTheme(),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Biometric App Lock',
                      style: TextStyle(color: p.textPrimary, fontSize: 14)),
                  value: s.biometricLockEnabled,
                  onChanged: (v) => s.updateSettings(biometricLock: v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Auto-Blur PII On-Device',
                      style: TextStyle(color: p.textPrimary, fontSize: 14)),
                  value: s.autoBlurPii,
                  onChanged: (v) => s.updateSettings(autoBlurPii: v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: p.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'EKSPOR KLAIM & SIDELOAD',
                  style: TextStyle(
                    color: p.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.picture_as_pdf_rounded,
                      color: role.canExportClaim ? p.cyan : p.textSecondary),
                  title: Text(
                    'Preview Laporan Klaim (PDF / SHA-256)',
                    style: TextStyle(color: p.textPrimary, fontSize: 14),
                  ),
                  subtitle: Text(
                    role.canExportClaim
                        ? 'Hash SHA-256 kanonik + Stempel Verifikasi'
                        : '🔒 Dibatasi untuk Role Tenant',
                    style: TextStyle(color: p.textSecondary, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showExportSummaryModal(format: 'PDF_PREVIEW'),
                ),
                if (role.canExportClaim)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showExportSummaryModal(format: 'CSV'),
                          child: const Text('Ekspor CSV'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showExportSummaryModal(format: 'JSON'),
                          child: const Text('Ekspor JSON'),
                        ),
                      ),
                    ],
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.install_mobile_rounded, color: p.emerald),
                  title: Text(
                    'Panduan Install iOS .ipa & Android .apk',
                    style: TextStyle(color: p.textPrimary, fontSize: 14),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _showSideloadGuide,
                ),
              ],
            ),
          ),
          if (role.canManageShareLinks) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: p.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SHARE LINK MANAGER (OWNER ONLY)',
                        style: TextStyle(
                          color: p.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showCreateShareLinkDialog,
                        icon: Icon(Icons.add_link_rounded, size: 16, color: p.cyan),
                        label: Text('Buat Link', style: TextStyle(color: p.cyan, fontSize: 12)),
                      ),
                    ],
                  ),
                  ...s.shareLinks.map((link) {
                    return Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: p.elevated,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  link.label,
                                  style: TextStyle(
                                    color: p.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${link.targetRole.label} • TTL ${link.ttlHours}j • ${link.revoked ? "REVOKED (410)" : "AKTIF"}',
                                  style: TextStyle(
                                    color: link.revoked ? p.danger : p.emerald,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!link.revoked)
                            TextButton(
                              onPressed: () => s.revokeShareLink(link.id),
                              style: TextButton.styleFrom(foregroundColor: p.danger),
                              child: const Text('Revoke'),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          if (role.canManageServerConfig) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: p.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'SERVER ENDPOINT & OFFLINE SYNC (OWNER ONLY)',
                    style: TextStyle(
                      color: p.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _serverCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Sync API Endpoint URL',
                    ),
                    onSubmitted: (val) => s.updateSettings(serverUrl: val),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Offline-First Mode',
                        style: TextStyle(color: p.textPrimary, fontSize: 14)),
                    value: s.offlineOnly,
                    onChanged: (v) => s.updateSettings(offlineOnly: v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Hanya Sync via Wi-Fi',
                        style: TextStyle(color: p.textPrimary, fontSize: 14)),
                    value: s.syncWifiOnly,
                    onChanged: (v) => s.updateSettings(syncWifiOnly: v),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            s.updateSettings(serverUrl: _serverCtrl.text);
                            s.syncNow();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Delta sync outbox berhasil disinkronkan.'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.sync_rounded),
                          label: Text('Sync Sekarang (${s.pendingSyncCount})'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (AppConfigFlags.enableDemoRoleSwitcher)
            OutlinedButton.icon(
              onPressed: () {
                s.resetDemoData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Seed data Villa Kemang di-reset.')),
                );
              },
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Reset Data Demo ke Seed Awal'),
            ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: s.logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: p.danger.withOpacity(0.16),
              foregroundColor: p.danger,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Keluar (Logout)', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
