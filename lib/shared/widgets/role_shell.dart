import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class RoleShell extends StatelessWidget {
  const RoleShell({
    super.key,
    required this.child,
    required this.items,
    required this.locations,
  });

  final Widget child;
  final List<ShellNavItem> items;
  final List<String> locations;

  int _selectedIndex(String path) {
    var best = 0;
    var bestLen = -1;
    for (var i = 0; i < locations.length; i++) {
      final loc = locations[i];
      final matches = path == loc || path.startsWith('$loc/');
      if (matches && loc.length > bestLen) {
        best = i;
        bestLen = loc.length;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final selected = _selectedIndex(path);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (index) => context.go(locations[index]),
        destinations: [
          for (final item in items)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon ?? item.icon),
              label: item.label(AppLocalizations.of(context)),
            ),
        ],
        height: 72,
        backgroundColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.96),
      ),
    );
  }
}

class ShellNavItem {
  const ShellNavItem({
    required this.icon,
    required this.label,
    this.selectedIcon,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String Function(AppLocalizations) label;
}
