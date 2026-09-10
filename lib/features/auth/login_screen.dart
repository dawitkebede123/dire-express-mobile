import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/phone.dart';
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
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  var _role = 'CUSTOMER';
  var _loading = false;
  var _obscurePassword = true;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _loading = true);
    try {
      final raw = _identifier.text.trim();
      final identifier = raw.contains('@') ? raw : (normalizePhone(raw) ?? raw);
      await ref.read(authControllerProvider.notifier).login(
            identifier,
            _password.text,
            expectedRole: _role,
          );
      if (!mounted) return;
      final user = ref.read(authControllerProvider).user;
      if (user != null) context.go(user.homePath);
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
      final message = e.code == 'roleMismatch' || e.message == 'roleMismatch'
          ? l10n.toastRoleMismatch
          : isAuthFailure
              ? l10n.toastInvalidCredentials
              : e.isNoNetwork
                  ? l10n.toastNoNetwork
                  : l10n.toastConnectionFailed;
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
    final roles = [
      ('BROKER', Icons.hub_outlined, l10n.roleBroker),
      ('DRIVER', Icons.local_shipping_outlined, l10n.roleDriver),
      ('CUSTOMER', Icons.inventory_2_outlined, l10n.roleCustomer),
    ];
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
                  const SizedBox(height: 16),
                  Text(l10n.registerIAmA, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: roles.map((r) {
                      final selected = _role == r.$1;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () => setState(() => _role = r.$1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selected ? AppColors.primary : AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: selected ? AppColors.primary : AppColors.outlineVariant),
                              ),
                              child: Column(
                                children: [
                                  Icon(r.$2, color: selected ? Colors.white : AppColors.onSurfaceVariant),
                                  const SizedBox(height: 4),
                                  Text(
                                    r.$3,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: selected ? Colors.white : AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.loginEmail, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _identifier,
                    keyboardType: TextInputType.text,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.username],
                  ),
                  const SizedBox(height: 14),
                  Text(l10n.loginPassword, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _password,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
