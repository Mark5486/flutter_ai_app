import 'dart:typed_data';

import 'package:http/http.dart' as http;

Future<Uint8List> readRecordingBytes(
  String path, {
  required http.Client httpClient,
}) {
  throw UnsupportedError('Audio recording is not supported on this platform.');
}
