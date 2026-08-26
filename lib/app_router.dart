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

const _brokerLocations = ['/broker', '/broker/loads', '/broker/drivers', '/broker/customers', '/broker/profile'];
const _driverLocations = ['/driver', '/driver/active', '/driver/history', '/driver/profile'];
const _customerLocations = ['/customer', '/customer/request', '/customer/history', '/customer/profile'];

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

Widget _brokerShell(Widget child) => RoleShell(items: _brokerNavItems(), locations: _brokerLocations, child: child);

Widget _driverShell(Widget child) => RoleShell(items: _driverNavItems(), locations: _driverLocations, child: child);

Widget _customerShell(Widget child) => RoleShell(items: _customerNavItems(), locations: _customerLocations, child: child);

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
      GoRoute(path: '/broker', builder: (_, __) => _brokerShell(const BrokerDashboardScreen())),
      GoRoute(path: '/broker/loads', builder: (_, __) => _brokerShell(const BrokerLoadsScreen())),
      GoRoute(path: '/broker/drivers', builder: (_, __) => _brokerShell(const BrokerDriversScreen())),
      GoRoute(path: '/broker/customers', builder: (_, __) => _brokerShell(const BrokerCustomersScreen())),
      GoRoute(path: '/broker/profile', builder: (_, __) => _brokerShell(const ProfileScreen(backPath: '/broker'))),
      GoRoute(path: '/driver', builder: (_, __) => _driverShell(const DriverBoardScreen())),
      GoRoute(path: '/driver/active', builder: (_, __) => _driverShell(const DriverActiveScreen())),
      GoRoute(path: '/driver/history', builder: (_, __) => _driverShell(const DriverHistoryScreen())),
      GoRoute(path: '/driver/profile', builder: (_, __) => _driverShell(const ProfileScreen(backPath: '/driver'))),
      GoRoute(path: '/customer', builder: (_, __) => _customerShell(const CustomerTrackListScreen())),
      GoRoute(path: '/customer/request', builder: (_, __) => _customerShell(const CreateLoadScreen(asCustomer: true))),
      GoRoute(path: '/customer/history', builder: (_, __) => _customerShell(const CustomerHistoryScreen())),
      GoRoute(path: '/customer/profile', builder: (_, __) => _customerShell(const ProfileScreen(backPath: '/customer'))),
    ],
  );
});
