import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) => debugPrint('Voice error: $error'),
        onStatus: (status) => debugPrint('Voice status: $status'),
      );
    } catch (e) {
      debugPrint('Voice init error: $e');
      _isInitialized = false;
    }
    return _isInitialized;
  }

  Future<void> startListening({
    required Function(String) onResult,
    required Function(bool) onListeningStateChanged,
  }) async {
    if (!_isInitialized) {
      bool initialized = await initialize();
      if (!initialized) {
        onListeningStateChanged(false);
        return;
      }
    }

    final List<LocaleName> locales = await _speechToText.locales();
    LocaleName? selectedLocale;
    try {
      selectedLocale = locales.firstWhere(
        (element) => element.localeId.startsWith('es'),
      );
    } catch (e) {
      if (locales.isNotEmpty) {
        selectedLocale = locales.first;
      }
    }

    await _speechToText.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
        if (result.finalResult) {
          onListeningStateChanged(false);
        }
      },
      localeId: selectedLocale?.localeId,
      listenOptions: SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
        listenMode: ListenMode.dictation,
      ),
    );
    onListeningStateChanged(true);
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  bool get isListening => _speechToText.isListening;
}
