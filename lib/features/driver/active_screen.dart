import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../models/load.dart';
import '../../shared/format.dart';
import '../../shared/widgets/app_header.dart';
import '../../theme/app_theme.dart';
import '../maps/trip_map.dart';
import '../notifications/pusher_service.dart';

class DriverActiveScreen extends ConsumerStatefulWidget {
  const DriverActiveScreen({super.key});

  @override
  ConsumerState<DriverActiveScreen> createState() => _DriverActiveScreenState();
}

class _DriverActiveScreenState extends ConsumerState<DriverActiveScreen> {
  FreightLoad? _load;
  var _loading = true;
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
  }

  @override
  void dispose() {
    if (_load != null) {
      pusherService.unsubscribe('load-${_load!.id}', 'status-update', _handler);
      pusherService.unsubscribe('load-${_load!.id}', 'location-update', _handler);
    }
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final loads = await ref.read(apiClientProvider).listLoads();
      final active = loads.where((l) => l.status == 'IN_TRANSIT').firstOrNull;
      if (!mounted) return;
      setState(() {
        _load = active;
        _loading = false;
        if (active?.latestLocation != null) {
          _driverPoint = LatLng(active!.latestLocation!.lat, active.latestLocation!.lng);
        }
      });
      if (active != null) {
        pusherService.subscribe('load-${active.id}', 'status-update', _handler);
        pusherService.subscribe('load-${active.id}', 'location-update', _handler);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final load = _load;

    return Scaffold(
      appBar: AppHeader(
        title: l10n.driverActiveTitle,
        notificationsPath: '/driver/notifications',
        profilePath: '/driver/profile',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : load == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l10n.driverNoTrip, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                        const SizedBox(height: 8),
                        Text(l10n.driverNoTripHint, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.onSurfaceVariant)),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: () => context.go('/driver'), child: Text(l10n.driverViewLoads)),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TripMap(
                      pickup: load.pickupLat != null ? LatLng(load.pickupLat!, load.pickupLng!) : null,
                      delivery: load.deliveryLat != null ? LatLng(load.deliveryLat!, load.deliveryLng!) : null,
                      driver: _driverPoint,
                      height: 260,
                      showLiveBadge: true,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(load.referenceNo, style: const TextStyle(color: Colors.white70, fontFamily: 'monospace')),
                        Text(load.customer?.name ?? l10n.driverCustomer, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                        Text('${shortAddress(load.pickupAddress)} → ${shortAddress(load.deliveryAddress)}', style: const TextStyle(color: Colors.white70)),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.push('/driver/loads/${load.id}'),
                      child: Text(l10n.driverCompleteDelivery),
                    ),
                  ],
                ),
    );
  }
}
