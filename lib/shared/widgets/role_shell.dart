import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import 'telebirr_bottom_nav.dart';

class RoleShell extends StatelessWidget {
  const RoleShell({
    super.key,
    required this.navigationShell,
    required this.items,
  });

  final StatefulNavigationShell navigationShell;
  final List<ShellNavItem> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: TelebirrBottomNav(
        icons: [for (final item in items) item.icon],
        labels: [
          for (final item in items) item.label(AppLocalizations.of(context)),
        ],
        selectedIndex: navigationShell.currentIndex,
        onSelected: (index) {
          if (index == navigationShell.currentIndex) return;
          navigationShell.goBranch(index);
        },
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
