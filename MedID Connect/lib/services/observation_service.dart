import 'api_client.dart';

class ObservationService {
  ObservationService(this._client);

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> list({String? observationType}) async {
    final response = await _client.dio.get(
      '/api/observations',
      queryParameters: {
        if (observationType != null) 'observation_type': observationType,
      },
    );
    return (response.data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final response = await _client.dio.post('/api/observations', data: payload);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> trends() async {
    final response = await _client.dio.get('/api/observations/trends');
    return (response.data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }
}
