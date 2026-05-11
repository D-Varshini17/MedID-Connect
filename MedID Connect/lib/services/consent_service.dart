import 'api_client.dart';

class ConsentService {
  ConsentService(this._client);

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> list() async {
    final response = await _client.dio.get('/api/consents');
    return (response.data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final response = await _client.dio.post('/api/consents', data: payload);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> revoke(int consentId) async {
    await _client.dio.delete('/api/consents/$consentId/revoke');
  }

  Future<List<Map<String, dynamic>>> logs(int consentId) async {
    final response = await _client.dio.get('/api/consents/$consentId/logs');
    return (response.data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }
}
