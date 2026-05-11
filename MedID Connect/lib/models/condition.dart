class HealthCondition {
  const HealthCondition({
    required this.id,
    required this.name,
    required this.clinicalStatus,
    required this.verificationStatus,
    required this.severity,
    required this.onsetDate,
    required this.notes,
  });

  final String id;
  final String name;
  final String clinicalStatus;
  final String verificationStatus;
  final String severity;
  final DateTime onsetDate;
  final String notes;
}
