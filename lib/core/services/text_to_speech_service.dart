import 'package:flutter_tts/flutter_tts.dart';

abstract class TextToSpeechService {
  Future<void> speak(String text);
  Future<void> stop();
}

class TextToSpeechServiceImpl implements TextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();

  TextToSpeechServiceImpl() {
    _flutterTts.setLanguage('ar');
    _flutterTts.setSpeechRate(0.5);
    _flutterTts.setVolume(1.0);
  }

  @override
  Future<void> speak(String text) async {
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
