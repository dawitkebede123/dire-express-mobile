import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/driver_position_cache.dart';
import '../../l10n/app_localizations.dart';
import '../../models/load.dart';
import '../../models/user.dart';
import '../../shared/format.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/driver_vehicle_row.dart';
import '../../shared/widgets/equipment_thumb.dart';
import '../../shared/widgets/person_avatar.dart';
import '../../shared/widgets/pod_documents.dart';
import '../../shared/widgets/status_chip.dart';
import '../../shared/widgets/tracking_timeline.dart';
import '../../shared/widgets/truck_thumb.dart';
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
        final load = FreightLoad.fromJson(data['load'] as Map<String, dynamic>);
        setState(() => _load = load);
        unawaited(DriverPositionCache.instance.saveFromLoad(load));
      }
      final loc = data['location'];
      if (loc is Map && loc['lat'] != null && loc['lng'] != null) {
        setState(() => _driverPoint = LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble()));
        unawaited(DriverPositionCache.instance.saveFromEvent(widget.loadId, loc));
      }
    };
    unawaited(_hydrateCache());
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

  Future<void> _hydrateCache() async {
    final pos = await DriverPositionCache.instance.readForLoad(widget.loadId);
    if (!mounted || pos == null || _driverPoint != null) return;
    setState(() => _driverPoint = pos.latLng);
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
      unawaited(DriverPositionCache.instance.saveFromLoad(load));
      unawaited(_refreshLiveLocation());
    } catch (_) {}
  }

  Future<void> _refreshLiveLocation() async {
    try {
      final loc = await ref.read(apiClientProvider).getLocation(loadId: widget.loadId);
      if (!mounted || loc == null) return;
      setState(() => _driverPoint = LatLng(loc.lat, loc.lng));
      unawaited(DriverPositionCache.instance.savePosition(
        lat: loc.lat,
        lng: loc.lng,
        recordedAt: loc.recordedAt,
        loadId: widget.loadId,
      ));
    } catch (_) {}
  }

  bool _isCurrentDriver(NamedPerson driver, NamedPerson? assigned) {
    if (assigned == null) return false;
    final email = assigned.email?.trim();
    final phone = assigned.phone?.trim();
    final driverEmail = driver.email?.trim();
    final driverPhone = driver.phone?.trim();
    if (email != null && email.isNotEmpty && email == driverEmail) return true;
    if (phone != null && phone.isNotEmpty && phone == driverPhone) return true;
    if ((email == null || email.isEmpty) && (phone == null || phone.isEmpty)) {
      return assigned.name.isNotEmpty && assigned.name == driver.name;
    }
    return false;
  }

  Future<void> _assign() async {
    final l10n = AppLocalizations.of(context);
    final assigned = _load?.driver;
    final drivers = await ref.read(apiClientProvider).listDrivers(all: true);
    if (!mounted) return;
    final loadWeight = _load?.weightLbs;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        if (drivers.isEmpty) {
          return Padding(padding: const EdgeInsets.all(24), child: Text(l10n.brokerNoDrivers));
        }
        return ListView(
          children: drivers.map((d) {
            final current = _isCurrentDriver(d.user, assigned);
            return DriverVehicleRow(
              driver: d,
              l10n: l10n,
              enabled: !current,
              isCurrent: current,
              loadWeight: loadWeight,
              onTap: () => Navigator.pop(context, d.id),
            );
          }).toList(),
        );
      },
    );
    if (selected == null) return;
    try {
      final updated = await ref.read(apiClientProvider).assignDriver(widget.loadId, selected);
      if (!mounted) return;
      setState(() => _load = updated);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastDriverAssigned)));
    } on ApiException catch (e) {
      if (!mounted) return;
      final detail = '${e.code ?? ''} ${e.message}'.toLowerCase();
      final message = e.code == 'cannotChangeDriver'
          ? l10n.toastCannotChangeDriver
          : detail.contains('payment approval')
              ? l10n.toastAssignWaitingPayment
              : l10n.toastAssignFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
    final canAssign = const {'PENDING', 'CREATED', 'REJECTED', 'ASSIGNED'}.contains(load.status);
    final hasDriver = load.driver != null && load.driver!.name.isNotEmpty;

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
                if (load.systemPrice != null)
                  _row(l10n.systemPrice, formatSystemPrice(l10n, locale, load.systemPrice!, load.distanceKm)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(l10n.brokerConfirmEquipment, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
                      ),
                      Expanded(
                        child: EquipmentLabelRow(
                          type: load.equipmentType,
                          label: equipmentLabel(l10n, load.equipmentType),
                          thumbSize: 36,
                          expandLabel: true,
                          textStyle: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                _row(l10n.brokerConfirmWeight, formatWeight(load.weightLbs, l10n) ?? '—'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PersonCard(title: l10n.brokerCustomer, person: load.customer, subtitle: load.customerCompany),
          const SizedBox(height: 8),
          _DriverCard(
            l10n: l10n,
            person: load.driver,
            vehicleType: load.driverVehicle,
            loadingCapacity: load.driverLoadingCapacity,
            truckImageUrl: load.driverTruckImageUrl,
          ),
          if (load.proofOfDelivery != null) ...[
            const SizedBox(height: 12),
            PodDocuments(pod: load.proofOfDelivery!),
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
                    child: Text(hasDriver ? l10n.brokerChangeDriver : l10n.brokerAssignDriver),
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

class _DriverCard extends StatelessWidget {
  const _DriverCard({
    required this.l10n,
    required this.person,
    this.vehicleType,
    this.loadingCapacity,
    this.truckImageUrl,
  });

  final AppLocalizations l10n;
  final NamedPerson? person;
  final String? vehicleType;
  final double? loadingCapacity;
  final String? truckImageUrl;

  @override
  Widget build(BuildContext context) {
    final name = person?.name ?? '—';
    final phone = person?.phone;
    final vehicleLabel = vehicleType != null
        ? equipmentLabel(l10n, vehicleType)
        : l10n.brokerAssignedDriver;
    final capacity = formatWeight(loadingCapacity, l10n);
    final subtitle = [
      vehicleLabel,
      if (capacity != null) l10n.brokerLoadingCapacity(capacity),
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          TruckThumb(truckImageUrl: truckImageUrl, vehicleType: vehicleType, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.brokerDriver, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          if (phone != null && phone.isNotEmpty)
            IconButton(onPressed: () => launchUrl(Uri.parse('tel:$phone')), icon: const Icon(Icons.phone, color: AppColors.secondary)),
        ],
      ),
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
