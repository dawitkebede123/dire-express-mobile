import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../core/config.dart';

typedef PusherHandler = void Function(String event, Map<String, dynamic> data);

class PusherService {
  PusherChannelsFlutter? _pusher;
  final _handlers = <String, Set<PusherHandler>>{};
  var _ready = false;

  Future<void> init() async {
    if (!AppConfig.hasPusher || _ready) return;
    try {
      final pusher = PusherChannelsFlutter.getInstance();
      await pusher.init(
        apiKey: AppConfig.pusherKey,
        cluster: AppConfig.pusherCluster,
        onEvent: (event) {
          final name = event.eventName;
          final channel = event.channelName;
          Map<String, dynamic> data = {};
          try {
            final raw = event.data;
            if (raw is String && raw.isNotEmpty) {
              data = jsonDecode(raw) as Map<String, dynamic>;
            } else if (raw is Map) {
              data = Map<String, dynamic>.from(raw);
            }
          } catch (_) {}
          final key = '$channel::$name';
          for (final handler in _handlers[key] ?? const <PusherHandler>{}) {
            handler(name, data);
          }
        },
      );
      await pusher.connect();
      _pusher = pusher;
      _ready = true;
    } catch (e) {
      debugPrint('Pusher init failed: $e');
    }
  }

  Future<void> subscribe(String channel, String event, PusherHandler handler) async {
    await init();
    if (!_ready || _pusher == null) return;
    final key = '$channel::$event';
    _handlers.putIfAbsent(key, () => <PusherHandler>{}).add(handler);
    try {
      await _pusher!.subscribe(channelName: channel);
    } catch (e) {
      debugPrint('Pusher subscribe failed: $e');
    }
  }

  Future<void> unsubscribe(String channel, String event, PusherHandler handler) async {
    final key = '$channel::$event';
    _handlers[key]?.remove(handler);
    if ((_handlers[key]?.isEmpty ?? true) && _pusher != null) {
      try {
        await _pusher!.unsubscribe(channelName: channel);
      } catch (_) {}
    }
  }
}

final pusherService = PusherService();
