import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../models/load.dart';
import '../../shared/format.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/person_avatar.dart';
import '../../shared/widgets/pod_documents.dart';
import '../../shared/widgets/status_chip.dart';
import '../../shared/widgets/tracking_timeline.dart';
import '../../theme/app_theme.dart';
import '../maps/trip_map.dart';
import '../notifications/pusher_service.dart';

class CustomerTrackDetailScreen extends ConsumerStatefulWidget {
  const CustomerTrackDetailScreen({super.key, required this.loadId});

  final String loadId;

  @override
  ConsumerState<CustomerTrackDetailScreen> createState() => _CustomerTrackDetailScreenState();
}

class _CustomerTrackDetailScreenState extends ConsumerState<CustomerTrackDetailScreen> {
  FreightLoad? _load;
  LatLng? _driverPoint;
  late final PusherHandler _handler;

  @override
  void initState() {
    super.initState();
    _handler = (_, data) {
      if (data['load'] is Map<String, dynamic>) {
        setState(() => _load = FreightLoad.fromJson(data['load'] as Map<String, dynamic>));
      }
      final loc = data['location'];
      if (loc is Map && loc['lat'] != null) {
        setState(() => _driverPoint = LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble()));
      }
    };
    _fetch();
    pusherService.subscribe('load-${widget.loadId}', 'status-update', _handler);
    pusherService.subscribe('load-${widget.loadId}', 'location-update', _handler);
  }

  @override
  void dispose() {
    pusherService.unsubscribe('load-${widget.loadId}', 'status-update', _handler);
    pusherService.unsubscribe('load-${widget.loadId}', 'location-update', _handler);
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final load = await ref.read(apiClientProvider).getLoad(widget.loadId);
      if (!mounted) return;
      setState(() {
        _load = load;
        if (load.latestLocation != null) {
          _driverPoint = LatLng(load.latestLocation!.lat, load.latestLocation!.lng);
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final load = _load;
    if (load == null) {
      return Scaffold(
        appBar: AppHeader(title: l10n.customerTrackDetailTitle, showBack: true),
        body: Center(child: Text(l10n.customerTrackLoading)),
      );
    }

    return Scaffold(
      appBar: AppHeader(title: l10n.customerTrackDetailTitle, showBack: true, notificationsPath: '/customer/notifications', profilePath: '/customer/profile'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          TripMap(
            pickup: load.pickupLat != null ? LatLng(load.pickupLat!, load.pickupLng!) : null,
            delivery: load.deliveryLat != null ? LatLng(load.deliveryLat!, load.deliveryLng!) : null,
            driver: _driverPoint,
            height: 240,
            showLiveBadge: load.status == 'IN_TRANSIT',
            expandable: true,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF0B1C30), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.speed, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(statusLabel(l10n, load.status), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    Text(bannerForStatus(l10n, load.status), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TrackingTimeline(load: load),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.outlineVariant)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(l10n.brokerTripDetails, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const Spacer(),
                  StatusChip(status: load.status),
                ]),
                const SizedBox(height: 8),
                Text(load.referenceNo, style: const TextStyle(fontFamily: 'monospace', color: AppColors.secondary)),
                const SizedBox(height: 8),
                _kv(l10n.customerEstDeparture, formatDateTime(load.pickupDate, locale)),
                _kv(l10n.customerEstArrival, load.deliveryDate != null ? formatDateTime(load.deliveryDate!, locale) : l10n.customerScheduling),
                _kv(l10n.customerFrom, load.pickupAddress),
                _kv(l10n.customerTo, load.deliveryAddress),
                if (load.systemPrice != null)
                  _kv(l10n.systemPrice, formatSystemPrice(l10n, locale, load.systemPrice!, load.distanceKm)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      PersonAvatar(
                        imageUrl: load.driver?.imageUrl,
                        name: load.driver?.name,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(load.driver?.name ?? l10n.customerNoDriver, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(
                            load.driver != null
                                ? l10n.customerAssignedDriver(equipmentLabel(l10n, load.equipmentType))
                                : l10n.customerAwaitingDriver,
                            style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                          ),
                        ]),
                      ),
                      if (load.driver?.phone != null)
                        IconButton(
                          onPressed: () => launchUrl(Uri.parse('tel:${load.driver!.phone}')),
                          icon: const Icon(Icons.phone, color: AppColors.secondary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (load.proofOfDelivery != null) ...[
            const SizedBox(height: 12),
            PodDocuments(pod: load.proofOfDelivery!),
          ],
        ],
      ),
      bottomNavigationBar: Material(
        color: AppColors.background,
        elevation: 8,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('mailto:support@direexpress.com?subject=${Uri.encodeComponent(load.referenceNo)}')),
                  icon: const Icon(Icons.description_outlined),
                  label: Text(l10n.customerViewDocuments),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => launchUrl(Uri.parse('tel:+18005550100')),
                  icon: const Icon(Icons.headset_mic_outlined),
                  label: Text(l10n.customerContactSupport),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.secondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(k.toUpperCase(), style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant, letterSpacing: 0.4))),
          Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
