import 'api_client.dart';

class AuthService {
  AuthService(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> signup({
    required String fullName,
    required String email,
    required String password,
    int? age,
    String? gender,
    String? bloodGroup,
    String? phone,
  }) async {
    final response = await _client.dio.post(
      '/api/auth/signup',
      data: {
        'full_name': fullName,
        'email': email,
        'password': password,
        'age': age,
        'gender': gender,
        'blood_group': bloodGroup,
        'phone': phone,
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    await _client.saveToken(data['access_token'] as String);
    return data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.dio.post(
      '/api/auth/login',
      data: {'email': email, 'password': password},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    await _client.saveToken(data['access_token'] as String);
    return data;
  }

  Future<Map<String, dynamic>> me() async {
    final response = await _client.dio.get('/api/auth/me');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<bool> hasToken() async {
    final token = await _client.readToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    try {
      await _client.dio.post('/api/auth/logout');
    } finally {
      await _client.clearToken();
    }
  }
}
