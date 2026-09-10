import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../models/directory.dart';
import '../../models/user.dart';
import '../../shared/widgets/person_avatar.dart';

class AuthState {
  const AuthState({this.user, this.loading = true});

  final AppUser? user;
  final bool loading;

  bool get isAuthenticated => user != null;
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(restore);
    return const AuthState();
  }

  ApiClient get _api => ref.read(apiClientProvider);

  Future<void> restore() async {
    final token = await ref.read(authStorageProvider).readToken();
    if (token == null || token.isEmpty) {
      state = const AuthState(loading: false);
      return;
    }
    try {
      final user = await _api.me().timeout(const Duration(seconds: 8));
      state = AuthState(user: user, loading: false);
      unawaited(prefetchPersonAvatar(user.imageUrl));
      unawaited(_refreshRuntimeConfig());
    } catch (_) {
      await ref.read(authStorageProvider).clear();
      state = const AuthState(loading: false);
    }
  }

  Future<AppUser> login(
    String identifier,
    String password, {
    String? expectedRole,
    bool applyState = true,
  }) async {
    final result = await _api.login(identifier, password, role: expectedRole);
    final user = result.user;
    final wanted = expectedRole?.trim().toUpperCase();
    if (wanted != null && wanted.isNotEmpty && user.role != wanted) {
      await ref.read(authStorageProvider).clear();
      throw ApiException('roleMismatch', code: 'roleMismatch');
    }
    if (applyState) {
      _applyAuthenticated(user);
    }
    return user;
  }

  void _applyAuthenticated(AppUser user) {
    state = AuthState(user: user, loading: false);
    unawaited(prefetchPersonAvatar(user.imageUrl));
    unawaited(_refreshRuntimeConfig());
    unawaited(_refreshMe());
  }

  Future<void> _refreshMe() async {
    try {
      var user = await _api.me().timeout(const Duration(seconds: 8));
      final current = state.user;
      if (current == null || current.id != user.id) return;
      final mePhone = user.phone?.trim() ?? '';
      final localPhone = current.phone?.trim() ?? '';
      if (mePhone.isEmpty && localPhone.isNotEmpty) {
        user = user.applyProfile(name: user.name, phone: current.phone);
      }
      final meCompany = user.company?.trim() ?? '';
      final localCompany = current.company?.trim() ?? '';
      if (meCompany.isEmpty && localCompany.isNotEmpty) {
        user = user.applyProfile(name: user.name, phone: user.phone, company: current.company);
      }
      final mePlate = user.plateNo?.trim() ?? '';
      final localPlate = current.plateNo?.trim() ?? '';
      if (mePlate.isEmpty && localPlate.isNotEmpty) {
        user = user.applyProfile(name: user.name, phone: user.phone, plateNo: current.plateNo);
      }
      final meVehicle = user.vehicleType?.trim() ?? '';
      final localVehicle = current.vehicleType?.trim() ?? '';
      if (meVehicle.isEmpty && localVehicle.isNotEmpty) {
        user = user.applyProfile(name: user.name, phone: user.phone, vehicleType: current.vehicleType);
      }
      if (user.loadingCapacity == null && current.loadingCapacity != null) {
        user = user.applyProfile(name: user.name, phone: user.phone, loadingCapacity: current.loadingCapacity);
      }
      if ((user.truckImageUrl == null || user.truckImageUrl!.isEmpty) &&
          current.truckImageUrl != null &&
          current.truckImageUrl!.isNotEmpty) {
        user = user.applyProfile(name: user.name, phone: user.phone, truckImageUrl: current.truckImageUrl);
      }
      final meAgentId = user.agentId?.trim() ?? '';
      final localAgentId = current.agentId?.trim() ?? '';
      if (meAgentId.isEmpty && localAgentId.isNotEmpty) {
        user = user.applyProfile(name: user.name, phone: user.phone, agentId: current.agentId);
      }
      state = AuthState(user: user, loading: false);
      unawaited(prefetchPersonAvatar(user.imageUrl));
    } catch (_) {}
  }

  Future<void> _refreshRuntimeConfig() async {
    try {
      await _api.fetchRuntimeConfig();
    } catch (_) {}
  }

  Future<AppUser> register(Map<String, dynamic> body) async {
    try {
      await _api.register(body).timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw ApiException('Connection timed out', code: 'timeout');
    }
    final email = (body['email'] as String?)?.trim() ?? '';
    final phone = (body['phone'] as String?)?.trim() ?? '';
    final company = (body['company'] as String?)?.trim() ?? '';
    final identifier = email.isNotEmpty ? email : phone;
    final role = (body['role'] as String?)?.trim();
    late AppUser user;
    try {
      user = await login(
        identifier,
        body['password'] as String,
        expectedRole: role,
        applyState: false,
      );
    } on ApiException catch (e) {
      throw LoginAfterRegisterException(e);
    }

    if (phone.isNotEmpty || company.isNotEmpty) {
      try {
        final data = await _api.updateMe(
          phone: phone.isNotEmpty ? phone : null,
          company: company.isNotEmpty ? company : null,
        );
        final savedPhone = data['phone']?.toString().trim();
        final savedCompany = data['company']?.toString().trim();
        user = user.applyProfile(
          name: user.name,
          phone: (savedPhone != null && savedPhone.isNotEmpty) ? savedPhone : (phone.isNotEmpty ? phone : user.phone),
          company: (savedCompany != null && savedCompany.isNotEmpty)
              ? savedCompany
              : (company.isNotEmpty ? company : user.company),
        );
      } catch (_) {
        user = user.applyProfile(
          name: user.name,
          phone: phone.isNotEmpty ? phone : user.phone,
          company: company.isNotEmpty ? company : user.company,
        );
      }
    }

    if (user.isCustomer && company.isNotEmpty) {
      try {
        final saved = await _api.updateMyCustomerProfile(company: company);
        user = user.applyProfile(name: user.name, phone: user.phone, company: saved.company ?? company);
      } catch (_) {
        user = user.applyProfile(name: user.name, phone: user.phone, company: company);
      }
    }

    if (user.isDriver) {
      final plate = (body['plateNo'] as String?)?.trim() ?? '';
      final vehicle = (body['vehicleType'] as String?)?.trim() ?? '';
      final truckPath = body['truckImagePath'] as String?;
      final capacity = switch (body['loadingCapacity']) {
        num n => n.toDouble(),
        String s => double.tryParse(s),
        _ => null,
      };
      if (plate.isNotEmpty || vehicle.isNotEmpty || truckPath != null || capacity != null) {
        Future<DriverProfile> patchDriver({String? truckImageUrl}) {
          return _api.updateMyDriverProfile(
            plateNo: plate.isNotEmpty ? plate : null,
            vehicleType: vehicle.isNotEmpty ? vehicle : null,
            loadingCapacity: capacity,
            truckImageUrl: truckImageUrl,
          );
        }

        try {
          String? truckImageUrl;
          if (truckPath != null && truckPath.isNotEmpty) {
            truckImageUrl = await _api.uploadFile(truckPath, kind: 'truck');
          }
          final saved = await patchDriver(truckImageUrl: truckImageUrl);
          user = user.applyProfile(
            name: user.name,
            phone: user.phone,
            plateNo: plate.isNotEmpty ? plate : user.plateNo,
            vehicleType: vehicle.isNotEmpty ? vehicle : user.vehicleType,
            loadingCapacity: saved.loadingCapacity ?? capacity ?? user.loadingCapacity,
            truckImageUrl: saved.truckImageUrl ?? truckImageUrl ?? user.truckImageUrl,
          );
        } catch (e) {
          if (kDebugMode) debugPrint('DRIVER PROFILE PATCH failed: $e');
          try {
            await Future<void>.delayed(const Duration(milliseconds: 400));
            String? truckImageUrl;
            if (truckPath != null && truckPath.isNotEmpty) {
              truckImageUrl = await _api.uploadFile(truckPath, kind: 'truck');
            }
            final saved = await patchDriver(truckImageUrl: truckImageUrl);
            user = user.applyProfile(
              name: user.name,
              phone: user.phone,
              plateNo: plate.isNotEmpty ? plate : user.plateNo,
              vehicleType: vehicle.isNotEmpty ? vehicle : user.vehicleType,
              loadingCapacity: saved.loadingCapacity ?? capacity ?? user.loadingCapacity,
              truckImageUrl: saved.truckImageUrl ?? truckImageUrl ?? user.truckImageUrl,
            );
          } catch (e2) {
            if (kDebugMode) debugPrint('DRIVER PROFILE PATCH retry failed: $e2');
            user = user.applyProfile(
              name: user.name,
              phone: user.phone,
              plateNo: plate.isNotEmpty ? plate : user.plateNo,
              vehicleType: vehicle.isNotEmpty ? vehicle : user.vehicleType,
              loadingCapacity: capacity ?? user.loadingCapacity,
            );
          }
        }
      }
    }

    _applyAuthenticated(user);
    return user;
  }

  void applyUser(AppUser user) {
    state = AuthState(user: user, loading: false);
    unawaited(prefetchPersonAvatar(user.imageUrl));
  }

  Future<void> signOut() async {
    await ref.read(authStorageProvider).clear();
    state = const AuthState(loading: false);
  }
}
