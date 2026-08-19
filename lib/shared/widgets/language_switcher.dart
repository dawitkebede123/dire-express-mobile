import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/locale_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key});

  Future<void> _setLocale(WidgetRef ref, Locale locale) async {
    await ref.read(localeControllerProvider.notifier).setLocale(locale);
    final token = await ref.read(authStorageProvider).readToken();
    if (token == null || token.isEmpty) return;
    try {
      await ref.read(apiClientProvider).updateLocale(locale.languageCode);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final l10n = AppLocalizations.of(context);
    final isAm = locale.languageCode == 'am';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Chip(
            label: l10n.languageEn,
            selected: !isAm,
            onTap: () => _setLocale(ref, const Locale('en')),
          ),
          _Chip(
            label: l10n.languageAm,
            selected: isAm,
            onTap: () => _setLocale(ref, const Locale('am')),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
