import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../models/directory.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/driver_vehicle_row.dart';
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
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DriverVehicleRow(
                            driver: d,
                            l10n: l10n,
                            trailing: d.user.phone != null && d.user.phone!.isNotEmpty
                                ? IconButton(
                                    onPressed: () => launchUrl(Uri.parse('tel:${d.user.phone}')),
                                    icon: const Icon(Icons.phone, color: AppColors.secondary),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
