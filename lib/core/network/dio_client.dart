import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

import 'csrf_manager.dart';

class DioClient {
  static Dio? _dio;
  static const String _csrfPath = '/mohammad-kamal-hosen';

  static Future<Dio> get instance async {
    if (_dio != null) return _dio!;

    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://search.mydisha.xyz',
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
        receiveTimeout: const Duration(seconds: 30),
        connectTimeout: const Duration(seconds: 30),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final cookieJar = PersistCookieJar(
      storage: FileStorage('${dir.path}/cookies'),
    );

    dio.interceptors.add(CookieManager(cookieJar));

    /// 🔥 CSRF Token Interceptor
    ///
    /// - Auto-injects CSRF token into FormData requests
    /// - Handles 419 (Token Expired) errors with auto-retry
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Inject CSRF token into FormData if token exists
          if (CsrfManager.token != null && options.data is FormData) {
            final formData = options.data as FormData;

            // Remove existing _token if present
            formData.fields.removeWhere((field) => field.key == '_token');

            // Add fresh token
            formData.fields.add(MapEntry('_token', CsrfManager.token!));
          }

          handler.next(options);
        },
        onError: (error, handler) async {
          // Handle CSRF token expiration (419 status code)
          if (error.response?.statusCode == 419) {
            try {
              // Refresh CSRF token
              await CsrfManager.refresh(dio, _csrfPath);

              // Retry the original request
              final retryOptions = error.requestOptions;

              // Update FormData with new token
              if (retryOptions.data is FormData) {
                final formData = retryOptions.data as FormData;
                formData.fields.removeWhere((field) => field.key == '_token');
                formData.fields.add(MapEntry('_token', CsrfManager.token!));
              }

              // Retry request
              final retryResponse = await dio.fetch(retryOptions);
              return handler.resolve(retryResponse);
            } catch (e) {
              // If refresh fails, pass the error through
              return handler.next(error);
            }
          }

          handler.next(error);
        },
      ),
    );

    // Add logging
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, logPrint: (obj) {}),
    );

    // Initialize CSRF token on first Dio instance creation
    await CsrfManager.init(dio, _csrfPath);

    _dio = dio;
    return dio;
  }
}
