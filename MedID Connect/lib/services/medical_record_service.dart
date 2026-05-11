import 'api_client.dart';

class MedicalRecordService {
  MedicalRecordService(this._client);

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> list({String? recordType}) async {
    final response = await _client.dio.get(
      '/api/records',
      queryParameters: {
        if (recordType != null) 'record_type': recordType,
      },
    );
    return (response.data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final response = await _client.dio.post('/api/records', data: payload);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> update(
      int id, Map<String, dynamic> payload) async {
    final response = await _client.dio.put('/api/records/$id', data: payload);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> delete(int id) async {
    await _client.dio.delete('/api/records/$id');
  }
}
