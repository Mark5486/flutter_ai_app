import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../errors/exceptions.dart';

abstract class GeminiService {
  Stream<String> generateStreamResponse({
    required String prompt,
    required List<Content> history,
    String? systemInstruction,
    List<Uint8List>? imageBytesList,
    Uint8List? pdfBytes,
  });

  Future<String> analyzeVideo({
    required Uint8List videoBytes,
    required String prompt,
  });
}

class GeminiServiceImpl implements GeminiService {
  final String _apiKey;

  GeminiServiceImpl({required String apiKey}) : _apiKey = apiKey;

  GenerativeModel _getModel({String? systemInstruction}) {
    return GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      systemInstruction:
          systemInstruction != null ? Content.system(systemInstruction) : null,
    );
  }

  @override
  Stream<String> generateStreamResponse({
    required String prompt,
    required List<Content> history,
    String? systemInstruction,
    List<Uint8List>? imageBytesList,
    Uint8List? pdfBytes,
  }) async* {
    try {
      final model = _getModel(systemInstruction: systemInstruction);
      final chat = model.startChat(history: history);

      final List<Part> parts = [TextPart(prompt)];

      if (imageBytesList != null) {
        for (final bytes in imageBytesList) {
          parts.add(DataPart('image/jpeg', bytes));
        }
      }

      if (pdfBytes != null) {
        parts.add(DataPart('application/pdf', pdfBytes));
      }

      final content = Content.multi(parts);
      final responseStream = chat.sendMessageStream(content);

      await for (final chunk in responseStream) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      throw AIException('فشل في توليد الاستجابة من Gemini: ${e.toString()}');
    }
  }

  @override
  Future<String> analyzeVideo({
    required Uint8List videoBytes,
    required String prompt,
  }) async {
    try {
      final model = _getModel();
      final content = Content.multi([
        TextPart(prompt),
        DataPart('video/mp4', videoBytes),
      ]);

      final response = await model.generateContent([content]);
      return response.text ?? 'لم يتم استخراج معلومات من الفيديو';
    } catch (e) {
      throw AIException('فشل في تحليل الفيديو: ${e.toString()}');
    }
  }
}
