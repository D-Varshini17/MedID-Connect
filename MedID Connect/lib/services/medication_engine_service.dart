import 'api_client.dart';

class MedicationEngineService {
  MedicationEngineService(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> checklist() async {
    final response =
        await _client.dio.get('/api/medication-engine/daily-checklist');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> createLog({
    required int medicationId,
    String status = 'taken',
  }) async {
    final response = await _client.dio.post(
      '/api/medication-engine/logs',
      data: {
        'medication_id': medicationId,
        'status': status,
        'taken_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }
}
