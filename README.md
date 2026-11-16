# Enrollment System

IT313AB final project. A Flutter app (Android and web) on a PostgreSQL database hosted on Neon.
The registrar manages students, subjects, schedules, enrollments and grades. Students see their
subjects, schedule and grades.

## Folders
```
lib/config         which database to use
lib/core           database access (direct on Android, HTTP on web) and helpers
lib/models         one class per table, same field names as the columns
lib/repositories   the SQL, one file per table
lib/viewmodels     screen state, one per table
lib/screens        admin tabs and the student view
db/migrations      tables, keys, checks and triggers
tools              migration runner, local setup, local web bridge, repository checks
```

## Setup
1. Copy `.env.example` to `.env` and `.env.app`, then fill in the connection strings.
   `.env.app` is read by the Flutter build and must not hold the admin password. Both files are git-ignored.
2. Run:
```
flutter run --dart-define-from-file=.env.app                 # Android emulator or device
flutter run -d chrome --dart-define-from-file=.env.app       # web, Neon over HTTPS
```
Local Postgres: set `DB_TARGET=local` in `.env.app`. Web with local Postgres also needs
`dart run tools/local_bridge.dart`.

## Database
- `python tools/run_migration.py` tests the migration without keeping it. Add `--apply` to keep it, `--local` for the local database.
- `python tools/setup_local.py` creates the local database and user.
- `dart run tools/integration_check.dart native` runs the repositories against the local database.

## Note
The connection string is compiled into the app, so anyone with the build can read it. Use a limited
Neon role and change the password if a build is shared.
