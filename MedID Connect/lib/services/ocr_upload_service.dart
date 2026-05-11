import 'package:dio/dio.dart';

import 'api_client.dart';

class OcrUploadService {
  OcrUploadService(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> uploadPrescription(String path) async {
    return _upload('/api/ocr/prescription', path);
  }

  Future<Map<String, dynamic>> uploadLabReport(String path) async {
    return _upload('/api/ocr/lab-report', path);
  }

  Future<Map<String, dynamic>> _upload(String endpoint, String path) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(path),
    });
    final response = await _client.dio.post(
      endpoint,
      data: formData,
      queryParameters: {'confirm_save': true},
      options: Options(contentType: 'multipart/form-data'),
      onSendProgress: (_, __) {},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }
}
