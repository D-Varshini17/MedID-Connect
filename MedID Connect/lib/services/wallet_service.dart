import 'api_client.dart';

class WalletService {
  WalletService(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> summary() async {
    final response = await _client.dio.get('/api/wallet/summary');
    return Map<String, dynamic>.from(response.data as Map);
  }
}
