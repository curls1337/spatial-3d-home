import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../models/app_models.dart';

class LoginScreen extends StatefulWidget {
  final AppState state;
  final SpatialPalette palette;

  const LoginScreen({
    super.key,
    required this.state,
    required this.palette,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController(text: 'owner@spatial3dhome.id');
  final _passCtrl = TextEditingController(text: 'Vault2026!');
  bool _obscure = true;
  bool _loading = false;
  bool _faceIdActive = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    final email = _emailCtrl.text.trim().toLowerCase();
    UserRole role = UserRole.owner;
    if (email.contains('inspector') || email.contains('appraiser')) {
      role = UserRole.inspector;
    } else if (email.contains('tenant') || email.contains('guest')) {
      role = UserRole.tenant;
    }
    setState(() => _loading = false);
    HapticFeedback.mediumImpact();
    widget.state.loginWithRole(role);
  }

  Future<void> _triggerFaceId() async {
    HapticFeedback.lightImpact();
    setState(() => _faceIdActive = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() => _faceIdActive = false);
    HapticFeedback.mediumImpact();
    widget.state.loginWithRole(UserRole.owner);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;

    return Scaffold(
      backgroundColor: p.canvas,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: p.lidarGradient,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: p.cyan.withOpacity(0.28),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.view_in_ar_rounded,
                          size: 36,
                          color: p.ctaForeground,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'SPATIAL 3D HOME',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'LiDAR Property & Asset Vault',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: p.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: p.emerald.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: p.emerald.withOpacity(0.32)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_rounded, size: 15, color: p.emerald),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'AES-256 On-Device Vault Active • Zero Raw Video Upload',
                              style: TextStyle(
                                color: p.emerald,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Email / ID Properti',
                      style: TextStyle(
                        color: p.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.alternate_email_rounded, size: 18),
                        hintText: 'owner@spatial3dhome.id',
                      ),
                      validator: (v) {
                        if (v == null || !v.contains('@')) {
                          return 'Masukkan alamat email yang valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'PIN / Passphrase',
                      style: TextStyle(
                        color: p.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.key_rounded, size: 18),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                            size: 18,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'PIN atau password wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: p.lidarGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submitForm,
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
                          _loading ? 'Membuka Vault...' : 'Masuk ke Vault Properti',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _triggerFaceId,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: p.textPrimary,
                        side: BorderSide(color: p.borderSubtle),
                        backgroundColor: p.surface,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: Icon(Icons.face_retouching_natural_rounded, color: p.cyan),
                      label: const Text(
                        'Buka dengan FaceID / Passkey',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (AppConfigFlags.enableDemoRoleSwitcher) ...[
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(child: Divider(color: p.borderSubtle)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'QUICK ROLE SWITCHER (DEMO)',
                              style: TextStyle(
                                color: p.textSecondary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: p.borderSubtle)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _QuickRoleCard(
                            role: UserRole.owner,
                            icon: Icons.verified_user_rounded,
                            accent: p.cyan,
                            palette: p,
                            onTap: () => widget.state.loginWithRole(UserRole.owner),
                          ),
                          const SizedBox(width: 8),
                          _QuickRoleCard(
                            role: UserRole.inspector,
                            icon: Icons.fact_check_rounded,
                            accent: p.gold,
                            palette: p,
                            onTap: () => widget.state.loginWithRole(UserRole.inspector),
                          ),
                          const SizedBox(width: 8),
                          _QuickRoleCard(
                            role: UserRole.tenant,
                            icon: Icons.visibility_rounded,
                            accent: p.emerald,
                            palette: p,
                            onTap: () => widget.state.loginWithRole(UserRole.tenant),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      'v1.0.0 • Offline-First Ready (${AppConfigFlags.appEnv})',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            if (_faceIdActive)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.65),
                  child: Center(
                    child: Container(
                      width: 240,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: p.cyan),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.face_retouching_natural_rounded,
                            size: 48,
                            color: p.cyan,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Memverifikasi FaceID',
                            style: TextStyle(
                              color: p.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Secure Enclave Keychain...',
                            style: TextStyle(
                              color: p.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 14),
                          LinearProgressIndicator(
                            color: p.cyan,
                            backgroundColor: p.elevated,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickRoleCard extends StatelessWidget {
  final UserRole role;
  final IconData icon;
  final Color accent;
  final SpatialPalette palette;
  final VoidCallback onTap;

  const _QuickRoleCard({
    required this.role,
    required this.icon,
    required this.accent,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withOpacity(0.38)),
          ),
          child: Column(
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(height: 6),
              Text(
                role.label,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                role == UserRole.owner
                    ? 'Full CRUD'
                    : (role == UserRole.inspector ? 'Audit' : 'Masked'),
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
