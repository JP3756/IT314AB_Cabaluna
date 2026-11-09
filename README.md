# Student Directory

## CI/CD deployment

Pushes to `feature/student-enrollment` run analysis, tests, and a release web
build in GitHub Actions. A successful build is deployed to the configured
Lightsail instance over SSH.

Add these repository Actions secrets before pushing:

- `LIGHTSAIL_SSH_KEY`: the private key for the `ubuntu` user (do not commit it)
- `LIGHTSAIL_HOST`: the instance public IPv4 address or DNS name
- `LIGHTSAIL_USER`: the SSH user, normally `ubuntu`

The first deployment installs Nginx and `unzip`, configures the server for
Flutter SPA routing, and serves the app on port 80. Ensure the Lightsail
firewall allows TCP port 80 and SSH access from GitHub Actions.

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
