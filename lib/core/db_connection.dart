import 'dart:async';
import 'dart:io';

import 'package:postgres/postgres.dart';

import 'db/db_service.dart';

// The one shared database connection (a small pool), created once in main.dart and reused by every repository.
// SSL is always required unless the URL explicitly says sslmode=disable (local development only).
class DbConnection implements DbService {
  DbConnection({required String connectionString, required this.description})
      : _pool = _buildPool(connectionString);

  final Pool<void> _pool;
  @override
  final String description;

  static Pool<void> _buildPool(String url) {
    final u = Uri.parse(url);
    final userInfo = u.userInfo.split(':');
    var host = u.host;
    // the emulator reaches the PC through 10.0.2.2
    if (Platform.isAndroid && (host == 'localhost' || host == '127.0.0.1')) host = '10.0.2.2';
    final ssl = u.queryParameters['sslmode'];
    return Pool.withEndpoints(
      [
        Endpoint(
          host: host,
          port: u.hasPort ? u.port : 5432,
          database: u.pathSegments.isEmpty ? 'postgres' : u.pathSegments.first,
          username: Uri.decodeComponent(userInfo.first),
          password: userInfo.length > 1 ? Uri.decodeComponent(userInfo.sublist(1).join(':')) : null,
        ),
      ],
      settings: PoolSettings(
        sslMode: ssl == 'disable' ? SslMode.disable : SslMode.require,
        maxConnectionCount: 4,
        connectTimeout: const Duration(seconds: 15),
        queryTimeout: const Duration(seconds: 30),
      ),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> query(String sql, [List<Object?> params = const []]) async {
    try {
      final result = await _pool.execute(sql, parameters: params);
      return result.map((row) => row.toColumnMap()).toList();
    } on ServerException catch (e) {
      throw DbException(e.message, code: e.code, constraint: e.constraintName);
    } on PgException catch (e) {
      throw DbException(e.message, code: 'connection');
    } on TimeoutException {
      throw DbException('The database did not answer in time.', code: 'connection');
    } on SocketException {
      throw DbException('Cannot reach the database server.', code: 'connection');
    } on HandshakeException {
      throw DbException('Secure connection to the database failed.', code: 'connection');
    }
  }

  @override
  Future<void> close() => _pool.close();
}
