import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../core/db/db_service.dart';
import 'admin_shell.dart';
import 'student_portal_screen.dart';

// role picker and a database check
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<void> _check = _ping();

  Future<void> _ping() async {
    final db = context.read<DbService>();
    await db.query('SELECT 1 AS ok');
  }

  @override
  Widget build(BuildContext context) {
    final config = context.read<AppConfig>();
    final db = context.read<DbService>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.school, size: 64, color: scheme.primary),
                const SizedBox(height: 12),
                Text('Enrollment System', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text('IT313AB Final Project', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                FutureBuilder<void>(
                  future: _check,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Card(child: ListTile(leading: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)), title: Text('Connecting to database...')));
                    }
                    if (snap.hasError) {
                      return Card(
                        color: scheme.errorContainer,
                        child: ListTile(
                          leading: Icon(Icons.cloud_off, color: scheme.onErrorContainer),
                          title: Text('Database not reachable', style: TextStyle(color: scheme.onErrorContainer)),
                          subtitle: Text(friendlyDbMessage(snap.error!), style: TextStyle(color: scheme.onErrorContainer)),
                          trailing: IconButton(
                            tooltip: 'Retry',
                            icon: Icon(Icons.refresh, color: scheme.onErrorContainer),
                            onPressed: () => setState(() => _check = _ping()),
                          ),
                        ),
                      );
                    }
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.cloud_done, color: scheme.primary),
                        title: const Text('Connected'),
                        subtitle: Text(db.description),
                      ),
                    );
                  },
                ),
                if (config.target == DbTarget.local)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('Development mode: using the local database.', textAlign: TextAlign.center),
                  ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminShell())),
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('Registrar / Admin'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentPortalScreen())),
                  icon: const Icon(Icons.person),
                  label: const Text('Student'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
