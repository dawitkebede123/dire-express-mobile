import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../l10n/app_localizations.dart';
import '../../models/load.dart';
import '../../models/user.dart';
import '../../shared/format.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/person_avatar.dart';
import '../../shared/widgets/status_chip.dart';
import '../../shared/widgets/tracking_timeline.dart';
import '../../theme/app_theme.dart';
import '../maps/trip_map.dart';
import '../notifications/pusher_service.dart';

class BrokerLoadDetailScreen extends ConsumerStatefulWidget {
  const BrokerLoadDetailScreen({super.key, required this.loadId});

  final String loadId;

  @override
  ConsumerState<BrokerLoadDetailScreen> createState() => _BrokerLoadDetailScreenState();
}

class _BrokerLoadDetailScreenState extends ConsumerState<BrokerLoadDetailScreen> {
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
      if (loc is Map && loc['lat'] != null && loc['lng'] != null) {
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

  Future<void> _assign() async {
    final l10n = AppLocalizations.of(context);
    final drivers = await ref.read(apiClientProvider).listDrivers();
    if (!mounted) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        if (drivers.isEmpty) {
          return Padding(padding: const EdgeInsets.all(24), child: Text(l10n.brokerNoDrivers));
        }
        return ListView(
          children: drivers
              .map(
                (d) => ListTile(
                  leading: PersonAvatar(
                    imageUrl: d.user.imageUrl,
                    name: d.user.name,
                    fallbackIcon: Icons.local_shipping,
                  ),
                  title: Text(d.user.name),
                  subtitle: Text(d.vehicleType ?? l10n.brokerNoVehicleInfo),
                  onTap: () => Navigator.pop(context, d.id),
                ),
              )
              .toList(),
        );
      },
    );
    if (selected == null) return;
    try {
      final updated = await ref.read(apiClientProvider).assignDriver(widget.loadId, selected);
      if (!mounted) return;
      setState(() => _load = updated);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastDriverAssigned)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastAssignFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final load = _load;
    if (load == null) {
      return Scaffold(
        appBar: AppHeader(title: l10n.brokerLoadDetailTitle, showBack: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final pickup = load.pickupLat != null && load.pickupLng != null ? LatLng(load.pickupLat!, load.pickupLng!) : null;
    final delivery = load.deliveryLat != null && load.deliveryLng != null ? LatLng(load.deliveryLat!, load.deliveryLng!) : null;
    final canAssign = const {'PENDING', 'CREATED', 'REJECTED'}.contains(load.status);

    return Scaffold(
      appBar: AppHeader(title: l10n.brokerLoadDetailTitle, showBack: true, notificationsPath: '/broker/notifications', profilePath: '/broker/profile'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Row(children: [Text(load.referenceNo, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700)), const Spacer(), StatusChip(status: load.status)]),
          const SizedBox(height: 12),
          TripMap(pickup: pickup, delivery: delivery, driver: _driverPoint, showLiveBadge: load.status == 'IN_TRANSIT', expandable: true),
          const SizedBox(height: 12),
          TrackingTimeline(load: load),
          const SizedBox(height: 12),
          _Card(
            title: l10n.brokerTripDetails,
            child: Column(
              children: [
                _row(l10n.brokerConfirmPickup, load.pickupAddress),
                _row(l10n.brokerConfirmDelivery, load.deliveryAddress),
                _row(l10n.brokerConfirmPickupDate, formatDateTime(load.pickupDate, locale)),
                _row(l10n.brokerConfirmRate, load.rate == null ? l10n.loadRateTbd : formatCurrency(load.rate, locale)),
                _row(l10n.brokerConfirmEquipment, equipmentLabel(l10n, load.equipmentType)),
                _row(l10n.brokerConfirmWeight, formatWeight(load.weightLbs, l10n) ?? '—'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PersonCard(title: l10n.brokerCustomer, person: load.customer, subtitle: load.customerCompany),
          const SizedBox(height: 8),
          _PersonCard(title: l10n.brokerDriver, person: load.driver, subtitle: load.driverVehicle ?? l10n.brokerAssignedDriver),
          if (load.proofOfDelivery != null) ...[
            const SizedBox(height: 12),
            _Card(
              title: l10n.brokerProofOfDelivery,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.brokerDeliveryPhoto, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(AppConfig.resolveMediaUrl(load.proofOfDelivery!.photoUrl) ?? load.proofOfDelivery!.photoUrl, height: 160, width: double.infinity, fit: BoxFit.cover)),
                  const SizedBox(height: 12),
                  Text(l10n.brokerRecipientSignature, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(AppConfig.resolveMediaUrl(load.proofOfDelivery!.signatureUrl) ?? load.proofOfDelivery!.signatureUrl, height: 120, width: double.infinity, fit: BoxFit.contain)),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: canAssign
          ? Material(
              color: AppColors.background,
              elevation: 8,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: FilledButton(
                    onPressed: _assign,
                    child: Text(l10n.brokerAssignDriver),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(k, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13))),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.outlineVariant)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 8),
        child,
      ]),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.title, required this.person, this.subtitle});
  final String title;
  final NamedPerson? person;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final name = person?.name ?? '—';
    final phone = person?.phone;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          PersonAvatar(imageUrl: person?.imageUrl, name: person?.name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
              Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
            ]),
          ),
          if (phone != null && phone.isNotEmpty)
            IconButton(onPressed: () => launchUrl(Uri.parse('tel:$phone')), icon: const Icon(Icons.phone, color: AppColors.secondary)),
        ],
      ),
    );
  }
}
