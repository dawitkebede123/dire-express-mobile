enum WeightUnit { quintal, kg }

/// 1 Ethiopian quintal = 100 kg.
double toQuintals(double value, WeightUnit unit) {
  return unit == WeightUnit.quintal ? value : value / 100;
}

double fromQuintals(double quintals, WeightUnit unit) {
  return unit == WeightUnit.quintal ? quintals : quintals * 100;
}

String formatWeightNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toStringAsFixed(1);
}
