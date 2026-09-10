import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import 'broker_loads_auto_refresh.dart';
import '../../l10n/app_localizations.dart';
import '../../models/load.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/load_card.dart';
import '../../theme/app_theme.dart';

class BrokerDashboardScreen extends ConsumerStatefulWidget {
  const BrokerDashboardScreen({super.key});

  @override
  ConsumerState<BrokerDashboardScreen> createState() => _BrokerDashboardScreenState();
}

class _BrokerDashboardScreenState extends ConsumerState<BrokerDashboardScreen> {
  List<FreightLoad> _loads = [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final loads = await ref.read(apiClientProvider).listLoads();
      if (mounted) setState(() {
        _loads = loads;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(brokerLoadsAutoRefreshProvider);
    ref.listen(loadsRefreshProvider, (_, __) {
      _load();
    });
    final l10n = AppLocalizations.of(context);
    final delivered = _loads.where((l) => l.status == 'DELIVERED').length;
    final active = _loads.where((l) => l.isActive).length;
    final pendingDrivers = _loads.where((l) => l.status == 'ASSIGNED').length;
    final recent = _loads.take(5).toList();

    return Scaffold(
      appBar: AppHeader(
        title: l10n.brokerDashboardTitle,
        notificationsPath: '/broker/notifications',
        profilePath: '/broker/profile',
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/broker/loads/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.brokerCreateLoad),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.brokerTotalLoads.toUpperCase(), style: const TextStyle(color: Colors.white70, letterSpacing: 1, fontSize: 12)),
                        const SizedBox(height: 6),
                        Text('${_loads.length}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
                        Text(l10n.brokerLoadsDelivered(delivered), style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _StatCard(icon: Icons.local_shipping, label: l10n.brokerActiveLoads, value: '$active', tint: AppColors.secondary)),
                      const SizedBox(width: 8),
                      Expanded(child: _StatCard(icon: Icons.person_outline, label: l10n.brokerPendingDrivers, value: '$pendingDrivers', tint: AppColors.error)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(l10n.brokerRecentLoads, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.go('/broker/loads'),
                        child: Text(l10n.brokerViewAll),
                      ),
                    ],
                  ),
                  if (recent.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(l10n.brokerEmptyLoads, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.onSurfaceVariant)),
                    )
                  else
                    ...recent.map((l) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: LoadRowCard(load: l, href: '/broker/loads/${l.id}'),
                        )),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value, required this.tint});

  final IconData icon;
  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: tint, foregroundColor: Colors.white, child: Icon(icon, size: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
