import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://187.124.55.8',
  );

  static const _mapboxKey = 'runtime_mapbox_token';
  static const _pusherKey = 'runtime_pusher_key';
  static const _pusherClusterKey = 'runtime_pusher_cluster';

  static String mapboxToken = '';
  static String pusherKey = '';
  static String pusherCluster = '';

  static bool get hasMapbox => mapboxToken.isNotEmpty;
  static bool get hasPusher => pusherKey.isNotEmpty;

  static void apply({
    required String mapboxToken,
    required String pusherKey,
    required String pusherCluster,
  }) {
    AppConfig.mapboxToken = mapboxToken;
    AppConfig.pusherKey = pusherKey;
    AppConfig.pusherCluster = pusherCluster;
  }

  static Future<void> loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    mapboxToken = prefs.getString(_mapboxKey) ?? '';
    pusherKey = prefs.getString(_pusherKey) ?? '';
    pusherCluster = prefs.getString(_pusherClusterKey) ?? '';
  }

  static Future<void> saveCached() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mapboxKey, mapboxToken);
    await prefs.setString(_pusherKey, pusherKey);
    await prefs.setString(_pusherClusterKey, pusherCluster);
  }
}
