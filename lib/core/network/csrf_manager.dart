import 'package:dio/dio.dart';

import 'csrf_extractor.dart';

/// CSRF Token Manager - Single Source of Truth
///
/// Manages CSRF token lifecycle:
/// - Stores token in memory
/// - Handles token refresh with race condition protection
/// - Provides token to interceptors
class CsrfManager {
  static String? _token;
  static bool _refreshing = false;
  static String? _csrfPath;

  /// Get current CSRF token
  static String? get token => _token;

  /// Initialize CSRF token from the given path
  ///
  /// [dio] - Dio instance to make GET request
  /// [path] - Path to fetch CSRF token from (e.g., '/mohammad-kamal-hosen')
  static Future<void> init(Dio dio, String path) async {
    _csrfPath = path;
    _token = await CsrfExtractor.extract(dio, path);
  }

  /// Refresh CSRF token when expired (419 error)
  ///
  /// Uses [_refreshing] flag to prevent concurrent refresh calls
  static Future<void> refresh(Dio dio, String path) async {
    if (_refreshing) return;
    _refreshing = true;

    try {
      _token = await CsrfExtractor.extract(dio, path);
    } finally {
      _refreshing = false;
    }
  }

  /// Get the CSRF path used for initialization
  static String? get csrfPath => _csrfPath;

  /// Clear token (useful for logout or reset)
  static void clear() {
    _token = null;
    _csrfPath = null;
  }
}
