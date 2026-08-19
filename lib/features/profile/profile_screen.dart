import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/auth/register_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/format.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/language_switcher.dart';
import '../../shared/widgets/person_avatar.dart';
import '../../theme/app_theme.dart';

enum _EditField { name, phone, plate, vehicle }

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, required this.backPath});

  final String backPath;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _draft = TextEditingController();
  var _name = '';
  var _phone = '';
  var _plate = '';
  var _vehicle = '';
  _EditField? _editing;
  var _loading = true;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    if (user != null) {
      _name = user.name;
      _phone = user.phone ?? '';
    }
    _load();
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final api = ref.read(apiClientProvider);
    final isDriver = ref.read(authControllerProvider).user?.isDriver == true;
    try {
      final user = await api.getMeProfile();
      String plate = '';
      String vehicle = '';
      if (isDriver) {
        try {
          final driver = await api.getMyDriverProfile();
          plate = driver.plateNo ?? '';
          vehicle = driver.vehicleType ?? '';
        } catch (_) {}
      }
      if (!mounted) return;
      final savedName = user['name'] is String ? user['name'] as String : _name;
      final savedPhone = user['phone'] as String?;
      final savedImage = user['imageUrl'] as String?;
      setState(() {
        _name = savedName;
        _phone = savedPhone ?? '';
        _plate = plate;
        _vehicle = vehicle;
      });
      final current = ref.read(authControllerProvider).user;
      if (current != null) {
        ref.read(authControllerProvider.notifier).applyUser(
          current.applyProfile(name: savedName, phone: savedPhone).applyImageUrl(savedImage),
        );
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changePhoto() async {
    final l10n = AppLocalizations.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(l10n.profileTakePhoto),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.profileChoosePhoto),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
    if (source == null || !mounted) return;

    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (file == null || !mounted) return;

    final user = ref.read(authControllerProvider).user;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      final url = await api.uploadFile(file.path, kind: 'avatar');
      final data = await api.updateMe(imageUrl: url);
      if (!mounted) return;
      final savedUrl = data['imageUrl'] as String? ?? url;
      ref.read(authControllerProvider.notifier).applyUser(user.applyImageUrl(savedUrl));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastPhotoUploaded)));
    } on ApiException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastUploadFailed)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastUploadFailed)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _savedValue(_EditField field) {
    return switch (field) {
      _EditField.name => _name,
      _EditField.phone => _phone,
      _EditField.plate => _plate,
      _EditField.vehicle => _vehicle,
    };
  }

  void _startEdit(_EditField field) {
    setState(() {
      _editing = field;
      _draft.text = _savedValue(field);
    });
  }

  void _cancelEdit() {
    setState(() {
      _editing = null;
      _draft.clear();
    });
  }

  Future<void> _saveField(_EditField field) async {
    final l10n = AppLocalizations.of(context);
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;

    final raw = _draft.text.trim();
    String? phoneToSave;
    switch (field) {
      case _EditField.name:
        if (raw.length < 2) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastProfileSaveFailed)));
          return;
        }
        break;
      case _EditField.phone:
        if (raw.isEmpty) {
          phoneToSave = '';
        } else {
          final normalized = normalizePhone(raw);
          if (normalized == null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastInvalidPhone)));
            return;
          }
          phoneToSave = normalized;
        }
        break;
      case _EditField.plate:
      case _EditField.vehicle:
        break;
    }

    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      if (field == _EditField.name || field == _EditField.phone) {
        final data = await api.updateMe(
          name: field == _EditField.name ? raw : null,
          phone: phoneToSave,
        );
        if (!mounted) return;
        final savedName = data['name'] as String? ?? _name;
        final savedPhone = data['phone'] as String?;
        setState(() {
          _name = savedName;
          _phone = savedPhone ?? '';
          _editing = null;
          _draft.clear();
        });
        ref.read(authControllerProvider.notifier).applyUser(
          user.applyProfile(name: savedName, phone: savedPhone),
        );
      } else {
        final driver = await api.updateMyDriverProfile(
          plateNo: field == _EditField.plate ? raw : null,
          vehicleType: field == _EditField.vehicle ? raw : null,
        );
        if (!mounted) return;
        setState(() {
          _plate = driver.plateNo ?? '';
          _vehicle = driver.vehicleType ?? '';
          _editing = null;
          _draft.clear();
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastProfileSaved)));
    } on ApiException catch (e) {
      if (!mounted) return;
      final message =
          e.code == 'invalidPhone' ? l10n.toastInvalidPhone : l10n.toastProfileSaveFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastProfileSaveFailed)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider).user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppHeader(
        title: l10n.profileTitle,
        showBack: true,
        onBack: () => context.go(widget.backPath),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _saving || _loading ? null : _changePhoto,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PersonAvatar(
                        imageUrl: user.imageUrl,
                        name: user.name,
                        radius: 32,
                        backgroundColor: const Color(0x26FFFFFF),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, size: 14, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                Text(user.email, style: const TextStyle(color: Color(0xCCFFFFFF))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _editableRow(
                  l10n: l10n,
                  icon: Icons.badge_outlined,
                  label: l10n.profileName,
                  value: _name,
                  field: _EditField.name,
                  first: true,
                ),
                _editableRow(
                  l10n: l10n,
                  icon: Icons.phone_outlined,
                  label: l10n.registerPhone,
                  value: _phone.isEmpty ? l10n.commonEmpty : _phone,
                  field: _EditField.phone,
                  hint: l10n.registerPhonePlaceholder,
                  keyboardType: TextInputType.phone,
                ),
                _viewRow(
                  icon: Icons.mail_outline,
                  label: l10n.profileEmail,
                  value: user.email,
                ),
                _viewRow(
                  icon: Icons.shield_outlined,
                  label: l10n.profileRole,
                  value: roleLabel(l10n, user.role),
                ),
                if (user.isBroker && user.agentId != null && user.agentId!.isNotEmpty)
                  _viewRow(
                    icon: Icons.fingerprint,
                    label: l10n.profileAgentId,
                    value: user.agentId!,
                    selectable: true,
                    trailing: IconButton(
                      tooltip: l10n.profileAgentIdCopied,
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: user.agentId!));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.profileAgentIdCopied)),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy, color: AppColors.secondary),
                    ),
                  ),
                if (user.isDriver) ...[
                  _editableRow(
                    l10n: l10n,
                    icon: Icons.pin_outlined,
                    label: l10n.registerPlateNo,
                    value: _plate.isEmpty ? l10n.commonEmpty : _plate,
                    field: _EditField.plate,
                    hint: l10n.registerPlatePlaceholder,
                  ),
                  _editableRow(
                    l10n: l10n,
                    icon: Icons.local_shipping_outlined,
                    label: l10n.registerVehicleType,
                    value: _vehicle.isEmpty ? l10n.commonEmpty : _vehicle,
                    field: _EditField.vehicle,
                    hint: l10n.registerVehiclePlaceholder,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.translate, color: AppColors.secondary),
                const SizedBox(width: 12),
                Text(l10n.languageLabel, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                const Spacer(),
                const LanguageSwitcher(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout, color: AppColors.error),
            label: Text(l10n.profileSignOut, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _editableRow({
    required AppLocalizations l10n,
    required IconData icon,
    required String label,
    required String value,
    required _EditField field,
    bool first = false,
    String? hint,
    TextInputType? keyboardType,
  }) {
    final editing = _editing == field;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: first ? null : const Border(top: BorderSide(color: Color(0x80C6C6CD))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.secondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                    if (!editing) Text(value, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              if (!editing)
                IconButton(
                  tooltip: l10n.commonEdit,
                  onPressed: _loading || _saving ? null : () => _startEdit(field),
                  icon: const Icon(Icons.edit_outlined, color: AppColors.secondary),
                ),
            ],
          ),
          if (editing) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _draft,
              autofocus: true,
              enabled: !_saving,
              keyboardType: keyboardType,
              decoration: InputDecoration(hintText: hint),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _cancelEdit,
                    child: Text(l10n.commonCancel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : () => _saveField(field),
                    child: Text(_saving ? l10n.commonLoading : l10n.commonSave),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _viewRow({
    required IconData icon,
    required String label,
    required String value,
    bool selectable = false,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x80C6C6CD))),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                if (selectable)
                  SelectableText(value, style: const TextStyle(fontSize: 16))
                else
                  Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
