import 'package:flutter/material.dart';

import '../../core/offline_map_service.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_header.dart';
import '../../theme/app_theme.dart';

class OfflineMapsScreen extends StatefulWidget {
  const OfflineMapsScreen({super.key});

  @override
  State<OfflineMapsScreen> createState() => _OfflineMapsScreenState();
}

class _OfflineMapsScreenState extends State<OfflineMapsScreen> {
  var _busy = false;
  var _progress = 0;
  String? _status;

  Future<void> _download({required bool update}) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _progress = 0;
      _status = null;
    });
    try {
      await OfflineMapService.instance.downloadRegion(
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (!mounted) return;
      setState(() => _status = l10n.offlineMapsReady);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.offlineMapsReady)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = l10n.offlineMapsFailed);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.offlineMapsFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    OfflineMapService.instance.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(title: l10n.offlineMapsTitle, showBack: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.offlineMapsHint, style: const TextStyle(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 20),
          if (_busy) ...[
            LinearProgressIndicator(value: _progress / 100),
            const SizedBox(height: 8),
            Text(l10n.offlineMapsDownloading(_progress)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                OfflineMapService.instance.cancel();
              },
              child: Text(l10n.commonCancel),
            ),
          ] else ...[
            FilledButton.icon(
              onPressed: () => _download(update: false),
              icon: const Icon(Icons.download),
              label: Text(l10n.offlineMapsDownload),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _download(update: true),
              icon: const Icon(Icons.sync),
              label: Text(l10n.offlineMapsUpdate),
            ),
          ],
          if (_status != null) ...[
            const SizedBox(height: 16),
            Text(_status!, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}
