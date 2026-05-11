enum MedicalEventType {
  visit,
  lab,
  medication,
  vaccine,
  condition,
}

class MedicalEvent {
  const MedicalEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.status,
  });

  final String id;
  final MedicalEventType type;
  final String title;
  final String subtitle;
  final DateTime date;
  final String status;
}
