import 'package:flutter/foundation.dart';

import '../core/db/db_service.dart';

// shared loading and error handling
abstract class BaseViewModel extends ChangeNotifier {
  bool _loading = false;
  bool _disposed = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  // true on success, otherwise sets [error]
  Future<bool> run(Future<void> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on DbException catch (e) {
      _error = friendlyDbMessage(e);
      return false;
    } catch (e) {
      debugPrint('Unexpected error: $e');
      _error = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
