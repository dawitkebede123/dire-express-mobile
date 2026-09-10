import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../features/auth/auth_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_header.dart';
import '../../theme/app_theme.dart';

class ProfileMoreScreen extends ConsumerWidget {
  const ProfileMoreScreen({super.key});

  Future<void> _startDeleteAccountFlow(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final continueDelete = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.profileDeleteAccountWarningTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.profileDeleteAccountWarningBody,
                  style: const TextStyle(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n.commonCancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                        child: Text(l10n.commonContinue),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (continueDelete != true || !context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _DeleteAccountPasswordSheet(
          onDelete: (password) => _submitDeleteAccount(sheetContext, ref, password),
        );
      },
    );
  }

  Future<void> _submitDeleteAccount(
    BuildContext sheetContext,
    WidgetRef ref,
    String password,
  ) async {
    final l10n = AppLocalizations.of(sheetContext);
    try {
      await ref.read(apiClientProvider).deleteAccount(password);
      if (!sheetContext.mounted) return;
      Navigator.pop(sheetContext);
      await ref.read(authControllerProvider.notifier).signOut();
      if (!sheetContext.mounted) return;
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        SnackBar(content: Text(l10n.toastAccountDeleted)),
      );
      sheetContext.go('/login');
    } on ApiException catch (e) {
      if (!sheetContext.mounted) return;
      final message = switch (e.code) {
        'invalidPassword' => l10n.toastInvalidPassword,
        'activeLoadsExist' => l10n.toastActiveLoadsExist,
        _ => l10n.toastActionFailed,
      };
      ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(content: Text(message)));
      if (e.code == 'activeLoadsExist') {
        Navigator.pop(sheetContext);
      }
    } catch (_) {
      if (!sheetContext.mounted) return;
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        SnackBar(content: Text(l10n.toastActionFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(title: l10n.profileMoreTitle, showBack: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_forever_outlined, color: AppColors.error),
            title: Text(
              l10n.profileDeleteAccount,
              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.error),
            onTap: () => _startDeleteAccountFlow(context, ref),
          ),
        ],
      ),
    );
  }
}

class _DeleteAccountPasswordSheet extends StatefulWidget {
  const _DeleteAccountPasswordSheet({required this.onDelete});

  final Future<void> Function(String password) onDelete;

  @override
  State<_DeleteAccountPasswordSheet> createState() => _DeleteAccountPasswordSheetState();
}

class _DeleteAccountPasswordSheetState extends State<_DeleteAccountPasswordSheet> {
  final _passwordController = TextEditingController();
  var _submitting = false;
  var _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    if (password.trim().isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.onDelete(password);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomInset),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.profileDeleteAccountPasswordTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscure,
              enabled: !_submitting,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.profileDeleteAccountPasswordHint,
                suffixIcon: IconButton(
                  onPressed: _submitting ? null : () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                ),
              ),
              onSubmitted: _submitting ? null : (_) => _submit(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting ? null : () => Navigator.pop(context),
                    child: Text(l10n.commonCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                          )
                        : Text(l10n.profileDeleteAccountConfirm),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
