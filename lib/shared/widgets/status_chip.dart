import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../format.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (bg, fg, icon) = _style(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            statusLabel(l10n, status),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }
}

(Color, Color, IconData) _style(String status) {
  switch (status) {
    case 'PENDING':
      return (AppColors.tertiaryFixed, AppColors.onTertiaryFixed, Icons.pending_actions);
    case 'CREATED':
    case 'CANCELLED':
      return (AppColors.surfaceContainerHighest, AppColors.onSurfaceVariant, Icons.note_add_outlined);
    case 'ASSIGNED':
    case 'IN_TRANSIT':
      return (AppColors.primaryContainer, AppColors.secondary, Icons.route);
    case 'ACCEPTED':
    case 'DELIVERED':
      return (AppColors.successContainer, AppColors.success, Icons.check_circle);
    case 'REJECTED':
      return (AppColors.errorContainer, AppColors.error, Icons.cancel);
    default:
      return (AppColors.surfaceContainer, AppColors.onSurface, Icons.info_outline);
  }
}

Color statusStripe(String status) {
  switch (status) {
    case 'PENDING':
      return const Color(0xFFFFB95F);
    case 'CREATED':
    case 'CANCELLED':
      return AppColors.outlineVariant;
    case 'ASSIGNED':
    case 'ACCEPTED':
    case 'IN_TRANSIT':
      return AppColors.secondary;
    case 'DELIVERED':
      return AppColors.success;
    case 'REJECTED':
      return AppColors.error;
    default:
      return AppColors.outlineVariant;
  }
}
