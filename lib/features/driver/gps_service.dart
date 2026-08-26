import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/api_client.dart';
import '../../core/locale_controller.dart';
import '../../l10n/app_localizations.dart';
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
        final current = await Geolocator.getCurrentPosition();
        await _send(current);
      } catch (_) {}

      _watch = Geolocator.getPositionStream(
        locationSettings: _locationSettings(title: notificationTitle, text: notificationText),
      ).listen((pos) {
        unawaited(_send(pos));
      });

      _poll = Timer.periodic(const Duration(seconds: 15), (_) async {
        try {
          final pos = await Geolocator.getCurrentPosition();
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
    final api = _api;
    final ids = _loadIds.toList();
    if (api == null || ids.isEmpty) return;
    for (final id in ids) {
      try {
        await api.postLocation(
          lat: pos.latitude,
          lng: pos.longitude,
          heading: pos.heading,
          speed: pos.speed,
          loadId: id,
        );
      } catch (_) {}
    }
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
      return await Geolocator.getCurrentPosition();
    } catch (_) {
      return null;
    }
  }

  Future<double?> distanceMetersTo(double lat, double lng) async {
    final pos = await currentPosition();
    if (pos == null) return null;
    return Geolocator.distanceBetween(pos.latitude, pos.longitude, lat, lng);
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
    _refresh ??= Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(sync());
    });
    if (started) await sync();
  }

  Future<void> includeLoad(String loadId) async {
    final next = {...state, loadId};
    state = next;
    await _ensureWatching(next);
  }

  Future<void> sync() async {
    final user = ref.read(authControllerProvider).user;
    if (user == null || !user.isDriver) {
      await stopSession();
      return;
    }
    if (_syncing) return;
    _syncing = true;
    try {
      final loads = await ref.read(apiClientProvider).listLoads();
      final ids = loads.where((l) => l.status == 'IN_TRANSIT').map((l) => l.id).toSet();
      if (ids.length != state.length || !state.containsAll(ids)) {
        state = ids;
      }
      await _ensureWatching(ids);
    } catch (_) {
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
