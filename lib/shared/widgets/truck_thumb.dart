import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../theme/app_theme.dart';
import 'equipment_thumb.dart';

/// Truck photo from API, or equipment thumbnail when no custom photo exists.
class TruckThumb extends StatelessWidget {
  const TruckThumb({
    super.key,
    this.truckImageUrl,
    this.vehicleType,
    this.size = 48,
    this.radius = 8,
  });

  final String? truckImageUrl;
  final String? vehicleType;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = AppConfig.resolveMediaUrl(truckImageUrl);
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          width: size,
          height: size,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (_, _) => ColoredBox(
              color: AppColors.surfaceContainer,
              child: Icon(Icons.local_shipping, size: size * 0.5, color: AppColors.secondary),
            ),
            errorWidget: (_, _, _) => EquipmentThumb(type: vehicleType, size: size, radius: radius),
          ),
        ),
      );
    }
    return EquipmentThumb(type: vehicleType, size: size, radius: radius);
  }
}
