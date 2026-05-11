import 'api_client.dart';

class SosService {
  SosService(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> sendMockAlert({
    double? latitude,
    double? longitude,
  }) async {
    final response = await _client.dio.post(
      '/api/sos/alert',
      data: {
        'message':
            'Emergency help needed. This is a MedID Connect mock SOS alert.',
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> alerts() async {
    final response = await _client.dio.get('/api/sos/alerts');
    return (response.data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }
}
