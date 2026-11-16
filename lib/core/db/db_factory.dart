// dart:io and package:postgres don't compile for web, so the platform picks the implementation.
export 'db_factory_stub.dart'
    if (dart.library.io) 'db_factory_io.dart'
    if (dart.library.js_interop) 'db_factory_web.dart';
