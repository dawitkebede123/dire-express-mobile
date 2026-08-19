import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class RouteMini extends StatelessWidget {
  const RouteMini({
    super.key,
    required this.pickupCity,
    required this.pickupTime,
    required this.deliveryCity,
    required this.deliveryTime,
    this.pickupReached = false,
    this.deliveryReached = false,
    this.error = false,
  });

  final String pickupCity;
  final String pickupTime;
  final String deliveryCity;
  final String deliveryTime;
  final bool pickupReached;
  final bool deliveryReached;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final deliveryColor = error ? AppColors.error : AppColors.secondary;
    return Column(
      children: [
        _Stop(
          city: pickupCity,
          time: pickupTime,
          color: AppColors.secondary,
          filled: pickupReached,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(width: 2, height: 18, color: AppColors.outlineVariant),
          ),
        ),
        _Stop(
          city: deliveryCity,
          time: deliveryTime,
          color: deliveryColor,
          filled: deliveryReached,
        ),
      ],
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop({
    required this.city,
    required this.time,
    required this.color,
    required this.filled,
  });

  final String city;
  final String time;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? color : Colors.transparent,
            border: Border.all(color: color, width: 2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(city, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text(time, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
