import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/load.dart';
import '../../theme/app_theme.dart';
import '../format.dart';

class TrackingTimeline extends StatelessWidget {
  const TrackingTimeline({super.key, required this.load});

  final FreightLoad load;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final current = trackingStepIndex(load.status);
    final steps = [
      (
        l10n.trackBooked,
        load.createdAt != null ? formatDayTime(load.createdAt!, l10n, locale) : l10n.trackRequestReceived,
      ),
      (
        l10n.trackPickedUp,
        current >= 1
            ? '${formatDayTime(load.pickupDate, l10n, locale)} • ${shortAddress(load.pickupAddress)}'
            : l10n.trackScheduled(formatDayTime(load.pickupDate, l10n, locale)),
      ),
      (
        l10n.trackInTransit,
        current == 2
            ? l10n.trackLiveActive
            : current > 2
                ? l10n.trackCompleted
                : l10n.trackPending,
      ),
      (
        l10n.trackDelivered,
        load.status == 'DELIVERED' && load.deliveryDate != null
            ? formatDayTime(load.deliveryDate!, l10n, locale)
            : l10n.trackPending,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.brokerShipmentStatus, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          for (var i = 0; i < steps.length; i++)
            _StepRow(
              label: steps[i].$1,
              detail: steps[i].$2,
              done: i < current,
              active: i == current,
              last: i == steps.length - 1,
            ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.detail,
    required this.done,
    required this.active,
    required this.last,
  });

  final String label;
  final String detail;
  final bool done;
  final bool active;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = done || active ? AppColors.secondary : AppColors.outlineVariant;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done || active ? AppColors.secondary : Colors.transparent,
                  border: Border.all(color: color, width: 2),
                ),
                child: done
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              if (!last)
                Expanded(
                  child: Container(width: 2, color: AppColors.outlineVariant),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: active ? const EdgeInsets.all(10) : EdgeInsets.zero,
              decoration: active
                  ? BoxDecoration(
                      color: const Color(0xFFD8E2FF),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: active || done ? AppColors.onSurface : AppColors.onSurfaceVariant)),
                  Text(detail, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
