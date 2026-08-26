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
