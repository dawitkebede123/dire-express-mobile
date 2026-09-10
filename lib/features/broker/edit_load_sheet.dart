import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../models/load.dart';
import '../../shared/format.dart';
import '../../shared/system_price.dart';
import '../../shared/weight_unit.dart';
import '../../shared/widgets/equipment_thumb.dart';
import '../../shared/widgets/load_date_time_picker.dart';
import '../../shared/widgets/weight_input_row.dart';
import '../../theme/app_theme.dart';
import '../maps/pick_location_screen.dart';

Future<FreightLoad?> showEditLoadSheet(BuildContext context, FreightLoad load) {
  return showModalBottomSheet<FreightLoad>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => EditLoadSheet(load: load),
  );
}

class EditLoadSheet extends ConsumerStatefulWidget {
  const EditLoadSheet({super.key, required this.load});

  final FreightLoad load;

  @override
  ConsumerState<EditLoadSheet> createState() => _EditLoadSheetState();
}

class _EditLoadSheetState extends ConsumerState<EditLoadSheet> {
  late var _equipment = widget.load.equipmentType ?? 'DRY_VAN';
  var _weightUnit = WeightUnit.quintal;
  late final _weight = TextEditingController(
    text: widget.load.weightLbs == null
        ? ''
        : formatWeightNumber(fromQuintals(widget.load.weightLbs!, WeightUnit.quintal)),
  );
  late final _rate = TextEditingController(
    text: widget.load.rate == null ? '' : formatWeightNumber(widget.load.rate!),
  );
  late final _pickup = TextEditingController(text: widget.load.pickupAddress);
  late final _delivery = TextEditingController(text: widget.load.deliveryAddress);
  late final _cargo = TextEditingController(text: widget.load.cargoDescription ?? '');
  late final _notes = TextEditingController(text: widget.load.notes ?? '');
  late DateTime? _pickupDate = widget.load.pickupDate;
  late DateTime? _deliveryDate = widget.load.deliveryDate;
  PlaceSuggestion? _pickupPlace;
  PlaceSuggestion? _deliveryPlace;
  List<PlaceSuggestion> _pickupHints = [];
  List<PlaceSuggestion> _deliveryHints = [];
  late double? _distanceKm = widget.load.distanceKm;
  late double? _systemPrice = widget.load.systemPrice;
  var _pricingBusy = false;
  var _pricingError = false;
  var _routeDirty = false;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final load = widget.load;
    if (load.pickupLat != null && load.pickupLng != null) {
      _pickupPlace = PlaceSuggestion(
        placeName: load.pickupAddress,
        lat: load.pickupLat!,
        lng: load.pickupLng!,
      );
    }
    if (load.deliveryLat != null && load.deliveryLng != null) {
      _deliveryPlace = PlaceSuggestion(
        placeName: load.deliveryAddress,
        lat: load.deliveryLat!,
        lng: load.deliveryLng!,
      );
    }
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

  void _invalidatePrice() {
    setState(() {
      _routeDirty = true;
      _distanceKm = null;
      _systemPrice = null;
      _pricingError = false;
    });
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
        _routeDirty = false;
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

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_pickup.text.trim().isEmpty ||
        _delivery.text.trim().isEmpty ||
        _pickupDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastPickupDeliveryRequired)));
      return;
    }
    if (_datesInvalid()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastDeliveryBeforePickup)));
      return;
    }
    if (_cargo.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastCargoRequired)));
      return;
    }
    if (_routeDirty) {
      await _refreshSystemPrice();
      if (!mounted) return;
    }
    setState(() => _saving = true);
    try {
      double? weightQuintals;
      if (_weight.text.isNotEmpty) {
        final parsed = double.tryParse(_weight.text);
        if (parsed != null) weightQuintals = toQuintals(parsed, _weightUnit);
      }
      final updated = await ref.read(apiClientProvider).updateLoad(widget.load.id, {
        'equipmentType': _equipment,
        if (weightQuintals != null) 'weightLbs': weightQuintals,
        if (_rate.text.isNotEmpty) 'rate': num.tryParse(_rate.text),
        if (_systemPrice != null) 'systemPrice': _systemPrice,
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
        'notes': _notes.text.trim(),
      });
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastLoadUpdateFailed)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final height = MediaQuery.sizeOf(context).height * 0.92;
    final billed = _systemPrice ?? widget.load.systemPrice;

    return SizedBox(
      height: height,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(l10n.brokerEditLoad, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                DropdownButtonFormField<String>(
                  value: _equipment,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.brokerEquipmentType),
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
                TextField(
                  controller: _rate,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.brokerRate),
                ),
                const SizedBox(height: 16),
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.brokerPickupDate),
                  subtitle: Text(_pickupDate == null ? l10n.loadScheduled : formatDateTime(_pickupDate!, locale)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _pickDate(pickup: true),
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 16),
                if (_pricingBusy)
                  Text(l10n.systemPriceCalculating, style: const TextStyle(color: AppColors.onSurfaceVariant))
                else if (billed != null) ...[
                  Text(
                    '${l10n.systemPrice}: ${formatCurrency(billed, locale)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (_distanceKm != null)
                    Text(
                      l10n.systemPriceBreakdown(
                        SystemPricing.formatNumber(SystemPricing.basePriceEtb, maxFractionDigits: 2),
                        SystemPricing.formatKm(_distanceKm!),
                        SystemPricing.formatNumber(SystemPricing.perKmEtb, maxFractionDigits: 2),
                      ),
                      style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                    ),
                ],
                if (_pricingError || _routeDirty)
                  TextButton(onPressed: _refreshSystemPrice, child: Text(l10n.systemPriceRetry)),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? l10n.commonLoading : l10n.commonSave),
                ),
              ),
            ),
          ),
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
