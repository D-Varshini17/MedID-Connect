import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String emulatorBaseUrl = 'http://10.0.2.2:8000';
  static const String webBaseUrl = 'http://localhost:8000';
  static const String productionBaseUrl = 'https://api.medidconnect.com';

  static const String _configuredBaseUrl =
      String.fromEnvironment('MEDID_API_BASE_URL');

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }
    if (kIsWeb) {
      return webBaseUrl;
    }
    if (kReleaseMode) {
      return productionBaseUrl;
    }
    return emulatorBaseUrl;
  }
}
