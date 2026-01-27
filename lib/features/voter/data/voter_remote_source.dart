import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';

class VoterRemoteSource {
  Future<Map<String, dynamic>> search(Map<String, dynamic> payload) async {
    final dio = await DioClient.instance;

    try {
      // init session (mimicking browser behavior)
      await dio.get('/mohammad-kamal-hosen');

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
