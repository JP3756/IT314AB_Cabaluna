import '../../config/app_config.dart';
import 'db_service.dart';

DbService createDbService(AppConfig config) =>
    throw UnsupportedError('No database implementation for this platform.');
