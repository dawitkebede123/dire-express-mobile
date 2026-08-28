import 'dart:convert';

import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/load.dart';

class CachedDriverPosition {
  const CachedDriverPosition({
    required this.lat,
    required this.lng,
    this.heading,
    this.speed,
    this.recordedAt,
    this.loadId,
  });

  final double lat;
  final double lng;
  final double? heading;
  final double? speed;
  final DateTime? recordedAt;
  final String? loadId;

  LatLng get latLng => LatLng(lat, lng);

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        if (heading != null) 'heading': heading,
        if (speed != null) 'speed': speed,
        if (recordedAt != null) 'recordedAt': recordedAt!.toIso8601String(),
        if (loadId != null) 'loadId': loadId,
      };

  factory CachedDriverPosition.fromJson(Map<String, dynamic> json) {
    return CachedDriverPosition(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      recordedAt: json['recordedAt'] != null
          ? DateTime.tryParse(json['recordedAt'].toString())
          : null,
      loadId: json['loadId'] as String?,
    );
  }
}

class DriverPositionCache {
  DriverPositionCache._();
  static final DriverPositionCache instance = DriverPositionCache._();

  static const _deviceKey = 'driver_last_position';
  static const _loadPrefix = 'driver_position_';
  static const _transitIdsKey = 'driver_in_transit_ids';
  static const _activeLoadKey = 'driver_active_load';

  Future<void> savePosition({
    required double lat,
    required double lng,
    double? heading,
    double? speed,
    String? loadId,
    DateTime? recordedAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final point = CachedDriverPosition(
      lat: lat,
      lng: lng,
      heading: heading,
      speed: speed,
      recordedAt: recordedAt ?? DateTime.now(),
      loadId: loadId,
    );
    final encoded = jsonEncode(point.toJson());
    await prefs.setString(_deviceKey, encoded);
    if (loadId != null && loadId.isNotEmpty) {
      await prefs.setString('$_loadPrefix$loadId', encoded);
    }
  }

  Future<void> saveFromLoad(FreightLoad load) async {
    final loc = load.latestLocation;
    if (loc != null) {
      await savePosition(
        lat: loc.lat,
        lng: loc.lng,
        recordedAt: loc.recordedAt,
        loadId: load.id,
      );
    }
    if (load.status == 'IN_TRANSIT') {
      await saveActiveLoad(load);
    }
  }

  Future<CachedDriverPosition?> readForLoad(String loadId) async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString('$_loadPrefix$loadId'));
  }

  Future<CachedDriverPosition?> readDevice() async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_deviceKey));
  }

  Future<void> saveTransitIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_transitIdsKey, ids.toList());
    if (ids.isEmpty) await prefs.remove(_activeLoadKey);
  }

  Future<Set<String>> readTransitIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_transitIdsKey) ?? const <String>[]).toSet();
  }

  Future<void> saveActiveLoad(FreightLoad load) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeLoadKey, jsonEncode(load.toCacheJson()));
  }

  Future<FreightLoad?> readActiveLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activeLoadKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return FreightLoad.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  CachedDriverPosition? _decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return CachedDriverPosition.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<CachedDriverPosition?> saveFromEvent(String loadId, dynamic loc) async {
    if (loc is! Map) return null;
    final lat = loc['lat'];
    final lng = loc['lng'];
    if (lat is! num || lng is! num) return null;
    await savePosition(
      lat: lat.toDouble(),
      lng: lng.toDouble(),
      heading: (loc['heading'] as num?)?.toDouble(),
      speed: (loc['speed'] as num?)?.toDouble(),
      loadId: loadId,
    );
    return CachedDriverPosition(
      lat: lat.toDouble(),
      lng: lng.toDouble(),
      loadId: loadId,
    );
  }
}
