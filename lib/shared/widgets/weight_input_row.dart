import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../weight_unit.dart';

class WeightInputRow extends StatelessWidget {
  const WeightInputRow({
    super.key,
    required this.controller,
    required this.unit,
    required this.onUnitChanged,
    required this.label,
    this.hint,
    this.enabled = true,
  });

  final TextEditingController controller;
  final WeightUnit unit;
  final ValueChanged<WeightUnit> onUnitChanged;
  final String label;
  final String? hint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(hintText: hint),
              ),
            ),
            const SizedBox(width: 8),
            _UnitToggle(
              unit: unit,
              onChanged: enabled ? onUnitChanged : null,
              l10n: l10n,
            ),
          ],
        ),
      ],
    );
  }
}

class _UnitToggle extends StatelessWidget {
  const _UnitToggle({
    required this.unit,
    required this.onChanged,
    required this.l10n,
  });

  final WeightUnit unit;
  final ValueChanged<WeightUnit>? onChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _UnitChip(
            label: l10n.unitQuintal,
            selected: unit == WeightUnit.quintal,
            onTap: onChanged == null ? null : () => onChanged!(WeightUnit.quintal),
          ),
          _UnitChip(
            label: l10n.unitKg,
            selected: unit == WeightUnit.kg,
            onTap: onChanged == null ? null : () => onChanged!(WeightUnit.kg),
          ),
        ],
      ),
    );
  }
}

class _UnitChip extends StatelessWidget {
  const _UnitChip({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
