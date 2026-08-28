import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../models/directory.dart';
import '../models/load.dart';
import '../models/user.dart';
import '../shared/system_price.dart';
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
  bool get isNoNetwork =>
      code == 'noNetwork' || code == 'connectionFailed' || code == 'timeout';

  @override
  String toString() => message;
}

class LoginAfterRegisterException implements Exception {
  LoginAfterRegisterException(this.cause);
  final ApiException cause;
}

class DeviceTier {
  const DeviceTier({
    required this.loadsCreated,
    required this.deviceLoadsCreated,
    required this.emailLoadsCreated,
    required this.freeLimit,
    required this.receiptRequired,
  });

  final int loadsCreated;
  final int deviceLoadsCreated;
  final int emailLoadsCreated;
  final int freeLimit;
  final bool receiptRequired;

  int get remaining {
    final left = freeLimit - loadsCreated;
    return left > 0 ? left : 0;
  }

  static const none = DeviceTier(
    loadsCreated: 0,
    deviceLoadsCreated: 0,
    emailLoadsCreated: 0,
    freeLimit: 3,
    receiptRequired: false,
  );

  factory DeviceTier.fromJson(Map<String, dynamic> json) {
    return DeviceTier(
      loadsCreated: (json['loadsCreated'] as num?)?.toInt() ?? 0,
      deviceLoadsCreated: (json['deviceLoadsCreated'] as num?)?.toInt() ?? 0,
      emailLoadsCreated: (json['emailLoadsCreated'] as num?)?.toInt() ?? 0,
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
          final path = options.path;
          final skipAuth = path == '/api/auth/mobile/login' || path == '/api/register';
          if (!skipAuth) {
            final token = await _storage.readToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
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
        code = 'noNetwork';
        message = 'noNetwork';
      } else if (e.type == DioExceptionType.connectionError) {
        code = 'noNetwork';
        message = 'noNetwork';
      }
      if (kDebugMode) {
        final bodyPreview = switch (data) {
          String s when s.length > 160 => '${s.substring(0, 160)}…',
          _ => data,
        };
        debugPrint(
          'API FAILED ${e.requestOptions.method} ${e.requestOptions.uri} '
          'type=${e.type.name} status=${e.response?.statusCode} '
          'body=$bodyPreview error=${e.error}',
        );
      }
      throw ApiException(message, statusCode: e.response?.statusCode, code: code);
    }
  }

  Future<({String token, AppUser user})> login(
    String identifier,
    String password, {
    String? role,
  }) async {
    if (kDebugMode) {
      debugPrint(
        'LOGIN POST ${AppConfig.apiBaseUrl}/api/auth/mobile/login identifier=$identifier',
      );
    }
    final data = await _unwrap(
      _dio.post('/api/auth/mobile/login', data: {
        'identifier': identifier,
        'password': password.trim(),
        if (identifier.contains('@'))
          'email': identifier
        else
          'phone': identifier,
        if (role != null && role.isNotEmpty) 'role': role,
      }),
    );
    final userJson = _asMap(data['user']);
    _mergeDriverFields(userJson, data);
    final user = AppUser.fromJson(userJson);
    final token = data['token'] as String;
    await _storage.writeToken(token);
    return (token: token, user: user);
  }

  Future<AppUser> me() async {
    final data = await _unwrap(_dio.get('/api/auth/mobile/me'));
    final userJson = _asMap(data['user']);
    _mergeDriverFields(userJson, data);
    return AppUser.fromJson(userJson);
  }

  Future<void> updateLocale(String locale) async {
    await updateMe(locale: locale);
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  String? _stringField(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String? _plateField(Map<String, dynamic> json) {
    return _stringField(json, 'plateNo') ?? _stringField(json, 'plateNumber');
  }

  double? _numberField(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  ({
    String? plateNo,
    String? vehicleType,
    double? loadingCapacity,
    String? truckImageUrl,
  }) _driverFieldsFromMap(Map<String, dynamic> driver) {
    return (
      plateNo: _plateField(driver),
      vehicleType: _stringField(driver, 'vehicleType'),
      loadingCapacity: _numberField(driver, 'loadingCapacity'),
      truckImageUrl: _stringField(driver, 'truckImageUrl'),
    );
  }

  void _mergeDriverFields(Map<String, dynamic> user, Map<String, dynamic> data) {
    final nestedDriver = _asMap(data['driver']).isNotEmpty
        ? _asMap(data['driver'])
        : _asMap(user['driver']);
    if (nestedDriver.isNotEmpty) {
      user['driver'] = nestedDriver;
    }
    final plate = _plateField(user) ?? _plateField(nestedDriver);
    final vehicle = _stringField(user, 'vehicleType') ?? _stringField(nestedDriver, 'vehicleType');
    final capacity = _numberField(user, 'loadingCapacity') ?? _numberField(nestedDriver, 'loadingCapacity');
    final truckImage = _stringField(user, 'truckImageUrl') ?? _stringField(nestedDriver, 'truckImageUrl');
    if (plate != null) user['plateNo'] = plate;
    if (vehicle != null) user['vehicleType'] = vehicle;
    if (capacity != null) user['loadingCapacity'] = capacity;
    if (truckImage != null) user['truckImageUrl'] = truckImage;
  }

  Map<String, dynamic> _driverMap(Map<String, dynamic> data) {
    final nested = _asMap(data['driver']);
    if (nested.isNotEmpty) return nested;
    return data;
  }

  Map<String, dynamic> _customerMap(Map<String, dynamic> data) {
    final nested = _asMap(data['customer']);
    if (nested.isNotEmpty) return nested;
    return data;
  }

  Future<Map<String, dynamic>> getMeProfile() async {
    final data = await _unwrap(_dio.get('/api/me'));
    final user = _asMap(data['user']);
    final customer = _asMap(data['customer']);
    final company = _stringField(user, 'company') ?? _stringField(customer, 'company');
    if (company != null) user['company'] = company;
    _mergeDriverFields(user, data);
    return user;
  }

  Future<Map<String, dynamic>> updateMe({
    String? name,
    String? phone,
    String? company,
    String? locale,
    String? imageUrl,
  }) async {
    final data = await _unwrap(
      _dio.patch('/api/me', data: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (company != null) 'company': company,
        if (locale != null) 'locale': locale,
        if (imageUrl != null) 'imageUrl': imageUrl,
      }),
    );
    return _asMap(data['user']);
  }

  Future<void> register(Map<String, dynamic> body) async {
    if (kDebugMode) {
      debugPrint('REGISTER POST ${AppConfig.apiBaseUrl}/api/register role=${body['role']}');
    }
    await _unwrap(
      _dio.post('/api/register', data: body).then((res) {
        if (kDebugMode) {
          debugPrint('REGISTER OK status=${res.statusCode}');
        }
        return res;
      }),
    );
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
    final loadJson = Map<String, dynamic>.from(_asMap(data['load']));
    final pod = _asMap(data['pod']);
    if (pod.isNotEmpty) {
      loadJson['proofOfDelivery'] ??= pod;
      loadJson['pod'] ??= pod;
    }
    return FreightLoad.fromJson(loadJson);
  }

  Future<DeviceTier> getDeviceTier() async {
    try {
      final data = await _unwrap(_dio.get('/api/devices/tier'));
      return DeviceTier.fromJson(data);
    } on ApiException catch (e) {
      if (e.statusCode == 403) return DeviceTier.none;
      rethrow;
    }
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
    final photo = AppConfig.resolveMediaUrl(photoUrl) ?? photoUrl;
    final signature = AppConfig.resolveMediaUrl(signatureUrl) ?? signatureUrl;
    final data = await _unwrap(
      _dio.post('/api/loads/$loadId/pod', data: {
        'photoUrl': photo,
        'signatureUrl': signature,
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
      _dio.post(
        '/api/drivers/location',
        data: {
          'lat': lat,
          'lng': lng,
          if (heading != null) 'heading': heading,
          if (speed != null) 'speed': speed,
          if (loadId != null) 'loadId': loadId,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      ),
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

  Future<({String? company})> getMyCustomerProfile() async {
    final data = await _unwrap(_dio.get('/api/customers/me'));
    final customer = _customerMap(data);
    return (company: _stringField(customer, 'company'));
  }

  Future<({String? company})> updateMyCustomerProfile({String? company}) async {
    final data = await _unwrap(
      _dio.patch('/api/customers/me', data: {
        if (company != null) 'company': company,
      }),
    );
    final customer = _customerMap(data);
    return (company: _stringField(customer, 'company'));
  }

  Future<({
    String? plateNo,
    String? vehicleType,
    double? loadingCapacity,
    String? truckImageUrl,
  })> getMyDriverProfile() async {
    final user = await getMeProfile();
    final nestedDriver = _asMap(user['driver']);
    final fields = _driverFieldsFromMap(nestedDriver.isNotEmpty ? nestedDriver : user);
    return (
      plateNo: fields.plateNo ?? _plateField(user),
      vehicleType: fields.vehicleType ?? _stringField(user, 'vehicleType'),
      loadingCapacity: fields.loadingCapacity ?? _numberField(user, 'loadingCapacity'),
      truckImageUrl: fields.truckImageUrl ?? _stringField(user, 'truckImageUrl'),
    );
  }

  Future<({
    String? plateNo,
    String? vehicleType,
    double? loadingCapacity,
    String? truckImageUrl,
  })> updateMyDriverProfile({
    String? plateNo,
    String? vehicleType,
    double? loadingCapacity,
    String? truckImageUrl,
  }) async {
    final data = await _unwrap(
      _dio.patch('/api/drivers/me', data: {
        if (plateNo != null) 'plateNo': plateNo,
        if (vehicleType != null) 'vehicleType': vehicleType,
        if (loadingCapacity != null) 'loadingCapacity': loadingCapacity,
        if (truckImageUrl != null) 'truckImageUrl': truckImageUrl,
      }),
    );
    return _driverFieldsFromMap(_driverMap(data));
  }

  Future<String> uploadFile(String path, {String kind = 'pod'}) async {
    final form = FormData.fromMap({
      'kind': kind,
      'file': await MultipartFile.fromFile(path),
    });
    final data = await _unwrap(_dio.post('/api/uploads', data: form));
    final raw = _stringField(data, 'url');
    if (raw == null) throw ApiException('Upload failed');
    if (kind == 'truck') return raw;
    final url = AppConfig.resolveMediaUrl(raw);
    if (url == null) throw ApiException('Upload failed');
    return url;
  }

  Future<void> fetchRuntimeConfig() async {
    try {
      final data = await _unwrap(_dio.get('/api/config'));
      AppConfig.apply(
        mapboxToken: data['mapboxToken'] as String? ?? '',
        pusherKey: data['pusherKey'] as String? ?? '',
        pusherCluster: data['pusherCluster'] as String? ?? '',
        basePrice: (data['basePrice'] as num?)?.toDouble(),
        pricePerKm: (data['pricePerKm'] as num?)?.toDouble(),
      );
      await AppConfig.saveCached();
    } on ApiException catch (e) {
      if (e.statusCode == 404) return;
      rethrow;
    }
  }

  Future<List<PlaceSuggestion>> geocodeSuggestions(String query) async {
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
      return features.map(_placeFromFeature).whereType<PlaceSuggestion>().toList();
    } catch (_) {
      return [];
    }
  }

  Future<PlaceSuggestion?> geocodePlace(String query) async {
    final results = await geocodeSuggestions(query);
    return results.isEmpty ? null : results.first;
  }

  Future<PlaceSuggestion?> reverseGeocode(double lat, double lng) async {
    if (!AppConfig.hasMapbox) return null;
    try {
      final res = await Dio().get(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json',
        queryParameters: {
          'access_token': AppConfig.mapboxToken,
          'limit': 1,
        },
      );
      final features = res.data['features'] as List<dynamic>? ?? [];
      if (features.isEmpty) {
        return PlaceSuggestion(
          placeName: '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
          lat: lat,
          lng: lng,
        );
      }
      return _placeFromFeature(features.first) ??
          PlaceSuggestion(
            placeName: '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
            lat: lat,
            lng: lng,
          );
    } catch (_) {
      return PlaceSuggestion(
        placeName: '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
        lat: lat,
        lng: lng,
      );
    }
  }

  /// Driving distance in km. Falls back to straight-line if Directions fails.
  Future<double?> drivingDistanceKm({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    if (AppConfig.hasMapbox) {
      try {
        final res = await Dio().get(
          'https://api.mapbox.com/directions/v5/mapbox/driving/$fromLng,$fromLat;$toLng,$toLat',
          queryParameters: {
            'access_token': AppConfig.mapboxToken,
            'overview': 'false',
          },
        );
        final routes = res.data['routes'] as List<dynamic>? ?? [];
        if (routes.isNotEmpty) {
          final meters = (routes.first as Map<String, dynamic>)['distance'] as num?;
          if (meters != null) return meters.toDouble() / 1000.0;
        }
      } catch (_) {}
    }
    try {
      const distance = Distance();
      final meters = distance.as(
        LengthUnit.Meter,
        LatLng(fromLat, fromLng),
        LatLng(toLat, toLng),
      );
      return meters / 1000.0;
    } catch (_) {
      return null;
    }
  }

  PlaceSuggestion? _placeFromFeature(dynamic feature) {
    if (feature is! Map) return null;
    final map = Map<String, dynamic>.from(feature);
    final name = map['place_name'] as String? ?? '';
    if (name.isEmpty) return null;
    final center = map['center'];
    if (center is! List || center.length < 2) return null;
    return PlaceSuggestion(
      placeName: name,
      lng: (center[0] as num).toDouble(),
      lat: (center[1] as num).toDouble(),
    );
  }
}
