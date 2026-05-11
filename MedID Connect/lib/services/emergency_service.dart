import 'api_client.dart';

class EmergencyService {
  EmergencyService(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> createToken({int expiresInMinutes = 60}) async {
    final response = await _client.dio.post(
      '/api/emergency/token',
      data: {'expires_in_minutes': expiresInMinutes},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> revoke(String token) async {
    await _client.dio.post('/api/emergency/revoke/$token');
  }

  Future<List<Map<String, dynamic>>> logs() async {
    final response = await _client.dio.get('/api/emergency/logs');
    return (response.data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }
}
