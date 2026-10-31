import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

Future<Uint8List> readRecordingBytes(
  String path, {
  required http.Client httpClient,
}) async {
  final file = File(path);
  try {
    if (!await file.exists()) {
      throw StateError('Recording file not found.');
    }
    return await file.readAsBytes();
  } finally {
    if (await file.exists()) await file.delete();
    httpClient.close();
  }
}
