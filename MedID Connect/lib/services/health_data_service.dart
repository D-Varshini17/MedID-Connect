import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/mock_fhir_data.dart';
import '../data/mock_fhir_json.dart';
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

class HealthDataService extends ChangeNotifier {
  Map<String, dynamic> get rawFhirBundle => MockFhirJson.bundle;

  Patient get patient => MockFhirData.patient;
  List<AllergyIntolerance> get allergies => MockFhirData.allergies;
  List<HealthCondition> get conditions => MockFhirData.conditions;
  List<Observation> get observations => MockFhirData.observations;
  List<DiagnosticReport> get diagnosticReports =>
      MockFhirData.diagnosticReports;
  List<Immunization> get immunizations => MockFhirData.immunizations;
  List<Appointment> get appointments => MockFhirData.appointments;
  List<MedicalEvent> get timeline => MockFhirData.timeline;
  List<HealthInsight> get insights => MockFhirData.insights;

  late List<MedicationRequest> _medications = List.of(MockFhirData.medications);

  List<MedicationRequest> get medications => List.unmodifiable(_medications);

  int get healthScore => patient.healthScore;

  int get activeMedicationCount {
    return _medications
        .where((medication) => medication.status == 'active')
        .length;
  }

  int get medicationsTakenToday {
    return _medications.where((medication) => medication.takenToday).length;
  }

  double get medicationAdherence {
    if (_medications.isEmpty) {
      return 0;
    }
    return medicationsTakenToday / _medications.length;
  }

  List<Observation> observationsByCode(String code) {
    final values =
        observations.where((observation) => observation.code == code).toList();
    values.sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));
    return values;
  }

  List<Observation> observationsForReport(DiagnosticReport report) {
    return observations
        .where((observation) => report.observationIds.contains(observation.id))
        .toList();
  }

  void toggleMedication(String id) {
    _medications = _medications.map((medication) {
      if (medication.id != id) {
        return medication;
      }
      return medication.copyWith(takenToday: !medication.takenToday);
    }).toList();
    notifyListeners();
  }

  String emergencyQrPayload() {
    final payload = {
      'app': 'MedID Connect',
      'resourceType': 'EmergencyAccess',
      'patient': {
        'id': patient.id,
        'name': patient.name,
        'age': patient.age,
        'bloodGroup': patient.bloodGroup,
        'gender': patient.gender,
      },
      'allergies': allergies
          .map((allergy) => {
                'code': allergy.code,
                'criticality': allergy.criticality,
                'reaction': allergy.reaction,
              })
          .toList(),
      'conditions': conditions
          .where((condition) => condition.clinicalStatus == 'active')
          .map((condition) => condition.name)
          .toList(),
      'medications': _medications
          .where((medication) => medication.status == 'active')
          .map((medication) => medication.medicationName)
          .toList(),
      'emergencyContact': {
        'name': patient.emergencyContactName,
        'phone': patient.emergencyContactPhone,
      },
      'note': 'Mock data only. Verify with patient and clinician.',
    };
    return jsonEncode(payload);
  }
}
