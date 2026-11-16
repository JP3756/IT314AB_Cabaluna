import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'db_service.dart';

// SQL over HTTP for web. Speaks Neon's POST /sql; tools/local_bridge.dart speaks the same.
class HttpDbService implements DbService {
  HttpDbService({required this.endpoint, required this.description, this.connectionString, http.Client? client})
      : _client = client ?? http.Client();

  final Uri endpoint;
  @override
  final String description;

  // sent as the Neon-Connection-String header (null for the local bridge)
  final String? connectionString;
  final http.Client _client;

  @override
  Future<List<Map<String, dynamic>>> query(String sql, [List<Object?> params = const []]) async {
    final http.Response res;
    try {
      res = await _client
          .post(
            endpoint,
            headers: {
              'Content-Type': 'application/json',
              'Neon-Connection-String': ?connectionString,
            },
            body: jsonEncode({'query': sql, 'params': params}),
          )
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw DbException('The database did not answer in time.', code: 'connection');
    } catch (_) {
      throw DbException('Network error while contacting the database.', code: 'connection');
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw DbException('Unexpected response from the database (HTTP ${res.statusCode}).', code: 'connection');
    }
    if (res.statusCode != 200) {
      throw DbException(
        (body['message'] ?? 'Database error (HTTP ${res.statusCode}).').toString(),
        code: body['code']?.toString(),
        constraint: body['constraint']?.toString(),
      );
    }
    return (body['rows'] as List? ?? const []).map((r) => Map<String, dynamic>.from(r as Map)).toList();
  }

  @override
  Future<void> close() async => _client.close();
}
