class Immunization {
  const Immunization({
    required this.id,
    required this.vaccineCode,
    required this.status,
    required this.occurrenceDate,
    required this.performer,
    required this.lotNumber,
  });

  final String id;
  final String vaccineCode;
  final String status;
  final DateTime occurrenceDate;
  final String performer;
  final String lotNumber;
}
