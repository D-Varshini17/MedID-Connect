class Observation {
  const Observation({
    required this.id,
    required this.code,
    required this.display,
    required this.value,
    required this.unit,
    required this.effectiveDate,
    required this.referenceRangeLow,
    required this.referenceRangeHigh,
    required this.status,
  });

  final String id;
  final String code;
  final String display;
  final double value;
  final String unit;
  final DateTime effectiveDate;
  final double? referenceRangeLow;
  final double? referenceRangeHigh;
  final String status;

  bool get isInRange {
    final low = referenceRangeLow;
    final high = referenceRangeHigh;
    if (low == null || high == null) {
      return true;
    }
    return value >= low && value <= high;
  }
}
