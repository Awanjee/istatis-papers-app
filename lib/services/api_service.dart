import 'package:dio/dio.dart';

import '../models/quote_history_item.dart';
import '../models/quote_request.dart';

class ApiService {
  final Dio _dio;
  final String _sessionId;
  final String? Function()? _accessTokenProvider;

  // URL of the deployed API
  static const String _baseUrl =
      'https://arco-papers-api.onrender.com'; // Deployed URL
  // static const String _baseUrl = 'http://127.0.0.1:8000'; // Local development

  ApiService({String? Function()? accessTokenProvider})
    : _accessTokenProvider = accessTokenProvider,
      _dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ),
      ),
      _sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}' {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _accessTokenProvider?.call();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

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

  Future<QuoteResponse> requestQuote(QuoteRequest request) async {
    try {
      final response = await _dio.post('/quote', data: request.toJson());
      return QuoteResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return QuoteResponse(
        success: false,
        message: 'Error: ${e.message}',
        quoteSummary: '',
      );
    }
  }

  Future<List<QuoteHistoryItem>> getQuoteHistory() async {
    final response = await _dio.get<List<dynamic>>('/quotes/history');
    final data = response.data ?? [];
    return data
        .map((e) => QuoteHistoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OrderResult> createOrder(String quoteId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/orders',
      data: {'quote_id': quoteId},
    );
    return OrderResult.fromJson(response.data!);
  }
}
