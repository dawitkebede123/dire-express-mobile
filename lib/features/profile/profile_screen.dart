import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/phone.dart';
import '../../features/auth/auth_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/format.dart';
import '../../shared/media/avatar_image.dart';
import '../../shared/weight_unit.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/equipment_thumb.dart';
import '../../shared/widgets/language_switcher.dart';
import '../../shared/widgets/person_avatar.dart';
import '../../shared/widgets/truck_thumb.dart';
import '../../shared/widgets/weight_input_row.dart';
import '../../theme/app_theme.dart';
import '../maps/offline_maps_screen.dart';
import 'avatar_crop_page.dart';
import 'profile_more_screen.dart';

enum _EditField { name, phone, company, plate, vehicle, capacity }

const _equipmentTypes = ['DRY_VAN', 'REEFER', 'FLATBED', 'LOW_BED'];

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
  var _company = '';
  var _plate = '';
  var _vehicle = 'DRY_VAN';
  var _loadingCapacity = '';
  var _capacityUnit = WeightUnit.quintal;
  String? _truckImageUrl;
  var _isAvailable = true;
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
      _company = user.company ?? '';
      _plate = user.plateNo ?? '';
      _vehicle = user.vehicleType ?? 'DRY_VAN';
      _loadingCapacity = user.loadingCapacity?.round().toString() ?? '';
      _truckImageUrl = user.truckImageUrl;
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
    final currentUser = ref.read(authControllerProvider).user;
    final isDriver = currentUser?.isDriver == true;
    final isCustomer = currentUser?.isCustomer == true;
    try {
      final user = await api.getMeProfile();
      String plate = '';
      String vehicle = '';
      double? loadingCapacity;
      String? truckImageUrl;
      String? companyFromRole;
      if (isDriver) {
        try {
          final driver = await api.getMyDriverProfile();
          plate = driver.plateNo ?? '';
          vehicle = driver.vehicleType ?? '';
          loadingCapacity = driver.loadingCapacity;
          truckImageUrl = driver.truckImageUrl;
          if (mounted) setState(() => _isAvailable = driver.isAvailable);
        } catch (_) {}
        if (plate.isEmpty) {
          plate = user['plateNo']?.toString().trim() ??
              user['plateNumber']?.toString().trim() ??
              '';
        }
        if (vehicle.isEmpty) {
          vehicle = user['vehicleType']?.toString().trim() ?? '';
        }
        loadingCapacity ??= (user['loadingCapacity'] is num)
            ? (user['loadingCapacity'] as num).toDouble()
            : double.tryParse(user['loadingCapacity']?.toString() ?? '');
        truckImageUrl ??= user['truckImageUrl']?.toString().trim();
      }
      if (isCustomer) {
        try {
          final customer = await api.getMyCustomerProfile();
          companyFromRole = customer.company;
        } catch (_) {}
      }
      if (!mounted) return;
      final current = ref.read(authControllerProvider).user;
      final savedName = user['name'] is String ? user['name'] as String : _name;
      final rawPhone = user['phone']?.toString().trim();
      final savedPhone = (rawPhone != null && rawPhone.isNotEmpty)
          ? rawPhone
          : (current?.phone?.trim().isNotEmpty == true ? current!.phone : (_phone.isNotEmpty ? _phone : null));
      final nestedCustomer = user['customer'];
      final nestedCompany = nestedCustomer is Map ? nestedCustomer['company']?.toString().trim() : null;
      final rawCompany = user['company']?.toString().trim();
      final savedCompany = [
        companyFromRole,
        (rawCompany != null && rawCompany.isNotEmpty) ? rawCompany : null,
        (nestedCompany != null && nestedCompany.isNotEmpty) ? nestedCompany : null,
        current?.company,
        _company.isNotEmpty ? _company : null,
      ].map((v) => v?.trim()).firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
      final savedImage = user['imageUrl'] as String?;
      final rawAgentId = user['agentId']?.toString().trim();
      final savedAgentId = (rawAgentId != null && rawAgentId.isNotEmpty)
          ? rawAgentId
          : current?.agentId;
      setState(() {
        _name = savedName;
        _phone = savedPhone ?? '';
        _company = savedCompany ?? '';
        _plate = plate.isNotEmpty ? plate : (_plate.isNotEmpty ? _plate : (current?.plateNo ?? ''));
        _vehicle = vehicle.isNotEmpty ? vehicle : (_vehicle.isNotEmpty ? _vehicle : (current?.vehicleType ?? 'DRY_VAN'));
        _loadingCapacity = loadingCapacity != null
            ? loadingCapacity.round().toString()
            : (_loadingCapacity.isNotEmpty ? _loadingCapacity : (current?.loadingCapacity?.round().toString() ?? ''));
        _truckImageUrl = (truckImageUrl != null && truckImageUrl.isNotEmpty)
            ? truckImageUrl
            : (current?.truckImageUrl ?? _truckImageUrl);
      });
      if (current != null) {
        final next = current
            .applyProfile(
              name: savedName,
              phone: savedPhone,
              company: savedCompany,
              plateNo: _plate.isNotEmpty ? _plate : current.plateNo,
              vehicleType: _vehicle.isNotEmpty ? _vehicle : current.vehicleType,
              loadingCapacity: double.tryParse(_loadingCapacity) ?? current.loadingCapacity,
              truckImageUrl: _truckImageUrl ?? current.truckImageUrl,
              agentId: savedAgentId,
            )
            .applyImageUrl(savedImage);
        if (next.name != current.name ||
            next.phone != current.phone ||
            next.company != current.company ||
            next.plateNo != current.plateNo ||
            next.vehicleType != current.vehicleType ||
            next.loadingCapacity != current.loadingCapacity ||
            next.truckImageUrl != current.truckImageUrl ||
            next.agentId != current.agentId ||
            next.imageUrl != current.imageUrl) {
          ref.read(authControllerProvider.notifier).applyUser(next);
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setAvailability(bool value) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final previous = _isAvailable;
    setState(() {
      _isAvailable = value;
      _saving = true;
    });
    try {
      final driver = await ref.read(apiClientProvider).updateMyDriverProfile(isAvailable: value);
      if (!mounted || !context.mounted) return;
      setState(() => _isAvailable = driver.isAvailable);
      messenger?.showSnackBar(SnackBar(content: Text(l10n.toastProfileSaved)));
    } catch (_) {
      if (!mounted || !context.mounted) return;
      setState(() => _isAvailable = previous);
      messenger?.showSnackBar(SnackBar(content: Text(l10n.toastProfileSaveFailed)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _previewPhoto(String imageUrl) {
    final url = AppConfig.resolveMediaUrl(imageUrl);
    if (url == null) return;
    final l10n = AppLocalizations.of(context);

    showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (dialogContext) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pop(dialogContext),
                ),
              ),
              Center(
                child: InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                    fadeInDuration: const Duration(milliseconds: 150),
                    errorWidget: (_, _, _) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.toastUploadFailed)),
                        );
                      });
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _changeTruckPhoto() async {
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

    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;

      final user = ref.read(authControllerProvider).user;
      if (user == null) return;

      setState(() => _saving = true);
      final api = ref.read(apiClientProvider);
      final url = await api.uploadFile(file.path, kind: 'truck');
      final driver = await api.updateMyDriverProfile(truckImageUrl: url);
      if (!mounted) return;
      final savedUrl = driver.truckImageUrl ?? url;
      setState(() => _truckImageUrl = savedUrl);
      ref.read(authControllerProvider.notifier).applyUser(
        user.applyProfile(
          name: user.name,
          phone: user.phone,
          truckImageUrl: savedUrl,
        ),
      );
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

    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;

      final originalBytes = await file.readAsBytes();
      if (!mounted) return;
      final croppedBytes = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(builder: (_) => AvatarCropPage(imageBytes: originalBytes)),
      );
      if (croppedBytes == null || !mounted) return;

      final user = ref.read(authControllerProvider).user;
      if (user == null) return;

      final jpegBytes = compressAvatar(croppedBytes);
      final croppedFile = File(
        p.join(Directory.systemTemp.path, 'avatar-${DateTime.now().millisecondsSinceEpoch}.jpg'),
      );
      await croppedFile.writeAsBytes(jpegBytes, flush: true);

      setState(() => _saving = true);
      final api = ref.read(apiClientProvider);
      final url = await api.uploadFile(croppedFile.path, kind: 'avatar');
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
      _EditField.company => _company,
      _EditField.plate => _plate,
      _EditField.vehicle => _vehicle,
      _EditField.capacity => _loadingCapacity,
    };
  }

  void _startEdit(_EditField field) {
    setState(() {
      _editing = field;
      if (field == _EditField.capacity) {
        final quintals = double.tryParse(_loadingCapacity);
        _draft.text = quintals == null
            ? ''
            : formatWeightNumber(fromQuintals(quintals, _capacityUnit));
      } else {
        _draft.text = _savedValue(field);
      }
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
      case _EditField.company:
      case _EditField.plate:
      case _EditField.vehicle:
      case _EditField.capacity:
        break;
    }

    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      if (field == _EditField.name || field == _EditField.phone || field == _EditField.company) {
        final data = await api.updateMe(
          name: field == _EditField.name ? raw : null,
          phone: phoneToSave,
          company: field == _EditField.company ? raw : null,
        );
        if (field == _EditField.company && user.isCustomer) {
          try {
            await api.updateMyCustomerProfile(company: raw);
          } catch (_) {}
        }
        if (!mounted) return;
        final savedName = data['name'] as String? ?? _name;
        final savedPhone = data['phone'] as String?;
        final savedCompany = data['company'] as String? ?? (field == _EditField.company ? raw : _company);
        setState(() {
          _name = savedName;
          _phone = savedPhone ?? _phone;
          _company = savedCompany;
          _editing = null;
          _draft.clear();
        });
        ref.read(authControllerProvider.notifier).applyUser(
          user.applyProfile(name: savedName, phone: savedPhone ?? user.phone, company: savedCompany),
        );
      } else {
        final capacityValue = field == _EditField.capacity
            ? (raw.isEmpty
                ? null
                : () {
                    final parsed = double.tryParse(raw);
                    return parsed == null ? null : toQuintals(parsed, _capacityUnit);
                  }())
            : null;
        if (field == _EditField.capacity && raw.isNotEmpty && capacityValue == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastProfileSaveFailed)));
          return;
        }
        final driver = await api.updateMyDriverProfile(
          plateNo: field == _EditField.plate ? raw : null,
          vehicleType: field == _EditField.vehicle ? raw : null,
          loadingCapacity: field == _EditField.capacity ? capacityValue : null,
        );
        if (!mounted) return;
        final savedPlate = (driver.plateNo != null && driver.plateNo!.trim().isNotEmpty)
            ? driver.plateNo!.trim()
            : (field == _EditField.plate ? raw : _plate);
        final savedVehicle = (driver.vehicleType != null && driver.vehicleType!.trim().isNotEmpty)
            ? driver.vehicleType!.trim()
            : (field == _EditField.vehicle ? raw : _vehicle);
        final savedCapacity = driver.loadingCapacity ?? capacityValue;
        setState(() {
          _plate = savedPlate;
          _vehicle = savedVehicle;
          if (savedCapacity != null) {
            _loadingCapacity = savedCapacity.round().toString();
          } else if (field == _EditField.capacity) {
            _loadingCapacity = raw;
          }
          _editing = null;
          _draft.clear();
        });
        ref.read(authControllerProvider.notifier).applyUser(
          user.applyProfile(
            name: user.name,
            phone: user.phone,
            plateNo: savedPlate.isNotEmpty ? savedPlate : user.plateNo,
            vehicleType: savedVehicle.isNotEmpty ? savedVehicle : user.vehicleType,
            loadingCapacity: savedCapacity ?? user.loadingCapacity,
            truckImageUrl: driver.truckImageUrl ?? user.truckImageUrl,
          ),
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastProfileSaved)));
    } on ApiException catch (e) {
      if (!mounted) return;
      final message = switch (e.code) {
        'phoneRegistered' => l10n.toastPhoneRegistered,
        'invalidPhone' => l10n.toastInvalidPhone,
        _ => l10n.toastProfileSaveFailed,
      };
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
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(widget.backPath);
          }
        },
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
                Stack(
                  alignment: Alignment.center,
                  children: [
                    GestureDetector(
                      onTap: _saving || _loading
                          ? null
                          : () {
                              final photo = user.imageUrl?.trim();
                              if (photo != null && photo.isNotEmpty) {
                                _previewPhoto(photo);
                              } else {
                                _changePhoto();
                              }
                            },
                      child: PersonAvatar(
                        imageUrl: user.imageUrl,
                        name: user.name,
                        radius: 32,
                        backgroundColor: const Color(0x26FFFFFF),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _saving || _loading ? null : _changePhoto,
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.camera_alt, size: 14, color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                Text(
                  user.email.isEmpty ? l10n.commonEmpty : user.email,
                  style: const TextStyle(color: Color(0xCCFFFFFF)),
                ),
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
                  keyboardType: TextInputType.phone,
                ),
                if (user.isCustomer || user.isBroker)
                  _editableRow(
                    l10n: l10n,
                    icon: Icons.apartment_outlined,
                    label: l10n.registerCompany,
                    value: _company.isEmpty ? l10n.commonEmpty : _company,
                    field: _EditField.company,
                  ),
                _viewRow(
                  icon: Icons.mail_outline,
                  label: l10n.profileEmail,
                  value: user.email.isEmpty ? l10n.commonEmpty : user.email,
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
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const Icon(Icons.local_shipping_outlined, color: AppColors.secondary),
                    title: Text(l10n.profileTruckPhoto, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                    subtitle: Text(l10n.profileTruckPhotoHint),
                    trailing: TruckThumb(
                      truckImageUrl: _truckImageUrl,
                      vehicleType: _vehicle,
                      size: 48,
                    ),
                    onTap: _loading || _saving ? null : _changeTruckPhoto,
                  ),
                  _editableRow(
                    l10n: l10n,
                    icon: Icons.pin_outlined,
                    label: l10n.registerPlateNo,
                    value: _plate.isEmpty ? l10n.commonEmpty : _plate,
                    field: _EditField.plate,
                  ),
                  _vehicleRow(l10n),
                  _capacityRow(l10n),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    secondary: const Icon(Icons.toggle_on_outlined, color: AppColors.secondary),
                    title: Text(
                      _isAvailable
                          ? l10n.driverAvailabilityAvailable
                          : l10n.driverAvailabilityUnavailable,
                    ),
                    subtitle: Text(l10n.driverAvailabilityHint, style: const TextStyle(fontSize: 12)),
                    value: _isAvailable,
                    onChanged: _loading || _saving ? null : _setAvailability,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.more_horiz, color: AppColors.secondary),
            title: Text(l10n.profileMore),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ProfileMoreScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.map_outlined, color: AppColors.secondary),
            title: Text(l10n.offlineMapsTitle),
            subtitle: Text(l10n.offlineMapsHint, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const OfflineMapsScreen()),
              );
            },
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

  Widget _editTextButton(AppLocalizations l10n, VoidCallback? onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.secondary,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(l10n.commonEdit),
    );
  }

  Widget _capacityRow(AppLocalizations l10n) {
    final editing = _editing == _EditField.capacity;
    final quintals = double.tryParse(_loadingCapacity);
    final display = quintals == null
        ? l10n.commonEmpty
        : (formatWeightValue(quintals, l10n, WeightUnit.quintal) ?? l10n.commonEmpty);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x80C6C6CD))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.scale_outlined, color: AppColors.secondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.profileLoadingCapacity, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                    if (!editing) Text(display, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              if (!editing)
                _editTextButton(
                  l10n,
                  _loading || _saving ? null : () => _startEdit(_EditField.capacity),
                ),
            ],
          ),
          if (editing) ...[
            const SizedBox(height: 8),
            WeightInputRow(
              controller: _draft,
              unit: _capacityUnit,
              onUnitChanged: (unit) => setState(() => _capacityUnit = unit),
              label: l10n.profileLoadingCapacity,
              enabled: !_saving,
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
                    onPressed: _saving ? null : () => _saveField(_EditField.capacity),
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

  Widget _vehicleRow(AppLocalizations l10n) {
    final editing = _editing == _EditField.vehicle;
    final label = equipmentLabel(l10n, _vehicle);
    final selected = _draft.text.isNotEmpty ? _draft.text : _vehicle;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x80C6C6CD))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined, color: AppColors.secondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.registerVehicleType, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                    if (!editing)
                      EquipmentLabelRow(type: _vehicle, label: label, thumbSize: 28),
                  ],
                ),
              ),
              if (!editing)
                _editTextButton(
                  l10n,
                  _loading || _saving ? null : () => _startEdit(_EditField.vehicle),
                ),
            ],
          ),
          if (editing) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _equipmentTypes.contains(selected) ? selected : 'DRY_VAN',
              decoration: const InputDecoration(),
              items: _equipmentTypes
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: EquipmentLabelRow(
                        type: type,
                        label: equipmentLabel(l10n, type),
                        thumbSize: 28,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => _draft.text = value);
                    },
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
                    onPressed: _saving
                        ? null
                        : () {
                            final selected = _draft.text.trim().isNotEmpty ? _draft.text.trim() : _vehicle;
                            _draft.text = selected;
                            _saveField(_EditField.vehicle);
                          },
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

  Widget _editableRow({
    required AppLocalizations l10n,
    required IconData icon,
    required String label,
    required String value,
    required _EditField field,
    bool first = false,
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
                _editTextButton(
                  l10n,
                  _loading || _saving ? null : () => _startEdit(field),
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
