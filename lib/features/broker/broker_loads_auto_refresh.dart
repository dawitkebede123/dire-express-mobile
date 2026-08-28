import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../auth/auth_controller.dart';
import '../notifications/pusher_service.dart';

/// Keeps broker dashboard and loads list in sync via Pusher + polling.
/// Watch from broker list screens while they are mounted.
final brokerLoadsAutoRefreshProvider = Provider<void>((ref) {
  final user = ref.watch(authControllerProvider.select((a) => a.user));
  if (user == null || !user.isBroker) return;

  final userId = user.id;
  void bump() => ref.read(loadsRefreshProvider.notifier).state++;

  void handler(String event, Map<String, dynamic> data) => bump();

  unawaited(pusherService.subscribe('user-$userId', 'notification', handler));

  final timer = Timer.periodic(const Duration(seconds: 30), (_) => bump());

  ref.onDispose(() {
    timer.cancel();
    unawaited(pusherService.unsubscribe('user-$userId', 'notification', handler));
  });
});
