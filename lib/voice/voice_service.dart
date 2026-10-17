// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_tts/flutter_tts.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:speech_to_text/speech_recognition_error.dart';
// import 'package:speech_to_text/speech_to_text.dart';
// import '../strings.dart';

// enum VoiceState { idle, listening, processing, speaking, success, error }

// /// One reusable service for ALL speech in the app (TTS + STT + language +
// /// state). Screens never talk to the speech plugins directly.
// class VoiceService extends ChangeNotifier {
//   final FlutterTts _tts = FlutterTts();
//   final SpeechToText _stt = SpeechToText();

//   VoiceState state = VoiceState.idle;
//   AppLang lang = AppLang.en; // language chosen by the user
//   AppLang _voiceLang = AppLang.en; // language the TTS voice actually uses
//   String? _sttLocale;
//   AppLang? _resolvedFor;
//   bool _sttReady = false;

//   String heard = '';
//   String spoken = 'Ready to guide you.';
//   double rate = 1.0;
//   bool haptics = true;
//   bool cancelled = false;
//   String? lastError;

//   Completer<String?>? _pending;
//   String _last = '';
//   Timer? _flash;

//   String get stateLabel => const {
//         VoiceState.idle: 'Ready',
//         VoiceState.listening: 'Listening...',
//         VoiceState.processing: 'Thinking...',
//         VoiceState.speaking: 'Speaking...',
//         VoiceState.success: 'Done',
//         VoiceState.error: 'Try again',
//       }[state]!;

//   /// Maps the last recognition error to a spoken-message key.
//   String get errorKey {
//     switch (lastError) {
//       case 'error_permission':
//       case 'permission':
//         return 'micDenied';
//       case 'error_network':
//       case 'error_network_timeout':
//       case 'error_server':
//         return 'offline';
//       case 'error_language_not_supported':
//       case 'error_language_unavailable':
//         return 'langUnsupported';
//       case 'error_no_match':
//       case 'error_speech_timeout':
//       case null:
//         return 'noHear';
//       default:
//         return 'sttUnavailable';
//     }
//   }

//   void _set(VoiceState s, {bool haptic = true}) {
//     state = s;
//     if (haptics && haptic) {
//       if (s == VoiceState.listening) HapticFeedback.mediumImpact();
//       if (s == VoiceState.success) HapticFeedback.lightImpact();
//       if (s == VoiceState.error) HapticFeedback.heavyImpact();
//     }
//     notifyListeners();
//   }

//   /// Show success/error for 1.5 s, then go back to idle.
//   void flash(VoiceState s) {
//     _flash?.cancel();
//     _set(s);
//     _flash = Timer(const Duration(milliseconds: 1500), () {
//       if (state == s) _set(VoiceState.idle);
//     });
//   }

//   void markProcessing() => _set(VoiceState.processing);

//   // ---------------------------------------------------------------- setup
//   Future<String> init(AppLang l, double r) async {
//     rate = r;
//     try {
//       await _tts.awaitSpeakCompletion(true);
//       await _tts.setSpeechRate((rate * 0.5).clamp(0.2, 1.0));
//       await _tts.setVolume(1.0);
//     } catch (_) {}
//     return setLanguage(l);
//   }

//   Future<bool> _ttsHas(AppLang l) async {
//     try {
//       final r = await _tts.isLanguageAvailable(l.ttsTag);
//       return r == true || r == 1;
//     } catch (_) {
//       return false;
//     }
//   }

//   /// Returns a (possibly empty) English note about any fallback that was needed.
//   Future<String> setLanguage(AppLang l) async {
//     lang = l;
//     _resolvedFor = null;
//     final notes = <String>[];
//     if (await _ttsHas(l)) {
//       _voiceLang = l;
//     } else {
//       _voiceLang = (l == AppLang.mr && await _ttsHas(AppLang.hi)) ? AppLang.hi : AppLang.en;
//       notes.add('A ${l.english} voice is not installed on this phone, so I will speak using '
//           '${_voiceLang.english}. You can install ${l.english} voice data in the phone text to speech settings.');
//     }
//     try {
//       await _tts.setLanguage(_voiceLang.ttsTag);
//     } catch (_) {}
//     // Only touch the recogniser if the mic is already allowed, otherwise the
//     // plugin would pop a permission dialog before we have explained it.
//     if (await Permission.microphone.isGranted) notes.add(await prepareListening());
//     notifyListeners();
//     return notes.where((n) => n.isNotEmpty).join(' ');
//   }

//   Future<void> setRate(double r) async {
//     rate = r;
//     try {
//       await _tts.setSpeechRate((rate * 0.5).clamp(0.2, 1.0));
//     } catch (_) {}
//     notifyListeners();
//   }

//   Future<bool> _ensureStt() async {
//     if (_sttReady) return true;
//     try {
//       _sttReady = await _stt.initialize(onStatus: _onStatus, onError: _onError);
//     } catch (_) {
//       _sttReady = false;
//     }
//     return _sttReady;
//   }

//   /// Picks the recogniser locale for the chosen language. Returns an English
//   /// note if the language is unsupported and English is used instead.
//   Future<String> prepareListening() async {
//     if (_resolvedFor == lang) return '';
//     if (!await _ensureStt()) return '';
//     String n(String s) => s.replaceAll('-', '_').toLowerCase();
//     final locales = await _stt.locales();
//     String? find(AppLang l) {
//       for (final x in locales) {
//         if (n(x.localeId) == n(l.sttTag)) return x.localeId;
//       }
//       for (final x in locales) {
//         if (n(x.localeId).startsWith('${l.name}_')) return x.localeId;
//       }
//       return null;
//     }

//     _resolvedFor = lang;
//     _sttLocale = find(lang);
//     if (_sttLocale == null && lang != AppLang.en) {
//       _sttLocale = find(AppLang.en);
//       return 'Speech recognition for ${lang.english} is not available on this phone, so I will listen in English. '
//           'You can still use the buttons.';
//     }
//     return '';
//   }

//   // ------------------------------------------------------------------ TTS
//   Future<void> speak(String text, {bool forceEn = false}) async {
//     if (text.trim().isEmpty) return;
//     if (state == VoiceState.listening) {
//       // never listen to ourselves: cancel any open microphone session first
//       cancelled = true;
//       try {
//         await _stt.cancel();
//       } catch (_) {}
//       _finish(null);
//     }
//     spoken = text;
//     _flash?.cancel();
//     _set(VoiceState.speaking);
//     final swap = forceEn && _voiceLang != AppLang.en;
//     try {
//       await _tts.stop();
//       if (swap) await _tts.setLanguage('en-IN');
//       await _tts.speak(text);
//       if (swap) await _tts.setLanguage(_voiceLang.ttsTag);
//     } catch (_) {
//       lastError = 'tts'; // the text stays visible in the guidance bar
//     }
//     if (state == VoiceState.speaking) _set(VoiceState.idle);
//   }

//   Future<void> stop() async {
//     cancelled = true;
//     try {
//       await _tts.stop();
//     } catch (_) {}
//     try {
//       await _stt.cancel();
//     } catch (_) {}
//     _finish(null);
//     if (state == VoiceState.speaking || state == VoiceState.listening) _set(VoiceState.idle);
//   }

//   // ------------------------------------------------------------------ STT
//   void _onStatus(String s) {
//     if (s == 'done' || s == 'notListening') _finish(_last.isEmpty ? null : _last);
//   }

//   void _onError(SpeechRecognitionError e) {
//     lastError = e.errorMsg;
//     _finish(null);
//   }

//   void _finish(String? v) {
//     final c = _pending;
//     if (c != null && !c.isCompleted) c.complete(v);
//   }

//   /// Listens for one utterance. Returns null on silence / error / cancel and
//   /// sets [lastError] so the caller can say something truthful.
//   Future<String?> listenOnce({Duration max = const Duration(seconds: 10), bool quiet = false}) async {
//     lastError = null;
//     cancelled = false;
//     _last = '';
//     heard = '';
//     if (!await Permission.microphone.isGranted) {
//       lastError = 'permission';
//       return null;
//     }
//     if (!await _ensureStt()) {
//       lastError = 'unavailable';
//       return null;
//     }
//     await prepareListening();
//     try {
//       await _tts.stop();
//     } catch (_) {}
//     final c = _pending = Completer<String?>();
//     _set(VoiceState.listening, haptic: !quiet);
//     try {
//       await _stt.listen(
//         localeId: _sttLocale,
//         listenFor: max,
//         pauseFor: const Duration(seconds: 3),
//         listenOptions: SpeechListenOptions(
//             partialResults: true, cancelOnError: true, listenMode: ListenMode.confirmation),
//         onResult: (r) {
//           _last = r.recognizedWords;
//           heard = _last;
//           notifyListeners();
//           if (r.finalResult) _finish(_last.isEmpty ? null : _last);
//         },
//       );
//     } catch (_) {
//       lastError = 'unavailable';
//       _finish(null);
//     }
//     final res = await c.future.timeout(max + const Duration(seconds: 4), onTimeout: () {
//       _stt.stop();
//       return _last.isEmpty ? null : _last;
//     });
//     _pending = null;
//     if (res == null && !cancelled) {
//       _set(quiet ? VoiceState.idle : VoiceState.error);
//     } else if (res != null) {
//       _set(VoiceState.processing);
//     }
//     return res;
//   }
// }

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../config.dart';
import '../strings.dart';
import 'speech_utils.dart';

enum VoiceState { idle, listening, processing, speaking, success, error }

/// What this phone can really do for a language.
class LangCheck {
  final bool tts, stt;
  const LangCheck(this.tts, this.stt);
  bool get ok => tts && stt;
}

/// One reusable service for ALL speech in the app (TTS + STT + language +
/// state). Screens never talk to the speech plugins directly.
class VoiceService extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();

  VoiceState state = VoiceState.idle;
  AppLang lang = AppLang.en; // language chosen by the user
  AppLang _voiceLang = AppLang.en; // language the TTS voice actually uses
  String? _sttLocale;
  AppLang? _resolvedFor;
  bool _sttReady = false;

  String heard = '';
  String spoken = 'Ready to guide you.';
  double rate = 1.0;
  bool haptics = true;
  bool cancelled = false;
  String? lastError;

  Completer<String?>? _pending;
  String _last = '';
  Timer? _flash;

  String get stateLabel => const {
        VoiceState.idle: 'Ready',
        VoiceState.listening: 'Listening...',
        VoiceState.processing: 'Thinking...',
        VoiceState.speaking: 'Speaking...',
        VoiceState.success: 'Done',
        VoiceState.error: 'Try again',
      }[state]!;

  /// Maps the last recognition error to a spoken-message key.
  String get errorKey {
    switch (lastError) {
      case 'error_permission':
      case 'permission':
        return 'micDenied';
      case 'error_network':
      case 'error_network_timeout':
      case 'error_server':
        return 'offline';
      case 'error_language_not_supported':
      case 'error_language_unavailable':
        return 'langUnsupported';
      case 'error_no_match':
      case 'error_speech_timeout':
      case null:
        return 'noHear';
      default:
        return 'sttUnavailable';
    }
  }

  void _set(VoiceState s, {bool haptic = true}) {
    state = s;
    if (haptics && haptic) {
      if (s == VoiceState.listening) HapticFeedback.mediumImpact();
      if (s == VoiceState.success) HapticFeedback.lightImpact();
      if (s == VoiceState.error) HapticFeedback.heavyImpact();
    }
    notifyListeners();
  }

  /// Show success/error for 1.5 s, then go back to idle.
  void flash(VoiceState s) {
    _flash?.cancel();
    _set(s);
    _flash = Timer(const Duration(milliseconds: 1500), () {
      if (state == s) _set(VoiceState.idle);
    });
  }

  void markProcessing() => _set(VoiceState.processing);

  // ---------------------------------------------------------------- setup
  Future<String> init(AppLang l, double r) async {
    rate = r;
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate((rate * 0.5).clamp(0.2, 1.0));
      await _tts.setVolume(1.0);
    } catch (_) {}
    return setLanguage(l);
  }

  Future<bool> _ttsHas(AppLang l) async {
    try {
      final r = await _tts.isLanguageAvailable(l.ttsTag);
      return r == true || r == 1;
    } catch (_) {
      return false;
    }
  }

  /// Returns a (possibly empty) English note about any fallback that was needed.
  Future<String> setLanguage(AppLang l) async {
    lang = l;
    _resolvedFor = null;
    final notes = <String>[];
    if (await _ttsHas(l)) {
      _voiceLang = l;
    } else {
      _voiceLang = (l == AppLang.mr && await _ttsHas(AppLang.hi))
          ? AppLang.hi
          : AppLang.en;
      notes.add(
          'A ${l.english} voice is not installed on this phone, so I will speak using '
          '${_voiceLang.english}. You can install ${l.english} voice data in the phone text to speech settings.');
    }
    try {
      await _tts.setLanguage(_voiceLang.ttsTag);
    } catch (_) {}
    // Only touch the recogniser if the mic is already allowed, otherwise the
    // plugin would pop a permission dialog before we have explained it.
    if (await Permission.microphone.isGranted)
      notes.add(await prepareListening());
    notifyListeners();
    return notes.where((n) => n.isNotEmpty).join(' ');
  }

  /// Honest availability check: is there a TTS voice AND a speech-recognition locale for [l]?
  Future<LangCheck> checkSupport(AppLang l) async {
    final tts = await _ttsHas(l);
    var stt = false;
    try {
      if (await _ensureStt()) {
        String n(String s) => s.replaceAll('-', '_').toLowerCase();
        final locales = await _stt.locales();
        stt = locales.any((x) =>
            n(x.localeId) == n(l.sttTag) ||
            n(x.localeId).startsWith('${l.name}_'));
      }
    } catch (_) {}
    return LangCheck(tts, stt);
  }

  Future<void> setRate(double r) async {
    rate = r;
    try {
      await _tts.setSpeechRate((rate * 0.5).clamp(0.2, 1.0));
    } catch (_) {}
    notifyListeners();
  }

  Future<bool> _ensureStt() async {
    if (_sttReady) return true;
    try {
      _sttReady = await _stt.initialize(onStatus: _onStatus, onError: _onError);
    } catch (_) {
      _sttReady = false;
    }
    return _sttReady;
  }

  /// Picks the recogniser locale for the chosen language. Returns an English
  /// note if the language is unsupported and English is used instead.
  Future<String> prepareListening() async {
    if (_resolvedFor == lang) return '';
    if (!await _ensureStt()) return '';
    String n(String s) => s.replaceAll('-', '_').toLowerCase();
    final locales = await _stt.locales();
    String? find(AppLang l) {
      for (final x in locales) {
        if (n(x.localeId) == n(l.sttTag)) return x.localeId;
      }
      for (final x in locales) {
        if (n(x.localeId).startsWith('${l.name}_')) return x.localeId;
      }
      return null;
    }

    _resolvedFor = lang;
    _sttLocale = find(lang);
    if (_sttLocale == null && lang != AppLang.en) {
      _sttLocale = find(AppLang.en);
      return 'Speech recognition for ${lang.english} is not available on this phone, so I will listen in English. '
          'You can still use the buttons.';
    }
    return '';
  }

  // ------------------------------------------------------------------ TTS
  Future<void> speak(String text, {bool forceEn = false}) async {
    if (text.trim().isEmpty) return;
    if (state == VoiceState.listening) {
      // never listen to ourselves: cancel any open microphone session first
      cancelled = true;
      try {
        await _stt.cancel();
      } catch (_) {}
      _finish(null);
    }
    spoken = text;
    _flash?.cancel();
    _set(VoiceState.speaking);
    final swap = forceEn && _voiceLang != AppLang.en;
    try {
      await _tts.stop();
      if (swap) await _tts.setLanguage('en-IN');
      if (kBargeIn && text.length > 60) unawaited(_startBarge());
      await _tts.speak(text);
      if (swap) await _tts.setLanguage(_voiceLang.ttsTag);
    } catch (_) {
      lastError = 'tts'; // the text stays visible in the guidance bar
    }
    await _endBarge();
    if (state == VoiceState.speaking) _set(VoiceState.idle);
  }

  // Voice barge-in: while Kalpana talks, listen ONLY for "okay got it" / "okay stop" etc.
  // It only stops the audio. It never cancels a confirmation or deletes anything.
  bool _bargeOn = false, _barging = false;

  Future<void> _startBarge() async {
    try {
      if (!await Permission.microphone.isGranted || !await _ensureStt()) return;
      _bargeOn = _barging = true;
      await _stt.listen(
        localeId: _sttLocale,
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 30),
        listenOptions: SpeechListenOptions(
            partialResults: true,
            cancelOnError: false,
            listenMode: ListenMode.dictation),
        onResult: (r) {
          if (_barging && isStopSpeech(r.recognizedWords)) {
            _barging = false;
            _tts.stop();
          }
        },
      );
    } catch (_) {
      _bargeOn = _barging = false;
    }
  }

  Future<void> _endBarge() async {
    if (!_bargeOn) return;
    _bargeOn = _barging = false;
    try {
      await _stt.cancel();
    } catch (_) {}
  }

  Future<void> stop() async {
    cancelled = true;
    try {
      await _tts.stop();
    } catch (_) {}
    try {
      await _stt.cancel();
    } catch (_) {}
    _finish(null);
    if (state == VoiceState.speaking || state == VoiceState.listening)
      _set(VoiceState.idle);
  }

  // ------------------------------------------------------------------ STT
  void _onStatus(String s) {
    if (s == 'done' || s == 'notListening')
      _finish(_last.isEmpty ? null : _last);
  }

  void _onError(SpeechRecognitionError e) {
    if (_pending == null)
      return; // errors from the barge-in listener are not ours
    lastError = e.errorMsg;
    _finish(null);
  }

  void _finish(String? v) {
    final c = _pending;
    if (c != null && !c.isCompleted) c.complete(v);
  }

  /// Listens for one utterance. Returns null on silence / error / cancel and
  /// sets [lastError] so the caller can say something truthful.
  Future<String?> listenOnce(
      {Duration max = const Duration(seconds: 10), bool quiet = false}) async {
    lastError = null;
    cancelled = false;
    _last = '';
    heard = '';
    if (!await Permission.microphone.isGranted) {
      lastError = 'permission';
      return null;
    }
    if (!await _ensureStt()) {
      lastError = 'unavailable';
      return null;
    }
    await prepareListening();
    try {
      await _tts.stop();
    } catch (_) {}
    final c = _pending = Completer<String?>();
    _set(VoiceState.listening, haptic: !quiet);
    try {
      await _stt.listen(
        localeId: _sttLocale,
        listenFor: max,
        pauseFor: const Duration(seconds: 3),
        listenOptions: SpeechListenOptions(
            partialResults: true,
            cancelOnError: true,
            listenMode: ListenMode.confirmation),
        onResult: (r) {
          _last = r.recognizedWords;
          heard = _last;
          notifyListeners();
          if (r.finalResult) _finish(_last.isEmpty ? null : _last);
        },
      );
    } catch (_) {
      lastError = 'unavailable';
      _finish(null);
    }
    final res =
        await c.future.timeout(max + const Duration(seconds: 4), onTimeout: () {
      _stt.stop();
      return _last.isEmpty ? null : _last;
    });
    _pending = null;
    if (res == null && !cancelled) {
      _set(quiet ? VoiceState.idle : VoiceState.error);
    } else if (res != null) {
      _set(VoiceState.processing);
    }
    return res;
  }
}
