import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/directory.dart';
import '../models/load.dart';
import '../models/user.dart';
import 'auth_storage.dart';
import 'config.dart';
import 'locale_controller.dart';

final authStorageProvider = Provider<AuthStorage>((_) => AuthStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(ref.watch(authStorageProvider));
  client.localeCode = ref.read(localeControllerProvider).languageCode;
  ref.listen<Locale>(localeControllerProvider, (_, next) {
    client.localeCode = next.languageCode;
  });
  return client;
});

final loadsRefreshProvider = StateProvider<int>((_) => 0);

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.code});
  final String message;
  final int? statusCode;
  final String? code;

  bool get isReceiptRequired => code == 'receiptRequired';
  bool get isDeviceIdRequired => code == 'deviceIdRequired';

  @override
  String toString() => message;
}

class DeviceTier {
  const DeviceTier({
    required this.loadsCreated,
    required this.freeLimit,
    required this.receiptRequired,
  });

  final int loadsCreated;
  final int freeLimit;
  final bool receiptRequired;

  factory DeviceTier.fromJson(Map<String, dynamic> json) {
    return DeviceTier(
      loadsCreated: (json['loadsCreated'] as num?)?.toInt() ?? 0,
      freeLimit: (json['freeLimit'] as num?)?.toInt() ?? 3,
      receiptRequired: json['receiptRequired'] as bool? ?? false,
    );
  }
}

class ApiClient {
  ApiClient(this._storage)
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['X-Device-Id'] = await _storage.getOrCreateDeviceId();
          options.headers['X-Locale'] = localeCode;
          options.headers['Accept-Language'] = localeCode;
          handler.next(options);
        },
      ),
    );
  }

  final AuthStorage _storage;
  final Dio _dio;
  String localeCode = 'en';

  Future<Map<String, dynamic>> _unwrap(Future<Response<dynamic>> request) async {
    try {
      final res = await request;
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return <String, dynamic>{};
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = e.message ?? 'Request failed';
      String? code;
      if (data is Map && data['error'] is String) {
        code = data['error'] as String;
        message = code;
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        message = 'Connection timed out. Is the API running at ${AppConfig.apiBaseUrl}?';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'Cannot reach API at ${AppConfig.apiBaseUrl}';
      }
      if (kDebugMode) {
        debugPrint(
          'API FAILED ${e.requestOptions.method} ${e.requestOptions.uri} '
          'type=${e.type.name} status=${e.response?.statusCode} '
          'body=$data error=${e.error}',
        );
      }
      throw ApiException(message, statusCode: e.response?.statusCode, code: code);
    }
  }

  Future<({String token, AppUser user})> login(String email, String password) async {
    if (kDebugMode) {
      debugPrint(
        'LOGIN POST ${AppConfig.apiBaseUrl}/api/auth/mobile/login email=$email',
      );
    }
    final data = await _unwrap(
      _dio.post('/api/auth/mobile/login', data: {'email': email, 'password': password}),
    );
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    final token = data['token'] as String;
    await _storage.writeToken(token);
    return (token: token, user: user);
  }

  Future<AppUser> me() async {
    final data = await _unwrap(_dio.get('/api/auth/mobile/me'));
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> updateLocale(String locale) async {
    await updateMe(locale: locale);
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getMeProfile() async {
    final data = await _unwrap(_dio.get('/api/me'));
    return _asMap(data['user']);
  }

  Future<Map<String, dynamic>> updateMe({
    String? name,
    String? phone,
    String? locale,
    String? imageUrl,
  }) async {
    final data = await _unwrap(
      _dio.patch('/api/me', data: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (locale != null) 'locale': locale,
        if (imageUrl != null) 'imageUrl': imageUrl,
      }),
    );
    return _asMap(data['user']);
  }

  Future<void> register(Map<String, dynamic> body) async {
    await _unwrap(_dio.post('/api/register', data: body));
  }

  Future<List<FreightLoad>> listLoads({String? status}) async {
    final data = await _unwrap(
      _dio.get('/api/loads', queryParameters: {if (status != null) 'status': status}),
    );
    final list = data['loads'] as List<dynamic>? ?? [];
    return list.map((e) => FreightLoad.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<FreightLoad> getLoad(String id) async {
    final data = await _unwrap(_dio.get('/api/loads/$id'));
    return FreightLoad.fromJson(data['load'] as Map<String, dynamic>);
  }

  Future<DeviceTier> getDeviceTier() async {
    final data = await _unwrap(_dio.get('/api/devices/tier'));
    return DeviceTier.fromJson(data);
  }

  Future<FreightLoad> createLoad(Map<String, dynamic> body) async {
    final data = await _unwrap(_dio.post('/api/loads', data: body));
    return FreightLoad.fromJson(data['load'] as Map<String, dynamic>);
  }

  Future<FreightLoad> assignDriver(String loadId, String driverId) async {
    final data = await _unwrap(
      _dio.post('/api/loads/$loadId/assign', data: {'driverId': driverId}),
    );
    return FreightLoad.fromJson(data['load'] as Map<String, dynamic>);
  }

  Future<FreightLoad> respond(String loadId, String action) async {
    final data = await _unwrap(
      _dio.post('/api/loads/$loadId/respond', data: {'action': action}),
    );
    return FreightLoad.fromJson(data['load'] as Map<String, dynamic>);
  }

  Future<FreightLoad> submitPod(
    String loadId, {
    required String photoUrl,
    required String signatureUrl,
    required String recipientName,
    String? notes,
  }) async {
    final data = await _unwrap(
      _dio.post('/api/loads/$loadId/pod', data: {
        'photoUrl': photoUrl,
        'signatureUrl': signatureUrl,
        'recipientName': recipientName,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      }),
    );
    return FreightLoad.fromJson(data['load'] as Map<String, dynamic>);
  }

  Future<List<DriverProfile>> listDrivers({bool all = false}) async {
    final data = await _unwrap(
      _dio.get('/api/drivers', queryParameters: {if (all) 'all': '1'}),
    );
    final list = data['drivers'] as List<dynamic>? ?? [];
    return list.map((e) => DriverProfile.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<CustomerProfile>> listCustomers() async {
    final data = await _unwrap(_dio.get('/api/customers'));
    final list = data['customers'] as List<dynamic>? ?? [];
    return list.map((e) => CustomerProfile.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> postLocation({
    required double lat,
    required double lng,
    double? heading,
    double? speed,
    String? loadId,
  }) async {
    await _unwrap(
      _dio.post('/api/drivers/location', data: {
        'lat': lat,
        'lng': lng,
        if (heading != null) 'heading': heading,
        if (speed != null) 'speed': speed,
        if (loadId != null) 'loadId': loadId,
      }),
    );
  }

  Future<GeoPoint?> getLocation({String? loadId, String? driverId}) async {
    final data = await _unwrap(
      _dio.get('/api/drivers/location', queryParameters: {
        if (loadId != null) 'loadId': loadId,
        if (driverId != null) 'driverId': driverId,
      }),
    );
    final loc = data['location'];
    if (loc is Map<String, dynamic>) return GeoPoint.fromJson(loc);
    return null;
  }

  Future<List<AppNotification>> listNotifications() async {
    final data = await _unwrap(_dio.get('/api/notifications'));
    final list = data['notifications'] as List<dynamic>? ?? [];
    return list.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markNotifications({String? id, bool readAll = false}) async {
    await _unwrap(
      _dio.patch('/api/notifications', data: {
        if (id != null) 'id': id,
        if (readAll) 'readAll': true,
      }),
    );
  }

  Future<({String? plateNo, String? vehicleType})> getMyDriverProfile() async {
    final data = await _unwrap(_dio.get('/api/drivers/me'));
    final driver = _asMap(data['driver']);
    return (
      plateNo: driver['plateNo'] as String?,
      vehicleType: driver['vehicleType'] as String?,
    );
  }

  Future<({String? plateNo, String? vehicleType})> updateMyDriverProfile({
    String? plateNo,
    String? vehicleType,
  }) async {
    final data = await _unwrap(
      _dio.patch('/api/drivers/me', data: {
        if (plateNo != null) 'plateNo': plateNo,
        if (vehicleType != null) 'vehicleType': vehicleType,
      }),
    );
    final driver = _asMap(data['driver']);
    return (
      plateNo: driver['plateNo'] as String?,
      vehicleType: driver['vehicleType'] as String?,
    );
  }

  Future<String> uploadFile(String path, {String kind = 'pod'}) async {
    final form = FormData.fromMap({
      'kind': kind,
      'file': await MultipartFile.fromFile(path),
    });
    final data = await _unwrap(
      _dio.post(
        '/api/uploads',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      ),
    );
    return data['url'] as String;
  }

  Future<void> fetchRuntimeConfig() async {
    final data = await _unwrap(_dio.get('/api/config'));
    AppConfig.apply(
      mapboxToken: data['mapboxToken'] as String? ?? '',
      pusherKey: data['pusherKey'] as String? ?? '',
      pusherCluster: data['pusherCluster'] as String? ?? '',
    );
    await AppConfig.saveCached();
  }

  Future<List<String>> geocodeSuggestions(String query) async {
    if (!AppConfig.hasMapbox || query.trim().length < 3) return [];
    try {
      final res = await Dio().get(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(query)}.json',
        queryParameters: {
          'access_token': AppConfig.mapboxToken,
          'limit': 5,
          'country': 'et,dj',
          'proximity': '38.7469,9.0250',
        },
      );
      final features = res.data['features'] as List<dynamic>? ?? [];
      return features
          .map((f) => (f as Map<String, dynamic>)['place_name'] as String? ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
