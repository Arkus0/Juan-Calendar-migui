import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    // Request microphone permission first
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      debugPrint('Microphone permission denied');
      return false;
    }

    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          debugPrint('Voice error: $error');
          _isInitialized = false;
        },
        onStatus: (status) => debugPrint('Voice status: $status'),
      );

      // Re-check availability
      if (!_isInitialized) {
        debugPrint('SpeechToText.initialize returned false, retrying once...');
        _isInitialized = await _speechToText.initialize(
          onError: (error) => debugPrint('Voice error retry: $error'),
          onStatus: (status) => debugPrint('Voice status retry: $status'),
        );
      }
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
      listenFor: const Duration(seconds: 30),
      listenOptions: SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
        listenMode: ListenMode.dictation,
      ),
    );
    onListeningStateChanged(true);

    // Safety: if no result arrives after a timeout, stop listening and notify.
    Future.delayed(const Duration(seconds: 35), () {
      if (_speechToText.isListening) {
        debugPrint('Voice timeout, stopping listen');
        _speechToText.stop();
        onListeningStateChanged(false);
      }
    });
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  bool get isListening => _speechToText.isListening;
}
