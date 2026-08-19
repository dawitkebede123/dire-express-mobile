import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

String intlTag(Locale locale) => locale.languageCode == 'am' ? 'am_ET' : 'en_US';

String formatCurrency(num? amount, Locale locale) {
  if (amount == null) return '—';
  if (locale.languageCode == 'am') {
    return '${NumberFormat('#,##0.00', 'en').format(amount)} ብር';
  }
  return NumberFormat.currency(locale: 'en', name: 'ETB', symbol: 'ETB ').format(amount);
}

String compactCurrency(num amount, Locale locale) {
  if (amount >= 1000) {
    final compact = NumberFormat.compact(locale: 'en').format(amount);
    return locale.languageCode == 'am' ? '$compact ብር' : 'ETB $compact';
  }
  return formatCurrency(amount, locale);
}

String formatDayTime(DateTime date, AppLocalizations l10n, Locale locale) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final time = DateFormat.Hm(intlTag(locale)).format(date);
  final diff = target.difference(today).inDays;
  if (diff == 0) return l10n.formatToday(time);
  if (diff == 1) return l10n.formatTomorrow(time);
  if (diff == -1) return l10n.formatYesterday(time);
  return DateFormat('MMM d, HH:mm', intlTag(locale)).format(date);
}

String formatDateTime(DateTime date, Locale locale) {
  return DateFormat('MMM d, h:mm a', intlTag(locale)).format(date);
}

String shortAddress(String address) {
  final parts = address.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
  if (parts.length < 2) return address;
  final city = parts[parts.length - 2];
  final region = parts.last.replaceAll(RegExp(r'\s*\d{5}(-\d{4})?$'), '').trim();
  return region.isNotEmpty ? '$city, $region' : city;
}

String? formatWeight(double? lbs, AppLocalizations l10n) {
  if (lbs == null) return null;
  if (lbs >= 1000) {
    final k = (lbs / 1000).toStringAsFixed(lbs % 1000 == 0 ? 0 : 1);
    return l10n.weightLbs('${k}k');
  }
  return l10n.weightLbs(lbs.round().toString());
}

String statusLabel(AppLocalizations l10n, String status) {
  switch (status) {
    case 'PENDING':
      return l10n.statusPending;
    case 'CREATED':
      return l10n.statusCreated;
    case 'ASSIGNED':
      return l10n.statusAssigned;
    case 'ACCEPTED':
      return l10n.statusAccepted;
    case 'REJECTED':
      return l10n.statusRejected;
    case 'IN_TRANSIT':
      return l10n.statusInTransit;
    case 'DELIVERED':
      return l10n.statusDelivered;
    case 'CANCELLED':
      return l10n.statusCancelled;
    default:
      return status;
  }
}

String equipmentLabel(AppLocalizations l10n, String? type) {
  switch (type) {
    case 'DRY_VAN':
      return l10n.equipmentDryVan;
    case 'REEFER':
      return l10n.equipmentReefer;
    case 'FLATBED':
      return l10n.equipmentFlatbed;
    default:
      return l10n.equipmentFreight;
  }
}

IconData equipmentIcon(String? type) {
  switch (type) {
    case 'REEFER':
      return Icons.ac_unit;
    case 'FLATBED':
      return Icons.view_in_ar;
    default:
      return Icons.local_shipping_outlined;
  }
}

String roleLabel(AppLocalizations l10n, String role) {
  switch (role) {
    case 'BROKER':
      return l10n.roleBroker;
    case 'DRIVER':
      return l10n.roleDriver;
    case 'CUSTOMER':
      return l10n.roleCustomer;
    default:
      return role;
  }
}

String bannerForStatus(AppLocalizations l10n, String status) {
  switch (status) {
    case 'PENDING':
      return l10n.bannerPending;
    case 'CREATED':
      return l10n.bannerCreated;
    case 'ASSIGNED':
      return l10n.bannerAssigned;
    case 'ACCEPTED':
      return l10n.bannerAccepted;
    case 'IN_TRANSIT':
      return l10n.bannerInTransit;
    case 'DELIVERED':
      return l10n.bannerDelivered;
    case 'REJECTED':
      return l10n.bannerRejected;
    case 'CANCELLED':
      return l10n.bannerCancelled;
    default:
      return l10n.customerTrackingFallback;
  }
}

int trackingStepIndex(String status) {
  switch (status) {
    case 'PENDING':
    case 'CREATED':
    case 'CANCELLED':
      return 0;
    case 'ASSIGNED':
    case 'ACCEPTED':
    case 'REJECTED':
      return 1;
    case 'IN_TRANSIT':
      return 2;
    case 'DELIVERED':
      return 3;
    default:
      return 0;
  }
}
