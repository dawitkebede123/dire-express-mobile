import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/language_switcher.dart';
import '../../shared/widgets/logo.dart';
import '../../theme/app_theme.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _loading = false;

  static const _demos = [
    ('BROKER', 'broker@direexpress.com'),
    ('DRIVER', 'driver@direexpress.com'),
    ('CUSTOMER', 'customer@direexpress.com'),
  ];

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _loading = true);
    try {
      final user = await ref.read(authControllerProvider.notifier).login(
            _email.text.trim(),
            _password.text,
          );
      if (!mounted) return;
      context.go(user.homePath);
    } on ApiException catch (e) {
      if (kDebugMode) {
        debugPrint('LOGIN FAILED status=${e.statusCode} ${e.message}');
      }
      if (!mounted) return;
      final code = e.statusCode;
      final msg = e.message.toLowerCase();
      final isAuthFailure = code == 400 ||
          code == 401 ||
          code == 403 ||
          msg.contains('invalid email') ||
          msg.contains('invalid credentials');
      final message = isAuthFailure
          ? l10n.toastInvalidCredentials
          : (e.message.isNotEmpty ? e.message : l10n.toastConnectionFailed);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('LOGIN FAILED unexpected: $e\n$st');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastConnectionFailed)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                GestureDetector(onTap: () => context.go('/welcome'), child: const Logo()),
                const Spacer(),
                const LanguageSwitcher(),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.loginTitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(l10n.loginSubtitle, style: const TextStyle(color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 20),
                  Text(l10n.loginEmail, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(hintText: l10n.loginEmailPlaceholder),
                  ),
                  const SizedBox(height: 14),
                  Text(l10n.loginPassword, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: '••••••••'),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: Text(_loading ? l10n.loginSubmitting : l10n.loginSubmit),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    children: [
                      Text(l10n.loginNoAccount, style: const TextStyle(color: AppColors.onSurfaceVariant)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => context.go('/register'),
                        child: Text(l10n.loginCreateOne, style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.loginDemo, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _demos.map((d) {
                      return ActionChip(
                        label: Text(d.$1, style: const TextStyle(fontSize: 12)),
                        onPressed: () {
                          _email.text = d.$2;
                          _password.text = 'password123';
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
