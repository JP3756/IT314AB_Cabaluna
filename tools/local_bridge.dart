// Local bridge for web: takes Neon-style POST /sql requests and runs them on the local database.
// Development only. Reads LOCAL_DATABASE_URL from .env.app.
//   dart run tools/local_bridge.dart
//   flutter run -d chrome --dart-define-from-file=.env.app --dart-define=DB_TARGET=local
import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';

Map<String, String> readEnv(String path) {
  final m = <String, String>{};
  for (final l in File(path).readAsLinesSync()) {
    final i = l.indexOf('=');
    if (i > 0 && !l.startsWith('#')) m[l.substring(0, i)] = l.substring(i + 1).trim();
  }
  return m;
}

const _cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Neon-Connection-String',
};

Future<void> main(List<String> args) async {
  final url = readEnv('.env.app')['LOCAL_DATABASE_URL'];
  if (url == null || url.isEmpty) {
    stderr.writeln('LOCAL_DATABASE_URL missing in .env.app');
    exit(1);
  }
  final u = Uri.parse(url);
  final user = u.userInfo.split(':');
  final pool = Pool.withEndpoints(
    [
      Endpoint(
        host: u.host,
        port: u.hasPort ? u.port : 5432,
        database: u.pathSegments.first,
        username: Uri.decodeComponent(user.first),
        password: Uri.decodeComponent(user.sublist(1).join(':')),
      ),
    ],
    settings: const PoolSettings(sslMode: SslMode.disable, maxConnectionCount: 4),
  );

  final port = args.isNotEmpty ? int.parse(args.first) : 4000;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln('Local bridge listening on http://localhost:$port/sql  ->  ${u.host}/${u.pathSegments.first}');

  await for (final req in server) {
    _cors.forEach(req.response.headers.set);
    if (req.method == 'OPTIONS') {
      req.response.statusCode = 204;
      await req.response.close();
      continue;
    }
    req.response.headers.contentType = ContentType.json;
    try {
      final body = jsonDecode(await utf8.decoder.bind(req).join()) as Map<String, dynamic>;
      final result = await pool.execute(
        body['query'] as String,
        parameters: (body['params'] as List?) ?? const [],
      );
      req.response.write(jsonEncode(
        {'rows': result.map((r) => r.toColumnMap()).toList(), 'rowCount': result.affectedRows},
        toEncodable: (o) => o.toString(),
      ));
    } on ServerException catch (e) {
      req.response.statusCode = 400;
      req.response.write(jsonEncode({'message': e.message, 'code': e.code, 'constraint': e.constraintName}));
    } catch (e) {
      req.response.statusCode = 500;
      req.response.write(jsonEncode({'message': e.toString()}));
    }
    await req.response.close();
  }
}
