class AllergyIntolerance {
  const AllergyIntolerance({
    required this.id,
    required this.code,
    required this.clinicalStatus,
    required this.criticality,
    required this.reaction,
    required this.recordedDate,
  });

  final String id;
  final String code;
  final String clinicalStatus;
  final String criticality;
  final String reaction;
  final DateTime recordedDate;
}
