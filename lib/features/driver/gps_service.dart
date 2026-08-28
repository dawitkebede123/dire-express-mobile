import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/api_client.dart';
import '../../core/driver_position_cache.dart';
import '../../core/locale_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/load.dart';
import '../auth/auth_controller.dart';

final driverLocationControllerProvider =
    NotifierProvider<DriverLocationController, Set<String>>(DriverLocationController.new);

class GpsService {
  StreamSubscription<Position>? _watch;
  Timer? _poll;
  ApiClient? _api;
  Set<String> _loadIds = {};
  String? _notificationTitle;
  String? _notificationText;
  var _starting = false;
  var _askedAlways = false;
  var _sending = false;
  Position? _queued;

  bool get isWatching => _watch != null || _poll != null;

  Future<String?> start({
    required ApiClient api,
    required Set<String> loadIds,
    required String notificationTitle,
    required String notificationText,
  }) async {
    _api = api;
    _loadIds = {...loadIds};
    if (_loadIds.isEmpty) {
      await stop();
      return null;
    }

    final sameNotification =
        _notificationTitle == notificationTitle && _notificationText == notificationText;
    if (isWatching && sameNotification) {
      return null;
    }

    if (_starting) return null;
    _starting = true;
    try {
      await _watch?.cancel();
      _watch = null;
      _poll?.cancel();
      _poll = null;

      final permissionError = await _ensurePermission();
      if (permissionError != null) return permissionError;

      _api = api;
      if (_loadIds.isEmpty) _loadIds = {...loadIds};

      _notificationTitle = notificationTitle;
      _notificationText = notificationText;

      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) unawaited(_send(lastKnown));
      } catch (_) {}

      try {
        final current = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(timeLimit: Duration(seconds: 8)),
        );
        unawaited(_send(current));
      } catch (_) {}

      _watch = Geolocator.getPositionStream(
        locationSettings: _locationSettings(title: notificationTitle, text: notificationText),
      ).listen((pos) {
        unawaited(_send(pos));
      });

      _poll = Timer.periodic(const Duration(seconds: 120), (_) async {
        try {
          final pos = await Geolocator.getLastKnownPosition() ??
              await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(timeLimit: Duration(seconds: 8)),
              );
          await _send(pos);
        } catch (_) {}
      });

      return null;
    } finally {
      _starting = false;
    }
  }

  Future<String?> _ensurePermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return 'unavailable';

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return 'denied';
    }
    if (permission == LocationPermission.whileInUse && !_askedAlways) {
      _askedAlways = true;
      permission = await Geolocator.requestPermission();
    }
    return null;
  }

  LocationSettings _locationSettings({required String title, required String text}) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: title,
          notificationText: text,
          notificationChannelName: 'Dire Express',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 25,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 25,
    );
  }

  Future<void> _send(Position pos) async {
    final cache = DriverPositionCache.instance;
    final ids = _loadIds.toList();
    await cache.savePosition(
      lat: pos.latitude,
      lng: pos.longitude,
      heading: pos.heading.isNaN ? null : pos.heading,
      speed: pos.speed.isNaN ? null : pos.speed,
    );
    for (final id in ids) {
      await cache.savePosition(
        lat: pos.latitude,
        lng: pos.longitude,
        heading: pos.heading.isNaN ? null : pos.heading,
        speed: pos.speed.isNaN ? null : pos.speed,
        loadId: id,
      );
    }

    if (_sending) {
      _queued = pos;
      return;
    }
    _sending = true;
    try {
      var next = pos;
      while (true) {
        await _post(next, ids);
        final queued = _queued;
        if (queued == null) break;
        _queued = null;
        next = queued;
      }
    } finally {
      _sending = false;
    }
  }

  Future<void> _post(Position pos, List<String> ids) async {
    final api = _api;
    if (api == null || ids.isEmpty) return;
    await Future.wait(ids.map((id) async {
      try {
        await api.postLocation(
          lat: pos.latitude,
          lng: pos.longitude,
          heading: pos.heading.isNaN ? null : pos.heading,
          speed: pos.speed.isNaN ? null : pos.speed,
          loadId: id,
        );
      } catch (_) {}
    }));
  }

  Future<Position?> currentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) return lastKnown;
    } catch (_) {}

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(timeLimit: Duration(seconds: 8)),
      );
    } catch (_) {
      return null;
    }
  }

  Future<double?> distanceMetersTo(double lat, double lng) async {
    final pos = await currentPosition();
    if (pos == null) return null;
    return Geolocator.distanceBetween(pos.latitude, pos.longitude, lat, lng);
  }

  /// Post the current device position immediately (e.g. right after trip start).
  Future<void> sendCurrentPosition() async {
    if (_loadIds.isEmpty) return;

    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        await _send(lastKnown);
        return;
      }
    } catch (_) {}

    try {
      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(timeLimit: Duration(seconds: 8)),
      );
      await _send(current);
    } catch (_) {}
  }

  Future<void> stop() async {
    await _watch?.cancel();
    _watch = null;
    _poll?.cancel();
    _poll = null;
    _api = null;
    _loadIds = {};
    _notificationTitle = null;
    _notificationText = null;
    _queued = null;
  }
}

class DriverLocationController extends Notifier<Set<String>> {
  final _gps = GpsService();
  Timer? _refresh;
  var _syncing = false;

  @override
  Set<String> build() {
    ref.keepAlive();
    ref.listen(authControllerProvider, (prev, next) {
      unawaited(_onAuth(next));
    });
    ref.listen(localeControllerProvider, (prev, next) {
      if (state.isNotEmpty) unawaited(_ensureWatching(state));
    });
    Future.microtask(() => _onAuth(ref.read(authControllerProvider)));
    ref.onDispose(() {
      _refresh?.cancel();
      unawaited(_gps.stop());
    });
    return {};
  }

  Future<void> _onAuth(AuthState auth) async {
    if (auth.loading) return;
    final user = auth.user;
    if (user == null || !user.isDriver) {
      await stopSession();
      return;
    }
    final started = _refresh == null;
    _refresh ??= Timer.periodic(const Duration(seconds: 90), (_) {
      unawaited(sync());
    });
    if (started) await sync();
  }

  Future<void> includeLoad(String loadId) async {
    final next = {...state, loadId};
    state = next;
    await _ensureWatching(next);
  }

  /// Start GPS tracking for a trip: cache load, watch position, post immediately.
  Future<void> beginTrip(String loadId, {FreightLoad? load}) async {
    final next = {...state, loadId};
    state = next;
    final cache = DriverPositionCache.instance;
    if (load != null) {
      await cache.saveFromLoad(load);
      await cache.saveTransitIds({loadId});
    }
    await _ensureWatching(next);
    await _gps.sendCurrentPosition();
  }

  /// Force a GPS sync and one fresh location post (e.g. when reopening a trip).
  Future<void> nudgeLocation() async {
    await sync();
    if (state.isEmpty) return;
    await _ensureWatching(state);
    await _gps.sendCurrentPosition();
  }

  Future<void> sync() async {
    final user = ref.read(authControllerProvider).user;
    if (user == null || !user.isDriver) {
      await stopSession();
      return;
    }
    if (_syncing) return;
    _syncing = true;
    final cache = DriverPositionCache.instance;
    try {
      List<FreightLoad> loads;
      try {
        loads = await ref.read(apiClientProvider).listLoads(status: 'IN_TRANSIT');
      } catch (_) {
        loads = await ref.read(apiClientProvider).listLoads();
      }
      final activeLoads = loads.where((l) => l.status == 'IN_TRANSIT').toList();
      final ids = activeLoads.map((l) => l.id).toSet();
      await cache.saveTransitIds(ids);
      if (activeLoads.isNotEmpty) {
        await cache.saveActiveLoad(activeLoads.first);
        for (final load in activeLoads) {
          await cache.saveFromLoad(load);
        }
      }
      if (ids.length != state.length || !state.containsAll(ids)) {
        state = ids;
      }
      await _ensureWatching(ids);
    } catch (_) {
      if (state.isEmpty) {
        final cached = await cache.readTransitIds();
        if (cached.isNotEmpty) {
          state = cached;
          await _ensureWatching(cached);
        }
      }
    } finally {
      _syncing = false;
    }
  }

  Future<void> stopSession() async {
    _refresh?.cancel();
    _refresh = null;
    state = {};
    await _gps.stop();
  }

  Future<void> _ensureWatching(Set<String> ids) async {
    if (ids.isEmpty) {
      await _gps.stop();
      return;
    }
    final l10n = lookupAppLocalizations(ref.read(localeControllerProvider));
    await _gps.start(
      api: ref.read(apiClientProvider),
      loadIds: ids,
      notificationTitle: l10n.driverGpsActive,
      notificationText: l10n.driverGpsHint,
    );
  }
}
