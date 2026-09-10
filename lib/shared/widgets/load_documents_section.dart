import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../l10n/app_localizations.dart';
import '../../models/load.dart';
import '../../theme/app_theme.dart';

class LoadDocumentsSection extends StatelessWidget {
  const LoadDocumentsSection({
    super.key,
    required this.documents,
    this.onAdd,
    this.onRemove,
    this.adding = false,
    this.hint,
  });

  final List<LoadDocument> documents;
  final VoidCallback? onAdd;
  final ValueChanged<LoadDocument>? onRemove;
  final bool adding;
  final String? hint;

  Future<void> _open(BuildContext context, LoadDocument doc) async {
    final l10n = AppLocalizations.of(context);
    final resolved = AppConfig.resolveMediaUrl(doc.url) ?? doc.url;
    final uri = Uri.tryParse(resolved);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastDocumentOpenFailed)));
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastDocumentOpenFailed)));
    }
  }

  IconData _iconFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf_outlined;
    return Icons.image_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.loadDocumentsTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(hint!, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          if (documents.isEmpty)
            Text(l10n.loadDocumentsEmpty, style: const TextStyle(color: AppColors.onSurfaceVariant))
          else
            ...documents.map((doc) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _open(context, doc),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Icon(_iconFor(doc.fileName), color: AppColors.secondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              doc.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (onRemove != null)
                            IconButton(
                              tooltip: l10n.commonCancel,
                              onPressed: () => onRemove!(doc),
                              icon: const Icon(Icons.close, size: 20),
                            )
                          else
                            const Icon(Icons.open_in_new, size: 18, color: AppColors.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          if (onAdd != null) ...[
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: adding ? null : onAdd,
              icon: adding
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.upload_file),
              label: Text(l10n.loadDocumentsAdd),
            ),
          ],
        ],
      ),
    );
  }
}
