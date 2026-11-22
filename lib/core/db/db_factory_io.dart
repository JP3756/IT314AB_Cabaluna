import '../../config/app_config.dart';
import 'db_service.dart';
import '../db_connection.dart';

// Android and desktop: direct connection.
DbService createDbService(AppConfig config) => DbConnection(
      connectionString: config.activeUrl,
      description: '${config.targetLabel} (direct connection)',
    );
