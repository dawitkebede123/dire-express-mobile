import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../models/directory.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/person_avatar.dart';
import '../../theme/app_theme.dart';

class BrokerDriversScreen extends ConsumerStatefulWidget {
  const BrokerDriversScreen({super.key});

  @override
  ConsumerState<BrokerDriversScreen> createState() => _BrokerDriversScreenState();
}

class _BrokerDriversScreenState extends ConsumerState<BrokerDriversScreen> {
  List<DriverProfile> _drivers = [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final drivers = await ref.read(apiClientProvider).listDrivers(all: true);
      if (mounted) setState(() {
        _drivers = drivers;
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
        title: l10n.brokerDriversTitle,
        notificationsPath: '/broker/notifications',
        profilePath: '/broker/profile',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _drivers.isEmpty
                  ? ListView(children: [Padding(padding: const EdgeInsets.all(48), child: Text(l10n.brokerDriversEmpty, textAlign: TextAlign.center))])
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _drivers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final d = _drivers[i];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              PersonAvatar(
                                imageUrl: d.user.imageUrl,
                                name: d.user.name,
                                fallbackIcon: Icons.local_shipping,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(child: Text(d.user.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                                        const SizedBox(width: 8),
                                        _Badge(d.isAvailable ? l10n.brokerDriversAvailable : l10n.brokerDriversOnALoad, success: d.isAvailable),
                                      ],
                                    ),
                                    Text(
                                      '${d.vehicleType ?? l10n.brokerVehicleNotSet}${d.plateNo != null ? ' • ${d.plateNo}' : ''}',
                                      style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
                                    ),
                                    Text(l10n.brokerLoadsAssigned(d.loadCount), style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                              if (d.user.phone != null && d.user.phone!.isNotEmpty)
                                IconButton(
                                  onPressed: () => launchUrl(Uri.parse('tel:${d.user.phone}')),
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

class _Badge extends StatelessWidget {
  const _Badge(this.label, {required this.success});
  final String label;
  final bool success;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: success ? AppColors.successContainer : AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: success ? AppColors.success : AppColors.onSurfaceVariant),
      ),
    );
  }
}
