import '../models/allergy_intolerance.dart';
import '../models/appointment.dart';
import '../models/condition.dart';
import '../models/diagnostic_report.dart';
import '../models/health_insight.dart';
import '../models/immunization.dart';
import '../models/medical_event.dart';
import '../models/medication_request.dart';
import '../models/observation.dart';
import '../models/patient.dart';

class MockFhirData {
  static final Patient patient = Patient(
    id: 'Patient/pat-1001',
    name: 'Aarav Mehta',
    age: 34,
    gender: 'Male',
    birthDate: DateTime(1991, 8, 22),
    bloodGroup: 'O+',
    phone: '+91 98765 43210',
    email: 'aarav.mehta@example.com',
    address: 'Bandra West, Mumbai, Maharashtra',
    emergencyContactName: 'Nisha Mehta',
    emergencyContactPhone: '+91 99887 77665',
    healthScore: 88,
  );

  static final List<AllergyIntolerance> allergies = [
    AllergyIntolerance(
      id: 'AllergyIntolerance/alg-101',
      code: 'Penicillin',
      clinicalStatus: 'active',
      criticality: 'high',
      reaction: 'Hives and facial swelling',
      recordedDate: DateTime(2021, 4, 12),
    ),
    AllergyIntolerance(
      id: 'AllergyIntolerance/alg-102',
      code: 'Peanuts',
      clinicalStatus: 'active',
      criticality: 'moderate',
      reaction: 'Throat irritation',
      recordedDate: DateTime(2022, 10, 4),
    ),
  ];

  static final List<HealthCondition> conditions = [
    HealthCondition(
      id: 'Condition/con-201',
      name: 'Mild hypertension',
      clinicalStatus: 'active',
      verificationStatus: 'confirmed',
      severity: 'mild',
      onsetDate: DateTime(2023, 3, 8),
      notes: 'Controlled with medication and low-sodium diet.',
    ),
    HealthCondition(
      id: 'Condition/con-202',
      name: 'Seasonal allergic rhinitis',
      clinicalStatus: 'active',
      verificationStatus: 'confirmed',
      severity: 'mild',
      onsetDate: DateTime(2019, 7, 14),
      notes: 'Usually flares during monsoon season.',
    ),
  ];

  static final List<MedicationRequest> medications = [
    MedicationRequest(
      id: 'MedicationRequest/med-301',
      medicationName: 'Amlodipine 5 mg',
      dosageInstruction: 'Take one tablet after breakfast',
      frequency: 'Daily',
      prescriber: 'Dr. Kavya Rao',
      status: 'active',
      intent: 'order',
      startDate: DateTime(2023, 3, 12),
      endDate: null,
      takenToday: true,
    ),
    MedicationRequest(
      id: 'MedicationRequest/med-302',
      medicationName: 'Cetirizine 10 mg',
      dosageInstruction: 'Take one tablet at night when symptoms appear',
      frequency: 'As needed',
      prescriber: 'Dr. Anil Shah',
      status: 'active',
      intent: 'order',
      startDate: DateTime(2024, 6, 5),
      endDate: null,
      takenToday: false,
    ),
    MedicationRequest(
      id: 'MedicationRequest/med-303',
      medicationName: 'Vitamin D3 1000 IU',
      dosageInstruction: 'Take one capsule with lunch',
      frequency: 'Daily',
      prescriber: 'Dr. Kavya Rao',
      status: 'active',
      intent: 'order',
      startDate: DateTime(2025, 1, 10),
      endDate: DateTime(2026, 7, 10),
      takenToday: false,
    ),
  ];

  static final List<Observation> observations = [
    Observation(
      id: 'Observation/obs-401',
      code: '8480-6',
      display: 'Systolic blood pressure',
      value: 124,
      unit: 'mmHg',
      effectiveDate: DateTime(2026, 4, 1),
      referenceRangeLow: 90,
      referenceRangeHigh: 120,
      status: 'final',
    ),
    Observation(
      id: 'Observation/obs-402',
      code: '8480-6',
      display: 'Systolic blood pressure',
      value: 121,
      unit: 'mmHg',
      effectiveDate: DateTime(2026, 4, 8),
      referenceRangeLow: 90,
      referenceRangeHigh: 120,
      status: 'final',
    ),
    Observation(
      id: 'Observation/obs-403',
      code: '8480-6',
      display: 'Systolic blood pressure',
      value: 118,
      unit: 'mmHg',
      effectiveDate: DateTime(2026, 4, 15),
      referenceRangeLow: 90,
      referenceRangeHigh: 120,
      status: 'final',
    ),
    Observation(
      id: 'Observation/obs-404',
      code: '8480-6',
      display: 'Systolic blood pressure',
      value: 116,
      unit: 'mmHg',
      effectiveDate: DateTime(2026, 4, 22),
      referenceRangeLow: 90,
      referenceRangeHigh: 120,
      status: 'final',
    ),
    Observation(
      id: 'Observation/obs-405',
      code: '2093-3',
      display: 'Total cholesterol',
      value: 198,
      unit: 'mg/dL',
      effectiveDate: DateTime(2026, 1, 20),
      referenceRangeLow: 120,
      referenceRangeHigh: 200,
      status: 'final',
    ),
    Observation(
      id: 'Observation/obs-406',
      code: '2093-3',
      display: 'Total cholesterol',
      value: 192,
      unit: 'mg/dL',
      effectiveDate: DateTime(2026, 2, 20),
      referenceRangeLow: 120,
      referenceRangeHigh: 200,
      status: 'final',
    ),
    Observation(
      id: 'Observation/obs-407',
      code: '2093-3',
      display: 'Total cholesterol',
      value: 188,
      unit: 'mg/dL',
      effectiveDate: DateTime(2026, 3, 20),
      referenceRangeLow: 120,
      referenceRangeHigh: 200,
      status: 'final',
    ),
    Observation(
      id: 'Observation/obs-408',
      code: '2093-3',
      display: 'Total cholesterol',
      value: 184,
      unit: 'mg/dL',
      effectiveDate: DateTime(2026, 4, 20),
      referenceRangeLow: 120,
      referenceRangeHigh: 200,
      status: 'final',
    ),
    Observation(
      id: 'Observation/obs-409',
      code: '2339-0',
      display: 'Fasting glucose',
      value: 97,
      unit: 'mg/dL',
      effectiveDate: DateTime(2026, 1, 20),
      referenceRangeLow: 70,
      referenceRangeHigh: 99,
      status: 'final',
    ),
    Observation(
      id: 'Observation/obs-410',
      code: '2339-0',
      display: 'Fasting glucose',
      value: 95,
      unit: 'mg/dL',
      effectiveDate: DateTime(2026, 2, 20),
      referenceRangeLow: 70,
      referenceRangeHigh: 99,
      status: 'final',
    ),
    Observation(
      id: 'Observation/obs-411',
      code: '2339-0',
      display: 'Fasting glucose',
      value: 93,
      unit: 'mg/dL',
      effectiveDate: DateTime(2026, 3, 20),
      referenceRangeLow: 70,
      referenceRangeHigh: 99,
      status: 'final',
    ),
    Observation(
      id: 'Observation/obs-412',
      code: '2339-0',
      display: 'Fasting glucose',
      value: 92,
      unit: 'mg/dL',
      effectiveDate: DateTime(2026, 4, 20),
      referenceRangeLow: 70,
      referenceRangeHigh: 99,
      status: 'final',
    ),
    Observation(
      id: 'Observation/obs-413',
      code: '4548-4',
      display: 'HbA1c',
      value: 5.5,
      unit: '%',
      effectiveDate: DateTime(2026, 4, 20),
      referenceRangeLow: 4,
      referenceRangeHigh: 5.7,
      status: 'final',
    ),
    Observation(
      id: 'Observation/obs-414',
      code: '8867-4',
      display: 'Heart rate',
      value: 78,
      unit: 'bpm',
      effectiveDate: DateTime(2026, 4, 1),
      referenceRangeLow: 60,
      referenceRangeHigh: 100,
      status: 'final',
    ),
    Observation(
      id: 'Observation/obs-415',
      code: '8867-4',
      display: 'Heart rate',
      value: 75,
      unit: 'bpm',
      effectiveDate: DateTime(2026, 4, 8),
      referenceRangeLow: 60,
      referenceRangeHigh: 100,
      status: 'final',
    ),
    Observation(
      id: 'Observation/obs-416',
      code: '8867-4',
      display: 'Heart rate',
      value: 74,
      unit: 'bpm',
      effectiveDate: DateTime(2026, 4, 15),
      referenceRangeLow: 60,
      referenceRangeHigh: 100,
      status: 'final',
    ),
    Observation(
      id: 'Observation/obs-417',
      code: '8867-4',
      display: 'Heart rate',
      value: 72,
      unit: 'bpm',
      effectiveDate: DateTime(2026, 4, 22),
      referenceRangeLow: 60,
      referenceRangeHigh: 100,
      status: 'final',
    ),
  ];

  static final List<DiagnosticReport> diagnosticReports = [
    DiagnosticReport(
      id: 'DiagnosticReport/dr-501',
      title: 'Annual wellness panel',
      category: 'Laboratory',
      status: 'final',
      issuedDate: DateTime(2026, 4, 20),
      performer: 'Apollo Diagnostics',
      summary: 'Metabolic markers are stable. Lipids and glucose are in range.',
      observationIds: [
        'Observation/obs-408',
        'Observation/obs-412',
        'Observation/obs-413'
      ],
    ),
    DiagnosticReport(
      id: 'DiagnosticReport/dr-502',
      title: 'Blood pressure review',
      category: 'Vital signs',
      status: 'final',
      issuedDate: DateTime(2026, 4, 22),
      performer: 'MedID Connect Remote Monitor',
      summary: 'Systolic trend improved over the last four readings.',
      observationIds: [
        'Observation/obs-401',
        'Observation/obs-402',
        'Observation/obs-403',
        'Observation/obs-404',
        'Observation/obs-417',
      ],
    ),
  ];

  static final List<Appointment> appointments = [
    Appointment(
      id: 'Appointment/app-701',
      title: 'Cardiology follow-up',
      practitioner: 'Dr. Kavya Rao',
      location: 'Apollo Heart Center',
      dateTime: DateTime(2026, 5, 18, 10, 30),
      status: 'booked',
    ),
    Appointment(
      id: 'Appointment/app-702',
      title: 'Wellness panel review',
      practitioner: 'Dr. Anil Shah',
      location: 'MedID Virtual Care',
      dateTime: DateTime(2026, 5, 24, 17),
      status: 'scheduled',
    ),
  ];

  static final List<Immunization> immunizations = [
    Immunization(
      id: 'Immunization/imm-601',
      vaccineCode: 'Influenza quadrivalent',
      status: 'completed',
      occurrenceDate: DateTime(2025, 11, 8),
      performer: 'City Care Clinic',
      lotNumber: 'FLU-25-MH-771',
    ),
    Immunization(
      id: 'Immunization/imm-602',
      vaccineCode: 'COVID-19 booster',
      status: 'completed',
      occurrenceDate: DateTime(2025, 2, 16),
      performer: 'BMC Health Center',
      lotNumber: 'C19-BST-4412',
    ),
  ];

  static final List<MedicalEvent> timeline = [
    MedicalEvent(
      id: 'event-1',
      type: MedicalEventType.lab,
      title: 'Annual wellness panel',
      subtitle: 'DiagnosticReport/dr-501 from Apollo Diagnostics',
      date: DateTime(2026, 4, 20),
      status: 'final',
    ),
    MedicalEvent(
      id: 'event-2',
      type: MedicalEventType.visit,
      title: 'Primary care follow-up',
      subtitle: 'Blood pressure reviewed, medication continued',
      date: DateTime(2026, 3, 28),
      status: 'completed',
    ),
    MedicalEvent(
      id: 'event-3',
      type: MedicalEventType.medication,
      title: 'Amlodipine 5 mg prescribed',
      subtitle: 'MedicationRequest/med-301 by Dr. Kavya Rao',
      date: DateTime(2023, 3, 12),
      status: 'active',
    ),
    MedicalEvent(
      id: 'event-4',
      type: MedicalEventType.vaccine,
      title: 'Influenza vaccination',
      subtitle: 'Immunization/imm-601 at City Care Clinic',
      date: DateTime(2025, 11, 8),
      status: 'completed',
    ),
    MedicalEvent(
      id: 'event-5',
      type: MedicalEventType.condition,
      title: 'Mild hypertension confirmed',
      subtitle: 'Condition/con-201 marked active',
      date: DateTime(2023, 3, 8),
      status: 'confirmed',
    ),
  ];

  static final List<HealthInsight> insights = [
    const HealthInsight(
      id: 'insight-1',
      title: 'Blood pressure is trending down',
      description:
          'The last four systolic readings moved from 124 to 116 mmHg, suggesting improved control.',
      recommendation:
          'Keep logging readings twice a week and continue the medication schedule unless your doctor changes it.',
      confidence: 0.89,
      category: 'Cardio',
    ),
    const HealthInsight(
      id: 'insight-2',
      title: 'Possible medication interaction',
      description:
          'Cetirizine can increase drowsiness when combined with alcohol or other sedating medicines.',
      recommendation:
          'Avoid sedating combinations and confirm your complete medication list with a clinician.',
      confidence: 0.78,
      category: 'Safety',
    ),
    const HealthInsight(
      id: 'insight-3',
      title: 'Lab markers look stable',
      description:
          'Glucose, HbA1c, and cholesterol are currently within the mock reference ranges.',
      recommendation:
          'Repeat the wellness panel at the interval recommended by your clinician.',
      confidence: 0.86,
      category: 'Labs',
    ),
    const HealthInsight(
      id: 'insight-4',
      title: 'Sleep quality decreased',
      description:
          'Mock wearable observations show shorter sleep duration over the last three nights.',
      recommendation:
          'Try a fixed sleep window and reduce screens during the last hour before bed.',
      confidence: 0.74,
      category: 'Recovery',
    ),
  ];
}
