import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 20,
    this.fallbackIcon = Icons.person,
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = Colors.white,
  });

  final String? imageUrl;
  final String? name;
  final double radius;
  final IconData fallbackIcon;
  final Color backgroundColor;
  final Color foregroundColor;

  String? get _initials {
    final parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return null;
    if (parts.length == 1) {
      final word = parts.first;
      final take = word.length >= 2 ? 2 : 1;
      return word.substring(0, take).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Widget _fallback() {
    final initials = _initials;
    if (initials != null) {
      return Text(
        initials,
        style: TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.72,
        ),
      );
    }
    return Icon(fallbackIcon, size: radius, color: foregroundColor);
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final hasUrl = url != null && url.isNotEmpty;
    final size = radius * 2;
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: hasUrl
            ? Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => ColoredBox(
                  color: backgroundColor,
                  child: Center(child: _fallback()),
                ),
              )
            : ColoredBox(
                color: backgroundColor,
                child: Center(child: _fallback()),
              ),
      ),
    );
  }
}
