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

List<ShellNavItem> _brokerNavItems() => [
      ShellNavItem(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: (l) => l.navDashboard),
      ShellNavItem(icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2, label: (l) => l.navLoads),
      ShellNavItem(icon: Icons.local_shipping_outlined, selectedIcon: Icons.local_shipping, label: (l) => l.navDrivers),
      ShellNavItem(icon: Icons.group_outlined, selectedIcon: Icons.group, label: (l) => l.navCustomers),
      ShellNavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: (l) => l.navProfile),
    ];

List<ShellNavItem> _driverNavItems() => [
      ShellNavItem(icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2, label: (l) => l.navLoads),
      ShellNavItem(icon: Icons.local_shipping_outlined, selectedIcon: Icons.local_shipping, label: (l) => l.navActive),
      ShellNavItem(icon: Icons.history, label: (l) => l.navHistory),
      ShellNavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: (l) => l.navProfile),
    ];

List<ShellNavItem> _customerNavItems() => [
      ShellNavItem(icon: Icons.pin_drop_outlined, selectedIcon: Icons.pin_drop, label: (l) => l.navTrack),
      ShellNavItem(icon: Icons.add_box_outlined, selectedIcon: Icons.add_box, label: (l) => l.navRequest),
      ShellNavItem(icon: Icons.history, label: (l) => l.navHistory),
      ShellNavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: (l) => l.navProfile),
    ];

Page<void> _noTransitionPage(GoRouterState state, Widget child) {
  return NoTransitionPage<void>(key: state.pageKey, child: child);
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.onDispose(refresh.dispose);
  ref.listen(authControllerProvider, (prev, next) {
    if (prev?.loading == next.loading &&
        prev?.user?.id == next.user?.id &&
        prev?.user?.role == next.user?.role) {
      return;
    }
    refresh.value++;
  });

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;
      const public = {'/', '/welcome', '/login', '/register'};
      final isPublic = public.contains(loc);

      if (auth.loading) return loc == '/' ? null : '/';
      if (!auth.isAuthenticated) {
        return (isPublic && loc != '/') ? null : '/welcome';
      }
      final home = auth.user!.homePath;
      if (isPublic && loc != home) return home;

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
        path: '/broker/profile/visit',
        builder: (_, __) => const ProfileScreen(backPath: '/broker'),
      ),
      GoRoute(
        path: '/customer/profile/visit',
        builder: (_, __) => const ProfileScreen(backPath: '/customer'),
      ),
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
          items: _brokerNavItems(),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/broker',
                pageBuilder: (context, state) => _noTransitionPage(state, const BrokerDashboardScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/broker/loads',
                pageBuilder: (context, state) => _noTransitionPage(state, const BrokerLoadsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/broker/drivers',
                pageBuilder: (context, state) => _noTransitionPage(state, const BrokerDriversScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/broker/customers',
                pageBuilder: (context, state) => _noTransitionPage(state, const BrokerCustomersScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/broker/profile',
                pageBuilder: (context, state) => _noTransitionPage(state, const ProfileScreen(backPath: '/broker')),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => RoleShell(
          navigationShell: navigationShell,
          items: _driverNavItems(),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/driver',
                pageBuilder: (context, state) => _noTransitionPage(state, const DriverBoardScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/driver/active',
                pageBuilder: (context, state) => _noTransitionPage(state, const DriverActiveScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/driver/history',
                pageBuilder: (context, state) => _noTransitionPage(state, const DriverHistoryScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/driver/profile',
                pageBuilder: (context, state) => _noTransitionPage(state, const ProfileScreen(backPath: '/driver')),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => RoleShell(
          navigationShell: navigationShell,
          items: _customerNavItems(),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer',
                pageBuilder: (context, state) => _noTransitionPage(state, const CustomerTrackListScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/request',
                pageBuilder: (context, state) => _noTransitionPage(state, const CreateLoadScreen(asCustomer: true)),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/history',
                pageBuilder: (context, state) => _noTransitionPage(state, const CustomerHistoryScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/profile',
                pageBuilder: (context, state) => _noTransitionPage(state, const ProfileScreen(backPath: '/customer')),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
