import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../models/user.dart';

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
      final user = await _api.me();
      await _refreshRuntimeConfig();
      state = AuthState(user: user, loading: false);
    } catch (_) {
      await ref.read(authStorageProvider).clear();
      state = const AuthState(loading: false);
    }
  }

  Future<AppUser> login(String email, String password) async {
    final result = await _api.login(email, password);
    await _refreshRuntimeConfig();
    var user = result.user;
    if (user.isBroker && (user.agentId == null || user.agentId!.isEmpty)) {
      try {
        user = await _api.me();
      } catch (_) {}
    }
    state = AuthState(user: user, loading: false);
    return user;
  }

  Future<void> _refreshRuntimeConfig() async {
    try {
      await _api.fetchRuntimeConfig();
    } catch (_) {}
  }

  Future<AppUser> register(Map<String, dynamic> body) async {
    await _api.register(body);
    return login(body['email'] as String, body['password'] as String);
  }

  void applyUser(AppUser user) {
    state = AuthState(user: user, loading: false);
  }

  Future<void> signOut() async {
    await ref.read(authStorageProvider).clear();
    state = const AuthState(loading: false);
  }
}
