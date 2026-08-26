import '../core/config.dart';

class SystemPricing {
  static double get basePriceEtb => AppConfig.basePrice;
  static double get perKmEtb => AppConfig.pricePerKm;

  static String formatNumber(double value, {int maxFractionDigits = 1}) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(maxFractionDigits);
  }

  static String formatKm(double distanceKm) {
    if (distanceKm <= 0) return '0';
    return formatNumber(distanceKm);
  }

  /// Platform fee: basePrice + pricePerKm × distanceKm from GET /api/config.
  static double calculate(double distanceKm) {
    final km = distanceKm < 0 ? 0.0 : distanceKm;
    return basePriceEtb + perKmEtb * km;
  }
}

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeName,
    required this.lat,
    required this.lng,
  });

  final String placeName;
  final double lat;
  final double lng;
}
