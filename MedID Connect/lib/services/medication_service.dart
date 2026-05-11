import 'api_client.dart';

class MedicationService {
  MedicationService(this._client);

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> list() async {
    final response = await _client.dio.get('/api/medications');
    return (response.data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final response = await _client.dio.post('/api/medications', data: payload);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> update(
      int id, Map<String, dynamic> payload) async {
    final response =
        await _client.dio.put('/api/medications/$id', data: payload);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> delete(int id) async {
    await _client.dio.delete('/api/medications/$id');
  }

  Future<List<Map<String, dynamic>>> safetyCheck() async {
    final response = await _client.dio.get('/api/medications/safety-check');
    final warnings = (response.data as Map)['warnings'] as List? ?? [];
    return warnings
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }
}
