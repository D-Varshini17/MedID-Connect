import 'api_client.dart';

class AppointmentService {
  AppointmentService(this._client);

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> list() async {
    final response = await _client.dio.get('/api/telemedicine/appointments');
    return (response.data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final response =
        await _client.dio.post('/api/telemedicine/appointments', data: payload);
    return Map<String, dynamic>.from(response.data as Map);
  }
}
