import 'api_client.dart';

class ProviderSandboxService {
  ProviderSandboxService(this._client);

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> providers() async {
    final response = await _client.dio.get('/api/providers');
    return (response.data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> startConnection(String providerId) async {
    final response = await _client.dio.post(
      '/api/providers/connect/start',
      data: {'provider_id': providerId},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> completeConnection(String providerId) async {
    final response = await _client.dio.post(
      '/api/providers/connect/callback',
      data: {'provider_id': providerId, 'auth_code': 'demo-code'},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> connected() async {
    final response = await _client.dio.get('/api/providers/connected');
    return (response.data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> sync(int connectionId) async {
    final response =
        await _client.dio.post('/api/providers/$connectionId/sync');
    return Map<String, dynamic>.from(response.data as Map);
  }
}
