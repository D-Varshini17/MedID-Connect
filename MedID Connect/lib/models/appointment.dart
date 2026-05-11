class Appointment {
  const Appointment({
    required this.id,
    required this.title,
    required this.practitioner,
    required this.location,
    required this.dateTime,
    required this.status,
  });

  final String id;
  final String title;
  final String practitioner;
  final String location;
  final DateTime dateTime;
  final String status;
}
