import 'dart:convert';

import 'package:daily_duel/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiService health checks', () {
    test('getHealth requests the hosted health endpoint', () async {
      Uri? requestedUri;
      final client = MockClient((request) async {
        requestedUri = request.url;
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      });
      final api = ApiService(client: client);

      final result = await api.getHealth();

      expect(requestedUri.toString(), 'https://dailyduel.onrender.com/health');
      expect(result['status'], 'ok');
      api.close();
    });

    test('getDatabaseHealth requests the database health endpoint', () async {
      Uri? requestedUri;
      final client = MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode({'status': 'ok', 'database': 'connected'}),
          200,
        );
      });
      final api = ApiService(client: client);

      final result = await api.getDatabaseHealth();

      expect(
        requestedUri.toString(),
        'https://dailyduel.onrender.com/health/database',
      );
      expect(result['database'], 'connected');
      api.close();
    });

    test('non-success response becomes a user-readable ApiException', () async {
      final client = MockClient((_) async => http.Response(
            jsonEncode({
              'error': {'message': 'Database is unavailable.'},
            }),
            503,
          ));
      final api = ApiService(client: client);

      expect(
        () => api.getDatabaseHealth(),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            'Database is unavailable.',
          ),
        ),
      );
      api.close();
    });
  });
}
