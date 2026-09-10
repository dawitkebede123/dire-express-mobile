import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'logo.dart';
import 'person_avatar.dart';

class AppHeader extends ConsumerWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.showBack = false,
    this.onBack,
    this.notificationsPath,
    this.profilePath,
    this.action,
  });

  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final String? notificationsPath;
  final String? profilePath;
  final Widget? action;

  /// Role shell tab roots — must use [GoRouter.go], never [GoRouter.push].
  static const _shellTabPaths = {
    '/broker',
    '/broker/loads',
    '/broker/drivers',
    '/broker/customers',
    '/broker/profile',
    '/driver',
    '/driver/active',
    '/driver/history',
    '/driver/profile',
    '/customer',
    '/customer/request',
    '/customer/history',
    '/customer/profile',
  };

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider).user;
    return Material(
      color: AppColors.background.withValues(alpha: 0.92),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              if (showBack)
                IconButton(
                  tooltip: l10n.headerGoBack,
                  onPressed: onBack ??
                      () {
                        if (context.canPop()) {
                          context.pop();
                        }
                      },
                  icon: const Icon(Icons.arrow_back),
                )
              else
                const LogoMark(size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              if (action != null) action!,
              if (notificationsPath != null)
                IconButton(
                  tooltip: l10n.headerNotifications,
                  onPressed: () => context.push(notificationsPath!),
                  icon: const Icon(Icons.notifications_none),
                ),
              if (profilePath != null)
                IconButton(
                  tooltip: l10n.headerProfile,
                  onPressed: () {
                    final path = profilePath!;
                    // Shell tabs: go switches branch. Visit/detail routes: push stacks.
                    if (_shellTabPaths.contains(path)) {
                      context.go(path);
                    } else {
                      context.push(path);
                    }
                  },
                  icon: PersonAvatar(
                    imageUrl: user?.imageUrl,
                    name: user?.name,
                    radius: 14,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
