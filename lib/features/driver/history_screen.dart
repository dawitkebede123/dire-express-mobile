import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../models/load.dart';
import '../../shared/format.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/load_card.dart';
import '../../theme/app_theme.dart';

class DriverHistoryScreen extends ConsumerStatefulWidget {
  const DriverHistoryScreen({super.key});

  @override
  ConsumerState<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends ConsumerState<DriverHistoryScreen> {
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
        _loads = loads.where((l) => const {'DELIVERED', 'REJECTED', 'CANCELLED'}.contains(l.status)).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final earned = _loads.where((l) => l.status == 'DELIVERED').fold<double>(0, (s, l) => s + (l.rate ?? 0));

    return Scaffold(
      appBar: AppHeader(
        title: l10n.driverHistoryTitle,
        notificationsPath: '/driver/notifications',
        profilePath: '/driver/profile',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetch,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l10n.driverTotalEarned.toUpperCase(), style: const TextStyle(color: Colors.white70, letterSpacing: 1, fontSize: 12)),
                      Text(formatCurrency(earned, locale), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  if (_loads.isEmpty)
                    Padding(padding: const EdgeInsets.only(top: 48), child: Text(l10n.driverHistoryEmpty, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.onSurfaceVariant)))
                  else
                    ..._loads.map((l) => Padding(padding: const EdgeInsets.only(bottom: 10), child: LoadRowCard(load: l, href: '/driver/loads/${l.id}'))),
                ],
              ),
            ),
    );
  }
}
