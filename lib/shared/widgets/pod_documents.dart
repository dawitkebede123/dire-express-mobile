import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../l10n/app_localizations.dart';
import '../../models/load.dart';
import '../../theme/app_theme.dart';

class PodDocuments extends StatelessWidget {
  const PodDocuments({super.key, required this.pod});

  final ProofOfDelivery pod;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final recipient = pod.recipientName?.trim();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.brokerProofOfDelivery, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          if (recipient != null && recipient.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(recipient, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
          if (pod.photoUrl.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(l10n.brokerDeliveryPhoto, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 6),
            _PodImage(url: pod.photoUrl, height: 160, fit: BoxFit.cover),
          ],
          if (pod.signatureUrl.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(l10n.brokerRecipientSignature, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 6),
            _PodImage(url: pod.signatureUrl, height: 120, fit: BoxFit.contain),
          ],
        ],
      ),
    );
  }
}

class _PodImage extends StatelessWidget {
  const _PodImage({required this.url, required this.height, required this.fit});

  final String url;
  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final resolved = AppConfig.resolveMediaUrl(url) ?? url;
    final bytes = _dataBytes(resolved);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: bytes != null
          ? Image.memory(bytes, height: height, width: double.infinity, fit: fit)
          : CachedNetworkImage(
              imageUrl: resolved,
              height: height,
              width: double.infinity,
              fit: fit,
              memCacheHeight: (height * 2).round(),
              errorWidget: (_, _, _) => _placeholder(height),
              placeholder: (_, _) => _placeholder(height),
            ),
    );
  }

  Uint8List? _dataBytes(String value) {
    if (!value.startsWith('data:')) return null;
    return Uri.parse(value).data?.contentAsBytes();
  }

  Widget _placeholder(double height) {
    return Container(
      height: height,
      width: double.infinity,
      color: AppColors.surfaceContainer,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_outlined, color: AppColors.onSurfaceVariant),
    );
  }
}
