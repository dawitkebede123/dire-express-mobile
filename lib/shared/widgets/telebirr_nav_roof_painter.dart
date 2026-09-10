import 'package:flutter/material.dart';

/// Draws the Telebirr-style downward valley notch on the top edge of the bottom nav bar.
class TelebirrNavRoofPainter extends CustomPainter {
  TelebirrNavRoofPainter({
    required this.centerX,
    required this.width,
    required this.dotZoneHeight,
    required this.notchDepth,
    required this.bumpWidth,
    required this.barHeight,
    required this.color,
    this.strokeColor,
  });

  final double centerX;
  final double width;
  final double dotZoneHeight;
  final double notchDepth;
  final double bumpWidth;
  final double barHeight;
  final Color color;
  final Color? strokeColor;

  Path _buildTopEdgePath(double leftShoulder, double rightShoulder, double topY) {
    final path = Path()
      ..moveTo(0, topY)
      ..lineTo(leftShoulder, topY);

    if (rightShoulder <= leftShoulder) {
      path.lineTo(width, topY);
      return path;
    }

    final valleyY = topY + notchDepth;
    final shoulderControl = bumpWidth * 0.35;
    final valleyControl = bumpWidth * 0.2;

    path
      ..cubicTo(
        leftShoulder + shoulderControl,
        topY,
        centerX - valleyControl,
        valleyY,
        centerX,
        valleyY,
      )
      ..cubicTo(
        centerX + valleyControl,
        valleyY,
        rightShoulder - shoulderControl,
        topY,
        rightShoulder,
        topY,
      )
      ..lineTo(width, topY);

    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final halfBump = bumpWidth / 2;
    final leftShoulder = (centerX - halfBump).clamp(0.0, width);
    final rightShoulder = (centerX + halfBump).clamp(0.0, width);
    final topY = dotZoneHeight;
    final bottomY = dotZoneHeight + barHeight;

    final fillPath = _buildTopEdgePath(leftShoulder, rightShoulder, topY)
      ..lineTo(width, bottomY)
      ..lineTo(0, bottomY)
      ..close();

    canvas.drawPath(fillPath, Paint()..color = color);

    if (strokeColor != null) {
      canvas.drawPath(
        _buildTopEdgePath(leftShoulder, rightShoulder, topY),
        Paint()
          ..color = strokeColor!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TelebirrNavRoofPainter oldDelegate) {
    return oldDelegate.centerX != centerX ||
        oldDelegate.width != width ||
        oldDelegate.dotZoneHeight != dotZoneHeight ||
        oldDelegate.notchDepth != notchDepth ||
        oldDelegate.bumpWidth != bumpWidth ||
        oldDelegate.barHeight != barHeight ||
        oldDelegate.color != color ||
        oldDelegate.strokeColor != strokeColor;
  }
}
