import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/api_client.dart';
import '../../core/driver_position_cache.dart';
import '../../l10n/app_localizations.dart';
import '../../models/load.dart';
import '../../shared/format.dart';
import '../../shared/widgets/app_header.dart';
import '../../theme/app_theme.dart';
import '../maps/trip_map.dart';
import '../notifications/pusher_service.dart';
import 'gps_service.dart';

class DriverActiveScreen extends ConsumerStatefulWidget {
  const DriverActiveScreen({super.key});

  @override
  ConsumerState<DriverActiveScreen> createState() => _DriverActiveScreenState();
}

class _DriverActiveScreenState extends ConsumerState<DriverActiveScreen> {
  FreightLoad? _load;
  var _loading = true;
  LatLng? _driverPoint;
  Timer? _driverPointTimer;
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
      if (loc is Map && loc['lat'] != null) {
        final point = LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
        setState(() => _driverPoint = point);
        final loadId = _load?.id;
        if (loadId != null) unawaited(DriverPositionCache.instance.saveFromEvent(loadId, loc));
      }
    };
    unawaited(_hydrateCache());
    _fetch();
  }

  @override
  void dispose() {
    _driverPointTimer?.cancel();
    if (_load != null) {
      pusherService.unsubscribe('load-${_load!.id}', 'status-update', _handler);
      pusherService.unsubscribe('load-${_load!.id}', 'location-update', _handler);
    }
    super.dispose();
  }

  Future<void> _hydrateCache() async {
    final cache = DriverPositionCache.instance;
    final cachedLoad = await cache.readActiveLoad();
    if (!mounted) return;
    if (cachedLoad == null) return;
    final pos = await cache.readForLoad(cachedLoad.id) ?? await cache.readDevice();
    if (!mounted) return;
    setState(() {
      _load = cachedLoad;
      _loading = false;
      if (pos != null) _driverPoint = pos.latLng;
    });
    pusherService.subscribe('load-${cachedLoad.id}', 'status-update', _handler);
    pusherService.subscribe('load-${cachedLoad.id}', 'location-update', _handler);
    if (cachedLoad.status == 'IN_TRANSIT') {
      unawaited(_refreshDriverPoint(cachedLoad.id));
      _startDriverPointTimer(cachedLoad.id);
    }
  }

  Future<void> _refreshDriverPoint(String loadId) async {
    final pos = await DriverPositionCache.instance.readForLoad(loadId) ??
        await DriverPositionCache.instance.readDevice();
    if (!mounted || pos == null) return;
    setState(() => _driverPoint = pos.latLng);
  }

  void _startDriverPointTimer(String loadId) {
    _driverPointTimer?.cancel();
    _driverPointTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      unawaited(_refreshDriverPoint(loadId));
    });
  }

  void _stopDriverPointTimer() {
    _driverPointTimer?.cancel();
    _driverPointTimer = null;
  }

  Future<void> _fetch() async {
    try {
      final loads = await ref.read(apiClientProvider).listLoads();
      final active = loads.where((l) => l.status == 'IN_TRANSIT').firstOrNull;
      if (!mounted) return;
      final previousId = _load?.id;
      setState(() {
        _load = active;
        _loading = false;
        if (active?.latestLocation != null) {
          _driverPoint = LatLng(active!.latestLocation!.lat, active.latestLocation!.lng);
        }
      });
      if (previousId != null && previousId != active?.id) {
        pusherService.unsubscribe('load-$previousId', 'status-update', _handler);
        pusherService.unsubscribe('load-$previousId', 'location-update', _handler);
      }
      if (active != null) {
        unawaited(DriverPositionCache.instance.saveFromLoad(active));
        unawaited(DriverPositionCache.instance.saveTransitIds({active.id}));
        pusherService.subscribe('load-${active.id}', 'status-update', _handler);
        pusherService.subscribe('load-${active.id}', 'location-update', _handler);
        unawaited(_refreshLiveLocation(active.id));
        final tracked = ref.read(driverLocationControllerProvider);
        if (!tracked.contains(active.id)) {
          await ref.read(driverLocationControllerProvider.notifier).beginTrip(active.id, load: active);
        } else {
          await ref.read(driverLocationControllerProvider.notifier).nudgeLocation();
        }
        await _refreshDriverPoint(active.id);
        _startDriverPointTimer(active.id);
      } else {
        _stopDriverPointTimer();
        unawaited(DriverPositionCache.instance.saveTransitIds({}));
      }
    } catch (_) {
      if (mounted && _load == null) setState(() => _loading = false);
    }
  }

  Future<void> _refreshLiveLocation(String loadId) async {
    try {
      final loc = await ref.read(apiClientProvider).getLocation(loadId: loadId);
      if (!mounted || loc == null) return;
      setState(() => _driverPoint = LatLng(loc.lat, loc.lng));
      unawaited(DriverPositionCache.instance.savePosition(
        lat: loc.lat,
        lng: loc.lng,
        recordedAt: loc.recordedAt,
        loadId: loadId,
      ));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(loadsRefreshProvider, (_, _) {
      unawaited(_fetch());
    });
    ref.listen<Set<String>>(driverLocationControllerProvider, (prev, next) {
      if (prev == next) return;
      unawaited(_fetch());
    });
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
