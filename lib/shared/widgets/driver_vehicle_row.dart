import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/directory.dart';
import '../../shared/format.dart';
import '../../theme/app_theme.dart';
import 'truck_thumb.dart';

class DriverAvailabilityBadge extends StatelessWidget {
  const DriverAvailabilityBadge({super.key, required this.available, required this.label});

  final bool available;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: available ? AppColors.successContainer : Colors.transparent,
        border: available ? null : Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: available ? AppColors.success : AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class DriverVehicleRow extends StatelessWidget {
  const DriverVehicleRow({
    super.key,
    required this.driver,
    required this.l10n,
    this.enabled = true,
    this.isCurrent = false,
    this.loadWeight,
    this.onTap,
    this.trailing,
    this.thumbSize = 48,
  });

  final DriverProfile driver;
  final AppLocalizations l10n;
  final bool enabled;
  final bool isCurrent;
  final double? loadWeight;
  final VoidCallback? onTap;
  final Widget? trailing;
  final double thumbSize;

  @override
  Widget build(BuildContext context) {
    final vehicleLabel = driver.vehicleType != null
        ? equipmentLabel(l10n, driver.vehicleType)
        : l10n.brokerVehicleNotSet;
    final capacity = formatWeight(driver.loadingCapacity, l10n);
    final exceedsCapacity = loadWeight != null &&
        driver.loadingCapacity != null &&
        loadWeight! > driver.loadingCapacity!;

    final details = <String>[
      vehicleLabel,
      if (driver.plateNo != null && driver.plateNo!.isNotEmpty) driver.plateNo!,
      if (capacity != null) l10n.brokerLoadingCapacity(capacity),
    ].join(' • ');

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                TruckThumb(
                  truckImageUrl: driver.truckImageUrl,
                  vehicleType: driver.vehicleType,
                  size: thumbSize,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              driver.user.name,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          DriverAvailabilityBadge(
                            available: driver.isAvailable,
                            label: driver.isAvailable
                                ? l10n.driverAvailabilityAvailable
                                : l10n.driverAvailabilityUnavailable,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCurrent ? l10n.brokerAssignedDriver : details,
                        style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
                      ),
                      if (!isCurrent && exceedsCapacity) ...[
                        const SizedBox(height: 4),
                        Text(
                          l10n.brokerCapacityExceeded,
                          style: TextStyle(fontSize: 12, color: AppColors.error.withValues(alpha: 0.9)),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
