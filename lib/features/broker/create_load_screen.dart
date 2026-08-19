import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../models/directory.dart';
import '../../shared/format.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/stepper.dart';
import '../../theme/app_theme.dart';

class CreateLoadScreen extends ConsumerStatefulWidget {
  const CreateLoadScreen({super.key});

  @override
  ConsumerState<CreateLoadScreen> createState() => _CreateLoadScreenState();
}

class _CreateLoadScreenState extends ConsumerState<CreateLoadScreen> {
  var _step = 0;
  var _submitting = false;
  var _uploadingReceipt = false;
  var _receiptRequired = false;
  String? _paymentReceiptUrl;
  List<CustomerProfile> _customers = [];
  String? _customerId;
  var _equipment = 'DRY_VAN';
  final _weight = TextEditingController();
  final _rate = TextEditingController();
  final _pickup = TextEditingController();
  final _delivery = TextEditingController();
  final _cargo = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _pickupDate;
  DateTime? _deliveryDate;
  List<String> _pickupHints = [];
  List<String> _deliveryHints = [];

  @override
  void initState() {
    super.initState();
    final api = ref.read(apiClientProvider);
    api.listCustomers().then((c) {
      if (mounted) setState(() => _customers = c);
    });
    api.getDeviceTier().then((tier) {
      if (mounted) setState(() => _receiptRequired = tier.receiptRequired);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _weight.dispose();
    _rate.dispose();
    _pickup.dispose();
    _delivery.dispose();
    _cargo.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _suggest(String query, bool pickup) async {
    final hints = await ref.read(apiClientProvider).geocodeSuggestions(query);
    if (!mounted) return;
    setState(() {
      if (pickup) {
        _pickupHints = hints;
      } else {
        _deliveryHints = hints;
      }
    });
  }

  Future<void> _pickDate({required bool pickup}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now));
    if (time == null || !mounted) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (pickup) {
        _pickupDate = dt;
      } else {
        _deliveryDate = dt;
      }
    });
  }

  void _next() {
    final l10n = AppLocalizations.of(context);
    if (_step == 0 && (_customerId == null || _customerId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastSelectCustomer)));
      return;
    }
    if (_step == 1 && (_pickup.text.isEmpty || _delivery.text.isEmpty || _pickupDate == null)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastPickupDeliveryRequired)));
      return;
    }
    setState(() => _step = (_step + 1).clamp(0, 2));
  }

  Future<void> _uploadReceipt() async {
    final l10n = AppLocalizations.of(context);
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    setState(() => _uploadingReceipt = true);
    try {
      final url = await ref.read(apiClientProvider).uploadFile(file.path, kind: 'receipt');
      if (!mounted) return;
      setState(() => _paymentReceiptUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastReceiptUploaded)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastUploadFailed)));
    } finally {
      if (mounted) setState(() => _uploadingReceipt = false);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_receiptRequired && (_paymentReceiptUrl == null || _paymentReceiptUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastReceiptRequired)));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(apiClientProvider).createLoad({
        'customerId': _customerId,
        'equipmentType': _equipment,
        if (_weight.text.isNotEmpty) 'weightLbs': num.tryParse(_weight.text),
        if (_rate.text.isNotEmpty) 'rate': num.tryParse(_rate.text),
        'pickupAddress': _pickup.text.trim(),
        'deliveryAddress': _delivery.text.trim(),
        'pickupDate': _pickupDate!.toUtc().toIso8601String(),
        if (_deliveryDate != null) 'deliveryDate': _deliveryDate!.toUtc().toIso8601String(),
        if (_cargo.text.isNotEmpty) 'cargoDescription': _cargo.text.trim(),
        if (_notes.text.isNotEmpty) 'notes': _notes.text.trim(),
        if (_paymentReceiptUrl != null && _paymentReceiptUrl!.isNotEmpty)
          'paymentReceiptUrl': _paymentReceiptUrl,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastLoadCreated)));
      ref.read(loadsRefreshProvider.notifier).state++;
      context.go('/broker/loads');
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isReceiptRequired) {
        setState(() => _receiptRequired = true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastReceiptRequired)));
      } else if (e.isDeviceIdRequired) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastDeviceIdRequired)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastCreateLoadFailed)));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastCreateLoadFailed)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final steps = [l10n.brokerStepDetails, l10n.brokerStepRoute, l10n.brokerStepConfirm];
    final customer = _customers.where((c) => c.id == _customerId).firstOrNull;
    final canSubmit = !_submitting && (!_receiptRequired || (_paymentReceiptUrl?.isNotEmpty ?? false));

    return Scaffold(
      appBar: AppHeader(title: l10n.brokerLoadsTitle, showBack: true, notificationsPath: '/broker/notifications', profilePath: '/broker/profile'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          WizardStepper(steps: steps, current: _step),
          const SizedBox(height: 20),
          if (_step == 0) ...[
            _Section(
              icon: Icons.apartment,
              title: l10n.brokerCustomerInfo,
              child: DropdownButtonFormField<String>(
                value: _customerId,
                hint: Text(l10n.brokerSelectCustomerPlaceholder),
                items: _customers
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.company ?? c.user.name)))
                    .toList(),
                onChanged: (v) => setState(() => _customerId = v),
              ),
            ),
            const SizedBox(height: 12),
            _Section(
              icon: Icons.inventory_2_outlined,
              title: l10n.brokerLoadDetails,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _equipment,
                    items: [
                      DropdownMenuItem(value: 'DRY_VAN', child: Text(l10n.equipmentDryVan)),
                      DropdownMenuItem(value: 'REEFER', child: Text(l10n.equipmentReefer)),
                      DropdownMenuItem(value: 'FLATBED', child: Text(l10n.equipmentFlatbed)),
                    ],
                    onChanged: (v) => setState(() => _equipment = v ?? 'DRY_VAN'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _weight, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.brokerWeightLbs, hintText: l10n.brokerWeightPlaceholder))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _rate, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.brokerRate, hintText: l10n.brokerRatePlaceholder))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _next,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(l10n.brokerContinueToRoute), const SizedBox(width: 8), const Icon(Icons.arrow_forward)]),
            ),
          ] else if (_step == 1) ...[
            _AddressField(
              label: l10n.brokerPickupAddress,
              controller: _pickup,
              hint: l10n.brokerPickupPlaceholder,
              suggestions: _pickupHints,
              onChanged: (v) => _suggest(v, true),
              onSelect: (v) => setState(() {
                _pickup.text = v;
                _pickupHints = [];
              }),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.brokerPickupDate),
              subtitle: Text(_pickupDate == null ? l10n.loadScheduled : formatDateTime(_pickupDate!, locale)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(pickup: true),
            ),
            _AddressField(
              label: l10n.brokerDeliveryAddress,
              controller: _delivery,
              hint: l10n.brokerDeliveryPlaceholder,
              suggestions: _deliveryHints,
              onChanged: (v) => _suggest(v, false),
              onSelect: (v) => setState(() {
                _delivery.text = v;
                _deliveryHints = [];
              }),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.brokerDeliveryDate),
              subtitle: Text(_deliveryDate == null ? l10n.loadScheduled : formatDateTime(_deliveryDate!, locale)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(pickup: false),
            ),
            TextField(controller: _cargo, decoration: InputDecoration(labelText: l10n.brokerCargoDescription, hintText: l10n.brokerCargoPlaceholder)),
            const SizedBox(height: 12),
            TextField(controller: _notes, maxLines: 3, decoration: InputDecoration(labelText: l10n.brokerNotes, hintText: l10n.brokerNotesPlaceholder)),
            const SizedBox(height: 20),
            FilledButton(onPressed: _next, child: Text(l10n.brokerReviewLoad)),
          ] else ...[
            _Section(
              icon: Icons.check_circle_outline,
              title: l10n.brokerConfirmLoad,
              child: Column(
                children: [
                  _kv(l10n.brokerConfirmCustomer, customer?.company ?? customer?.user.name ?? '—'),
                  _kv(l10n.brokerConfirmEquipment, equipmentLabel(l10n, _equipment)),
                  _kv(l10n.brokerConfirmWeight, _weight.text.isEmpty ? '—' : l10n.weightLbs(_weight.text)),
                  _kv(
                    l10n.brokerConfirmRate,
                    _rate.text.isEmpty
                        ? l10n.loadRateTbd
                        : formatCurrency(num.tryParse(_rate.text.replaceAll(',', '')), locale),
                  ),
                  _kv(l10n.brokerConfirmPickup, _pickup.text),
                  _kv(l10n.brokerConfirmDelivery, _delivery.text),
                  _kv(l10n.brokerConfirmPickupDate, _pickupDate == null ? '—' : formatDateTime(_pickupDate!, locale)),
                  _kv(l10n.brokerConfirmCargo, _cargo.text.isEmpty ? '—' : _cargo.text),
                ],
              ),
            ),
            if (_receiptRequired) ...[
              const SizedBox(height: 12),
              _Section(
                icon: Icons.receipt_long_outlined,
                title: l10n.brokerPaymentReceipt,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.brokerPaymentReceiptHint, style: const TextStyle(color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 12),
                    if (_paymentReceiptUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.success),
                            const SizedBox(width: 8),
                            Expanded(child: Text(l10n.brokerReceiptReady, style: const TextStyle(fontWeight: FontWeight.w600))),
                          ],
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: _uploadingReceipt ? null : _uploadReceipt,
                      icon: _uploadingReceipt
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.upload_file),
                      label: Text(l10n.brokerUploadReceipt),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: canSubmit ? _submit : null,
              child: Text(_submitting ? l10n.brokerCreating : l10n.brokerCreateLoad),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(k, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13))),
          Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.child});
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: AppColors.secondary), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))]),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _AddressField extends StatelessWidget {
  const _AddressField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.suggestions,
    required this.onChanged,
    required this.onSelect,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final List<String> suggestions;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label, hintText: hint),
          onChanged: onChanged,
        ),
        if (suggestions.isNotEmpty)
          ...suggestions.map(
            (s) => ListTile(
              dense: true,
              leading: const Icon(Icons.place_outlined, size: 18),
              title: Text(s, style: const TextStyle(fontSize: 13)),
              onTap: () => onSelect(s),
            ),
          ),
      ],
    );
  }
}
