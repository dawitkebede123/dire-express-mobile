import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/logo.dart';
import 'auth_controller.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authControllerProvider, (prev, next) {
      if (next.loading) return;
      if (next.user != null) {
        context.go(next.user!.homePath);
      } else {
        context.go('/welcome');
      }
    });

    return const Scaffold(
      body: Center(child: Logo(size: 48)),
    );
  }
}
