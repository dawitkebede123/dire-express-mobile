import 'package:flutter/material.dart';

/// Telebirr-style fade + directional slide for bottom-tab content switches.
class TabContentTransition extends StatelessWidget {
  const TabContentTransition({
    super.key,
    required this.tabIndex,
    required this.previousIndex,
    required this.child,
  });

  final int tabIndex;
  final int previousIndex;
  final Widget child;

  static const _duration = Duration(milliseconds: 300);
  static const _slideOffset = 0.28;

  int get _slideDirection {
    if (tabIndex == previousIndex) return 0;
    return tabIndex.compareTo(previousIndex);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: _duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final direction = _slideDirection;
        final begin = direction == 0 ? Offset.zero : Offset(direction * _slideOffset, 0);
        final slideAnimation = Tween<Offset>(
          begin: begin,
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slideAnimation, child: child),
        );
      },
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          fit: StackFit.expand,
          children: [
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      child: KeyedSubtree(
        key: ValueKey(tabIndex),
        child: child,
      ),
    );
  }
}
