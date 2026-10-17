import 'package:speech_to_text/speech_to_text.dart';

abstract class VoiceInputService {
  Future<bool> initialize();
  Future<void> startListening({required Function(String text) onResult});
  Future<void> stopListening();
  bool get isListening;
}

class VoiceInputServiceImpl implements VoiceInputService {
  final SpeechToText _speechToText = SpeechToText();

  @override
  Future<bool> initialize() async {
    return await _speechToText.initialize();
  }

  @override
  Future<void> startListening({required Function(String text) onResult}) async {
    if (!_speechToText.isListening) {
      await _speechToText.listen(
        onResult: (result) => onResult(result.recognizedWords),
        listenOptions: SpeechListenOptions(localeId: 'ar_SA'),
      );
    }
  }

  @override
  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  @override
  bool get isListening => _speechToText.isListening;
}
