import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/language_switcher.dart';
import '../../shared/widgets/logo.dart';
import '../../theme/app_theme.dart';
import 'auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _company = TextEditingController();
  final _plate = TextEditingController();
  final _vehicle = TextEditingController();
  final _agentId = TextEditingController();
  var _role = 'CUSTOMER';
  var _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _company.dispose();
    _plate.dispose();
    _vehicle.dispose();
    _agentId.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final needsAgent = _role == 'DRIVER' || _role == 'CUSTOMER';
    if (needsAgent && _agentId.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastAgentIdRequired)));
      return;
    }
    final phone = normalizePhone(_phone.text);
    if (phone == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastInvalidPhone)));
      return;
    }
    setState(() => _loading = true);
    try {
      final user = await ref.read(authControllerProvider.notifier).register({
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
        'phone': phone,
        'role': _role,
        if (_role != 'DRIVER') 'company': _company.text.trim(),
        if (_role == 'DRIVER') 'plateNo': _plate.text.trim(),
        if (_role == 'DRIVER') 'vehicleType': _vehicle.text.trim(),
        if (needsAgent) 'agentId': _agentId.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastAccountCreated)));
      context.go(user.homePath);
    } on ApiException catch (e) {
      if (!mounted) return;
      final code = e.code ?? e.message;
      final message = switch (code) {
        'emailRegistered' => l10n.toastEmailRegistered,
        'agentIdRequired' => l10n.toastAgentIdRequired,
        'agentIdInvalid' => l10n.toastAgentIdInvalid,
        _ => l10n.toastRegistrationFailed,
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
            const SizedBox(height: 24),
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
                  Text(l10n.registerTitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(l10n.registerSubtitle, style: const TextStyle(color: AppColors.onSurfaceVariant)),
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
                  _Labeled(l10n.registerFullName, _name, l10n.registerNamePlaceholder),
                  _Labeled(l10n.registerEmail, _email, l10n.registerEmailPlaceholder, email: true),
                  _Labeled(l10n.registerPassword, _password, l10n.registerPasswordPlaceholder, obscure: true),
                  _Labeled(l10n.registerPhone, _phone, l10n.registerPhonePlaceholder, phone: true),
                  if (_role != 'DRIVER')
                    _Labeled(l10n.registerCompany, _company, l10n.registerCompanyPlaceholder),
                  if (_role == 'DRIVER') ...[
                    _Labeled(l10n.registerPlateNo, _plate, l10n.registerPlatePlaceholder),
                    _Labeled(l10n.registerVehicleType, _vehicle, l10n.registerVehiclePlaceholder),
                  ],
                  if (_role == 'DRIVER' || _role == 'CUSTOMER')
                    _Labeled(l10n.registerAgentId, _agentId, l10n.registerAgentIdPlaceholder),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: Text(_loading ? l10n.registerSubmitting : l10n.registerSubmit),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    children: [
                      Text(l10n.registerAlready, style: const TextStyle(color: AppColors.onSurfaceVariant)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(l10n.registerSignIn, style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w700)),
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

class _Labeled extends StatelessWidget {
  const _Labeled(this.label, this.controller, this.hint, {this.email = false, this.obscure = false, this.phone = false});

  final String label;
  final TextEditingController controller;
  final String hint;
  final bool email;
  final bool obscure;
  final bool phone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: phone
                ? TextInputType.phone
                : email
                    ? TextInputType.emailAddress
                    : TextInputType.text,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }
}

/// Returns E.164, or null if invalid.
String? normalizePhone(String raw) {
  final compact = raw.trim().replaceAll(RegExp(r'[\s\-()]'), '');
  if (compact.isEmpty) return null;

  if (compact.startsWith('+')) {
    final digits = compact.substring(1);
    if (RegExp(r'^\d{8,15}$').hasMatch(digits)) return '+$digits';
    return null;
  }

  if (RegExp(r'^09\d{8}$').hasMatch(compact)) {
    return '+251${compact.substring(1)}';
  }
  if (RegExp(r'^9\d{8}$').hasMatch(compact)) {
    return '+251$compact';
  }
  // Kenya Safaricom: 07XXXXXXXX, 011XXXXXXX (with leading 0)
  if (RegExp(r'^07\d{8}$').hasMatch(compact) || RegExp(r'^011\d{7}$').hasMatch(compact)) {
    return '+254${compact.substring(1)}';
  }
  // Kenya without leading 0: 7XXXXXXXX or 11XXXXXXX
  if (RegExp(r'^7\d{8}$').hasMatch(compact) || RegExp(r'^11\d{7}$').hasMatch(compact)) {
    return '+254$compact';
  }
  // Djibouti: 77XXXXXX or 077XXXXXX
  if (RegExp(r'^77\d{6}$').hasMatch(compact)) {
    return '+253$compact';
  }
  if (RegExp(r'^077\d{6}$').hasMatch(compact)) {
    return '+253${compact.substring(1)}';
  }
  // Eritrea: 7XXXXXX or 07XXXXXX
  if (RegExp(r'^7\d{6}$').hasMatch(compact)) {
    return '+291$compact';
  }
  if (RegExp(r'^07\d{6}$').hasMatch(compact)) {
    return '+291${compact.substring(1)}';
  }
  return null;
}
