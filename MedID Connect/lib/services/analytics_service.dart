import 'api_client.dart';

class AnalyticsService {
  AnalyticsService(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> summary() async {
    final response = await _client.dio.get('/api/product-analytics/summary');
    return Map<String, dynamic>.from(response.data as Map);
  }
}
