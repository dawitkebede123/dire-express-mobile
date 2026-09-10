import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'telebirr_nav_roof_painter.dart';

/// Telebirr-style bottom bar: downward notch + dot above the top edge.
class TelebirrBottomNav extends StatelessWidget {
  const TelebirrBottomNav({
    super.key,
    required this.icons,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<IconData> icons;
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _duration = Duration(milliseconds: 300);
  static const _barHeight = 64.0;
  static const _dotZoneHeight = 10.0;
  static const _notchDepth = 30.0;
  static const _iconTopInset = 14.0;
  static const _bumpWidth = 48.0;
  static const _dotSize = 6.0;

  static double get _tabAreaTop => _dotZoneHeight + _iconTopInset;
  static double get _tabAreaHeight => _barHeight - _iconTopInset;
  static double get _effectiveNotchDepth => _notchDepth.clamp(0, _iconTopInset - 2);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final tabWidth = width / icons.length;
            final targetCenterX = tabWidth * selectedIndex + tabWidth / 2;

            return TweenAnimationBuilder<double>(
              tween: Tween(end: targetCenterX),
              duration: _duration,
              curve: Curves.easeOutCubic,
              builder: (context, centerX, _) {
                return SizedBox(
                  height: _dotZoneHeight + _barHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CustomPaint(
                        size: Size(width, _dotZoneHeight + _barHeight),
                        painter: TelebirrNavRoofPainter(
                          centerX: centerX,
                          width: width,
                          dotZoneHeight: _dotZoneHeight,
                          notchDepth: _effectiveNotchDepth,
                          bumpWidth: _bumpWidth,
                          barHeight: _barHeight,
                          color: AppColors.surfaceContainerLowest,
                          strokeColor: AppColors.outlineVariant,
                        ),
                      ),
                      Positioned(
                        left: centerX - _dotSize / 2,
                        top: 2,
                        child: Container(
                          width: _dotSize,
                          height: _dotSize,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        top: _tabAreaTop,
                        left: 0,
                        right: 0,
                        height: _tabAreaHeight,
                        child: Row(
                          children: [
                            for (var i = 0; i < icons.length; i++)
                              Expanded(
                                child: _TelebirrNavTab(
                                  icon: icons[i],
                                  label: labels[i],
                                  selected: i == selectedIndex,
                                  onTap: () => onSelected(i),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _TelebirrNavTab extends StatelessWidget {
  const _TelebirrNavTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: TelebirrBottomNav._tabAreaHeight,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: color),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
