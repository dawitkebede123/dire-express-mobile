import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:signature/signature.dart';

import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../models/load.dart';
import '../../shared/format.dart';
import '../../shared/widgets/app_header.dart';
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
  var _busy = false;
  var _submitted = false;
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
        setState(() => _load = FreightLoad.fromJson(data['load'] as Map<String, dynamic>));
      }
    };
    _fetch();
    pusherService.subscribe('load-${widget.loadId}', 'status-update', _handler);
  }

  @override
  void dispose() {
    pusherService.unsubscribe('load-${widget.loadId}', 'status-update', _handler);
    _recipient.dispose();
    _notes.dispose();
    _signature.dispose();
    _gps.stop();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final load = await ref.read(apiClientProvider).getLoad(widget.loadId);
      if (mounted) setState(() => _load = load);
      if (load.status == 'IN_TRANSIT') {
        await _gps.start(api: ref.read(apiClientProvider), loadId: load.id);
      }
    } catch (_) {}
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
        await _gps.start(api: ref.read(apiClientProvider), loadId: widget.loadId);
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

  Future<void> _saveSignature() async {
    final l10n = AppLocalizations.of(context);
    if (_signature.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastSignBeforeSaving)));
      return;
    }
    setState(() => _busy = true);
    try {
      final bytes = await _signature.toPngBytes();
      if (bytes == null) throw Exception('empty');
      final file = File('${Directory.systemTemp.path}/signature-${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      final url = await ref.read(apiClientProvider).uploadFile(file.path, kind: 'signature');
      if (!mounted) return;
      setState(() => _signatureUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastSignatureCaptured)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastUploadFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitPod() async {
    final l10n = AppLocalizations.of(context);
    if (_photoUrl == null || _signatureUrl == null || _recipient.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastPodFieldsRequired)));
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(apiClientProvider).submitPod(
            widget.loadId,
            photoUrl: _photoUrl!,
            signatureUrl: _signatureUrl!,
            recipientName: _recipient.text.trim(),
            notes: _notes.text.trim(),
          );
      if (!mounted) return;
      setState(() => _submitted = true);
      await _gps.stop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastPodSubmitFailed)));
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

    return Scaffold(
      appBar: AppHeader(title: load.referenceNo, showBack: true, notificationsPath: '/driver/notifications', profilePath: '/driver/profile'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [StatusChip(status: load.status), const Spacer(), Text(load.rate == null ? l10n.loadRateTbd : formatCurrency(load.rate, locale), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20))]),
          const SizedBox(height: 12),
          TripMap(
            pickup: load.pickupLat != null ? LatLng(load.pickupLat!, load.pickupLng!) : null,
            delivery: load.deliveryLat != null ? LatLng(load.deliveryLat!, load.deliveryLng!) : null,
            driver: load.latestLocation != null ? LatLng(load.latestLocation!.lat, load.latestLocation!.lng) : null,
            showLiveBadge: load.status == 'IN_TRANSIT',
            expandable: true,
          ),
          const SizedBox(height: 12),
          Text('${l10n.driverDestination}: ${load.deliveryAddress}'),
          Text('${l10n.driverConsignee}: ${load.customer?.name ?? '—'}'),
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
            Container(
              height: 140,
              decoration: BoxDecoration(border: Border.all(color: AppColors.outlineVariant), borderRadius: BorderRadius.circular(12)),
              child: Signature(controller: _signature, backgroundColor: Colors.white),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () => _signature.clear(), child: Text(l10n.driverClearSignature)),
            ),
            OutlinedButton(onPressed: _busy ? null : _saveSignature, child: Text(_signatureUrl == null ? l10n.driverSignHere : l10n.toastSignatureCaptured)),
            const SizedBox(height: 12),
            TextField(controller: _recipient, decoration: InputDecoration(labelText: l10n.driverRecipientName, hintText: l10n.driverRecipientPlaceholder)),
            const SizedBox(height: 12),
            TextField(controller: _notes, maxLines: 3, decoration: InputDecoration(labelText: l10n.driverDeliveryNotes, hintText: l10n.driverNotesPlaceholder)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _busy ? null : _submitPod, child: Text(_busy ? l10n.driverProcessing : l10n.driverSubmitPod)),
          ],
        ],
      ),
    );
  }
}
