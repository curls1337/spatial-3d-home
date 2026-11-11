import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/app_models.dart';

class RoleBadge extends StatelessWidget {
  final UserRole role;
  final SpatialPalette palette;

  const RoleBadge({
    super.key,
    required this.role,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final IconData icon;

    switch (role) {
      case UserRole.owner:
        bg = palette.cyan.withOpacity(0.16);
        fg = palette.cyan;
        icon = Icons.verified_user_rounded;
        break;
      case UserRole.inspector:
        bg = palette.gold.withOpacity(0.16);
        fg = palette.gold;
        icon = Icons.fact_check_rounded;
        break;
      case UserRole.tenant:
        bg = palette.textSecondary.withOpacity(0.16);
        fg = palette.textSecondary;
        icon = Icons.visibility_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            role.label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class VerificationPill extends StatelessWidget {
  final VerificationStatus status;
  final SpatialPalette palette;

  const VerificationPill({
    super.key,
    required this.status,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    switch (status) {
      case VerificationStatus.verified:
        color = palette.emerald;
        icon = Icons.check_circle_rounded;
        break;
      case VerificationStatus.pending:
        color = palette.gold;
        icon = Icons.schedule_rounded;
        break;
      case VerificationStatus.flagged:
        color = palette.danger;
        icon = Icons.warning_amber_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
