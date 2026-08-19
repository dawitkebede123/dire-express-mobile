import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/widgets/language_switcher.dart';
import '../../shared/widgets/logo.dart';
import '../../theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Logo(),
                  const Spacer(),
                  const LanguageSwitcher(),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(l10n.landingBadge, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.landingTitle,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, height: 1.15),
              ),
              const SizedBox(height: 12),
              Text(l10n.landingCopy, style: const TextStyle(color: AppColors.onSurfaceVariant, height: 1.4)),
              const SizedBox(height: 28),
              Text(l10n.landingHowHeading, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              _Step(index: '1', title: l10n.landingBookTitle, copy: l10n.landingBookCopy),
              _Step(index: '2', title: l10n.landingDispatchTitle, copy: l10n.landingDispatchCopy),
              _Step(index: '3', title: l10n.landingDeliverTitle, copy: l10n.landingDeliverCopy),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go('/register'),
                child: Text(l10n.landingCta),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => context.go('/login'),
                child: Text(l10n.landingSignIn),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.index, required this.title, required this.copy});

  final String index;
  final String title;
  final String copy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            child: Text(index, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(copy, style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
