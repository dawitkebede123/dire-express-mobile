import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../models/load.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/load_card.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_controller.dart';
import '../notifications/pusher_service.dart';
import 'gps_service.dart';

class DriverBoardScreen extends ConsumerStatefulWidget {
  const DriverBoardScreen({super.key});

  @override
  ConsumerState<DriverBoardScreen> createState() => _DriverBoardScreenState();
}

class _DriverBoardScreenState extends ConsumerState<DriverBoardScreen> {
  var _tab = 0;
  List<FreightLoad> _loads = [];
  var _loading = true;
  String? _busyId;
  String? _userId;
  late final PusherHandler _handler;

  @override
  void initState() {
    super.initState();
    _handler = (_, data) {
      final l10n = AppLocalizations.of(context);
      final title = _notificationToastTitle(data, l10n);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(title)));
      }
      _fetch();
    };
    _fetch();
    _userId = ref.read(authControllerProvider).user?.id;
    if (_userId != null) {
      pusherService.subscribe('user-$_userId', 'notification', _handler);
    }
  }

  @override
  void dispose() {
    if (_userId != null) {
      pusherService.unsubscribe('user-$_userId', 'notification', _handler);
    }
    super.dispose();
  }

  Future<void> _fetch() async {
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

  Future<void> _respond(String id, String action) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busyId = id);
    try {
      final updated = await ref.read(apiClientProvider).respond(id, action);
      if (!mounted) return;
      setState(() {
        final i = _loads.indexWhere((l) => l.id == id);
        if (i >= 0) {
          _loads = [..._loads]..[i] = updated;
        } else {
          _loads = [..._loads, updated];
        }
        if (action == 'accept') _tab = 1;
        _busyId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(action == 'accept' ? l10n.toastLoadAccepted : l10n.toastLoadRejected)),
      );
      ref.read(loadsRefreshProvider.notifier).state++;
      if (action == 'accept') {
        final gpsError = await ref.read(driverLocationControllerProvider.notifier).beginTrip(updated.id, load: updated);
        if (!mounted) return;
        if (gpsError == 'denied') {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.driverGpsDenied)));
        } else if (gpsError == 'unavailable') {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.driverGpsUnavailable)));
        }
      }
      await _fetch();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastActionFailed)));
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(loadsRefreshProvider, (_, _) {
      _fetch();
    });
    final l10n = AppLocalizations.of(context);
    final available = _loads.where((l) => l.status == 'ASSIGNED').toList();
    final trips = _loads.where((l) => l.status != 'ASSIGNED').toList();
    final visible = _tab == 0 ? available : trips;

    return Scaffold(
      appBar: AppHeader(
        title: _tab == 0 ? l10n.driverAvailableTitle : l10n.driverMyTrips,
        notificationsPath: '/driver/notifications',
        profilePath: '/driver/profile',
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(999)),
              child: Row(
                children: [
                  _TabBtn(label: l10n.driverAvailableCount(available.length), selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
                  _TabBtn(label: l10n.driverMyTrips, selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetch,
                    child: visible.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 80),
                              Text(_tab == 0 ? l10n.driverEmptyAvailable : l10n.driverEmptyTrips, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Text(_tab == 0 ? l10n.driverEmptyAvailableHint : l10n.driverEmptyTripsHint, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.onSurfaceVariant)),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: visible.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final load = visible[i];
                              return LoadBoardCard(
                                load: load,
                                detailsHref: '/driver/loads/${load.id}',
                                action: load.status == 'ASSIGNED'
                                    ? FilledButton(
                                        onPressed: _busyId == load.id ? null : () => _respond(load.id, 'accept'),
                                        child: Text(l10n.driverAcceptLoad),
                                      )
                                    : null,
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  const _TabBtn({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.onSurfaceVariant)),
        ),
      ),
    );
  }
}

String _notificationToastTitle(Map<String, dynamic> data, AppLocalizations l10n) {
  final type = (data['type'] as String? ?? '').toUpperCase().replaceAll('-', '_');
  return switch (type) {
    'LOAD_ASSIGNED' || 'ASSIGNED' || 'ASSIGNMENT' => l10n.statusAssigned,
    'LOAD_ACCEPTED' || 'ACCEPTED' => l10n.statusAccepted,
    'LOAD_REJECTED' || 'REJECTED' => l10n.statusRejected,
    'TRIP_STARTED' || 'IN_TRANSIT' || 'STATUS_UPDATE' => l10n.statusInTransit,
    'POD' || 'DELIVERED' || 'PROOF_OF_DELIVERY' => l10n.statusDelivered,
    'TRANSPORT_REQUEST' || 'LOAD_CREATED' => l10n.toastNewLoadUpdate,
    _ => (data['title'] as String?)?.isNotEmpty == true
        ? data['title'] as String
        : l10n.toastNewLoadUpdate,
  };
}
