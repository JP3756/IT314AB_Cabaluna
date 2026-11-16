import '../../config/app_config.dart';
import 'db_service.dart';
import 'postgres_db_service.dart';

// Android and desktop: direct connection.
DbService createDbService(AppConfig config) => PostgresDbService(
      connectionString: config.activeUrl,
      description: '${config.targetLabel} (direct connection)',
    );
