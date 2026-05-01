import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio;
  final String _sessionId;

  // Change this to your deployed URL later
  static const String _baseUrl = 'http://127.0.0.1:8000';

  ApiService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ),
      ),
      _sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';

  Future<String> sendMessage(String message) async {
    try {
      final response = await _dio.post(
        '/chat',
        data: {'message': message, 'session_id': _sessionId},
      );
      return response.data['response'] as String;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return 'Connection timed out. Please try again.';
      }
      return 'Error: ${e.message}';
    }
  }
}
