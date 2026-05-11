class MedicationRequest {
  const MedicationRequest({
    required this.id,
    required this.medicationName,
    required this.dosageInstruction,
    required this.frequency,
    required this.prescriber,
    required this.status,
    required this.intent,
    required this.startDate,
    required this.endDate,
    required this.takenToday,
  });

  final String id;
  final String medicationName;
  final String dosageInstruction;
  final String frequency;
  final String prescriber;
  final String status;
  final String intent;
  final DateTime startDate;
  final DateTime? endDate;
  final bool takenToday;

  MedicationRequest copyWith({
    String? id,
    String? medicationName,
    String? dosageInstruction,
    String? frequency,
    String? prescriber,
    String? status,
    String? intent,
    DateTime? startDate,
    DateTime? endDate,
    bool? takenToday,
  }) {
    return MedicationRequest(
      id: id ?? this.id,
      medicationName: medicationName ?? this.medicationName,
      dosageInstruction: dosageInstruction ?? this.dosageInstruction,
      frequency: frequency ?? this.frequency,
      prescriber: prescriber ?? this.prescriber,
      status: status ?? this.status,
      intent: intent ?? this.intent,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      takenToday: takenToday ?? this.takenToday,
    );
  }
}
