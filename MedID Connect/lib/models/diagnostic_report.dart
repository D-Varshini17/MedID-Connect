class DiagnosticReport {
  const DiagnosticReport({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.issuedDate,
    required this.performer,
    required this.summary,
    required this.observationIds,
  });

  final String id;
  final String title;
  final String category;
  final String status;
  final DateTime issuedDate;
  final String performer;
  final String summary;
  final List<String> observationIds;
}
