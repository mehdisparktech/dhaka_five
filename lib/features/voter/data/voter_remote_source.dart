import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';

class VoterRemoteSource {
  Future<Map<String, dynamic>> search(Map<String, dynamic> payload) async {
    final dio = await DioClient.instance;

    try {
      // CSRF token is automatically injected by Dio interceptor
      // Token initialization happens in DioClient.instance
      final res = await dio.post(
        '/mohammad-kamal-hosen/result',
        data: FormData.fromMap(payload),
      );

      return res.data;
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.message ?? 'Network Error');
      }
      rethrow;
    }
  }
}
