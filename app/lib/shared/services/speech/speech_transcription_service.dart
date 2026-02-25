import 'dart:async';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

typedef SpeechStatusCallback = void Function(String status);
typedef SpeechErrorCallback = void Function(String message);
typedef SpeechResultCallback =
    void Function(String recognizedWords, {required bool isFinal});

abstract class ISpeechTranscriptionService {
  bool get isAvailable;
  bool get isListening;

  Future<bool> ensureInitialized({
    required SpeechStatusCallback onStatus,
    required SpeechErrorCallback onError,
  });

  Future<bool> startListening({
    required SpeechResultCallback onResult,
    String localeId = 'pt_BR',
    Duration listenFor = const Duration(seconds: 45),
    Duration pauseFor = const Duration(seconds: 3),
    bool partialResults = true,
  });

  Future<void> stopListening();
  Future<void> cancelListening();
}

class SpeechTranscriptionService implements ISpeechTranscriptionService {
  SpeechTranscriptionService();

  final SpeechToText _speechToText = SpeechToText();

  bool _initialized = false;
  bool _available = false;
  SpeechStatusCallback? _onStatus;
  SpeechErrorCallback? _onError;
  Future<void> _serialOperation = Future<void>.value();

  @override
  bool get isAvailable => _available;

  @override
  bool get isListening => _speechToText.isListening;

  @override
  Future<bool> ensureInitialized({
    required SpeechStatusCallback onStatus,
    required SpeechErrorCallback onError,
  }) async {
    _onStatus = onStatus;
    _onError = onError;

    if (_initialized && _available) return true;

    final available = await _speechToText.initialize(
      onStatus: _handleStatus,
      onError: _handleError,
      debugLogging: false,
    );

    _initialized = true;
    _available = available;
    return available;
  }

  @override
  Future<bool> startListening({
    required SpeechResultCallback onResult,
    String localeId = 'pt_BR',
    Duration listenFor = const Duration(seconds: 45),
    Duration pauseFor = const Duration(seconds: 3),
    bool partialResults = true,
  }) async {
    return _runSerial(() async {
      if (!_available || !_initialized) return false;

      try {
        await _settleSpeechEngine();

        final result = await _speechToText.listen(
          onResult: (SpeechRecognitionResult result) {
            onResult(result.recognizedWords, isFinal: result.finalResult);
          },
          localeId: localeId,
          listenFor: listenFor,
          pauseFor: pauseFor,
          listenOptions: SpeechListenOptions(
            partialResults: partialResults,
            listenMode: ListenMode.dictation,
          ),
        );
        if (result is bool) return result;
        return _speechToText.isListening;
      } catch (_) {
        _onError?.call('Falha ao iniciar captura de voz.');
        return false;
      }
    });
  }

  @override
  Future<void> stopListening() {
    return _runSerial(() async {
      try {
        if (_speechToText.isListening) {
          await _speechToText.stop();
        }
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 220));
    });
  }

  @override
  Future<void> cancelListening() {
    return _runSerial(() async {
      try {
        await _speechToText.cancel();
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 220));
    });
  }

  void _handleStatus(String status) {
    _onStatus?.call(status);
  }

  void _handleError(SpeechRecognitionError error) {
    final message = error.errorMsg.trim();
    _onError?.call(
      message.isNotEmpty ? message : 'Falha ao processar transcrição por voz.',
    );
  }

  Future<void> _settleSpeechEngine() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
    await _speechToText.cancel();
    await Future<void>.delayed(const Duration(milliseconds: 260));
  }

  Future<T> _runSerial<T>(Future<T> Function() action) {
    final completer = Completer<T>();

    _serialOperation = _serialOperation.then((_) async {
      try {
        final value = await action();
        completer.complete(value);
      } catch (err, stack) {
        completer.completeError(err, stack);
      }
    });

    return completer.future;
  }
}
