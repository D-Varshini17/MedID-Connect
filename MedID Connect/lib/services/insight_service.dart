import 'api_client.dart';

class InsightService {
  InsightService(this._client);

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> list() async {
    final response = await _client.dio.get('/api/insights');
    return (response.data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }
}
