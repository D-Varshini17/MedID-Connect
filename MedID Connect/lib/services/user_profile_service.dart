import 'api_client.dart';

class UserProfileService {
  UserProfileService(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _client.dio.get('/api/user/profile');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> payload) async {
    final response = await _client.dio.put('/api/user/profile', data: payload);
    return Map<String, dynamic>.from(response.data as Map);
  }
}
