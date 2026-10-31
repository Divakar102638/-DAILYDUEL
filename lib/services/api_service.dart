import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Reusable client for the DailyDuel hosted API.
///
/// Only health endpoints are currently implemented by the backend.
/// Do not add feature methods until their server routes exist.
class ApiService {
  ApiService({
    http.Client? client,
    this.baseUrl = 'https://dailyduel.onrender.com',
    this.timeout = const Duration(seconds: 12),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  final Duration timeout;

  Future<Map<String, dynamic>> getHealth() {
    return _getJson('/health');
  }

  Future<Map<String, dynamic>> getDatabaseHealth() {
    return _getJson('/health/database');
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    final uri = Uri.parse(baseUrl).resolve(path);

    try {
      final response = await _client.get(
        uri,
        headers: const {'Accept': 'application/json'},
      ).timeout(timeout);

      final dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw ApiException(
          'The server returned an unexpected response. Please try again.',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded is Map<String, dynamic> &&
                decoded['error'] is Map<String, dynamic> &&
                decoded['error']['message'] is String
            ? decoded['error']['message'] as String
            : 'The server could not complete the request.';
        throw ApiException(message, statusCode: response.statusCode);
      }

      if (decoded is! Map<String, dynamic>) {
        throw ApiException('The server returned an unexpected response.');
      }

      return decoded;
    } on TimeoutException {
      throw ApiException(
        'The request took too long. Please check your connection and try again.',
      );
    } on http.ClientException {
      throw ApiException(
        'Could not reach DailyDuel. Check your internet connection and try again.',
      );
    }
  }

  void close() => _client.close();
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
