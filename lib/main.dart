import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'core/db/db_factory.dart';
import 'core/db/db_service.dart';
import 'repositories/enrollment_repository.dart';
import 'repositories/grades_repository.dart';
import 'repositories/schedule_repository.dart';
import 'repositories/student_repository.dart';
import 'repositories/subject_repository.dart';
import 'screens/home_screen.dart';
import 'viewmodels/enrollment_view_model.dart';
import 'viewmodels/grades_view_model.dart';
import 'viewmodels/schedule_view_model.dart';
import 'viewmodels/student_view_model.dart';
import 'viewmodels/subject_view_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  runApp(config.isConfigured ? EnrollmentApp(config: config) : _ConfigError(config: config));
}

ThemeData _theme() => ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3949AB)),
      useMaterial3: true,
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    );

// builds the db service once and wires repositories and view models
class EnrollmentApp extends StatelessWidget {
  const EnrollmentApp({super.key, required this.config, this.db});

  final AppConfig config;

  // tests pass a fake db
  final DbService? db;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppConfig>.value(value: config),
        Provider<DbService>(
          create: (_) => db ?? createDbService(config),
          dispose: (_, s) => s.close(),
        ),
        ProxyProvider<DbService, StudentRepository>(update: (_, d, _) => StudentRepository(d)),
        ProxyProvider<DbService, SubjectRepository>(update: (_, d, _) => SubjectRepository(d)),
        ProxyProvider<DbService, ScheduleRepository>(update: (_, d, _) => ScheduleRepository(d)),
        ProxyProvider<DbService, EnrollmentRepository>(update: (_, d, _) => EnrollmentRepository(d)),
        ProxyProvider<DbService, GradesRepository>(update: (_, d, _) => GradesRepository(d)),
        ChangeNotifierProvider(create: (c) => StudentViewModel(c.read<StudentRepository>())),
        ChangeNotifierProvider(create: (c) => SubjectViewModel(c.read<SubjectRepository>())),
        ChangeNotifierProvider(create: (c) => ScheduleViewModel(c.read<ScheduleRepository>())),
        ChangeNotifierProvider(create: (c) => EnrollmentViewModel(c.read<EnrollmentRepository>())),
        ChangeNotifierProvider(create: (c) => GradesViewModel(c.read<GradesRepository>())),
      ],
      child: MaterialApp(
        title: 'Enrollment System',
        debugShowCheckedModeBanner: false,
        theme: _theme(),
        home: const HomeScreen(),
      ),
    );
  }
}

// shown when the build has no connection string
class _ConfigError extends StatelessWidget {
  const _ConfigError({required this.config});
  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _theme(),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.settings_suggest, size: 56),
                const SizedBox(height: 12),
                Text('Database not configured', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(config.missingMessage, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
