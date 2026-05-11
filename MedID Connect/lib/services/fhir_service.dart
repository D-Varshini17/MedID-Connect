import 'api_client.dart';

class FhirService {
  FhirService(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> patient(int patientId) async {
    final response = await _client.dio.get('/api/fhir/Patient/$patientId');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> bundle(
      String resourceType, int patientId) async {
    final response = await _client.dio.get(
      '/api/fhir/$resourceType',
      queryParameters: {'patient': patientId},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }
}
