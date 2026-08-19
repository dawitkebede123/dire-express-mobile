import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:uuid/uuid.dart';

class AuthStorage {
  static const _tokenKey = 'dire_express_token';
  static const _deviceIdKey = 'dire_express_device_id';
  static const _storage = FlutterSecureStorage();
  static const _uuid = Uuid();

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  /// Platform device ID (Android ANDROID_ID / iOS IDFV). Survives reinstall on Android.
  /// Cached in secure storage; migrated from older random UUIDs to the platform ID.
  Future<String> getOrCreateDeviceId() async {
    final cached = await _storage.read(key: _deviceIdKey);
    String? platformId;
    try {
      final udid = await FlutterUdid.consistentUdid;
      if (udid.trim().isNotEmpty) platformId = udid.trim();
    } catch (_) {}

    if (platformId != null) {
      if (cached != platformId) {
        await _storage.write(key: _deviceIdKey, value: platformId);
      }
      return platformId;
    }

    if (cached != null && cached.isNotEmpty) return cached;

    final fallback = _uuid.v4();
    await _storage.write(key: _deviceIdKey, value: fallback);
    return fallback;
  }

  Future<void> clear() => _storage.delete(key: _tokenKey);
}
