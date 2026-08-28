import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:signature/signature.dart';

import '../../core/api_client.dart';
import '../../core/driver_position_cache.dart';
import '../../l10n/app_localizations.dart';
import '../../models/load.dart';
import '../../shared/format.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/pod_documents.dart';
import '../../shared/widgets/status_chip.dart';
import '../../theme/app_theme.dart';
import '../maps/trip_map.dart';
import '../notifications/pusher_service.dart';
import 'gps_service.dart';

class DriverLoadDetailScreen extends ConsumerStatefulWidget {
  const DriverLoadDetailScreen({super.key, required this.loadId});

  final String loadId;

  @override
  ConsumerState<DriverLoadDetailScreen> createState() => _DriverLoadDetailScreenState();
}

class _DriverLoadDetailScreenState extends ConsumerState<DriverLoadDetailScreen> {
  FreightLoad? _load;
  LatLng? _driverPoint;
  var _busy = false;
  var _submitted = false;
  Timer? _driverPointTimer;
  XFile? _photo;
  String? _photoUrl;
  String? _signatureUrl;
  final _recipient = TextEditingController();
  final _notes = TextEditingController();
  final _signature = SignatureController(penStrokeWidth: 2.5, penColor: Colors.black);
  final _gps = GpsService();
  late final PusherHandler _handler;

  @override
  void initState() {
    super.initState();
    _handler = (_, data) {
      if (data['load'] is Map<String, dynamic>) {
        final load = FreightLoad.fromJson(data['load'] as Map<String, dynamic>);
        setState(() => _load = load);
        unawaited(DriverPositionCache.instance.saveFromLoad(load));
      }
      final loc = data['location'];
      if (loc is Map && loc['lat'] != null && loc['lng'] != null) {
        setState(() => _driverPoint = LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble()));
        unawaited(DriverPositionCache.instance.saveFromEvent(widget.loadId, loc));
      }
    };
    unawaited(_hydrateCache());
    _fetch();
    pusherService.subscribe('load-${widget.loadId}', 'status-update', _handler);
    pusherService.subscribe('load-${widget.loadId}', 'location-update', _handler);
  }

  @override
  void dispose() {
    _driverPointTimer?.cancel();
    pusherService.unsubscribe('load-${widget.loadId}', 'status-update', _handler);
    pusherService.unsubscribe('load-${widget.loadId}', 'location-update', _handler);
    _recipient.dispose();
    _notes.dispose();
    _signature.dispose();
    super.dispose();
  }

  Future<void> _hydrateCache() async {
    final pos = await DriverPositionCache.instance.readForLoad(widget.loadId);
    if (!mounted || pos == null) return;
    setState(() => _driverPoint = pos.latLng);
  }

  Future<void> _fetch() async {
    try {
      final load = await ref.read(apiClientProvider).getLoad(widget.loadId);
      if (!mounted) return;
      setState(() {
        _load = load;
        if (load.latestLocation != null) {
          _driverPoint = LatLng(load.latestLocation!.lat, load.latestLocation!.lng);
        }
      });
      unawaited(DriverPositionCache.instance.saveFromLoad(load));
      try {
        final loc = await ref.read(apiClientProvider).getLocation(loadId: widget.loadId);
        if (!mounted || loc == null) return;
        setState(() => _driverPoint = LatLng(loc.lat, loc.lng));
      } catch (_) {}
      if (load.status == 'IN_TRANSIT') {
        unawaited(_refreshDriverPoint());
        _startDriverPointTimer();
      }
    } catch (_) {}
  }

  Future<void> _refreshDriverPoint() async {
    final pos = await DriverPositionCache.instance.readForLoad(widget.loadId) ??
        await DriverPositionCache.instance.readDevice();
    if (!mounted || pos == null) return;
    setState(() => _driverPoint = pos.latLng);
  }

  void _startDriverPointTimer() {
    _driverPointTimer?.cancel();
    _driverPointTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      unawaited(_refreshDriverPoint());
    });
  }

  void _stopDriverPointTimer() {
    _driverPointTimer?.cancel();
    _driverPointTimer = null;
  }

  Future<void> _respond(String action) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final updated = await ref.read(apiClientProvider).respond(widget.loadId, action);
      if (!mounted) return;
      setState(() => _load = updated);
      final msg = switch (action) {
        'accept' => l10n.toastLoadAccepted,
        'reject' => l10n.toastLoadRejected,
        'start' => l10n.toastTripStarted,
        _ => l10n.toastActionFailed,
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      if (action == 'start') {
        await ref.read(driverLocationControllerProvider.notifier).beginTrip(widget.loadId, load: updated);
        await _refreshDriverPoint();
        _startDriverPointTimer();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastActionFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickPhoto() async {
    final l10n = AppLocalizations.of(context);
    final file = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80);
    if (file == null) return;
    setState(() => _busy = true);
    try {
      final url = await ref.read(apiClientProvider).uploadFile(file.path, kind: 'pod');
      if (!mounted) return;
      setState(() {
        _photo = file;
        _photoUrl = url;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastPhotoUploaded)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastUploadFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<String> _uploadSignature() async {
    final bytes = await _signature.toPngBytes();
    if (bytes == null) throw Exception('empty');
    final file = File('${Directory.systemTemp.path}/signature-${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes);
    return ref.read(apiClientProvider).uploadFile(file.path, kind: 'signature');
  }

  Future<void> _saveSignature() async {
    final l10n = AppLocalizations.of(context);
    if (_signature.isEmpty) {
      _toast(l10n.toastSignBeforeSaving);
      return;
    }
    setState(() => _busy = true);
    try {
      final url = await _uploadSignature();
      if (!mounted) return;
      setState(() => _signatureUrl = url);
      _toast(l10n.toastSignatureCaptured);
    } catch (_) {
      if (!mounted) return;
      _toast(l10n.toastUploadFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitPod() async {
    final l10n = AppLocalizations.of(context);
    if (_photoUrl == null ||
        _recipient.text.trim().isEmpty ||
        (_signatureUrl == null && _signature.isEmpty)) {
      _toast(l10n.toastPodFieldsRequired);
      return;
    }
    final destLat = _load?.deliveryLat;
    final destLng = _load?.deliveryLng;
    if (destLat != null && destLng != null) {
      final meters = await _gps.distanceMetersTo(destLat, destLng);
      if (meters != null && meters > 1000) {
        if (!mounted) return;
        final proceed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                content: Text(l10n.podFarFromDelivery),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.commonCancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(l10n.commonContinue),
                  ),
                ],
              ),
            ) ??
            false;
        if (!proceed) return;
      }
    }
    setState(() => _busy = true);
    try {
      var signatureUrl = _signatureUrl;
      if (signatureUrl == null) {
        signatureUrl = await _uploadSignature();
        if (!mounted) return;
        setState(() => _signatureUrl = signatureUrl);
      }
      await ref.read(apiClientProvider).submitPod(
            widget.loadId,
            photoUrl: _photoUrl!,
            signatureUrl: signatureUrl,
            recipientName: _recipient.text.trim(),
            notes: _notes.text.trim(),
          );
      if (!mounted) return;
      setState(() => _submitted = true);
      _stopDriverPointTimer();
      await ref.read(driverLocationControllerProvider.notifier).sync();
    } catch (_) {
      if (!mounted) return;
      _toast(l10n.toastPodSubmitFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final load = _load;
    if (load == null) {
      return Scaffold(appBar: AppHeader(title: l10n.driverPodTitle, showBack: true), body: const Center(child: CircularProgressIndicator()));
    }

    if (_submitted) {
      return Scaffold(
        appBar: AppHeader(title: l10n.driverPodTitle, showBack: true),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 64, color: AppColors.success),
              const SizedBox(height: 16),
              Text(l10n.driverPodSuccessTitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(l10n.driverPodSuccessCopy(load.referenceNo), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 24),
              FilledButton(onPressed: () => context.go('/driver'), child: Text(l10n.driverReturnDashboard)),
            ],
          ),
        ),
      );
    }

    final inTransit = load.status == 'IN_TRANSIT';
    return Scaffold(
      appBar: AppHeader(title: load.referenceNo, showBack: true, notificationsPath: '/driver/notifications', profilePath: '/driver/profile'),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, inTransit ? 24 : 16),
        children: [
          Row(children: [StatusChip(status: load.status), const Spacer(), Text(load.rate == null ? l10n.loadRateTbd : formatCurrency(load.rate, locale), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20))]),
          const SizedBox(height: 12),
          TripMap(
            pickup: load.pickupLat != null ? LatLng(load.pickupLat!, load.pickupLng!) : null,
            delivery: load.deliveryLat != null ? LatLng(load.deliveryLat!, load.deliveryLng!) : null,
            driver: _driverPoint ??
                (load.latestLocation != null ? LatLng(load.latestLocation!.lat, load.latestLocation!.lng) : null),
            showLiveBadge: load.status == 'IN_TRANSIT',
            expandable: true,
          ),
          const SizedBox(height: 12),
          Text('${l10n.driverDestination}: ${load.deliveryAddress}'),
          Text('${l10n.driverConsignee}: ${load.customer?.name ?? '—'}'),
          if (load.proofOfDelivery != null) ...[
            const SizedBox(height: 16),
            PodDocuments(pod: load.proofOfDelivery!),
          ],
          const SizedBox(height: 16),
          if (load.status == 'ASSIGNED')
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: _busy ? null : () => _respond('reject'), child: Text(l10n.driverReject))),
              const SizedBox(width: 8),
              Expanded(child: FilledButton(onPressed: _busy ? null : () => _respond('accept'), child: Text(l10n.driverAcceptLoad))),
            ]),
          if (load.status == 'ACCEPTED')
            FilledButton(onPressed: _busy ? null : () => _respond('start'), child: Text(l10n.driverStartTrip)),
          if (load.status == 'IN_TRANSIT') ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.successContainer, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l10n.driverGpsActive, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.success)),
                Text(l10n.driverGpsHint, style: const TextStyle(color: AppColors.success)),
              ]),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _busy ? null : _pickPhoto,
              child: Container(
                height: 160,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(12)),
                child: _photo != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(_photo!.path), fit: BoxFit.cover, width: double.infinity, height: 160))
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.camera_alt_outlined),
                        Text(_photoUrl == null ? l10n.driverCapturePod : l10n.driverReplacePod),
                        Text(l10n.driverPodHint, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                      ]),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.driverReceiverSignature, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SizedBox(
              height: 140,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Signature(controller: _signature, backgroundColor: Colors.white),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () => _signature.clear(), child: Text(l10n.driverClearSignature)),
            ),
            OutlinedButton(onPressed: _busy ? null : _saveSignature, child: Text(_signatureUrl == null ? l10n.driverSignHere : l10n.toastSignatureCaptured)),
            const SizedBox(height: 12),
            TextField(controller: _recipient, decoration: InputDecoration(labelText: l10n.driverRecipientName)),
            const SizedBox(height: 12),
            TextField(controller: _notes, maxLines: 3, decoration: InputDecoration(labelText: l10n.driverDeliveryNotes)),
          ],
        ],
      ),
      bottomNavigationBar: inTransit
          ? Material(
              color: AppColors.background,
              elevation: 8,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: FilledButton(
                    onPressed: _busy ? null : _submitPod,
                    child: Text(_busy ? l10n.driverProcessing : l10n.driverSubmitPod),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
