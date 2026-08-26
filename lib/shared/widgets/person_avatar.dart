import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../../core/config.dart';
import '../../theme/app_theme.dart';

Future<void> prefetchPersonAvatar(String? imageUrl) async {
  final url = AppConfig.resolveMediaUrl(imageUrl);
  if (url == null || url.isEmpty) return;
  try {
    await DefaultCacheManager().downloadFile(url);
  } catch (_) {}
}

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

  Widget _placeholder() {
    return ColoredBox(
      color: backgroundColor,
      child: Center(child: _fallback()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = AppConfig.resolveMediaUrl(imageUrl);
    final size = radius * 2;
    final cachePx = (size * MediaQuery.devicePixelRatioOf(context)).round().clamp(32, 512);
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: url == null || url.isEmpty
            ? _placeholder()
            : CachedNetworkImage(
                imageUrl: url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                memCacheWidth: cachePx,
                memCacheHeight: cachePx,
                fadeInDuration: const Duration(milliseconds: 150),
                fadeOutDuration: const Duration(milliseconds: 100),
                placeholder: (_, _) => _placeholder(),
                errorWidget: (_, _, _) => _placeholder(),
              ),
      ),
    );
  }
}
