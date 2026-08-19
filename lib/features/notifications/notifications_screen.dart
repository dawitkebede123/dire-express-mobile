import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/locale_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/directory.dart';
import '../../shared/format.dart';
import '../../shared/widgets/app_header.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_controller.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<AppNotification> _items = [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await ref.read(apiClientProvider).listNotifications();
      if (mounted) setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _detailPath(AppNotification n) {
    final role = ref.read(authControllerProvider).user?.role;
    if (n.loadId == null) return '';
    switch (role) {
      case 'BROKER':
        return '/broker/loads/${n.loadId}';
      case 'DRIVER':
        return '/driver/loads/${n.loadId}';
      case 'CUSTOMER':
        return '/customer/track/${n.loadId}';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(localeControllerProvider, (_, __) {
      _load();
    });
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final unread = _items.where((n) => !n.read).length;

    return Scaffold(
      appBar: AppHeader(
        title: l10n.notificationsTitle,
        showBack: true,
        action: unread == 0
            ? null
            : TextButton(
                onPressed: () async {
                  await ref.read(apiClientProvider).markNotifications(readAll: true);
                  _load();
                },
                child: Text(l10n.commonMarkAllRead),
              ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text(l10n.commonNoNotifications))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final n = _items[i];
                      return InkWell(
                        onTap: () async {
                          if (!n.read) {
                            await ref.read(apiClientProvider).markNotifications(id: n.id);
                          }
                          final path = _detailPath(n);
                          if (path.isNotEmpty && context.mounted) context.push(path);
                          _load();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Ink(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: n.read ? AppColors.surfaceContainerLowest : AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                n.read ? Icons.notifications_none : Icons.notifications_active,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                                    Text(n.body, style: const TextStyle(color: AppColors.onSurfaceVariant)),
                                    const SizedBox(height: 4),
                                    Text(
                                      formatDateTime(n.createdAt, locale),
                                      style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
