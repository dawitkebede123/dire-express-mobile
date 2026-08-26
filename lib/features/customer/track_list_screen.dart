import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../models/load.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/load_card.dart';
import '../../theme/app_theme.dart';

class CustomerTrackListScreen extends ConsumerStatefulWidget {
  const CustomerTrackListScreen({super.key});

  @override
  ConsumerState<CustomerTrackListScreen> createState() => _CustomerTrackListScreenState();
}

class _CustomerTrackListScreenState extends ConsumerState<CustomerTrackListScreen> {
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
        _loads = loads.where((l) => l.status != 'DELIVERED' && l.status != 'CANCELLED').toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(loadsRefreshProvider, (_, _) {
      _fetch();
    });
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(
        title: l10n.customerTrackTitle,
        notificationsPath: '/customer/notifications',
        profilePath: '/customer/profile',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetch,
              child: _loads.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 80),
                        Text(l10n.customerTrackEmpty, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(l10n.customerTrackEmptyHint, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.onSurfaceVariant)),
                      ],
                    )
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
