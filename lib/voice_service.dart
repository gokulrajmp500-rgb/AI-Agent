import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  Process? _windowsProcess;
  bool _isListening = false;
  bool _ttsEnabled = true;
  String? _lastError;

  String? get errorMessage => _lastError;

  Future<bool> initialize() async {
    try {
      _lastError = null;
      if (!kIsWeb && Platform.isWindows) {
        // On Windows, use native PowerShell speech recognition instead of the plugin.
        _ttsEnabled = true;
        return true;
      }

      final available = await _speech.initialize(
        onError: (error) {
          _lastError = 'Speech error: ${error.errorMsg}';
        },
        onStatus: (status) {
          if (status == 'listening') {
            _isListening = true;
          } else if (status == 'notListening' || status == 'done') {
            _isListening = false;
          }
        },
      );
      if (!available) {
        final hasPermission = await _speech.hasPermission;
        _lastError = hasPermission
            ? 'Speech recognition is unavailable. Please make sure a microphone is connected and try again.'
            : 'Microphone permission is required. Please allow microphone access in Windows privacy settings.';
        return false;
      }

      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      return true;
    } catch (e) {
      _lastError = 'Voice initialization failed. $e';
      _ttsEnabled = false;
      return false;
    }
  }

  Future<bool> startListening(
    Future<void> Function(String recognizedWords, bool isFinal) onResult, {
    void Function(String errorMessage)? onError,
  }) async {
    if (_isListening) {
      return false;
    }

    if (!kIsWeb && Platform.isWindows) {
      _isListening = true;
      _lastError = null;
      try {
        final script =
            r"Add-Type -AssemblyName System.Speech; "
            r"$recognizer = New-Object System.Speech.Recognition.SpeechRecognitionEngine([System.Globalization.CultureInfo]::CurrentCulture); "
            r"$recognizer.SetInputToDefaultAudioDevice(); "
            r"$grammar = New-Object System.Speech.Recognition.DictationGrammar; "
            r"$recognizer.LoadGrammar($grammar); "
            r"$result = $recognizer.Recognize([TimeSpan]::FromSeconds(12)); "
            r"if ($result) { $result.Text } else { Write-Error 'No speech result was returned.'; exit 1 }";

        _windowsProcess = await Process.start('powershell.exe', [
          '-NoProfile',
          '-Command',
          script,
        ], runInShell: false);

        _listenWindows(onResult, onError);
        return true;
      } catch (e) {
        _lastError = 'Windows speech recognition failed: $e';
        onError?.call(_lastError!);
        _isListening = false;
        return false;
      }
    }

    if (!_speech.isAvailable) {
      final available = await _speech.initialize(
        onError: (error) {
          _lastError = 'Speech error: ${error.errorMsg}';
        },
        onStatus: (status) {
          if (status == 'listening') {
            _isListening = true;
          } else if (status == 'notListening' || status == 'done') {
            _isListening = false;
          }
        },
      );
      if (!available) {
        final hasPermission = await _speech.hasPermission;
        _lastError = hasPermission
            ? 'Unable to start listening. Please make sure a microphone is connected.'
            : 'Microphone permission is required. Please allow microphone access in Windows privacy settings.';
        return false;
      }
    }

    _isListening = true;
    _lastError = null;
    await _speech.listen(
      onResult: (result) async {
        if (result.finalResult) {
          await onResult(result.recognizedWords, true);
          await stopListening();
        } else {
          await onResult(result.recognizedWords, false);
        }
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: true,
      ),
    );

    return true;
  }

  Future<String> stopListening() async {
    if (!kIsWeb && Platform.isWindows) {
      if (!_isListening) {
        return '';
      }
      _isListening = false;
      if (_windowsProcess != null) {
        try {
          _windowsProcess!.kill();
        } catch (_) {
          // Ignore if already exited.
        }
        _windowsProcess = null;
      }
      return '';
    }

    if (!_isListening) {
      return '';
    }
    await _speech.stop();
    _isListening = false;
    return _speech.lastRecognizedWords;
  }

  Future<void> _listenWindows(
    Future<void> Function(String recognizedWords, bool isFinal) onResult,
    void Function(String errorMessage)? onError,
  ) async {
    final process = _windowsProcess;
    if (process == null) {
      return;
    }

    try {
      final stdoutFuture = process.stdout.transform(utf8.decoder).join();
      final stderrFuture = process.stderr.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;
      final recognizedText = (await stdoutFuture).trim();
      final stderr = (await stderrFuture).trim();

      if (!_isListening) {
        return;
      }

      _isListening = false;
      _windowsProcess = null;

      if (exitCode != 0 || recognizedText.isEmpty) {
        final message = stderr.isNotEmpty
            ? 'Windows speech recognition error: $stderr'
            : 'I could not hear your command. Please check your microphone and try again.';
        _lastError = message;
        onError?.call(message);
        return;
      }

      await onResult(recognizedText, true);
    } catch (e) {
      if (!_isListening) {
        return;
      }
      _isListening = false;
      _windowsProcess = null;
      final message = 'Windows speech recognition failed: $e';
      _lastError = message;
      onError?.call(message);
    }
  }

  Future<void> speak(String text) async {
    if (text.isEmpty || !_ttsEnabled) {
      return;
    }

    try {
      if (!kIsWeb && Platform.isWindows) {
        final escaped = text.replaceAll("'", "''");
        final script =
            "Add-Type -AssemblyName System.Speech; "
            "\$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer; "
            "\$female = \$synth.GetInstalledVoices() | Where-Object { \$_.VoiceInfo.Gender -eq 'Female' } | Select-Object -First 1; "
            "if (\$female) { \$synth.SelectVoice(\$female.VoiceInfo.Name) }; "
            "\$synth.Rate = 0; \$synth.Volume = 100; \$synth.Speak('$escaped')";
        await Process.run('powershell.exe', ['-NoProfile', '-Command', script]);
        return;
      }

      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setPitch(1.15);
      await _flutterTts.speak(text);
    } catch (_) {
      _ttsEnabled = false;
    }
  }

  Future<void> dispose() async {
    if (kIsWeb || !Platform.isWindows) {
      await _speech.stop();
      if (_ttsEnabled) {
        await _flutterTts.stop();
      }
    }
  }
}
