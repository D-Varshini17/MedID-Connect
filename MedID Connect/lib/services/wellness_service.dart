import 'api_client.dart';

class WellnessService {
  WellnessService(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> score() async {
    final response = await _client.dio.get('/api/wellness/score');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> logs() async {
    final response = await _client.dio.get('/api/wellness/logs');
    return (response.data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createLog(Map<String, dynamic> payload) async {
    final response =
        await _client.dio.post('/api/wellness/logs', data: payload);
    return Map<String, dynamic>.from(response.data as Map);
  }
}
