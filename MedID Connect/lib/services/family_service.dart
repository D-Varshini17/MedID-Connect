import 'api_client.dart';

class FamilyService {
  FamilyService(this._client);

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> members() async {
    final response = await _client.dio.get('/api/family/members');
    return (response.data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createMember(
      Map<String, dynamic> payload) async {
    final response =
        await _client.dio.post('/api/family/members', data: payload);
    return Map<String, dynamic>.from(response.data as Map);
  }
}
