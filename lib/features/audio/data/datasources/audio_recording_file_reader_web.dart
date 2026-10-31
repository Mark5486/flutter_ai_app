import 'dart:typed_data';

import 'package:http/http.dart' as http;

Future<Uint8List> readRecordingBytes(
  String path, {
  required http.Client httpClient,
}) async {
  try {
    final response = await httpClient.get(Uri.parse(path));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('تعذر قراءة التسجيل الصوتي من المتصفح.');
    }
    return response.bodyBytes;
  } finally {
    httpClient.close();
  }
}
