import '../../config/app_config.dart';
import 'db_service.dart';
import 'http_db_service.dart';

// Web: Neon over HTTPS, or the local bridge.
DbService createDbService(AppConfig config) {
  if (config.target == DbTarget.local) {
    return HttpDbService(
      endpoint: Uri.parse(config.bridgeUrl),
      description: '${config.targetLabel} (via local bridge)',
    );
  }
  final host = Uri.parse(config.neonUrl).host;
  return HttpDbService(
    endpoint: Uri.https(host, '/sql'),
    connectionString: config.neonUrl,
    description: '${config.targetLabel} (HTTP)',
  );
}
