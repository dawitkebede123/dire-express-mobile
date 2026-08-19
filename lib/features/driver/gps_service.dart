import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../core/api_client.dart';

class GpsService {
  StreamSubscription<Position>? _watch;
  Timer? _poll;

  Future<String?> start({required ApiClient api, required String loadId}) async {
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

    Future<void> send(Position pos) {
      return api.postLocation(
        lat: pos.latitude,
        lng: pos.longitude,
        heading: pos.heading,
        speed: pos.speed,
        loadId: loadId,
      );
    }

    try {
      final current = await Geolocator.getCurrentPosition();
      await send(current);
    } catch (_) {}

    _watch = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
      ),
    ).listen((pos) {
      send(pos);
    });

    _poll = Timer.periodic(const Duration(seconds: 15), (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition();
        await send(pos);
      } catch (_) {}
    });

    return null;
  }

  Future<void> stop() async {
    await _watch?.cancel();
    _watch = null;
    _poll?.cancel();
    _poll = null;
  }
}
