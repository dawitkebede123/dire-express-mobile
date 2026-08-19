import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _TruckMarkPainter()),
    );
  }
}

class Logo extends StatelessWidget {
  const Logo({super.key, this.showWordmark = true, this.size = 32});

  final bool showWordmark;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LogoMark(size: size),
        if (showWordmark) ...[
          const SizedBox(width: 8),
          Text(
            'Dire Express',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
          ),
        ],
      ],
    );
  }
}

class _TruckMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 32;
    canvas.scale(s, s);
    final fill = Paint()..color = AppColors.primary;
    final white = Paint()..color = Colors.white;
    final whiteDim = Paint()..color = Colors.white.withValues(alpha: 0.72);

    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 32, 32), const Radius.circular(8)), fill);
    canvas.drawPath(
      Path()
        ..moveTo(6, 12.5)
        ..lineTo(15.5, 12.5)
        ..cubicTo(17.156, 12.5, 18.5, 13.844, 18.5, 15.5)
        ..lineTo(18.5, 22)
        ..lineTo(9, 22)
        ..cubicTo(7.344, 22, 6, 20.656, 6, 19)
        ..close(),
      white,
    );
    canvas.drawPath(
      Path()
        ..moveTo(18.5, 15)
        ..lineTo(22.7, 15)
        ..lineTo(26, 18.6)
        ..lineTo(26, 22)
        ..lineTo(18.5, 22)
        ..close(),
      whiteDim,
    );

    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final hub = Paint()..color = AppColors.onPrimaryContainer;
    canvas.drawCircle(const Offset(11, 22.5), 2.4, hub);
    canvas.drawCircle(const Offset(11, 22.5), 2.4, stroke);
    canvas.drawCircle(const Offset(22, 22.5), 2.4, hub);
    canvas.drawCircle(const Offset(22, 22.5), 2.4, stroke);

    final line = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(4, 9.5), const Offset(12, 9.5), line);
    canvas.drawLine(const Offset(4, 6.5), const Offset(9, 6.5), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
