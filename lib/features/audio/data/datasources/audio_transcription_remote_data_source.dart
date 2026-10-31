import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

abstract interface class IAudioTranscriptionRemoteDataSource {
  Future<String> transcribe(Uint8List bytes);
}

class AudioTranscriptionRemoteDataSourceImpl
    implements IAudioTranscriptionRemoteDataSource {
  AudioTranscriptionRemoteDataSourceImpl({
    required FirebaseAuth auth,
    required http.Client client,
    required String baseUrl,
  }) : _auth = auth,
       _client = client,
       _baseUrl = baseUrl;

  final FirebaseAuth _auth;
  final http.Client _client;
  final String _baseUrl;

  @override
  Future<String> transcribe(Uint8List bytes) async {
    if (_baseUrl.trim().isEmpty) {
      throw StateError('لم يتم إعداد رابط خدمة تفريغ الصوت بعد.');
    }

    final user = _auth.currentUser;
    if (user == null) throw StateError('يجب تسجيل الدخول لتفريغ الصوت.');

    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw StateError('تعذر التحقق من جلسة تسجيل الدخول.');
    }

    final uri = Uri.parse(_baseUrl).resolve('/transcribe');
    final request =
        http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer $idToken'
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              bytes,
              filename: kIsWeb ? 'recording.webm' : 'recording.m4a',
            ),
          );

    final streamedResponse = await _client
        .send(request)
        .timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'فشل تفريغ التسجيل الصوتي.';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['error'] is String) {
          message = decoded['error'] as String;
        }
      } catch (_) {}
      throw StateError(message);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['text'] is! String) {
      throw const FormatException('استجابة تفريغ الصوت غير صالحة.');
    }

    final text = (decoded['text'] as String).trim();
    if (text.isEmpty) throw StateError('لم يتم التعرف على كلام في التسجيل.');
    return text;
  }
}
