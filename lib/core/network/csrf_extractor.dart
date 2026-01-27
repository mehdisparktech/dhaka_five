import 'package:dio/dio.dart';
import 'package:html/parser.dart';

class CsrfExtractor {
  static Future<String> extract(Dio dio, String path) async {
    final res = await dio.get(path);
    final document = parse(res.data.toString());

    final tokenInput = document.querySelector('input[name="_token"]');

    if (tokenInput == null) {
      throw Exception('CSRF token not found');
    }

    return tokenInput.attributes['value']!;
  }
}
