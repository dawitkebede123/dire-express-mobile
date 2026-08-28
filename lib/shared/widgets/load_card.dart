import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../models/load.dart';
import '../../theme/app_theme.dart';
import '../format.dart';
import 'equipment_thumb.dart';
import 'route_timeline.dart';
import 'status_chip.dart';

class LoadRowCard extends StatelessWidget {
  const LoadRowCard({super.key, required this.load, required this.href});

  final FreightLoad load;
  final String href;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final delayed = load.status == 'REJECTED' || load.status == 'CANCELLED';

    return InkWell(
      onTap: () => context.push(href),
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: statusStripe(load.status),
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              load.referenceNo,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              load.rate != null
                                  ? formatCurrency(load.rate, locale)
                                  : l10n.loadRateTbd,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      StatusChip(status: load.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  RouteMini(
                    pickupCity: shortAddress(load.pickupAddress),
                    pickupTime: formatDayTime(load.pickupDate, l10n, locale),
                    deliveryCity: shortAddress(load.deliveryAddress),
                    deliveryTime: load.deliveryDate != null
                        ? formatDayTime(load.deliveryDate!, l10n, locale)
                        : l10n.loadScheduled,
                    pickupReached: const {'IN_TRANSIT', 'DELIVERED'}.contains(load.status),
                    deliveryReached: load.status == 'DELIVERED',
                    error: delayed,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoadBoardCard extends StatelessWidget {
  const LoadBoardCard({
    super.key,
    required this.load,
    required this.detailsHref,
    this.action,
  });

  final FreightLoad load;
  final String detailsHref;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final weight = formatWeight(load.weightLbs, l10n);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryFixed,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    EquipmentThumb(type: load.equipmentType, size: 20, radius: 4),
                    const SizedBox(width: 6),
                    Text(
                      equipmentLabel(l10n, load.equipmentType),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onTertiaryFixed,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    load.rate != null ? formatCurrency(load.rate, locale) : l10n.loadRateTbd,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  if (weight != null)
                    Text(weight, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          RouteMini(
            pickupCity: shortAddress(load.pickupAddress),
            pickupTime: formatDayTime(load.pickupDate, l10n, locale),
            deliveryCity: shortAddress(load.deliveryAddress),
            deliveryTime: load.deliveryDate != null
                ? formatDayTime(load.deliveryDate!, l10n, locale)
                : l10n.loadDeliveryScheduled,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push(detailsHref),
                  child: Text(l10n.commonDetails),
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: 8),
                Expanded(child: action!),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
