import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class WizardStepper extends StatelessWidget {
  const WizardStepper({super.key, required this.steps, required this.current});

  final List<String> steps;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 18),
                color: i <= current ? AppColors.secondary : AppColors.surfaceContainerHighest,
              ),
            ),
          Column(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: i <= current ? AppColors.secondary : AppColors.surfaceContainerHighest,
                foregroundColor: i <= current ? Colors.white : AppColors.onSurfaceVariant,
                child: Text('${i + 1}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 6),
              Text(
                steps[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: i <= current ? AppColors.secondary : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
