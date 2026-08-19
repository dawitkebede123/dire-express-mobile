import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../models/directory.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/person_avatar.dart';
import '../../theme/app_theme.dart';

class BrokerCustomersScreen extends ConsumerStatefulWidget {
  const BrokerCustomersScreen({super.key});

  @override
  ConsumerState<BrokerCustomersScreen> createState() => _BrokerCustomersScreenState();
}

class _BrokerCustomersScreenState extends ConsumerState<BrokerCustomersScreen> {
  List<CustomerProfile> _customers = [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final customers = await ref.read(apiClientProvider).listCustomers();
      if (mounted) setState(() {
        _customers = customers;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(
        title: l10n.brokerCustomersTitle,
        notificationsPath: '/broker/notifications',
        profilePath: '/broker/profile',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _customers.isEmpty
                  ? ListView(children: [Padding(padding: const EdgeInsets.all(48), child: Text(l10n.brokerCustomersEmpty, textAlign: TextAlign.center))])
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _customers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final c = _customers[i];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              PersonAvatar(
                                imageUrl: c.user.imageUrl,
                                name: c.user.name,
                                fallbackIcon: Icons.apartment,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.company ?? c.user.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                    Text(c.user.email ?? '', style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
                                    if (c.user.phone != null) Text(c.user.phone!, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
                                    Text(l10n.brokerCustomersLoads(c.loadCount), style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                              if (c.user.phone != null && c.user.phone!.isNotEmpty)
                                IconButton(
                                  onPressed: () => launchUrl(Uri.parse('tel:${c.user.phone}')),
                                  icon: const Icon(Icons.phone, color: AppColors.secondary),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
