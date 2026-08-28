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

class BrokerLoadsScreen extends ConsumerStatefulWidget {
  const BrokerLoadsScreen({super.key});

  @override
  ConsumerState<BrokerLoadsScreen> createState() => _BrokerLoadsScreenState();
}

class _BrokerLoadsScreenState extends ConsumerState<BrokerLoadsScreen> {
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
    return Scaffold(
      appBar: AppHeader(
        title: l10n.brokerLoadsTitle,
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
              child: _loads.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(48),
                          child: Text(
                            l10n.brokerLoadsEmpty,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.onSurfaceVariant),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _loads.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => LoadRowCard(load: _loads[i], href: '/broker/loads/${_loads[i].id}'),
                    ),
            ),
    );
  }
}
