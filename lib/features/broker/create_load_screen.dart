import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../models/directory.dart';
import '../../models/load.dart';
import '../../shared/format.dart';
import '../../shared/media/load_document_upload.dart';
import '../../shared/system_price.dart';
import '../../shared/weight_unit.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/equipment_thumb.dart';
import '../../shared/widgets/load_date_time_picker.dart';
import '../../shared/widgets/load_documents_section.dart';
import '../../shared/widgets/stepper.dart';
import '../../shared/widgets/weight_input_row.dart';
import '../../theme/app_theme.dart';
import '../maps/pick_location_screen.dart';
import 'create_load_draft.dart';

class CreateLoadScreen extends ConsumerStatefulWidget {
  const CreateLoadScreen({super.key, this.asCustomer = false});

  final bool asCustomer;

  @override
  ConsumerState<CreateLoadScreen> createState() => _CreateLoadScreenState();
}

class _CreateLoadScreenState extends ConsumerState<CreateLoadScreen> {
  var _step = 0;
  var _submitting = false;
  var _uploadingReceipt = false;
  var _uploadingDocument = false;
  DeviceTier? _tier;
  String? _paymentReceiptUrl;
  List<LoadDocument> _documents = [];
  List<CustomerProfile> _customers = [];
  String? _customerId;
  var _equipment = 'DRY_VAN';
  var _weightUnit = WeightUnit.quintal;
  final _weight = TextEditingController();
  final _rate = TextEditingController();
  final _pickup = TextEditingController();
  final _delivery = TextEditingController();
  final _cargo = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _pickupDate;
  DateTime? _deliveryDate;
  List<PlaceSuggestion> _pickupHints = [];
  List<PlaceSuggestion> _deliveryHints = [];
  PlaceSuggestion? _pickupPlace;
  PlaceSuggestion? _deliveryPlace;
  double? _distanceKm;
  double? _systemPrice;
  var _pricingBusy = false;
  var _pricingError = false;
  var _draftPersistenceEnabled = true;

  bool get _receiptRequired => _tier?.receiptRequired ?? false;

  bool get _asCustomer => widget.asCustomer;

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _saveDraft();
  }

  @override
  void initState() {
    super.initState();
    _restoreDraft();
    for (final c in [_weight, _rate, _pickup, _delivery, _cargo, _notes]) {
      c.addListener(_saveDraft);
    }
    final api = ref.read(apiClientProvider);
    if (!widget.asCustomer) {
      api.listCustomers().then((c) {
        if (mounted) setState(() => _customers = c);
      });
      _fetchDeviceTier();
    }
  }

  void _restoreDraft() {
    final draft = readCreateLoadDraft(ref, _asCustomer);
    if (draft == null) return;
    _step = draft.step;
    _customerId = draft.customerId;
    _equipment = draft.equipment;
    _weight.text = draft.weight;
    _rate.text = draft.rate;
    _pickup.text = draft.pickup;
    _delivery.text = draft.delivery;
    _cargo.text = draft.cargo;
    _notes.text = draft.notes;
    _pickupDate = draft.pickupDate;
    _deliveryDate = draft.deliveryDate;
    _pickupPlace = draft.pickupPlace;
    _deliveryPlace = draft.deliveryPlace;
    _distanceKm = draft.distanceKm;
    _systemPrice = draft.systemPrice;
    _paymentReceiptUrl = draft.paymentReceiptUrl;
    _documents = List<LoadDocument>.from(draft.documents);
  }

  void _saveDraft() {
    if (!_draftPersistenceEnabled || !mounted) return;
    saveCreateLoadDraft(
      ref,
      _asCustomer,
      CreateLoadDraft(
        step: _step,
        customerId: _customerId,
        equipment: _equipment,
        weight: _weight.text,
        rate: _rate.text,
        pickup: _pickup.text,
        delivery: _delivery.text,
        cargo: _cargo.text,
        notes: _notes.text,
        pickupDate: _pickupDate,
        deliveryDate: _deliveryDate,
        pickupPlace: _pickupPlace,
        deliveryPlace: _deliveryPlace,
        distanceKm: _distanceKm,
        systemPrice: _systemPrice,
        paymentReceiptUrl: _paymentReceiptUrl,
        documents: List<LoadDocument>.from(_documents),
      ),
    );
  }

  Future<void> _fetchDeviceTier() async {
    if (widget.asCustomer) return;
    try {
      final tier = await ref.read(apiClientProvider).getDeviceTier();
      if (mounted) setState(() => _tier = tier);
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final c in [_weight, _rate, _pickup, _delivery, _cargo, _notes]) {
      c.removeListener(_saveDraft);
    }
    _saveDraft();
    _weight.dispose();
    _rate.dispose();
    _pickup.dispose();
    _delivery.dispose();
    _cargo.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _resetForm() {
    _weight.clear();
    _rate.clear();
    _pickup.clear();
    _delivery.clear();
    _cargo.clear();
    _notes.clear();
    setState(() {
      _step = 0;
      _submitting = false;
      _uploadingReceipt = false;
      _uploadingDocument = false;
      _paymentReceiptUrl = null;
      _documents = [];
      _equipment = 'DRY_VAN';
      _pickupDate = null;
      _deliveryDate = null;
      _pickupHints = [];
      _deliveryHints = [];
      _pickupPlace = null;
      _deliveryPlace = null;
      _distanceKm = null;
      _systemPrice = null;
      _pricingBusy = false;
      _pricingError = false;
    });
    clearCreateLoadDraft(ref, _asCustomer);
    _fetchDeviceTier();
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

  void _invalidatePrice() {
    _distanceKm = null;
    _systemPrice = null;
    _pricingError = false;
    _saveDraft();
  }

  Future<void> _refreshSystemPrice() async {
    final pickupText = _pickup.text.trim();
    final deliveryText = _delivery.text.trim();
    if (pickupText.isEmpty || deliveryText.isEmpty) return;
    setState(() {
      _pricingBusy = true;
      _pricingError = false;
    });
    try {
      final api = ref.read(apiClientProvider);
      try {
        await api.fetchRuntimeConfig();
      } catch (_) {}
      var pickup = _pickupPlace;
      var delivery = _deliveryPlace;
      if (pickup == null || pickup.placeName != pickupText) {
        pickup = await api.geocodePlace(pickupText);
      }
      if (delivery == null || delivery.placeName != deliveryText) {
        delivery = await api.geocodePlace(deliveryText);
      }
      if (!mounted) return;
      if (pickup == null || delivery == null) {
        setState(() {
          _pricingBusy = false;
          _pricingError = true;
          _distanceKm = null;
          _systemPrice = null;
        });
        return;
      }
      final km = await api.drivingDistanceKm(
        fromLat: pickup.lat,
        fromLng: pickup.lng,
        toLat: delivery.lat,
        toLng: delivery.lng,
      );
      if (!mounted) return;
      if (km == null) {
        setState(() {
          _pricingBusy = false;
          _pricingError = true;
          _distanceKm = null;
          _systemPrice = null;
        });
        return;
      }
      setState(() {
        _pickupPlace = pickup;
        _deliveryPlace = delivery;
        _distanceKm = km;
        _systemPrice = SystemPricing.calculate(km);
        _pricingBusy = false;
        _pricingError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pricingBusy = false;
        _pricingError = true;
        _distanceKm = null;
        _systemPrice = null;
      });
    }
  }

  Future<void> _pickDate({required bool pickup}) async {
    final l10n = AppLocalizations.of(context);
    final dt = await pickLoadDateTime(
      context,
      initial: pickup ? _pickupDate : _deliveryDate,
      firstDate: !pickup && _pickupDate != null
          ? DateTime(_pickupDate!.year, _pickupDate!.month, _pickupDate!.day)
          : null,
    );
    if (dt == null || !mounted) return;
    if (!pickup && _pickupDate != null && dt.isBefore(_pickupDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastDeliveryBeforePickup)));
      return;
    }
    setState(() {
      if (pickup) {
        _pickupDate = dt;
        if (_deliveryDate != null && _deliveryDate!.isBefore(dt)) {
          _deliveryDate = null;
        }
      } else {
        _deliveryDate = dt;
      }
    });
  }

  Future<void> _pickOnMap({required bool pickup}) async {
    final initial = pickup ? _pickupPlace : _deliveryPlace;
    final result = await Navigator.of(context).push<PlaceSuggestion>(
      MaterialPageRoute(
        builder: (_) => PickLocationScreen(
          initial: initial != null ? LatLng(initial.lat, initial.lng) : null,
          initialName: initial?.placeName,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (pickup) {
        _pickup.text = result.placeName;
        _pickupPlace = result;
        _pickupHints = [];
      } else {
        _delivery.text = result.placeName;
        _deliveryPlace = result;
        _deliveryHints = [];
      }
      _invalidatePrice();
    });
  }

  bool _datesInvalid() {
    return _pickupDate != null &&
        _deliveryDate != null &&
        _deliveryDate!.isBefore(_pickupDate!);
  }

  void _next() {
    final l10n = AppLocalizations.of(context);
    if (_step == 0 && !widget.asCustomer && (_customerId == null || _customerId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastSelectCustomer)));
      return;
    }
    if (_step == 1 &&
        (_pickup.text.trim().isEmpty ||
            _delivery.text.trim().isEmpty ||
            _pickupDate == null)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastPickupDeliveryRequired)));
      return;
    }
    if (_step == 1 && _datesInvalid()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastDeliveryBeforePickup)));
      return;
    }
    if (_step == 1 && _cargo.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastCargoRequired)));
      return;
    }
    final next = (_step + 1).clamp(0, 2);
    setState(() => _step = next);
    if (next == 2) {
      _refreshSystemPrice();
      _fetchDeviceTier();
    }
  }

  void _back() {
    if (_step <= 0) return;
    setState(() => _step--);
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

  Future<void> _addDocument() async {
    final l10n = AppLocalizations.of(context);
    if (_documents.length >= maxLoadDocuments) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastDocumentsMaxReached)));
      return;
    }
    setState(() => _uploadingDocument = true);
    try {
      final doc = await pickAndUploadLoadDocument(ref.read(apiClientProvider));
      if (!mounted || doc == null) return;
      setState(() => _documents = [..._documents, doc]);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastDocumentUploaded)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastUploadFailed)));
    } finally {
      if (mounted) setState(() => _uploadingDocument = false);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (_datesInvalid()) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.toastDeliveryBeforePickup)));
      return;
    }
    if (_cargo.text.trim().isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.toastCargoRequired)));
      return;
    }
    if (_receiptRequired && (_paymentReceiptUrl == null || _paymentReceiptUrl!.isEmpty)) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.toastReceiptRequired)));
      return;
    }
    setState(() => _submitting = true);
    try {
      double? weightQuintals;
      if (_weight.text.isNotEmpty) {
        final parsed = double.tryParse(_weight.text);
        if (parsed != null) weightQuintals = toQuintals(parsed, _weightUnit);
      }
      await ref.read(apiClientProvider).createLoad({
        if (!widget.asCustomer) 'customerId': _customerId,
        'equipmentType': _equipment,
        if (weightQuintals != null) 'weightLbs': weightQuintals,
        if (_rate.text.isNotEmpty) 'rate': num.tryParse(_rate.text),
        'systemPrice': _systemPrice ?? SystemPricing.basePriceEtb,
        if (_distanceKm != null) 'distanceKm': _distanceKm,
        'pickupAddress': _pickup.text.trim(),
        'deliveryAddress': _delivery.text.trim(),
        if (_pickupPlace != null) 'pickupLat': _pickupPlace!.lat,
        if (_pickupPlace != null) 'pickupLng': _pickupPlace!.lng,
        if (_deliveryPlace != null) 'deliveryLat': _deliveryPlace!.lat,
        if (_deliveryPlace != null) 'deliveryLng': _deliveryPlace!.lng,
        'pickupDate': _pickupDate!.toUtc().toIso8601String(),
        if (_deliveryDate != null) 'deliveryDate': _deliveryDate!.toUtc().toIso8601String(),
        'cargoDescription': _cargo.text.trim(),
        if (_notes.text.isNotEmpty) 'notes': _notes.text.trim(),
        if (_documents.isNotEmpty) 'documents': _documents.map((d) => d.toJson()).toList(),
        if (_paymentReceiptUrl != null && _paymentReceiptUrl!.isNotEmpty)
          'paymentReceiptUrl': _paymentReceiptUrl,
      });
      if (!mounted) return;
      ref.read(loadsRefreshProvider.notifier).state++;
      _draftPersistenceEnabled = false;
      clearCreateLoadDraft(ref, _asCustomer);
      final message = widget.asCustomer ? l10n.toastRequestSubmitted : l10n.toastLoadCreated;
      if (widget.asCustomer) {
        context.go('/customer');
      } else {
        context.go('/broker/loads');
      }
      messenger.showSnackBar(SnackBar(content: Text(message)));
      return;
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isReceiptRequired) {
        final current = _tier;
        if (current != null && !current.receiptRequired) {
          setState(() {
            _tier = DeviceTier(
              loadsCreated: current.loadsCreated,
              deviceLoadsCreated: current.deviceLoadsCreated,
              emailLoadsCreated: current.emailLoadsCreated,
              freeLimit: current.freeLimit,
              receiptRequired: true,
            );
          });
        }
        _fetchDeviceTier();
        messenger.showSnackBar(SnackBar(content: Text(l10n.toastReceiptRequired)));
      } else if (e.isDeviceIdRequired) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.toastDeviceIdRequired)));
      } else {
        messenger.showSnackBar(SnackBar(
          content: Text(widget.asCustomer ? l10n.toastRequestFailed : l10n.toastCreateLoadFailed),
        ));
      }
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(widget.asCustomer ? l10n.toastRequestFailed : l10n.toastCreateLoadFailed),
      ));
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
    final canSubmit = !_submitting &&
        !_pricingBusy &&
        (!_receiptRequired || (_paymentReceiptUrl?.isNotEmpty ?? false));
    final billedSystemPrice = _systemPrice ?? SystemPricing.basePriceEtb;

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _back();
      },
      child: Scaffold(
      appBar: AppHeader(
        title: widget.asCustomer ? l10n.customerRequestTitle : l10n.brokerLoadsTitle,
        showBack: !widget.asCustomer || _step > 0,
        onBack: _step > 0 ? _back : null,
        notificationsPath: widget.asCustomer ? '/customer/notifications' : '/broker/notifications',
        profilePath: widget.asCustomer ? '/customer/profile/visit' : '/broker/profile/visit',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          WizardStepper(steps: steps, current: _step),
          const SizedBox(height: 20),
          if (_step == 0) ...[
            if (!widget.asCustomer) ...[
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
            ],
            _Section(
              icon: Icons.inventory_2_outlined,
              title: l10n.brokerLoadDetails,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _equipment,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(
                        value: 'DRY_VAN',
                        child: EquipmentLabelRow(type: 'DRY_VAN', label: l10n.equipmentDryVan, thumbSize: 36),
                      ),
                      DropdownMenuItem(
                        value: 'REEFER',
                        child: EquipmentLabelRow(type: 'REEFER', label: l10n.equipmentReefer, thumbSize: 36),
                      ),
                      DropdownMenuItem(
                        value: 'FLATBED',
                        child: EquipmentLabelRow(type: 'FLATBED', label: l10n.equipmentFlatbed, thumbSize: 36),
                      ),
                      DropdownMenuItem(
                        value: 'LOW_BED',
                        child: EquipmentLabelRow(type: 'LOW_BED', label: l10n.equipmentLowBed, thumbSize: 36),
                      ),
                    ],
                    selectedItemBuilder: (context) => [
                      EquipmentLabelRow(type: 'DRY_VAN', label: l10n.equipmentDryVan, thumbSize: 28),
                      EquipmentLabelRow(type: 'REEFER', label: l10n.equipmentReefer, thumbSize: 28),
                      EquipmentLabelRow(type: 'FLATBED', label: l10n.equipmentFlatbed, thumbSize: 28),
                      EquipmentLabelRow(type: 'LOW_BED', label: l10n.equipmentLowBed, thumbSize: 28),
                    ],
                    onChanged: (v) => setState(() => _equipment = v ?? 'DRY_VAN'),
                  ),
                  const SizedBox(height: 12),
                  WeightInputRow(
                    controller: _weight,
                    unit: _weightUnit,
                    onUnitChanged: (unit) => setState(() => _weightUnit = unit),
                    label: l10n.brokerWeightLbs,
                    hint: l10n.brokerWeightPlaceholder,
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: _rate, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.brokerRate)),
                ],
              ),
            ),
          ] else if (_step == 1) ...[
            _AddressField(
              label: l10n.brokerPickupAddress,
              controller: _pickup,
              suggestions: _pickupHints,
              onChanged: (v) {
                if (_pickupPlace != null && _pickupPlace!.placeName != v) {
                  _pickupPlace = null;
                  _invalidatePrice();
                }
                _suggest(v, true);
              },
              onSelect: (v) => setState(() {
                _pickup.text = v.placeName;
                _pickupPlace = v;
                _pickupHints = [];
                _invalidatePrice();
              }),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _pickOnMap(pickup: true),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: Text(l10n.brokerPickOnMap),
              ),
            ),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.brokerPickupDate),
              subtitle: Text(_pickupDate == null ? l10n.loadScheduled : formatDateTime(_pickupDate!, locale)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(pickup: true),
            ),
            const SizedBox(height: 12),
            _AddressField(
              label: l10n.brokerDeliveryAddress,
              controller: _delivery,
              suggestions: _deliveryHints,
              onChanged: (v) {
                if (_deliveryPlace != null && _deliveryPlace!.placeName != v) {
                  _deliveryPlace = null;
                  _invalidatePrice();
                }
                _suggest(v, false);
              },
              onSelect: (v) => setState(() {
                _delivery.text = v.placeName;
                _deliveryPlace = v;
                _deliveryHints = [];
                _invalidatePrice();
              }),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _pickOnMap(pickup: false),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: Text(l10n.brokerPickOnMap),
              ),
            ),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.brokerDeliveryDate),
              subtitle: Text(_deliveryDate == null ? l10n.loadScheduled : formatDateTime(_deliveryDate!, locale)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(pickup: false),
            ),
            const SizedBox(height: 12),
            TextField(controller: _cargo, decoration: InputDecoration(labelText: l10n.brokerCargoDescription)),
            const SizedBox(height: 12),
            TextField(controller: _notes, maxLines: 3, decoration: InputDecoration(labelText: l10n.brokerNotes)),
            const SizedBox(height: 12),
            LoadDocumentsSection(
              documents: _documents,
              adding: _uploadingDocument,
              hint: l10n.loadDocumentsHint,
              onAdd: _addDocument,
              onRemove: (doc) => setState(() {
                _documents = _documents.where((d) => d.url != doc.url || d.fileName != doc.fileName).toList();
              }),
            ),
          ] else ...[
            _Section(
              icon: Icons.check_circle_outline,
              title: l10n.brokerConfirmLoad,
              child: Column(
                children: [
                  if (!widget.asCustomer)
                    _kv(l10n.brokerConfirmCustomer, customer?.company ?? customer?.user.name ?? '—'),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(l10n.brokerConfirmEquipment, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
                        ),
                        Expanded(
                          child: EquipmentLabelRow(
                            type: _equipment,
                            label: equipmentLabel(l10n, _equipment),
                            thumbSize: 36,
                            expandLabel: true,
                            textStyle: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _kv(
                    l10n.brokerConfirmWeight,
                    () {
                      if (_weight.text.isEmpty) return '—';
                      final parsed = double.tryParse(_weight.text);
                      if (parsed == null) return '—';
                      final quintals = toQuintals(parsed, _weightUnit);
                      return formatWeightValue(quintals, l10n, WeightUnit.quintal) ?? '—';
                    }(),
                  ),
                  _kv(
                    l10n.brokerConfirmRate,
                    _rate.text.isEmpty
                        ? l10n.loadRateTbd
                        : formatCurrency(num.tryParse(_rate.text.replaceAll(',', '')), locale),
                  ),
                  _systemPriceRows(l10n, locale, billedSystemPrice),
                  _kv(l10n.brokerConfirmPickup, _pickup.text),
                  _kv(l10n.brokerConfirmDelivery, _delivery.text),
                  _kv(l10n.brokerConfirmPickupDate, _pickupDate == null ? '—' : formatDateTime(_pickupDate!, locale)),
                  _kv(l10n.brokerConfirmCargo, _cargo.text.isEmpty ? '—' : _cargo.text),
                  if (_documents.isNotEmpty)
                    _kv(
                      l10n.loadDocumentsTitle,
                      _documents.map((d) => d.fileName).join(', '),
                    ),
                ],
              ),
            ),
            if (!widget.asCustomer && _tier != null && !_receiptRequired) ...[
              const SizedBox(height: 12),
              Text(
                l10n.brokerFreeLoadsRemaining(_tier!.remaining, _tier!.freeLimit),
                style: const TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ],
            if (_receiptRequired) ...[
              const SizedBox(height: 12),
              _Section(
                icon: Icons.receipt_long_outlined,
                title: l10n.brokerPaymentReceipt,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.brokerPaymentReceiptHintAmount(formatCurrency(billedSystemPrice, locale)),
                      style: const TextStyle(color: AppColors.onSurfaceVariant),
                    ),
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
          ],
        ],
      ),
      bottomNavigationBar: Material(
        color: AppColors.background,
        elevation: 8,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: _buildStepActions(l10n, canSubmit),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildStepActions(AppLocalizations l10n, bool canSubmit) {
    if (_step == 0) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _next,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(l10n.brokerContinueToRoute, textAlign: TextAlign.center)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward),
            ],
          ),
        ),
      );
    }

    final primaryLabel = _step == 1
        ? l10n.brokerReviewLoad
        : (_submitting
            ? (widget.asCustomer ? l10n.customerSubmitting : l10n.brokerCreating)
            : (widget.asCustomer ? l10n.customerSubmit : l10n.brokerCreateLoad));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(onPressed: _back, child: Text(l10n.commonBack)),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _step == 1 ? _next : (canSubmit ? _submit : null),
            child: Text(primaryLabel),
          ),
        ),
      ],
    );
  }

  Widget _systemPriceRows(AppLocalizations l10n, Locale locale, double billedSystemPrice) {
    if (_pricingBusy) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(width: 110, child: Text(l10n.systemPrice, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13))),
            const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.systemPriceCalculating, style: const TextStyle(fontSize: 13))),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _kv(l10n.systemPrice, formatCurrency(billedSystemPrice, locale)),
        if (_distanceKm != null)
          Padding(
            padding: const EdgeInsets.only(left: 110, bottom: 4),
            child: Text(
              l10n.systemPriceBreakdown(
                SystemPricing.formatNumber(SystemPricing.basePriceEtb, maxFractionDigits: 2),
                SystemPricing.formatKm(_distanceKm!),
                SystemPricing.formatNumber(SystemPricing.perKmEtb, maxFractionDigits: 2),
              ),
              style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
            ),
          ),
        if (_pricingError) ...[
          Padding(
            padding: const EdgeInsets.only(left: 110, bottom: 4),
            child: Text(
              l10n.systemPriceBaseFallback(formatCurrency(SystemPricing.basePriceEtb, locale)),
              style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 110, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.systemPriceUnavailable, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                TextButton(onPressed: _refreshSystemPrice, child: Text(l10n.systemPriceRetry)),
              ],
            ),
          ),
        ],
      ],
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
    required this.suggestions,
    required this.onChanged,
    required this.onSelect,
  });

  final String label;
  final TextEditingController controller;
  final List<PlaceSuggestion> suggestions;
  final ValueChanged<String> onChanged;
  final ValueChanged<PlaceSuggestion> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          onChanged: onChanged,
        ),
        if (suggestions.isNotEmpty)
          ...suggestions.map(
            (s) => ListTile(
              dense: true,
              leading: const Icon(Icons.place_outlined, size: 18),
              title: Text(s.placeName, style: const TextStyle(fontSize: 13)),
              onTap: () => onSelect(s),
            ),
          ),
      ],
    );
  }
}
