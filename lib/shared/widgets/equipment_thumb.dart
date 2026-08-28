import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../format.dart';

String? equipmentImageAsset(String? type) {
  switch (type) {
    case 'DRY_VAN':
      return 'assets/trailers/dry-van.jpg';
    case 'REEFER':
      return 'assets/trailers/reefer.jpg';
    case 'FLATBED':
      return 'assets/trailers/flat-bed.jpg';
    case 'LOW_BED':
    case 'CONTAINER_20':
    case 'CONTAINER_40':
      return 'assets/trailers/low_bed.jpg';
    default:
      return null;
  }
}

/// Small trailer thumbnail with icon fallback.
class EquipmentThumb extends StatelessWidget {
  const EquipmentThumb({
    super.key,
    required this.type,
    this.size = 40,
    this.radius = 8,
  });

  final String? type;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final asset = equipmentImageAsset(type);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: asset == null
            ? ColoredBox(
                color: AppColors.surfaceContainer,
                child: Icon(equipmentIcon(type), size: size * 0.5, color: AppColors.secondary),
              )
            : Image.asset(
                asset,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: AppColors.surfaceContainer,
                  child: Icon(equipmentIcon(type), size: size * 0.5, color: AppColors.secondary),
                ),
              ),
      ),
    );
  }
}

class EquipmentLabelRow extends StatelessWidget {
  const EquipmentLabelRow({
    super.key,
    required this.type,
    required this.label,
    this.thumbSize = 40,
    this.textStyle,
    this.expandLabel = false,
  });

  final String? type;
  final String label;
  final double thumbSize;
  final TextStyle? textStyle;

  /// Use only when the parent already provides a bounded max width.
  final bool expandLabel;

  @override
  Widget build(BuildContext context) {
    final text = Text(label, style: textStyle, overflow: TextOverflow.ellipsis);
    return Row(
      mainAxisSize: expandLabel ? MainAxisSize.max : MainAxisSize.min,
      children: [
        EquipmentThumb(type: type, size: thumbSize),
        const SizedBox(width: 10),
        if (expandLabel) Flexible(child: text) else text,
      ],
    );
  }
}
