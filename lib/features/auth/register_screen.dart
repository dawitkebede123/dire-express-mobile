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
    final name = _name.text.trim();
    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastNameRequired)));
      return;
    }
    if (_password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastPasswordTooShort)));
      return;
    }
    final phone = normalizePhone(_phone.text);
    final phoneDigits = phone?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (phone == null || phoneDigits.length < 7) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastPhoneRequired)));
      return;
    }
    final needsAgent = _role == 'DRIVER' || _role == 'CUSTOMER';
    final agentId = _agentId.text.trim();
    if (needsAgent && agentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastAgentIdRequired)));
      return;
    }
    if (needsAgent && !RegExp(r'^\d{6}$').hasMatch(agentId)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastAgentIdInvalid)));
      return;
    }
    final email = _email.text.trim();
    if (email.isNotEmpty && !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastInvalidEmail)));
      return;
    }
    final company = _company.text.trim();
    final plate = _plate.text.trim();
    final vehicle = _vehicle.text.trim();
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).register({
        'name': name,
        'password': _password.text,
        'phone': phone,
        'role': _role,
        if (email.isNotEmpty) 'email': email,
        if (needsAgent) 'agentId': agentId,
        if (_role != 'DRIVER' && company.isNotEmpty) 'company': company,
        if (_role == 'DRIVER' && plate.isNotEmpty) 'plateNo': plate,
        if (_role == 'DRIVER' && vehicle.isNotEmpty) 'vehicleType': vehicle,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastAccountCreated)));
    } on LoginAfterRegisterException catch (e) {
      if (!mounted) return;
      final cause = e.cause;
      final status = cause.statusCode;
      final msg = cause.message.toLowerCase();
      final isAuthFailure = status == 400 ||
          status == 401 ||
          status == 403 ||
          msg.contains('invalid email') ||
          msg.contains('invalid credentials');
      final message = cause.code == 'roleMismatch' || cause.message == 'roleMismatch'
          ? l10n.toastRoleMismatch
          : isAuthFailure
              ? l10n.toastInvalidCredentials
              : (cause.message.isNotEmpty ? cause.message : l10n.toastConnectionFailed);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      context.go('/login');
    } on ApiException catch (e) {
      if (!mounted) return;
      final code = e.code ?? e.message;
      final message = switch (code) {
        'phoneRequired' => l10n.toastPhoneRequired,
        'agentIdRequired' => l10n.toastAgentIdRequired,
        'agentIdInvalid' => l10n.toastAgentIdInvalid,
        'referredByNotFound' => l10n.toastReferredByNotFound,
        'emailRegistered' => l10n.toastEmailRegistered,
        'phoneRegistered' => l10n.toastPhoneRegistered,
        'timeout' => l10n.toastConnectionFailed,
        'registrationFailed' => l10n.toastRegistrationFailed,
        _ => l10n.toastRegistrationFailed,
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastRegistrationFailed)));
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
                  _Labeled(l10n.registerFullName, _name),
                  _Labeled(l10n.registerEmail, _email, email: true),
                  _Labeled(l10n.registerPassword, _password, obscure: true),
                  _Labeled(l10n.registerPhone, _phone, phone: true),
                  if (_role != 'DRIVER')
                    _Labeled(l10n.registerCompany, _company),
                  if (_role == 'DRIVER') ...[
                    _Labeled(l10n.registerPlateNo, _plate),
                    _Labeled(l10n.registerVehicleType, _vehicle),
                  ],
                  if (_role == 'DRIVER' || _role == 'CUSTOMER')
                    _Labeled(l10n.registerAgentId, _agentId),
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

class _Labeled extends StatefulWidget {
  const _Labeled(this.label, this.controller, {this.email = false, this.obscure = false, this.phone = false});

  final String label;
  final TextEditingController controller;
  final bool email;
  final bool obscure;
  final bool phone;

  @override
  State<_Labeled> createState() => _LabeledState();
}

class _LabeledState extends State<_Labeled> {
  late var _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: widget.controller,
            obscureText: _hidden,
            keyboardType: widget.phone
                ? TextInputType.phone
                : widget.email
                    ? TextInputType.emailAddress
                    : TextInputType.text,
            decoration: InputDecoration(
              suffixIcon: widget.obscure
                  ? IconButton(
                      icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _hidden = !_hidden),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
