import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../models/load.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/load_card.dart';
import '../../theme/app_theme.dart';

class CustomerHistoryScreen extends ConsumerStatefulWidget {
  const CustomerHistoryScreen({super.key});

  @override
  ConsumerState<CustomerHistoryScreen> createState() => _CustomerHistoryScreenState();
}

class _CustomerHistoryScreenState extends ConsumerState<CustomerHistoryScreen> {
  List<FreightLoad> _loads = [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final loads = await ref.read(apiClientProvider).listLoads();
      if (mounted) setState(() {
        _loads = loads.where((l) => l.status == 'DELIVERED' || l.status == 'CANCELLED').toList();
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
        title: l10n.customerHistoryTitle,
        notificationsPath: '/customer/notifications',
        profilePath: '/customer/profile',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetch,
              child: _loads.isEmpty
                  ? ListView(children: [Padding(padding: const EdgeInsets.all(48), child: Text(l10n.customerHistoryEmpty, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.onSurfaceVariant)))])
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _loads.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => LoadRowCard(load: _loads[i], href: '/customer/track/${_loads[i].id}'),
                    ),
            ),
    );
  }
}
