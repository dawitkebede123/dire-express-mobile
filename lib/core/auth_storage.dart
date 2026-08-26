import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:uuid/uuid.dart';

class AuthStorage {
  static const _tokenKey = 'dire_express_token';
  static const _deviceIdKey = 'dire_express_device_id';
  static const _storage = FlutterSecureStorage();
  static const _uuid = Uuid();

  String? _token;
  var _tokenLoaded = false;
  String? _deviceId;
  Future<String>? _deviceIdFuture;

  Future<String?> readToken() async {
    if (_tokenLoaded) return _token;
    _token = await _storage.read(key: _tokenKey);
    _tokenLoaded = true;
    return _token;
  }

  Future<void> writeToken(String token) async {
    _token = token;
    _tokenLoaded = true;
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Platform device ID (Android ANDROID_ID / iOS IDFV). Survives reinstall on Android.
  /// Cached in memory and secure storage; migrated from older random UUIDs to the platform ID.
  Future<String> getOrCreateDeviceId() {
    if (_deviceId != null) return Future.value(_deviceId);
    return _deviceIdFuture ??= _loadDeviceId();
  }

  Future<String> _loadDeviceId() async {
    final cached = await _storage.read(key: _deviceIdKey);
    if (cached != null && cached.isNotEmpty) {
      _deviceId = cached;
      unawaited(_refreshPlatformId(cached));
      return cached;
    }

    final platformId = await _readPlatformId();
    if (platformId != null) {
      await _storage.write(key: _deviceIdKey, value: platformId);
      return _deviceId = platformId;
    }

    final fallback = _uuid.v4();
    await _storage.write(key: _deviceIdKey, value: fallback);
    return _deviceId = fallback;
  }

  Future<void> _refreshPlatformId(String cached) async {
    final platformId = await _readPlatformId();
    if (platformId == null || platformId == cached) return;
    _deviceId = platformId;
    await _storage.write(key: _deviceIdKey, value: platformId);
  }

  Future<String?> _readPlatformId() async {
    try {
      final udid = await FlutterUdid.consistentUdid.timeout(const Duration(seconds: 2));
      final trimmed = udid.trim();
      if (trimmed.isNotEmpty) return trimmed;
    } catch (_) {}
    return null;
  }

  Future<void> clear() async {
    _token = null;
    _tokenLoaded = true;
    await _storage.delete(key: _tokenKey);
  }
}
