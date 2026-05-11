import '../models/diagnostic_report.dart';
import '../models/health_insight.dart';
import '../models/medication_request.dart';
import '../models/observation.dart';
import '../models/patient.dart';
import '../services/api_client.dart';
import '../services/emergency_service.dart';
import '../services/health_data_service.dart';
import '../services/insight_service.dart';
import '../services/medical_record_service.dart';
import '../services/medication_service.dart';
import '../services/observation_service.dart';
import '../services/user_profile_service.dart';

class HealthDataProvider extends HealthDataService {
  HealthDataProvider({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  bool isLoadingRemote = false;
  bool usingBackend = false;
  String? remoteError;
  Map<String, dynamic>? emergencyToken;
  List<Map<String, dynamic>> medicalRecords = [];
  List<Map<String, dynamic>> medicationSafetyWarnings = [];

  Patient? _remotePatient;
  List<MedicationRequest>? _remoteMedications;
  List<Observation>? _remoteObservations;
  List<DiagnosticReport>? _remoteReports;
  List<HealthInsight>? _remoteInsights;

  UserProfileService get _profileService => UserProfileService(_apiClient);
  MedicationService get _medicationService => MedicationService(_apiClient);
  ObservationService get _observationService => ObservationService(_apiClient);
  MedicalRecordService get _recordService => MedicalRecordService(_apiClient);
  EmergencyService get _emergencyService => EmergencyService(_apiClient);
  InsightService get _insightService => InsightService(_apiClient);

  @override
  Patient get patient => _remotePatient ?? super.patient;

  @override
  List<MedicationRequest> get medications =>
      _remoteMedications ?? super.medications;

  @override
  List<Observation> get observations =>
      _remoteObservations ?? super.observations;

  @override
  List<DiagnosticReport> get diagnosticReports =>
      _remoteReports ?? super.diagnosticReports;

  @override
  List<HealthInsight> get insights => _remoteInsights ?? super.insights;

  Future<void> loadRemoteData() async {
    isLoadingRemote = true;
    remoteError = null;
    notifyListeners();
    try {
      final profile = await _profileService.getProfile();
      final meds = await _medicationService.list();
      final observations = await _observationService.list();
      final records = await _recordService.list();
      final warnings = await _medicationService.safetyCheck();
      final remoteInsights = await _insightService.list();

      _remotePatient = _patientFromJson(profile);
      _remoteMedications = meds.map(_medicationFromJson).toList();
      _remoteObservations = observations.map(_observationFromJson).toList();
      medicalRecords = records;
      medicationSafetyWarnings = warnings;
      _remoteReports = records
          .where((record) =>
              record['record_type'].toString().toLowerCase().contains('lab'))
          .map(_reportFromRecord)
          .toList();
      _remoteInsights = remoteInsights.map(_insightFromJson).toList();
      usingBackend = true;
    } catch (error) {
      usingBackend = false;
      remoteError = _apiClient.readableError(error);
    } finally {
      isLoadingRemote = false;
      notifyListeners();
    }
  }

  Future<void> createEmergencyToken({int expiresInMinutes = 60}) async {
    emergencyToken = await _emergencyService.createToken(
      expiresInMinutes: expiresInMinutes,
    );
    notifyListeners();
  }

  Future<void> revokeEmergencyToken() async {
    final token = emergencyToken?['token']?.toString();
    if (token == null || token.isEmpty) return;
    await _emergencyService.revoke(token);
    emergencyToken = null;
    notifyListeners();
  }

  Future<void> addObservation(Map<String, dynamic> payload) async {
    await _observationService.create(payload);
    await loadRemoteData();
  }

  Future<void> addMedication(Map<String, dynamic> payload) async {
    await _medicationService.create(payload);
    await loadRemoteData();
  }

  Future<void> updateMedication(int id, Map<String, dynamic> payload) async {
    await _medicationService.update(id, payload);
    await loadRemoteData();
  }

  Future<void> deleteMedication(int id) async {
    await _medicationService.delete(id);
    await loadRemoteData();
  }

  Future<void> addMedicalRecord(Map<String, dynamic> payload) async {
    await _recordService.create(payload);
    await loadRemoteData();
  }

  Future<void> updateProfile(Map<String, dynamic> payload) async {
    final profile = await _profileService.updateProfile(payload);
    _remotePatient = _patientFromJson(profile);
    notifyListeners();
  }

  Future<void> deleteMedicalRecord(int id) async {
    await _recordService.delete(id);
    await loadRemoteData();
  }

  @override
  void toggleMedication(String id) {
    if (_remoteMedications == null) {
      super.toggleMedication(id);
      return;
    }
    _remoteMedications = _remoteMedications!.map((medication) {
      if (medication.id != id) {
        return medication;
      }
      return medication.copyWith(takenToday: !medication.takenToday);
    }).toList();
    notifyListeners();
  }

  Patient _patientFromJson(Map<String, dynamic> json) {
    return Patient(
      id: 'Patient/${json['id']}',
      name: json['full_name']?.toString() ?? super.patient.name,
      age: (json['age'] as num?)?.toInt() ?? super.patient.age,
      gender: json['gender']?.toString() ?? super.patient.gender,
      birthDate: DateTime.now(),
      bloodGroup: json['blood_group']?.toString() ?? super.patient.bloodGroup,
      phone: json['phone']?.toString() ?? super.patient.phone,
      email: json['email']?.toString() ?? super.patient.email,
      address: 'Stored securely in MedID Connect',
      emergencyContactName: _firstEmergencyContact(json)?['name']?.toString() ??
          super.patient.emergencyContactName,
      emergencyContactPhone:
          _firstEmergencyContact(json)?['phone']?.toString() ??
              super.patient.emergencyContactPhone,
      healthScore: super.patient.healthScore,
    );
  }

  Map<String, dynamic>? _firstEmergencyContact(Map<String, dynamic> json) {
    final contacts = json['emergency_contacts'];
    if (contacts is List && contacts.isNotEmpty && contacts.first is Map) {
      return Map<String, dynamic>.from(contacts.first as Map);
    }
    return null;
  }

  MedicationRequest _medicationFromJson(Map<String, dynamic> json) {
    return MedicationRequest(
      id: json['id'].toString(),
      medicationName: json['medicine_name']?.toString() ?? 'Medication',
      dosageInstruction: json['dosage']?.toString() ?? 'As prescribed',
      frequency: json['frequency']?.toString() ?? 'As scheduled',
      prescriber: json['prescribing_doctor']?.toString() ?? 'Clinician',
      status: json['active'] == false ? 'inactive' : 'active',
      intent: 'order',
      startDate: DateTime.tryParse(json['start_date']?.toString() ?? '') ??
          DateTime.now(),
      endDate: DateTime.tryParse(json['end_date']?.toString() ?? ''),
      takenToday: false,
    );
  }

  Observation _observationFromJson(Map<String, dynamic> json) {
    final type = json['observation_type']?.toString() ?? 'observation';
    return Observation(
      id: json['id'].toString(),
      code: _codeForObservationType(type),
      display: _labelForObservationType(type),
      value: (json['value'] as num?)?.toDouble() ?? 0,
      unit: json['unit']?.toString() ?? '',
      effectiveDate: DateTime.tryParse(json['observed_at']?.toString() ?? '') ??
          DateTime.now(),
      referenceRangeLow: (json['normal_min'] as num?)?.toDouble(),
      referenceRangeHigh: (json['normal_max'] as num?)?.toDouble(),
      status: json['status']?.toString() ?? 'final',
    );
  }

  DiagnosticReport _reportFromRecord(Map<String, dynamic> json) {
    return DiagnosticReport(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? 'Medical report',
      category: json['record_type']?.toString() ?? 'Record',
      status: 'final',
      issuedDate: DateTime.tryParse(json['record_date']?.toString() ?? '') ??
          DateTime.now(),
      performer: json['provider_name']?.toString() ?? 'Provider',
      summary: json['description']?.toString() ?? 'No summary available.',
      observationIds: const [],
    );
  }

  HealthInsight _insightFromJson(Map<String, dynamic> json) {
    return HealthInsight(
      id: json['title']?.toString() ?? 'insight',
      title: json['title']?.toString() ?? 'Health insight',
      description: json['description']?.toString() ?? '',
      recommendation: json['recommendation']?.toString() ?? '',
      confidence: 0.82,
      category: json['category']?.toString() ?? 'General',
    );
  }

  String _codeForObservationType(String type) {
    return switch (type) {
      'blood_pressure' => '8480-6',
      'cholesterol' => '2093-3',
      'glucose' => '2339-0',
      'heart_rate' => '8867-4',
      _ => type,
    };
  }

  String _labelForObservationType(String type) {
    return switch (type) {
      'blood_pressure' => 'Systolic blood pressure',
      'cholesterol' => 'Total cholesterol',
      'glucose' => 'Fasting glucose',
      'heart_rate' => 'Heart rate',
      _ => type,
    };
  }
}
