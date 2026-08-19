import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/splash_screen.dart';
import 'features/auth/welcome_screen.dart';
import 'features/broker/create_load_screen.dart';
import 'features/broker/customers_screen.dart';
import 'features/broker/dashboard_screen.dart';
import 'features/broker/drivers_screen.dart';
import 'features/broker/load_detail_screen.dart';
import 'features/broker/loads_screen.dart';
import 'features/customer/history_screen.dart';
import 'features/customer/track_detail_screen.dart';
import 'features/customer/track_list_screen.dart';
import 'features/driver/active_screen.dart';
import 'features/driver/board_screen.dart';
import 'features/driver/history_screen.dart';
import 'features/driver/load_detail_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/profile/profile_screen.dart';
import 'shared/widgets/role_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.onDispose(refresh.dispose);
  ref.listen(authControllerProvider, (_, __) => refresh.value++);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;
      const public = {'/', '/welcome', '/login', '/register'};
      final isPublic = public.contains(loc);

      if (auth.loading) return loc == '/' ? null : '/';
      if (!auth.isAuthenticated && !isPublic) return '/welcome';
      if (auth.isAuthenticated && isPublic) return auth.user!.homePath;

      final user = auth.user;
      if (user != null) {
        if (loc.startsWith('/broker') && !user.isBroker) return user.homePath;
        if (loc.startsWith('/driver') && !user.isDriver) return user.homePath;
        if (loc.startsWith('/customer') && !user.isCustomer) return user.homePath;
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/broker/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/driver/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/customer/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(
        path: '/broker/loads/new',
        builder: (_, __) => const CreateLoadScreen(),
      ),
      GoRoute(
        path: '/broker/loads/:id',
        builder: (_, state) => BrokerLoadDetailScreen(loadId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/driver/loads/:id',
        builder: (_, state) => DriverLoadDetailScreen(loadId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/customer/track/:id',
        builder: (_, state) => CustomerTrackDetailScreen(loadId: state.pathParameters['id']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => RoleShell(
          navigationShell: navigationShell,
          items: [
            ShellNavItem(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: (l) => l.navDashboard),
            ShellNavItem(icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2, label: (l) => l.navLoads),
            ShellNavItem(icon: Icons.local_shipping_outlined, selectedIcon: Icons.local_shipping, label: (l) => l.navDrivers),
            ShellNavItem(icon: Icons.group_outlined, selectedIcon: Icons.group, label: (l) => l.navCustomers),
            ShellNavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: (l) => l.navProfile),
          ],
        ),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/broker', builder: (_, __) => const BrokerDashboardScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/broker/loads', builder: (_, __) => const BrokerLoadsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/broker/drivers', builder: (_, __) => const BrokerDriversScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/broker/customers', builder: (_, __) => const BrokerCustomersScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/broker/profile', builder: (_, __) => const ProfileScreen(backPath: '/broker'))]),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => RoleShell(
          navigationShell: navigationShell,
          items: [
            ShellNavItem(icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2, label: (l) => l.navLoads),
            ShellNavItem(icon: Icons.local_shipping_outlined, selectedIcon: Icons.local_shipping, label: (l) => l.navActive),
            ShellNavItem(icon: Icons.history, label: (l) => l.navHistory),
            ShellNavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: (l) => l.navProfile),
          ],
        ),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/driver', builder: (_, __) => const DriverBoardScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/driver/active', builder: (_, __) => const DriverActiveScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/driver/history', builder: (_, __) => const DriverHistoryScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/driver/profile', builder: (_, __) => const ProfileScreen(backPath: '/driver'))]),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => RoleShell(
          navigationShell: navigationShell,
          items: [
            ShellNavItem(icon: Icons.pin_drop_outlined, selectedIcon: Icons.pin_drop, label: (l) => l.navTrack),
            ShellNavItem(icon: Icons.history, label: (l) => l.navHistory),
            ShellNavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: (l) => l.navProfile),
          ],
        ),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/customer', builder: (_, __) => const CustomerTrackListScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/customer/history', builder: (_, __) => const CustomerHistoryScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/customer/profile', builder: (_, __) => const ProfileScreen(backPath: '/customer'))]),
        ],
      ),
    ],
  );
});
