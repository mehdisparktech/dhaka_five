import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

class DioClient {
  static Dio? _dio;

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

    // Add logging
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, logPrint: (obj) {}),
    );

    _dio = dio;
    return dio;
  }
}
