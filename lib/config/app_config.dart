// Settings come from the build: flutter run --dart-define-from-file=.env.app
// Keys: DB_TARGET (neon | local), NEON_DATABASE_URL, LOCAL_DATABASE_URL, LOCAL_BRIDGE_URL
enum DbTarget { neon, local }

class AppConfig {
  const AppConfig({
    required this.target,
    required this.neonUrl,
    required this.localUrl,
    required this.bridgeUrl,
  });

  factory AppConfig.fromEnvironment() => AppConfig(
        target: const String.fromEnvironment('DB_TARGET', defaultValue: 'neon') == 'local'
            ? DbTarget.local
            : DbTarget.neon,
        neonUrl: const String.fromEnvironment('NEON_DATABASE_URL'),
        localUrl: const String.fromEnvironment('LOCAL_DATABASE_URL'),
        bridgeUrl: const String.fromEnvironment('LOCAL_BRIDGE_URL', defaultValue: 'http://localhost:4000/sql'),
      );

  final DbTarget target;
  final String neonUrl;
  final String localUrl;
  final String bridgeUrl;

  // url of the selected target
  String get activeUrl => target == DbTarget.neon ? neonUrl : localUrl;

  bool get isConfigured => activeUrl.isNotEmpty;

  String get targetLabel => target == DbTarget.neon ? 'Neon PostgreSQL' : 'Local PostgreSQL';

  String get missingMessage => target == DbTarget.neon
      ? 'NEON_DATABASE_URL is not set. Run with --dart-define-from-file=.env.app (see README).'
      : 'LOCAL_DATABASE_URL is not set. Run with --dart-define-from-file=.env.app and DB_TARGET=local (see README).';
}
