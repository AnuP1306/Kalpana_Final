// import 'dart:async';
// import 'dart:io';
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:flutter_contacts/flutter_contacts.dart' as fc;
// import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
// import 'ai/gemini_service.dart';
// import 'config.dart';
// import 'vision/offline_vision.dart';
// import 'strings.dart';
// import 'theme.dart';
// import 'voice/command_router.dart';
// import 'voice/speech_utils.dart';
// import 'voice/voice_service.dart';
// import 'widgets.dart';

// /// Same 15 screens as the Bolt `Screen` union. Order matches `screenTitles`.
// enum Screen {
//   welcome,
//   onboarding,
//   dashboard,
//   camera,
//   voice,
//   explore,
//   ocr,
//   location,
//   sos,
//   community,
//   help,
//   settings,
//   daily,
//   dial,
//   color
// }

// class Contact {
//   final String label, number;
//   const Contact(this.label, this.number);
// }

// class ScreenInfo {
//   final String subtitle, heading, body;
//   final IconData icon;
//   final Color? accent;
//   final bool demo;
//   const ScreenInfo(this.subtitle, this.icon, this.heading, this.body,
//       {this.accent, this.demo = false});
// }

// class AppController extends ChangeNotifier {
//   final navKey = GlobalKey<NavigatorState>();
//   final voice = VoiceService();
//   final ai = GeminiService();
//   final vision = OfflineVision();
//   bool online = true;
//   Timer? _netTimer;
//   late final CommandRouter router = CommandRouter(this);
//   SharedPreferences? _prefs;

//   Screen screen = Screen.welcome;
//   final nameCtl = TextEditingController();
//   final phoneCtl = TextEditingController();
//   final emergencyCtl = TextEditingController();
//   final chatCtl = TextEditingController();
//   final typedCtl = TextEditingController();
//   bool haptics = true, highContrast = true, onboarded = false;
//   bool micOk = false, camOk = false, locOk = false, contactsOk = false;
//   bool _confirmTimedOut = false;
//   String? liveHeading, liveBody, liveSub;
//   Position? lastPos;

//   // reminders + camera results
//   List<String> reminders = [];
//   CameraController? cam;
//   Future<void>? _camFuture;
//   bool analysing = false;
//   String? captureBody;

//   // always-listening state
//   bool micOff = false;
//   int activeField = -1; // sign-up field being filled by voice
//   int _busy = 0, _flow = 0, _loopGen = 0;
//   bool _loopOn = false, _sessionEnded = false;
//   DateTime _awakeUntil = DateTime.fromMillisecondsSinceEpoch(0);
//   Timer? _awakeTimer;

//   bool get loopOn => _loopOn;
//   bool get awake => DateTime.now().isBefore(_awakeUntil);
//   bool get camReady => cam?.value.isInitialized ?? false;
//   static bool isCapture(Screen s) =>
//       s == Screen.camera ||
//       s == Screen.ocr ||
//       s == Screen.explore ||
//       s == Screen.color;

//   AppLang get lang => voice.lang;
//   String t(String k, [Map<String, String> a = const {}]) =>
//       tr(voice.lang, k, a);
//   String titleOf(Screen s) => screenTitles[lang.index][s.index];
//   String get firstName => nameCtl.text.trim().split(' ').first;
//   String _nameOr() => firstName.isNotEmpty
//       ? firstName
//       : const ['friend', 'दोस्त', 'मित्र'][lang.index];

//   AppController() {
//     voice.addListener(notifyListeners);
//   }

//   Future<T> _exclusive<T>(Future<T> Function() f) async {
//     _busy++;
//     try {
//       return await f();
//     } finally {
//       _busy--;
//     }
//   }

//   // ------------------------------------------------------------ lifecycle
//   Future<void> _init() async {
//     final p = _prefs = await SharedPreferences.getInstance();
//     nameCtl.text = p.getString('name') ?? '';
//     phoneCtl.text = p.getString('phone') ?? '';
//     emergencyCtl.text = p.getString('emergency') ?? '';
//     reminders = p.getStringList('reminders') ?? [];
//     haptics = p.getBool('haptics') ?? true;
//     highContrast = p.getBool('contrast') ?? true;
//     onboarded = p.getBool('onboarded') ?? false;
//     K.setContrast(highContrast);
//     voice.haptics = haptics;
//     micOk = await Permission.microphone.isGranted;
//     camOk = await Permission.camera.isGranted;
//     locOk = await Permission.locationWhenInUse.isGranted;
//     contactsOk = await Permission.contacts.isGranted;
//     final note = await voice.init(
//         AppLang.values[p.getInt('lang') ?? 0], p.getDouble('rate') ?? 1.0);
//     notifyListeners();
//     _netTimer ??=
//         Timer.periodic(const Duration(seconds: 15), (_) => _checkNet());
//     unawaited(_checkNet());
//     if (note.isNotEmpty) await voice.speak(note, forceEn: true);
//   }

//   Future<void> _checkNet() async {
//     var ok = false;
//     try {
//       final r = await InternetAddress.lookup('google.com')
//           .timeout(const Duration(seconds: 3));
//       ok = r.isNotEmpty && r.first.rawAddress.isNotEmpty;
//     } catch (_) {}
//     if (ok != online) {
//       online = ok;
//       notifyListeners();
//     }
//   }

//   /// App open: welcome -> (new user) voice sign-up, or (returning user) straight to listening.
//   Future<void> start() async {
//     await _init();
//     if (onboarded) {
//       await voice.speak(t('welcomeBack', {'name': _nameOr()}));
//       if (screen != Screen.welcome) return;
//       await go(Screen.dashboard, announce: false);
//       startLoop();
//       return;
//     }
//     await voice.speak(t('welcome'));
//     if (screen != Screen.welcome) return;
//     await beginFromButton();
//   }

//   Future<void> beginFromButton() async {
//     if (onboarded) {
//       await go(Screen.dashboard, announce: false);
//       startLoop();
//     } else {
//       await go(Screen.onboarding, announce: false);
//       await startSignup();
//     }
//   }

//   void onLifecycle(AppLifecycleState s) {
//     if (s == AppLifecycleState.resumed) {
//       if (onboarded && !micOff) startLoop();
//       if (isCapture(screen)) unawaited(initCamera());
//     } else if (s == AppLifecycleState.paused) {
//       stopLoop(); // never listen / talk in the background
//       unawaited(disposeCamera());
//     }
//   }

//   // ----------------------------------------------------------- navigation
//   Future<void> go(Screen s, {bool announce = true}) async {
//     await voice.stop();
//     voice.bargeEnabled = s != Screen.onboarding;
//     final leaving = isCapture(screen) && !isCapture(s);
//     screen = s;
//     if (isCapture(s)) {
//       captureBody = null;
//       analysing = false;
//     }
//     notifyListeners();
//     if (leaving) unawaited(disposeCamera());
//     if (announce) await _announce(s);
//   }

//   Future<void> back() async {
//     if (screen == Screen.onboarding) return go(Screen.welcome, announce: false);
//     if (screen != Screen.welcome && screen != Screen.dashboard)
//       return go(Screen.dashboard);
//   }

//   Future<void> openVoice() async {
//     if (screen != Screen.voice) await go(Screen.voice, announce: false);
//     await listenAndRun();
//   }

//   String greeting() {
//     final h = DateTime.now().hour;
//     final g = t(h < 12
//         ? 'greetMorning'
//         : h < 17
//             ? 'greetAfternoon'
//             : 'greetEvening');
//     return firstName.isEmpty ? g : '$g, $firstName';
//   }

//   Future<void> _announce(Screen s) async {
//     final title = titleOf(s);
//     switch (s) {
//       case Screen.dashboard:
//         await voice.speak('${greeting()}. ${t('dashHint')}');
//       case Screen.sos:
//         await voice.speak('$title. ${t('sosHint')}');
//       case Screen.help:
//         await voice.speak('$title. ${t('helpHint')}');
//       case Screen.location:
//         await whereAmI();
//       case Screen.daily:
//         await voice.speak('$title. ${_remindersSpeech()}');
//       case Screen.dial:
//         await voice.speak('$title. ${t('dialHint', {
//               'names': contacts.map((e) => e.label).join(', ')
//             })}');
//       case Screen.camera || Screen.explore || Screen.ocr || Screen.color:
//         await initCamera();
//         if (camReady) await voice.speak('$title. ${t('camReady')}');
//       case Screen.community:
//         final i = info(s);
//         await voice.speak('$title. ${t('demo')} ${i.heading}. ${i.body}');
//       default:
//         await voice.speak(title);
//     }
//   }

//   Future<void> readCurrent() async {
//     switch (screen) {
//       case Screen.voice:
//         return voice.speak(voice.spoken);
//       case Screen.location:
//         return whereAmI();
//       case Screen.camera || Screen.explore || Screen.ocr || Screen.color:
//         return voice.speak(captureBody ?? t('camReady'));
//       case Screen.dashboard ||
//             Screen.welcome ||
//             Screen.onboarding ||
//             Screen.help ||
//             Screen.daily:
//         return _announce(screen);
//       default:
//         final i = info(screen);
//         await voice
//             .speak('${i.demo ? '${t('demo')} ' : ''}${i.heading}. ${i.body}');
//     }
//   }

//   // -------------------------------------------- always-listening ("Hey Kalpana")
//   static final _wakeWord = RegExp(r'kalpana|kalpna|calpana|कल्पना|कल्पणा|कलपना',
//       caseSensitive: false, unicode: true);
//   static final _wakeFull = RegExp(
//       r'(?:(?:hey|hay|hi|hello|okay|ok|हे|हेय|हाय|हेलो|ओके)\s+)?(?:kalpana|kalpna|calpana|कल्पना|कल्पणा|कलपना)[\s,.!]*',
//       caseSensitive: false,
//       unicode: true);

//   void startLoop() {
//     if (_loopOn || micOff || !onboarded) return;
//     _loopOn = true;
//     unawaited(_runLoop());
//   }

//   void stopLoop() {
//     _loopGen++;
//     _loopOn = false;
//     voice.stop();
//     notifyListeners();
//   }

//   Future<void> _runLoop() async {
//     if (!await ensureMic()) {
//       _loopOn = false;
//       micOff = true;
//       notifyListeners();
//       return;
//     }
//     final gen = ++_loopGen;
//     notifyListeners();
//     var fails = 0;
//     try {
//       while (gen == _loopGen) {
//         while (gen == _loopGen &&
//             (_busy > 0 || voice.state == VoiceState.speaking)) {
//           await Future.delayed(const Duration(milliseconds: 150));
//         }
//         if (gen != _loopGen) break;
//         final heard = await voice.listenOnce(
//             max: const Duration(seconds: 8), quiet: true);
//         if (gen != _loopGen) break;
//         if (heard != null) {
//           fails = 0;
//           await _onUtterance(heard);
//           await Future.delayed(const Duration(milliseconds: 250));
//           continue;
//         }
//         final e = voice.lastError;
//         if (voice.cancelled ||
//             e == null ||
//             e == 'error_no_match' ||
//             e == 'error_speech_timeout') {
//           await Future.delayed(const Duration(milliseconds: 300));
//           continue;
//         }
//         if (e == 'error_busy' || e == 'error_client' || e == 'error_audio') {
//           await Future.delayed(const Duration(milliseconds: 1200));
//           continue;
//         }
//         fails++;
//         if (fails >= 3 ||
//             e == 'permission' ||
//             e == 'unavailable' ||
//             e == 'error_network' ||
//             e == 'error_language_not_supported') {
//           micOff =
//               true; // stop honestly instead of looping on a broken recogniser
//           _loopGen++;
//           await voice.speak('${t(voice.errorKey)} ${t('micOffMsg')}');
//           break;
//         }
//         await Future.delayed(const Duration(milliseconds: 1500));
//       }
//     } finally {
//       if (gen == _loopGen) _loopOn = false;
//       notifyListeners();
//     }
//   }

//   void _extendAwake() {
//     _awakeUntil = DateTime.now().add(const Duration(seconds: 20));
//     _awakeTimer?.cancel();
//     _awakeTimer = Timer(const Duration(seconds: 21), notifyListeners);
//     notifyListeners();
//   }

//   bool _awaitingMore = false;
//   DateTime _deaf = DateTime.fromMillisecondsSinceEpoch(
//       0); // ignore the mic briefly after she says "Hey Kalpana" herself
//   static final _thanksRe =
//       RegExp(r'thank|धन्यवाद|शुक्रिया|आभार|थैंक', unicode: true);
//   static final _noMoreRe = RegExp(
//       r'^(?:no|nope|nothing else|nothing|that s all|that is all|nahi|नहीं|नही|नाही|कुछ नहीं|काही नाही|बस)(?:\s|$)',
//       unicode: true);

//   Future<void> _endSession(String msg) async {
//     _sessionEnded = true;
//     _awaitingMore = false;
//     _awakeUntil = DateTime.fromMillisecondsSinceEpoch(0);
//     notifyListeners();
//     await voice.speak(msg);
//     _deaf = DateTime.now().add(const Duration(milliseconds: 1500));
//   }

//   Future<void> _onUtterance(String raw) async {
//     if (DateTime.now().isBefore(_deaf)) {
//       return;
//     }
//     final woke = _wakeWord.hasMatch(raw);
//     final wasAwake = awake;
//     if (!woke && !wasAwake) {
//       return; // not for us: ignore everything without the wake phrase
//     }
//     if (!wasAwake) {
//       _awaitingMore = false;
//     }
//     final cmd = raw.replaceFirst(_wakeFull, '').trim();
//     final n = normText(cmd);
//     final words = n.isEmpty ? 0 : n.split(' ').length;
//     _sessionEnded = false;
//     _extendAwake();
//     if (cmd.isEmpty) {
//       _awaitingMore = false;
//       await voice.speak(t('hiName', {'name': _nameOr()}));
//     } else if (_awaitingMore && _noMoreRe.hasMatch(n)) {
//       await _endSession(
//           t('byeReply')); // "okay, if you need anything say Hey Kalpana"
//       return;
//     } else if (_awaitingMore &&
//         words <= 3 &&
//         CommandRouter.parseYesNo(cmd) == true) {
//       _awaitingMore = false;
//       await voice.speak(t('sureHelp'));
//     } else if (words <= 5 && _thanksRe.hasMatch(n)) {
//       _awaitingMore =
//           true; // "okay thank you" -> you're welcome, anything else?
//       await voice.speak(t('thanksReply'));
//     } else {
//       _awaitingMore = false;
//       await handleUtterance(cmd);
//       if (screen == Screen.daily || screen == Screen.location) {
//         await _returnHome();
//       }
//     }
//     if (!_sessionEnded) {
//       _extendAwake();
//     }
//   }

//   Future<void> pauseSession() async {
//     _sessionEnded = true;
//     _awakeUntil = DateTime.fromMillisecondsSinceEpoch(0);
//     _awaitingMore = false;
//     notifyListeners();
//     await voice.speak(t('pausedMsg'));
//     _deaf = DateTime.now().add(const Duration(milliseconds: 1500));
//   }

//   Future<void> toggleMic() async {
//     if (micOff) {
//       micOff = false;
//       notifyListeners();
//       startLoop();
//       await voice.speak(t('micOnMsg'));
//     } else {
//       micOff = true;
//       stopLoop();
//       await voice.speak(t('micOffMsg'));
//     }
//   }

//   /// Understand a request (Gemini first, offline keyword router as fallback),
//   /// then act on it and answer.
//   Future<void> handleUtterance(String text) async {
//     voice.heard = text;
//     voice.markProcessing();
//     final r = (kUseCloudAi && online)
//         ? await ai.understand(text, lang, screen: screen.name, name: firstName)
//         : null;
//     if (r != null) {
//       if (r.command != null) {
//         final ok = await router.route(r.command!);
//         voice.flash(ok ? VoiceState.success : VoiceState.error);
//         if (!ok) await voice.speak(r.reply ?? t('notUnderstood', {'x': text}));
//         return;
//       }
//       if (r.reply != null) {
//         voice.flash(VoiceState.success);
//         await voice.speak(r.reply!);
//         return;
//       }
//     }
//     final ok = await router.route(text);
//     voice.flash(ok ? VoiceState.success : VoiceState.error);
//     if (!ok) await voice.speak(t('notUnderstood', {'x': text}));
//   }

//   /// Orb tap = push-to-talk (works even if the mic loop is off).
//   Future<void> listenAndRun() => _exclusive(() async {
//         await voice.stop();
//         if (!await ensureMic()) return;
//         final note = await voice.prepareListening();
//         if (note.isNotEmpty) await voice.speak(note, forceEn: true);
//         final heard = await voice.listenOnce();
//         if (heard == null) {
//           if (!voice.cancelled) await voice.speak(t(voice.errorKey));
//           return;
//         }
//         await handleUtterance(heard);
//         if (screen == Screen.daily || screen == Screen.location)
//           await _returnHome();
//       });

//   /// Chips / typed commands.
//   Future<void> runCommand(String text) async {
//     if (text.trim().isEmpty) return;
//     await handleUtterance(text);
//   }

//   // ---------------------------------------------------------- permissions
//   Future<bool> requestPerm(Permission p, String explain, String denied) async {
//     var s = await p.status;
//     if (!s.isGranted) {
//       if (s.isPermanentlyDenied) {
//         await voice.speak(t('openSettings'));
//         await openAppSettings();
//         s = await p.status;
//       } else {
//         await voice.speak(t(explain));
//         s = await p.request();
//       }
//     }
//     if (p == Permission.microphone) micOk = s.isGranted;
//     if (p == Permission.camera) camOk = s.isGranted;
//     if (p == Permission.locationWhenInUse) locOk = s.isGranted;
//     if (p == Permission.contacts) contactsOk = s.isGranted;
//     notifyListeners();
//     if (!s.isGranted) await voice.speak(t(denied));
//     return s.isGranted;
//   }

//   Future<bool> ensureMic() async {
//     if (micOk || await Permission.microphone.isGranted) return micOk = true;
//     return requestPerm(Permission.microphone, 'micExplain', 'micDenied');
//   }

//   Future<void> requestPermissionRow(int i) async {
//     await [
//       () => requestPerm(Permission.microphone, 'micExplain', 'micDenied'),
//       () => requestPerm(Permission.camera, 'camExplain', 'camDenied'),
//       () =>
//           requestPerm(Permission.locationWhenInUse, 'locExplain', 'locDenied'),
//       () => requestPerm(Permission.contacts, 'whyContacts', 'whyContacts'),
//     ][i]();
//   }

//   Future<void> requestAllPermissions() async {
//     for (var i = 0; i < 4; i++) {
//       await requestPermissionRow(i);
//     }
//   }

//   // -------------------------------------------------- voice sign-up flow
//   // Rule of this flow: it never gives up on its own. If Kalpana can't hear you she encourages you
//   // and tries again. Only leaving the screen, pressing Restart, or a lost microphone ends it.
//   static final _typeRe = RegExp(r'\btype\b|typing|टाइप|लिख', unicode: true);
//   static final _clearRe = RegExp(
//       r'start over|clear|reset|from the beginning|फिर से शुरू|दोबारा शुरू|पुन्हा सुरू|सुरुवातीपासून',
//       unicode: true);
//   static final _undoRe = RegExp(
//       r'delete last|remove last|undo|last one|आख़िरी हटाओ|आखिरी हटाओ|शेवटचा काढा|मागील काढा',
//       unicode: true);
//   static final _repeatRe = RegExp(
//       r'repeat|read it back|what do you have|दोहराओ|पुन्हा सांगा',
//       unicode: true);
//   static final _doneRe = RegExp(
//       r'^(done|that s all|that is all|finished|that s it|पूरा|पूर्ण|झाले|हो गया)$',
//       unicode: true);

//   String _digitsSpoken(String n) => n
//       .replaceAll(RegExp(r'[^\d+]'), '')
//       .split('')
//       .map((c) => c == '+' ? 'plus' : c)
//       .join(', ');

//   void _flag(Permission p, bool v) {
//     if (p == Permission.microphone) micOk = v;
//     if (p == Permission.camera) camOk = v;
//     if (p == Permission.locationWhenInUse) locOk = v;
//     if (p == Permission.contacts) contactsOk = v;
//     notifyListeners();
//   }

//   bool get _micLost =>
//       voice.lastError == 'permission' || voice.lastError == 'unavailable';

//   Future<void> _encourage(int misses) async {
//     final k = const [
//       'didntCatch',
//       'encourage1',
//       'encourage2',
//       'encourage3'
//     ][misses.clamp(1, 4) - 1];
//     await voice.speak(t(k));
//   }

//   /// One listening attempt. Ignores "okay got it / stop" (those only stop talking).
//   Future<String?> _hearOnce(
//       {Duration max = const Duration(seconds: 9),
//       bool dictation = false,
//       String? locale}) async {
//     for (var i = 0; i < 3; i++) {
//       final h = await voice.listenOnce(
//           max: max, dictation: dictation, localeId: locale);
//       if (h != null && isStopSpeech(h)) {
//         continue;
//       }
//       return h;
//     }
//     return null;
//   }

//   /// Listens until something is heard, encouraging the user after every miss.
//   /// Returns null only if the flow was left/restarted or the microphone is gone.
//   Future<String?> _hear() async {
//     final id = _flow;
//     var misses = 0;
//     while (id == _flow && screen == Screen.onboarding) {
//       final h = await _hearOnce();
//       if (h != null) {
//         return h;
//       }
//       if (id != _flow || _micLost) {
//         return null;
//       }
//       misses++;
//       await _encourage(misses);
//     }
//     return null;
//   }

//   Future<bool?> _askYesNo(String prompt) async {
//     final id = _flow;
//     var misses = 0;
//     while (id == _flow && screen == Screen.onboarding) {
//       await voice.speak(prompt);
//       final h = await _hearOnce(max: const Duration(seconds: 7));
//       if (id != _flow) {
//         return null;
//       }
//       if (h != null) {
//         final yn = CommandRouter.parseYesNo(h);
//         if (yn != null) {
//           return yn;
//         }
//         await voice.speak(t('yesNoPlease'));
//         continue;
//       }
//       if (_micLost) {
//         return null;
//       }
//       misses++;
//       await _encourage(misses);
//     }
//     return null;
//   }

//   String _cleanName(String raw) {
//     final s = raw
//         .trim()
//         .replaceAll(
//             RegExp(
//                 r"^(my name is|i am|i'm|this is|name is|मेरा नाम|माझे नाव|मैं|मी)\s+",
//                 caseSensitive: false),
//             '')
//         .replaceAll(RegExp(r'\s+(है|आहे|hai)$'), '');
//     return s
//         .split(' ')
//         .where((w) => w.isNotEmpty)
//         .map((w) => w[0].toUpperCase() + w.substring(1))
//         .join(' ');
//   }

//   /// Short and fast: one sentence, then straight to the Android permission box.
//   /// [attempts] 2 = if refused, say why it matters and ask once more.
//   Future<bool> _quickPermission(int id, Permission p, String introKey,
//       {String? whyKey, int attempts = 1}) async {
//     if (await p.isGranted) {
//       _flag(p, true);
//       return true;
//     }
//     for (var a = 0; a < attempts; a++) {
//       if (id != _flow) {
//         return false;
//       }
//       await voice.speak(t(a == 0 || whyKey == null ? introKey : whyKey));
//       var s = await p.request();
//       if (!s.isGranted && s.isPermanentlyDenied) {
//         await voice.speak(t('openSettings'));
//         await openAppSettings();
//         s = await p.status;
//       }
//       _flag(p, s.isGranted);
//       if (s.isGranted) {
//         return true;
//       }
//     }
//     return false;
//   }

//   Future<List<AppLang>> _supportedLangs({AppLang? exclude}) async => [
//         for (final l in AppLang.values)
//           if (l != exclude && (await voice.checkSupport(l)).ok) l
//       ];

//   static const _langQ = <AppLang, List<String>>{
//     AppLang.en: [
//       'Which language would you like to use? Say English, Hindi or Marathi.',
//       'English, Hindi or Marathi?'
//     ],
//     AppLang.hi: [
//       'आप किस भाषा में बात करना चाहेंगे? बोलिए अंग्रेज़ी, हिंदी या मराठी।',
//       'अंग्रेज़ी, हिंदी या मराठी?'
//     ],
//     AppLang.mr: [
//       'तुम्हाला कोणत्या भाषेत बोलायचे आहे? म्हणा इंग्रजी, हिंदी किंवा मराठी.',
//       'इंग्रजी, हिंदी की मराठी?'
//     ],
//   };

//   /// Asks the language in ALL three languages (so a user who only knows Hindi or Marathi understands),
//   /// listens with the English, then Hindi, then Marathi recogniser, CHECKS the phone really supports
//   /// the choice (voice + recognition) and, if not, explains honestly and offers what does work.
//   Future<bool> _chooseLanguage(int id, {bool trouble = false}) async {
//     var attempt = 0;
//     var listAlternatives = trouble;
//     while (id == _flow && screen == Screen.onboarding) {
//       if (listAlternatives) {
//         final alts = await _supportedLangs(exclude: trouble ? lang : null);
//         if (alts.isEmpty) {
//           await voice.speak(
//               "No spoken language is fully available on this phone, so I'll continue in English.",
//               forceEn: true);
//           await changeLanguage(AppLang.en);
//           return true;
//         }
//         await voice.speak(
//             'Which language would you like: ${alts.map((e) => e.english).join(' or ')}?',
//             forceEn: true);
//         listAlternatives = false;
//       } else {
//         for (final l in AppLang.values) {
//           await voice.speak(_langQ[l]![attempt == 0 ? 0 : 1], inLang: l);
//         }
//       }
//       final loc = attempt % 3 == 0
//           ? null
//           : await voice.localeFor(attempt % 3 == 1 ? AppLang.hi : AppLang.mr);
//       final h = await _hearOnce(locale: loc);
//       attempt++;
//       if (id != _flow) {
//         return false;
//       }
//       if (h == null) {
//         if (_micLost) {
//           return false;
//         }
//         continue;
//       }
//       final l = router.langIn(CommandRouter.norm(h));
//       if (l == null) {
//         continue;
//       }
//       if (trouble && l == lang) {
//         await voice.speak(
//             '${l.english} is the one that is not working. Please choose another.',
//             forceEn: true);
//         listAlternatives = true;
//         continue;
//       }
//       final chk = await voice.checkSupport(l);
//       if (chk.ok) {
//         await changeLanguage(l);
//         return true;
//       }
//       final missing = [
//         if (!chk.stt) 'speech recognition',
//         if (!chk.tts) 'the ${l.english} voice'
//       ].join(' and ');
//       await voice.speak(
//           "${l.english} isn't fully available on this phone: $missing is missing. I won't pretend otherwise. "
//           "You can add it in the phone's speech settings and restart me.",
//           forceEn: true);
//       listAlternatives = true; // next round lists the languages that do work
//     }
//     return false;
//   }

//   /// One question; the answer is typed live into [ctl], read back, accepted only after a spoken yes.
//   /// [probe]: if a non-English language can't be understood, offer a working one.
//   Future<String?> _askField(
//       int id, String prompt, TextEditingController ctl, int idx,
//       {required String Function(String) clean,
//       bool Function(String)? valid,
//       bool probe = false}) async {
//     activeField = idx;
//     notifyListeners();
//     var misses = 0, rounds = 0;
//     while (id == _flow && screen == Screen.onboarding) {
//       rounds++;
//       await voice.speak(rounds == 1 ? prompt : '${t('retry')} $prompt');
//       void live() => ctl.text = clean(voice.heard);
//       voice.addListener(live);
//       final h = await _hearOnce();
//       voice.removeListener(live);
//       if (id != _flow) {
//         return null;
//       }
//       if (h == null) {
//         if (_micLost) {
//           return null;
//         }
//         misses++;
//         final e = voice.lastError;
//         final langErr = e == 'error_language_not_supported' ||
//             e == 'error_language_unavailable';
//         if (probe && lang != AppLang.en && (langErr || misses >= 2)) {
//           await voice.speak(
//               "I'm having trouble understanding ${lang.english} on this phone.",
//               forceEn: true);
//           if (!await _chooseLanguage(id, trouble: true)) {
//             return null;
//           }
//           misses = 0;
//           rounds = 0;
//           continue;
//         }
//         await _encourage(misses);
//         continue;
//       }
//       misses = 0;
//       if (_typeRe.hasMatch(normText(h))) {
//         await voice.speak(t('noTypeNeeded'));
//         continue;
//       }
//       final v = clean(h);
//       ctl.text = v;
//       if (valid != null && !valid(v)) {
//         await voice.speak(t('didntCatch'));
//         continue;
//       }
//       final ok = await _askYesNo(t('heardSure', {'x': v}));
//       if (ok == true) {
//         return v;
//       }
//       if (ok == null) {
//         return null;
//       }
//     }
//     return null;
//   }

//   /// Phone number by voice, in small groups (dictation mode, longer pauses). Each group is echoed
//   /// digit by digit; unclear words are never guessed; the full number is read back for confirmation.
//   Future<String?> _collectPhone(int id, TextEditingController ctl, int idx,
//       {required String prompt}) async {
//     activeField = idx;
//     notifyListeners();
//     final chunks = <String>[];
//     var plus = false;
//     String all() => chunks.join();
//     String shown() => '${plus ? '+' : ''}${all()}';
//     void sync() => ctl.text = shown();
//     await voice.speak(prompt);
//     var misses = 0;
//     while (id == _flow && screen == Screen.onboarding) {
//       final h =
//           await _hearOnce(max: const Duration(seconds: 12), dictation: true);
//       if (id != _flow) {
//         return null;
//       }
//       if (h == null) {
//         if (_micLost) {
//           return null;
//         }
//         misses++;
//         await _encourage(misses);
//         if (misses % 3 == 0) {
//           await voice.speak(prompt);
//         }
//         continue;
//       }
//       misses = 0;
//       final n = normText(h);
//       if (_typeRe.hasMatch(n)) {
//         await voice.speak(t('noTypeNeeded'));
//         continue;
//       }
//       if (_clearRe.hasMatch(n)) {
//         chunks.clear();
//         plus = false;
//         sync();
//         await voice.speak(t('startedOver'));
//         continue;
//       }
//       if (_undoRe.hasMatch(n)) {
//         if (chunks.isEmpty) {
//           await voice.speak(t('digitsNone'));
//           continue;
//         }
//         final r = chunks.removeLast();
//         sync();
//         await voice.speak('${t('removed', {
//               'x': _digitsSpoken(r)
//             })} ${chunks.isEmpty ? '' : t('phoneSoFar', {
//                 'x': _digitsSpoken(all())
//               })}');
//         continue;
//       }
//       if (_repeatRe.hasMatch(n)) {
//         await voice.speak(all().isEmpty
//             ? t('digitsNone')
//             : t('phoneSoFar', {'x': _digitsSpoken(shown())}));
//         continue;
//       }
//       final doneCmd = _doneRe.hasMatch(n);
//       if (!doneCmd) {
//         final p = parseDigits(h);
//         if (p.unclear.isNotEmpty) {
//           await voice.speak(t('digitUnclear', {'x': p.unclear.join(' ')}));
//           continue;
//         }
//         if (p.digits.isEmpty) {
//           await voice.speak(t('digitsNone'));
//           continue;
//         }
//         if (chunks.isEmpty && p.plus) {
//           plus = true;
//         }
//         chunks.add(p.digits);
//         sync();
//         await voice
//             .speak(_digitsSpoken(p.digits)); // echo this group, digit by digit
//       }
//       final len = all().length;
//       if (doneCmd && len < 10) {
//         await voice.speak(t('phoneShort', {'n': '$len'}));
//         continue;
//       }
//       if (len > 13 || (!plus && len > 10)) {
//         await voice.speak(t('phoneLong', {'n': '$len'}));
//         continue;
//       }
//       if (doneCmd || (plus ? len >= 12 : len == 10)) {
//         final yn =
//             await _askYesNo(t('phoneConfirm', {'x': _digitsSpoken(shown())}));
//         if (yn == true) {
//           return shown();
//         }
//         if (yn == null) {
//           return null;
//         }
//         await voice.speak(t('phoneFix'));
//       }
//     }
//     return null;
//   }

//   Future<int?> _chooseAmong(List<fc.Contact> list, List<int> idxs) async {
//     final shown = idxs.take(5).toList();
//     final names = [
//       for (var i = 0; i < shown.length; i++)
//         '${i + 1}. ${list[shown[i]].displayName}'
//     ].join(', ');
//     for (var a = 0; a < 3; a++) {
//       await voice.speak(t('emMany', {'n': '${shown.length}', 'list': names}));
//       final h = await _hearOnce();
//       if (h == null) {
//         continue;
//       }
//       final ch = parseChoice(h);
//       if (ch == -1) {
//         return null;
//       }
//       if (ch != null && ch >= 1 && ch <= shown.length) {
//         return shown[ch - 1];
//       }
//     }
//     return null;
//   }

//   Future<bool> _manualContact(int id) async {
//     final name = await _askField(id, t('emManualName'), emergencyCtl, 2,
//         clean: _cleanName, valid: (v) => v.isNotEmpty);
//     if (name == null) {
//       return false;
//     }
//     final tmp = TextEditingController();
//     final ph = await _collectPhone(id, tmp, 2,
//         prompt: t('emManualPhone', {'name': name}));
//     if (ph == null) {
//       return false;
//     }
//     emergencyCtl.text = '$name • $ph';
//     return true;
//   }

//   /// Emergency contact. Kalpana explains: say the name exactly as saved in your phone's contacts.
//   /// The heard name appears live, is matched against the real contacts, disambiguated and confirmed.
//   Future<bool> _emergencyStep(int id) async {
//     activeField = 2;
//     notifyListeners();
//     var list = <fc.Contact>[];
//     if (contactsOk || await Permission.contacts.isGranted) {
//       try {
//         list = (await fc.FlutterContacts.getContacts(withProperties: true))
//             .where((c) => c.phones.isNotEmpty)
//             .toList();
//       } catch (_) {}
//     }
//     if (list.isEmpty) {
//       return _manualContact(
//           id); // no contacts access (or none saved): name + number by voice
//     }
//     await voice.speak(t('emIntro'));
//     for (var a = 0; a < 5; a++) {
//       if (id != _flow) {
//         return false;
//       }
//       if (a > 0) {
//         await voice.speak(t(a >= 2 ? 'emPick' : 'emRetry'));
//       }
//       void live() => emergencyCtl.text = voice.heard;
//       voice.addListener(live);
//       final h = await _hear();
//       voice.removeListener(live);
//       if (h == null) {
//         return false;
//       }
//       final n = normText(h);
//       if (RegExp(r'skip|छोड़|छोड|वगळा').hasMatch(n) && a >= 2) {
//         emergencyCtl.clear();
//         await voice.speak(t('noEmergency'));
//         return true;
//       }
//       final idxs = matchNames([for (final c in list) c.displayName], h);
//       if (idxs.isEmpty) {
//         await voice.speak(t('emNone', {'x': h}));
//         continue;
//       }
//       final pick =
//           idxs.length == 1 ? idxs.first : await _chooseAmong(list, idxs);
//       if (pick == null) {
//         continue;
//       }
//       final c = list[pick];
//       final number = c.phones.first.number.replaceAll(RegExp(r'[^\d+]'), '');
//       emergencyCtl.text = '${c.displayName} • $number';
//       final yn = await _askYesNo(
//           t('emOne', {'name': c.displayName, 'num': _digitsSpoken(number)}));
//       if (yn == true) {
//         return true;
//       }
//       if (yn == null) {
//         return false;
//       }
//     }
//     return _manualContact(id);
//   }

//   /// Reads the whole profile back. Nothing is saved until the user says yes.
//   Future<bool> _review(int id) async {
//     while (id == _flow && screen == Screen.onboarding) {
//       final has = emergencyCtl.text.trim().isNotEmpty && contacts.length > 1;
//       final em = has
//           ? '${contacts.first.label}, ${_digitsSpoken(contacts.first.number)}'
//           : t('noEmSaved');
//       await voice.speak('${t('profileSummary', {
//             'name': nameCtl.text,
//             'phone': _digitsSpoken(phoneCtl.text),
//             'contact': em,
//             'lang': lang.label
//           })} ${t('proceedAsk')}');
//       var h = await _hear();
//       if (h == null) {
//         return false;
//       }
//       if (CommandRouter.parseYesNo(h) == true) {
//         return true;
//       }
//       var n = normText(h);
//       if (!RegExp(
//               r'contact|emergency|संपर्क|आपातकाल|आणीबाणी|phone|number|नंबर|फोन|फ़ोन|क्रमांक|name|नाम|नाव')
//           .hasMatch(n)) {
//         await voice.speak(t('changeWhat'));
//         h = await _hear();
//         if (h == null) {
//           return false;
//         }
//         n = normText(h);
//       }
//       if (RegExp(r'contact|emergency|संपर्क|आपातकाल|आणीबाणी').hasMatch(n)) {
//         if (!await _emergencyStep(id)) {
//           return false;
//         }
//       } else if (RegExp(r'phone|number|नंबर|फोन|फ़ोन|क्रमांक').hasMatch(n)) {
//         final ph =
//             await _collectPhone(id, phoneCtl, 1, prompt: t('digitsPrompt'));
//         if (ph == null) {
//           return false;
//         }
//         phoneCtl.text = ph;
//       } else if (RegExp(r'name|नाम|नाव').hasMatch(n)) {
//         if (await _askField(id, t('askName'), nameCtl, 0,
//                 clean: _cleanName, valid: (v) => v.isNotEmpty) ==
//             null) {
//           return false;
//         }
//       }
//     }
//     return false;
//   }

//   Future<void> startSignup() => _exclusive(() async {
//         await voice.stop();
//         final id = ++_flow;
//         bool alive() => id == _flow && screen == Screen.onboarding;
//         Future<void> fail() async {
//           activeField = -1;
//           notifyListeners();
//           if (alive()) {
//             await voice.speak(t('signupFail'));
//           }
//         }

//         voice.bargeEnabled =
//             false; // keeps the recogniser free for answers during sign-up
//         // 1. microphone FIRST: the user needs voice to do everything else
//         if (!await _quickPermission(id, Permission.microphone, 'micExplain',
//             whyKey: 'whyMic', attempts: 2)) {
//           activeField = -1;
//           notifyListeners();
//           if (alive()) {
//             await voice.speak(t('micFallback'));
//           }
//           return;
//         }
//         if (!alive()) {
//           return;
//         }
//         // 2. language, asked in all three languages
//         if (!await _chooseLanguage(id)) {
//           return fail();
//         }
//         // 3. the other permissions, one short sentence each: camera, contacts, location
//         await _quickPermission(id, Permission.camera, 'permCamShort');
//         await _quickPermission(id, Permission.contacts, 'permContactsShort',
//             whyKey: 'whyContacts', attempts: 2);
//         await _quickPermission(
//             id, Permission.locationWhenInUse, 'permLocShort');
//         if (!alive()) {
//           return;
//         }
//         // 4. name (doubles as a live test of the chosen language)
//         final name = await _askField(id, t('askName'), nameCtl, 0,
//             clean: _cleanName, valid: (v) => v.isNotEmpty, probe: true);
//         if (name == null) {
//           return fail();
//         }
//         // 5. phone number
//         final phone =
//             await _collectPhone(id, phoneCtl, 1, prompt: t('digitsPrompt'));
//         if (phone == null) {
//           return fail();
//         }
//         phoneCtl.text = phone;
//         // 6. emergency contact from the device contacts
//         if (!await _emergencyStep(id)) {
//           return fail();
//         }
//         // 7. read everything back; save only after an explicit yes
//         if (!await _review(id)) {
//           return fail();
//         }
//         await finishOnboarding();
//       });

//   /// Saves the profile (this is the ONLY place sign-up data is persisted), goes home, explains Hey Kalpana.
//   Future<void> finishOnboarding() async {
//     _flow++; // cancels any running sign-up flow
//     saveProfile();
//     onboarded = true;
//     activeField = -1;
//     await _prefs?.setBool('onboarded', true);
//     await go(Screen.dashboard, announce: false);
//     await voice.speak(t('signupDone', {'name': _nameOr()}));
//     startLoop();
//   }

//   Future<void> _returnHome() async {
//     if (onboarded && screen != Screen.dashboard) {
//       await go(Screen.dashboard, announce: false);
//     }
//   }

//   // ------------------------------------------------------------- settings
//   Future<void> changeLanguage(AppLang l) async {
//     final note = await voice.setLanguage(l);
//     await _prefs?.setInt('lang', l.index);
//     notifyListeners();
//     await voice.speak(t('langSet', {'lang': l.label}));
//     if (note.isNotEmpty) await voice.speak(note, forceEn: true);
//   }

//   Future<void> adjustRate(double d) async {
//     final r = ((voice.rate + d).clamp(0.5, 1.5) * 10).round() / 10;
//     await voice.setRate(r);
//     await _prefs?.setDouble('rate', r);
//     await voice.speak(t('rateSet', {'r': r.toStringAsFixed(1)}));
//   }

//   void toggleHaptics() {
//     haptics = voice.haptics = !haptics;
//     _prefs?.setBool('haptics', haptics);
//     notifyListeners();
//   }

//   void toggleContrast() {
//     highContrast = !highContrast;
//     K.setContrast(highContrast);
//     _prefs?.setBool('contrast', highContrast);
//     notifyListeners();
//   }

//   void saveProfile() {
//     _prefs?.setString('name', nameCtl.text);
//     _prefs?.setString('phone', phoneCtl.text);
//     _prefs?.setString('emergency', emergencyCtl.text);
//   }

//   void setName(String n) {
//     nameCtl.text = _cleanName(n);
//     saveProfile();
//     notifyListeners();
//     voice.speak('Saved. I will call you ${nameCtl.text}.');
//   }

//   bool setEmergencyContact(String name, String number) {
//     emergencyCtl.text = '$name • ${number.trim()}';
//     saveProfile();
//     notifyListeners();
//     voice.speak(
//         'Saved emergency contact $name, number ${_spell(number)}. Check it on screen if needed.');
//     return true;
//   }

//   // ------------------------------------------------------------ reminders
//   String _remindersSpeech() => reminders.isEmpty
//       ? t('noReminders')
//       : t('remindersAre', {
//           'n': reminders.length.toString(),
//           'list': [
//             for (var i = 0; i < reminders.length; i++)
//               '${i + 1}. ${reminders[i]}.'
//           ].join(' ')
//         });

//   Future<bool> addReminder(String text) async {
//     var x = text.trim();
//     if (x.isEmpty) return false;
//     x = x[0].toUpperCase() + x.substring(1);
//     reminders = [...reminders, x];
//     await _prefs?.setStringList('reminders', reminders);
//     notifyListeners();
//     await voice.speak(t('reminderSaved', {'x': x}));
//     await _returnHome();
//     return true;
//   }

//   Future<bool> clearReminders() async {
//     if (reminders.isEmpty) {
//       await voice.speak(t('noReminders'));
//       return true;
//     }
//     if (!await confirm(t('confirmClear'))) {
//       await voice.speak(t(_confirmTimedOut ? 'noAnswer' : 'cancelled'));
//       return true;
//     }
//     reminders = [];
//     await _prefs?.setStringList('reminders', reminders);
//     notifyListeners();
//     await voice.speak(t('remindersCleared'));
//     await _returnHome();
//     return true;
//   }

//   // --------------------------------------------------------------- camera
//   Future<void> initCamera() => _camFuture ??= _initCam();

//   Future<void> _initCam() async {
//     try {
//       if (!await requestPerm(Permission.camera, 'camExplain', 'camDenied'))
//         return;
//       final cams = await availableCameras();
//       if (cams.isEmpty) throw Exception('none');
//       final back = cams.firstWhere(
//           (c) => c.lensDirection == CameraLensDirection.back,
//           orElse: () => cams.first);
//       final ctl = CameraController(back, ResolutionPreset.medium,
//           enableAudio: false); // audio off: keeps the mic free for speech
//       await ctl.initialize();
//       cam = ctl;
//       notifyListeners();
//     } catch (_) {
//       await voice.speak(t('camFail'));
//     } finally {
//       if (!camReady) _camFuture = null;
//     }
//   }

//   Future<void> disposeCamera() async {
//     final c0 = cam;
//     cam = null;
//     _camFuture = null;
//     await c0?.dispose();
//     notifyListeners();
//   }

//   String _prompt(Screen s) => switch (s) {
//         Screen.ocr =>
//           'Read all the text visible in this photo, in the order a person would read it. If there is no readable text, say so. Do not describe anything else.',
//         Screen.camera =>
//           'Tell a blind person what the main object in front of the camera is. If it is a medicine or packaged product, read the name, strength or dosage and expiry date if visible. Keep it under 4 sentences.',
//         Screen.explore =>
//           'Describe the surroundings for a blind person who is walking: obstacles, doors, steps, people, and whether the path ahead looks clear. Estimate distances in steps. Keep it under 4 sentences. If you cannot judge safety from a single photo, say so.',
//         _ =>
//           'Name the dominant colour of the main object in the centre of the photo in plain words (for example deep navy blue). Mention any pattern. One or two sentences.',
//       };

//   /// Offline analysis (ML Kit OCR / labels / colour). Gemini only if kUseCloudAi, and only as a bonus.
//   Future<String> _analyse(String path, Screen s) async {
//     final bytes = await File(path).readAsBytes();
//     if (kUseCloudAi &&
//         ai.configured &&
//         online &&
//         (s == Screen.camera || s == Screen.explore)) {
//       try {
//         return await ai.describeImage(bytes, _prompt(s), lang);
//       } catch (_) {}
//     }
//     switch (s) {
//       case Screen.ocr:
//         final txt = await vision.readText(path);
//         if (txt.isNotEmpty) {
//           return t('textIs', {'x': txt});
//         }
//         final seen = await vision.labels(path, lang);
//         return seen.isEmpty
//             ? t('noText')
//             : '${t('noText')} ${t('seeLabels', {'x': seen.join(', ')})}';
//       case Screen.color:
//         return t('colorIs', {'x': await vision.colorName(bytes, lang)});
//       case Screen.explore:
//         final l = await vision.labels(path, lang);
//         return '${l.isEmpty ? t('seeNothing') : t('seeLabels', {
//                 'x': l.join(', ')
//               })} ${t('exploreNote')}';
//       default:
//         final txt = await vision.readText(path);
//         final l = await vision.labels(path, lang);
//         final parts = <String>[
//           if (l.isNotEmpty) t('seeLabels', {'x': l.join(', ')}),
//           if (txt.length >= 4) t('textIs', {'x': txt}),
//         ];
//         return parts.isEmpty ? t('seeNothing') : parts.join(' ');
//     }
//   }

//   /// Takes a photo and analyses it, speaks the answer. Opens the camera first if needed.
//   Future<void> takePicture() => _exclusive(() async {
//         try {
//           if (!isCapture(screen)) await go(Screen.ocr, announce: false);
//           await initCamera();
//           final ctl = cam;
//           if (ctl == null || !camReady) return;
//           await voice.speak(t('holdSteady'));
//           final shot = await ctl.takePicture();
//           HapticFeedback.mediumImpact();
//           analysing = true;
//           captureBody = null;
//           notifyListeners();
//           unawaited(voice.speak(t('analysing')));
//           final text = await _analyse(shot.path, screen);
//           captureBody = text;
//           analysing = false;
//           notifyListeners();
//           await voice.speak(text);
//         } on AiException catch (e) {
//           await voice.speak(t(e.key));
//         } catch (_) {
//           await voice.speak(t('camFail'));
//         } finally {
//           analysing = false;
//           notifyListeners();
//         }
//       });

//   // ------------------------------------------------------------- contacts
//   List<Contact> get contacts {
//     final out = <Contact>[];
//     final txt = emergencyCtl.text;
//     final m = RegExp(r'\+?\d[\d\s\-]{6,}\d').firstMatch(txt);
//     if (m != null) {
//       var label = txt
//           .substring(0, m.start)
//           .replaceAll(RegExp(r'[•\-–,:\s]+$'), '')
//           .trim();
//       if (label.isEmpty) label = 'Emergency contact';
//       out.add(Contact(label, m.group(0)!.trim()));
//     }
//     out.add(const Contact('National Helpline', '112'));
//     return out;
//   }

//   Contact? findContact(String query) {
//     final q = query.toLowerCase();
//     if (RegExp(r'112|police|helpline|पोलीस|पुलिस').hasMatch(q))
//       return contacts.last;
//     if (RegExp(r'emergency|contact|आपातकालीन|आणीबाणी').hasMatch(q) &&
//         contacts.length > 1) return contacts.first;
//     final words = q.split(' ').where((w) => w.length > 1);
//     for (final c in contacts) {
//       final l = c.label.toLowerCase();
//       if (words.any(l.contains)) return c;
//     }
//     return null;
//   }

//   String _spell(String n) =>
//       n.replaceAll(RegExp(r'[^\d+]'), '').split('').join(' ');

//   Future<bool> callContact(String name) async {
//     if (name.trim().isEmpty) {
//       await voice.speak(
//           t('dialHint', {'names': contacts.map((e) => e.label).join(', ')}));
//       return true;
//     }
//     final c = findContact(name);
//     if (c == null) {
//       await voice.speak(t('noContact', {'x': name}));
//       return false;
//     }
//     if (!await confirm(
//         t('confirmCall', {'name': c.label, 'number': _spell(c.number)}))) {
//       await voice.speak(t(_confirmTimedOut ? 'noAnswer' : 'cancelled'));
//       return true;
//     }
//     return dial(c.number, name: c.label);
//   }

//   /// Calls directly (Android CALL_PHONE): no dialer, no contacts app. If direct calling isn't
//   /// possible (permission refused, iOS), it falls back to opening the pre-filled dialer.
//   Future<bool> dial(String number, {String? name}) async {
//     final clean = number.replaceAll(RegExp(r'[^\d+]'), '');
//     if (Platform.isAndroid) {
//       var s = await Permission.phone.status;
//       if (!s.isGranted) {
//         await voice.speak(t('callPermAsk'));
//         s = await Permission.phone.request();
//       }
//       if (s.isGranted) {
//         await voice.speak(t('calling', {'name': name ?? _spell(clean)}));
//         try {
//           if (await FlutterPhoneDirectCaller.callNumber(clean) ?? false) {
//             return true;
//           }
//         } catch (_) {}
//       }
//     }
//     var ok = false;
//     try {
//       ok = await launchUrl(Uri(scheme: 'tel', path: clean));
//     } catch (_) {}
//     await voice.speak(t(ok ? 'dialer' : 'dialFail'));
//     return ok;
//   }

//   Future<void> sos() async {
//     final cs = contacts;
//     final target = cs.first;
//     if (cs.length == 1) await voice.speak(t('noEmergency'));
//     if (!await confirm(t('confirmSos', {'name': target.label}))) {
//       await voice.speak(t(_confirmTimedOut ? 'noAnswer' : 'cancelled'));
//       return;
//     }
//     await dial(target.number, name: target.label);
//   }

//   Future<bool> sendLocation() async {
//     final cs = contacts;
//     if (cs.length == 1) {
//       await voice.speak(t('noEmergency'));
//       return false;
//     }
//     final p = await _position();
//     if (p == null) return false;
//     if (!await confirm(t('confirmSms', {'name': cs.first.label}))) {
//       await voice.speak(t(_confirmTimedOut ? 'noAnswer' : 'cancelled'));
//       return true;
//     }
//     final body =
//         'I need help. My location: https://maps.google.com/?q=${p.latitude},${p.longitude}';
//     var ok = false;
//     try {
//       ok = await launchUrl(Uri(
//           scheme: 'sms',
//           path: cs.first.number.replaceAll(RegExp(r'\s'), ''),
//           query: 'body=${Uri.encodeComponent(body)}'));
//     } catch (_) {}
//     await voice.speak(t(ok ? 'smsOpened' : 'dialFail'));
//     return ok;
//   }

//   // ------------------------------------------------------------- location
//   Future<Position?> _position() async {
//     if (!await requestPerm(
//         Permission.locationWhenInUse, 'locExplain', 'locDenied')) return null;
//     if (!await Geolocator.isLocationServiceEnabled()) {
//       await voice.speak(t('locOff'));
//       return null;
//     }
//     try {
//       return await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//         timeLimit: const Duration(seconds: 12),
//       );
//     } catch (_) {
//       await voice.speak(t('locFail'));
//       return null;
//     }
//   }

//   Future<void> whereAmI() async {
//     liveHeading = liveBody = liveSub = null;
//     notifyListeners();
//     unawaited(voice.speak(t('whereWait')));
//     final p = await _position();
//     if (p == null) return;
//     lastPos = p;
//     var place =
//         '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';
//     var detail = place;
//     try {
//       final pm =
//           (await placemarkFromCoordinates(p.latitude, p.longitude)).first;
//       final parts = <String>{
//         for (final s in [
//           pm.name,
//           pm.subLocality,
//           pm.locality,
//           pm.administrativeArea,
//           pm.postalCode
//         ])
//           if (s != null && s.trim().isNotEmpty) s.trim()
//       }.toList();
//       if (parts.isNotEmpty) {
//         place = parts.take(2).join(', ');
//         detail = parts.join(', ');
//       }
//     } catch (_) {}
//     liveHeading = 'Near $place';
//     liveBody = detail;
//     liveSub = 'GPS ACCURACY ±${p.accuracy.round()} METERS';
//     notifyListeners();
//     await voice.speak(t(
//         'whereResult', {'place': place, 'acc': p.accuracy.round().toString()}));
//   }

//   // ----------------------------------------------------------------- chat
//   Future<void> dictate() => _exclusive(() async {
//         if (!await ensureMic()) return;
//         await voice.stop();
//         final h = await voice.listenOnce();
//         if (h == null) {
//           if (!voice.cancelled) await voice.speak(t(voice.errorKey));
//           return;
//         }
//         chatCtl.text = h;
//         voice.flash(VoiceState.success);
//         await voice.speak('Your message: $h');
//       });

//   Future<void> sendChat() async {
//     if (chatCtl.text.trim().isEmpty) {
//       await voice
//           .speak('Your message is empty. Tap the microphone to dictate one.');
//     } else {
//       voice.flash(VoiceState.error);
//       await voice.speak(t('chatOffline'));
//     }
//   }

//   // -------------------------------------------------------------- confirm
//   /// Spoken + on-screen confirmation. Voice yes/no OR the two big buttons.
//   /// Silence twice = cancel (never proceeds without a clear yes).
//   Future<bool> confirm(String prompt) => _exclusive(() async {
//         final ctx = navKey.currentContext;
//         if (ctx == null) return false;
//         _confirmTimedOut = false;
//         final done = Completer<bool>();
//         unawaited(showDialog<void>(
//             context: ctx,
//             barrierDismissible: false,
//             builder: (_) => ConfirmDialog(
//                 prompt: prompt,
//                 onChoice: (v) {
//                   if (!done.isCompleted) done.complete(v);
//                 })));
//         unawaited(() async {
//           for (var i = 0; i < 2 && !done.isCompleted; i++) {
//             await voice.speak(prompt);
//             if (done.isCompleted) return;
//             final h = await voice.listenOnce(max: const Duration(seconds: 7));
//             if (done.isCompleted) return;
//             final yn = h == null ? null : CommandRouter.parseYesNo(h);
//             if (yn != null) {
//               done.complete(yn);
//               return;
//             }
//           }
//           if (!done.isCompleted) {
//             _confirmTimedOut = true;
//             done.complete(false);
//           }
//         }());
//         final res = await done.future;
//         await voice.stop();
//         navKey.currentState?.pop();
//         return res;
//       });

//   // ---------------------------------------------------------- screen data
//   ScreenInfo _cap(IconData i, String sub, String ready, {Color? accent}) =>
//       captureBody != null
//           ? ScreenInfo(sub, i, 'Here is what I see', captureBody!,
//               accent: accent)
//           : ScreenInfo(
//               sub,
//               i,
//               analysing ? 'Looking at your picture…' : ready,
//               analysing
//                   ? 'Please wait a moment.'
//                   : 'Say “take picture” or press Take Picture.',
//               accent: accent);

//   ScreenInfo info(Screen s) {
//     final cs = contacts;
//     final sosLine = cs
//         .map((e) => e.number == '112'
//             ? 'National Helpline • 112'
//             : '${e.label} • ${e.number}')
//         .join(' and ');
//     switch (s) {
//       case Screen.camera:
//         return _cap(Ic.camera, 'VISION AI WITH VERIFICATION',
//             'Ask about what is in front');
//       case Screen.explore:
//         return _cap(
//             Ic.navigation, 'LIVE AI DETECTION', 'Describe my surroundings',
//             accent: const Color(0xFFEBF6F1));
//       case Screen.ocr:
//         return _cap(Ic.fileText, 'DOCUMENT & SIGN READER', 'Read text aloud');
//       case Screen.color:
//         return _cap(Ic.palette, 'SURFACE SAMPLING', 'Identify a colour');
//       case Screen.location:
//         return liveHeading != null
//             ? ScreenInfo(liveSub!, Ic.mapPin, liveHeading!, liveBody!)
//             : const ScreenInfo(
//                 'GPS LOCATING…',
//                 Ic.mapPin,
//                 'Finding your location…',
//                 'Tap “Speak Result Aloud” to check again.');
//       case Screen.sos:
//         return ScreenInfo('TAP OR SAY “EMERGENCY”', Ic.alert,
//             'Emergency contacts ready', '$sosLine.',
//             accent: const Color(0xFFFFF8F8));
//       case Screen.community:
//         return const ScreenInfo(
//             'PRIVATE & ASSISTED',
//             Ic.message,
//             'Rohit Kulkarni',
//             'Are we meeting at Dadar station at 5 PM today? Your assisted reply is ready.',
//             demo: true);
//       case Screen.help:
//         return const ScreenInfo('SAY “HELP” ANYTIME', Ic.help,
//             'What you can say', 'Tap any command below to try it.');
//       case Screen.settings:
//         return ScreenInfo(
//             'AUDIO & ACCESSIBILITY',
//             Ic.settings,
//             'Speech Rate ${voice.rate.toStringAsFixed(1)}x',
//             'Haptic feedback ${haptics ? 'on' : 'off'} and high contrast borders ${highContrast ? 'on' : 'off'}.');
//       case Screen.daily:
//         return ScreenInfo(
//             'VOICE REMINDERS',
//             Ic.bell,
//             reminders.isEmpty
//                 ? 'No reminders yet'
//                 : '${reminders.length} reminder${reminders.length == 1 ? '' : 's'}',
//             reminders.isEmpty
//                 ? 'Say “Hey Kalpana, remind me to take medicine at 2 PM”.'
//                 : [
//                     for (var i = 0; i < reminders.length; i++)
//                       '${i + 1}. ${reminders[i]}'
//                   ].join('\n'));
//       case Screen.dial:
//         return ScreenInfo(
//             'HANDS-FREE CALLING',
//             Ic.phone,
//             'Say “Call” followed by name',
//             '“Kalpana, call ${cs.first.label}” • Mobile • ${cs.first.number}.');
//       default:
//         return ScreenInfo('', Ic.mic, titleOf(s), '');
//     }
//   }
// }

//works but not accurate-22-10
// import 'dart:async';
// import 'dart:io';
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:flutter_contacts/flutter_contacts.dart' as fc;
// import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
// import 'ai/gemini_service.dart';
// import 'config.dart';
// import 'vision/explore_logic.dart';
// import 'vision/explore_strings.dart';
// import 'vision/offline_vision.dart';
// import 'vision/yolo_detector.dart';
// import 'strings.dart';
// import 'theme.dart';
// import 'voice/command_router.dart';
// import 'voice/speech_utils.dart';
// import 'voice/voice_service.dart';
// import 'widgets.dart';

// /// Same 15 screens as the Bolt `Screen` union. Order matches `screenTitles`.
// enum Screen {
//   welcome,
//   onboarding,
//   dashboard,
//   camera,
//   voice,
//   explore,
//   ocr,
//   location,
//   sos,
//   community,
//   help,
//   settings,
//   daily,
//   dial,
//   color
// }

// class Contact {
//   final String label, number;
//   const Contact(this.label, this.number);
// }

// class ScreenInfo {
//   final String subtitle, heading, body;
//   final IconData icon;
//   final Color? accent;
//   final bool demo;
//   const ScreenInfo(this.subtitle, this.icon, this.heading, this.body,
//       {this.accent, this.demo = false});
// }

// class AppController extends ChangeNotifier {
//   final navKey = GlobalKey<NavigatorState>();
//   final voice = VoiceService();
//   final ai = GeminiService();
//   final vision = OfflineVision();
//   bool online = true;
//   Timer? _netTimer;
//   late final CommandRouter router = CommandRouter(this);
//   SharedPreferences? _prefs;

//   Screen screen = Screen.welcome;
//   final nameCtl = TextEditingController();
//   final phoneCtl = TextEditingController();
//   final emergencyCtl = TextEditingController();
//   final chatCtl = TextEditingController();
//   final typedCtl = TextEditingController();
//   bool haptics = true, highContrast = true, onboarded = false;
//   bool micOk = false, camOk = false, locOk = false, contactsOk = false;
//   bool _confirmTimedOut = false;
//   String? liveHeading, liveBody, liveSub;
//   Position? lastPos;

//   // reminders + camera results
//   List<String> reminders = [];
//   CameraController? cam;
//   Future<void>? _camFuture;
//   bool analysing = false;
//   String? captureBody;

//   // ---- live Explore (on-device YOLO26n, no cloud) ----
//   bool exploring = false; // engine running (camera stream + detector)
//   bool exploreMuted =
//       false; // "okay, got it": silent monitoring, urgent hazards only
//   String? exploreError; // technical reason live mode is unavailable
//   String exploreStatus =
//       ''; // last thing said / current status, shown on screen
//   List<ExploreBox> exploreBoxes = const [];
//   YoloDetector? _det;
//   Tracker _tracker = Tracker();
//   final Narrator _narr = Narrator();
//   final FramingMonitor _framing = FramingMonitor();
//   bool _exploreStarting = false, _frameBusy = false, _narrating = false;
//   bool _narrUrgent = false, _framingSpoken = false, _exiting = false;
//   int _exploreGen = 0, _narrTok = 0, _detErrors = 0, _sensorRot = 90;
//   DateTime _lastFrameAt = DateTime.fromMillisecondsSinceEpoch(0);
//   DateTime _lastNotify = DateTime.fromMillisecondsSinceEpoch(0);
//   DateTime _lastFramingSpeech = DateTime.fromMillisecondsSinceEpoch(0);

//   // always-listening state
//   bool micOff = false;
//   int activeField = -1; // sign-up field being filled by voice
//   int _busy = 0, _flow = 0, _loopGen = 0;
//   bool _loopOn = false, _sessionEnded = false;
//   DateTime _awakeUntil = DateTime.fromMillisecondsSinceEpoch(0);
//   Timer? _awakeTimer;

//   bool get loopOn => _loopOn;
//   bool get awake => DateTime.now().isBefore(_awakeUntil);
//   bool get camReady => cam?.value.isInitialized ?? false;
//   static bool isCapture(Screen s) =>
//       s == Screen.camera ||
//       s == Screen.ocr ||
//       s == Screen.explore ||
//       s == Screen.color;

//   AppLang get lang => voice.lang;
//   String t(String k, [Map<String, String> a = const {}]) =>
//       tr(voice.lang, k, a);
//   String et(String k, [Map<String, String> a = const {}]) =>
//       exploreText(voice.lang, k, a);
//   String titleOf(Screen s) => screenTitles[lang.index][s.index];
//   String get firstName => nameCtl.text.trim().split(' ').first;
//   String _nameOr() => firstName.isNotEmpty
//       ? firstName
//       : const ['friend', 'दोस्त', 'मित्र'][lang.index];

//   AppController() {
//     voice.addListener(notifyListeners);
//     voice.onBargeWords = _onBargeWords;
//   }

//   Future<T> _exclusive<T>(Future<T> Function() f) async {
//     _busy++;
//     try {
//       return await f();
//     } finally {
//       _busy--;
//     }
//   }

//   // ------------------------------------------------------------ lifecycle
//   Future<void> _init() async {
//     final p = _prefs = await SharedPreferences.getInstance();
//     nameCtl.text = p.getString('name') ?? '';
//     phoneCtl.text = p.getString('phone') ?? '';
//     emergencyCtl.text = p.getString('emergency') ?? '';
//     reminders = p.getStringList('reminders') ?? [];
//     haptics = p.getBool('haptics') ?? true;
//     highContrast = p.getBool('contrast') ?? true;
//     onboarded = p.getBool('onboarded') ?? false;
//     K.setContrast(highContrast);
//     voice.haptics = haptics;
//     micOk = await Permission.microphone.isGranted;
//     camOk = await Permission.camera.isGranted;
//     locOk = await Permission.locationWhenInUse.isGranted;
//     contactsOk = await Permission.contacts.isGranted;
//     final note = await voice.init(
//         AppLang.values[p.getInt('lang') ?? 0], p.getDouble('rate') ?? 1.0);
//     notifyListeners();
//     _netTimer ??=
//         Timer.periodic(const Duration(seconds: 15), (_) => _checkNet());
//     unawaited(_checkNet());
//     if (note.isNotEmpty) await voice.speak(note, forceEn: true);
//   }

//   Future<void> _checkNet() async {
//     var ok = false;
//     try {
//       final r = await InternetAddress.lookup('google.com')
//           .timeout(const Duration(seconds: 3));
//       ok = r.isNotEmpty && r.first.rawAddress.isNotEmpty;
//     } catch (_) {}
//     if (ok != online) {
//       online = ok;
//       notifyListeners();
//     }
//   }

//   /// App open: welcome -> (new user) voice sign-up, or (returning user) straight to listening.
//   Future<void> start() async {
//     await _init();
//     if (onboarded) {
//       await voice.speak(t('welcomeBack', {'name': _nameOr()}));
//       if (screen != Screen.welcome) return;
//       await go(Screen.dashboard, announce: false);
//       startLoop();
//       return;
//     }
//     await voice.speak(t('welcome'));
//     if (screen != Screen.welcome) return;
//     await beginFromButton();
//   }

//   Future<void> beginFromButton() async {
//     if (onboarded) {
//       await go(Screen.dashboard, announce: false);
//       startLoop();
//     } else {
//       await go(Screen.onboarding, announce: false);
//       await startSignup();
//     }
//   }

//   void onLifecycle(AppLifecycleState s) {
//     if (s == AppLifecycleState.resumed) {
//       if (onboarded && !micOff) startLoop();
//       if (isCapture(screen)) {
//         unawaited(screen == Screen.explore
//             ? startExplore(quiet: true)
//             : initCamera());
//       }
//     } else if (s == AppLifecycleState.paused) {
//       stopLoop(); // never listen / talk in the background
//       unawaited(disposeCamera()); // also stops live Explore
//     }
//   }

//   // ----------------------------------------------------------- navigation
//   Future<void> go(Screen s, {bool announce = true}) async {
//     await voice.stop();
//     if (screen == Screen.explore && s != Screen.explore) {
//       await _stopExploreEngine();
//     }
//     voice.bargeEnabled = s != Screen.onboarding;
//     final leaving = isCapture(screen) && !isCapture(s);
//     screen = s;
//     if (isCapture(s)) {
//       captureBody = null;
//       analysing = false;
//     }
//     notifyListeners();
//     if (leaving) unawaited(disposeCamera());
//     if (announce) await _announce(s);
//   }

//   Future<void> back() async {
//     if (screen == Screen.onboarding) return go(Screen.welcome, announce: false);
//     if (screen != Screen.welcome && screen != Screen.dashboard)
//       return go(Screen.dashboard);
//   }

//   Future<void> openVoice() async {
//     if (screen != Screen.voice) await go(Screen.voice, announce: false);
//     await listenAndRun();
//   }

//   String greeting() {
//     final h = DateTime.now().hour;
//     final g = t(h < 12
//         ? 'greetMorning'
//         : h < 17
//             ? 'greetAfternoon'
//             : 'greetEvening');
//     return firstName.isEmpty ? g : '$g, $firstName';
//   }

//   Future<void> _announce(Screen s) async {
//     final title = titleOf(s);
//     switch (s) {
//       case Screen.dashboard:
//         await voice.speak('${greeting()}. ${t('dashHint')}');
//       case Screen.sos:
//         await voice.speak('$title. ${t('sosHint')}');
//       case Screen.help:
//         await voice.speak('$title. ${t('helpHint')}');
//       case Screen.location:
//         await whereAmI();
//       case Screen.daily:
//         await voice.speak('$title. ${_remindersSpeech()}');
//       case Screen.dial:
//         await voice.speak('$title. ${t('dialHint', {
//               'names': contacts.map((e) => e.label).join(', ')
//             })}');
//       case Screen.explore:
//         await startExplore();
//       case Screen.camera || Screen.ocr || Screen.color:
//         await initCamera();
//         if (camReady) await voice.speak('$title. ${t('camReady')}');
//       case Screen.community:
//         final i = info(s);
//         await voice.speak('$title. ${t('demo')} ${i.heading}. ${i.body}');
//       default:
//         await voice.speak(title);
//     }
//   }

//   Future<void> readCurrent() async {
//     switch (screen) {
//       case Screen.voice:
//         return voice.speak(voice.spoken);
//       case Screen.location:
//         return whereAmI();
//       case Screen.explore:
//         return voice
//             .speak(exploreStatus.isNotEmpty ? exploreStatus : et('exAgain'));
//       case Screen.camera || Screen.ocr || Screen.color:
//         return voice.speak(captureBody ?? t('camReady'));
//       case Screen.dashboard ||
//             Screen.welcome ||
//             Screen.onboarding ||
//             Screen.help ||
//             Screen.daily:
//         return _announce(screen);
//       default:
//         final i = info(screen);
//         await voice
//             .speak('${i.demo ? '${t('demo')} ' : ''}${i.heading}. ${i.body}');
//     }
//   }

//   // -------------------------------------------- always-listening ("Hey Kalpana")
//   // static final _wakeWord = RegExp(r'kalpana|kalpna|calpana|कल्पना|कल्पणा|कलपना',
//   //     caseSensitive: false, unicode: true);
//   // static final _wakeFull = RegExp(
//   //     r'(?:(?:hey|hay|hi|hello|okay|ok|हे|हेय|हाय|हेलो|ओके)\s+)?(?:kalpana|kalpna|calpana|कल्पना|कल्पणा|कलपना)[\s,.!]*',
//   //     caseSensitive: false,
//   //     unicode: true);

//   // Match Kalpana as a whole word, not as part of another word.
//   static final _wakeWord = RegExp(
//     r'\b(?:kalpana|kalpna|calpana)\b|कल्पना|कल्पणा|कलपना',
//     caseSensitive: false,
//     unicode: true,
//   );

//   // Recognize the wake phrase at the beginning of the utterance.
//   static final _wakeFull = RegExp(
//     r'^(?:(?:hey|hay|hi|hello|okay|ok|हे|हेय|हाय|हेलो|ओके)\s+)?'
//     r'(?:kalpana|kalpna|calpana|कल्पना|कल्पणा|कलपना)[\s,.!]*',
//     caseSensitive: false,
//     unicode: true,
//   );

//   void startLoop() {
//     if (_loopOn || micOff || !onboarded) return;
//     _loopOn = true;
//     unawaited(_runLoop());
//   }

//   void stopLoop() {
//     _loopGen++;
//     _loopOn = false;
//     voice.stop();
//     notifyListeners();
//   }

//   Future<void> _runLoop() async {
//     if (!await ensureMic()) {
//       _loopOn = false;
//       micOff = true;
//       notifyListeners();
//       return;
//     }
//     final gen = ++_loopGen;
//     notifyListeners();
//     var fails = 0;
//     try {
//       while (gen == _loopGen) {
//         while (gen == _loopGen &&
//             (_busy > 0 || voice.state == VoiceState.speaking)) {
//           await Future.delayed(const Duration(milliseconds: 150));
//         }
//         if (gen != _loopGen) break;
//         final heard = await voice.listenOnce(
//             max: const Duration(seconds: 8), quiet: true);
//         if (gen != _loopGen) break;
//         if (heard != null) {
//           fails = 0;
//           await _onUtterance(heard);
//           await Future.delayed(const Duration(milliseconds: 250));
//           continue;
//         }
//         final e = voice.lastError;
//         if (voice.cancelled ||
//             e == null ||
//             e == 'error_no_match' ||
//             e == 'error_speech_timeout') {
//           await Future.delayed(const Duration(milliseconds: 300));
//           continue;
//         }
//         if (e == 'error_busy' || e == 'error_client' || e == 'error_audio') {
//           await Future.delayed(const Duration(milliseconds: 1200));
//           continue;
//         }
//         fails++;
//         if (fails >= 3 ||
//             e == 'permission' ||
//             e == 'unavailable' ||
//             e == 'error_network' ||
//             e == 'error_language_not_supported') {
//           micOff =
//               true; // stop honestly instead of looping on a broken recogniser
//           _loopGen++;
//           await voice.speak('${t(voice.errorKey)} ${t('micOffMsg')}');
//           break;
//         }
//         await Future.delayed(const Duration(milliseconds: 1500));
//       }
//     } finally {
//       if (gen == _loopGen) _loopOn = false;
//       notifyListeners();
//     }
//   }

//   void _extendAwake() {
//     _awakeUntil = DateTime.now().add(const Duration(seconds: 20));
//     _awakeTimer?.cancel();
//     _awakeTimer = Timer(const Duration(seconds: 21), notifyListeners);
//     notifyListeners();
//   }

//   bool _awaitingMore = false;
//   DateTime _deaf = DateTime.fromMillisecondsSinceEpoch(
//       0); // ignore the mic briefly after she says "Hey Kalpana" herself
//   static final _thanksRe =
//       RegExp(r'thank|धन्यवाद|शुक्रिया|आभार|थैंक', unicode: true);
//   static final _noMoreRe = RegExp(
//       r'^(?:no|nope|nothing else|nothing|that s all|that is all|nahi|नहीं|नही|नाही|कुछ नहीं|काही नाही|बस)(?:\s|$)',
//       unicode: true);

//   Future<void> _endSession(String msg) async {
//     _sessionEnded = true;
//     _awaitingMore = false;
//     _awakeUntil = DateTime.fromMillisecondsSinceEpoch(0);
//     notifyListeners();
//     await voice.speak(msg);
//     _deaf = DateTime.now().add(const Duration(milliseconds: 1500));
//   }

//   Future<void> _onUtterance(String raw) async {
//     if (DateTime.now().isBefore(_deaf)) {
//       return;
//     }
//     // Live Explore control phrases work without the wake word.
//     if (exploring && await _exploreControl(raw)) return;
//     final woke = _wakeWord.hasMatch(raw);
//     final wasAwake = awake;
//     if (!woke && !wasAwake) {
//       return; // not for us: ignore everything without the wake phrase
//     }
//     if (!wasAwake) {
//       _awaitingMore = false;
//     }
//     final cmd = raw.replaceFirst(_wakeFull, '').trim();
//     final n = normText(cmd);
//     final words = n.isEmpty ? 0 : n.split(' ').length;
//     _sessionEnded = false;
//     _extendAwake();
//     if (cmd.isEmpty) {
//       _awaitingMore = false;

//       await voice.speak(
//         t('hiName', {'name': _nameOr()}),
//       );

//       // Briefly ignore residual audio from Kalpana's own greeting.
//       _deaf = DateTime.now().add(
//         const Duration(milliseconds: 900),
//       );
//     } else if (_awaitingMore && _noMoreRe.hasMatch(n)) {
//       await _endSession(
//           t('byeReply')); // "okay, if you need anything say Hey Kalpana"
//       return;
//     } else if (_awaitingMore &&
//         words <= 3 &&
//         CommandRouter.parseYesNo(cmd) == true) {
//       _awaitingMore = false;
//       await voice.speak(t('sureHelp'));
//     } else if (words <= 5 && _thanksRe.hasMatch(n)) {
//       _awaitingMore =
//           true; // "okay thank you" -> you're welcome, anything else?
//       await voice.speak(t('thanksReply'));
//     } else {
//       _awaitingMore = false;
//       await handleUtterance(cmd);
//       if (screen == Screen.daily || screen == Screen.location) {
//         await _returnHome();
//       }
//     }
//     if (!_sessionEnded) {
//       _extendAwake();
//     }
//   }

//   Future<void> pauseSession() async {
//     _sessionEnded = true;
//     _awakeUntil = DateTime.fromMillisecondsSinceEpoch(0);
//     _awaitingMore = false;
//     notifyListeners();
//     await voice.speak(t('pausedMsg'));
//     _deaf = DateTime.now().add(const Duration(milliseconds: 1500));
//   }

//   Future<void> toggleMic() async {
//     if (micOff) {
//       micOff = false;
//       notifyListeners();
//       startLoop();
//       await voice.speak(t('micOnMsg'));
//     } else {
//       micOff = true;
//       stopLoop();
//       await voice.speak(t('micOffMsg'));
//     }
//   }

//   /// Understand a request (Gemini first, offline keyword router as fallback),
//   /// then act on it and answer.
//   Future<void> handleUtterance(String text) async {
//     if (exploring && await _exploreControl(text)) return;
//     voice.heard = text;
//     voice.markProcessing();
//     final r = (kUseCloudAi && online)
//         ? await ai.understand(text, lang, screen: screen.name, name: firstName)
//         : null;
//     if (r != null) {
//       if (r.command != null) {
//         final ok = await router.route(r.command!);
//         voice.flash(ok ? VoiceState.success : VoiceState.error);
//         if (!ok) await voice.speak(r.reply ?? t('notUnderstood', {'x': text}));
//         return;
//       }
//       if (r.reply != null) {
//         voice.flash(VoiceState.success);
//         await voice.speak(r.reply!);
//         return;
//       }
//     }
//     final ok = await router.route(text);
//     voice.flash(ok ? VoiceState.success : VoiceState.error);
//     if (!ok) await voice.speak(t('notUnderstood', {'x': text}));
//   }

//   /// Orb tap = push-to-talk (works even if the mic loop is off).
//   Future<void> listenAndRun() => _exclusive(() async {
//         await voice.stop();
//         if (!await ensureMic()) return;
//         final note = await voice.prepareListening();
//         if (note.isNotEmpty) await voice.speak(note, forceEn: true);
//         final heard = await voice.listenOnce();
//         if (heard == null) {
//           if (!voice.cancelled) await voice.speak(t(voice.errorKey));
//           return;
//         }
//         await handleUtterance(heard);
//         if (screen == Screen.daily || screen == Screen.location)
//           await _returnHome();
//       });

//   /// Chips / typed commands.
//   Future<void> runCommand(String text) async {
//     if (text.trim().isEmpty) return;
//     await handleUtterance(text);
//   }

//   // ---------------------------------------------------------- permissions
//   Future<bool> requestPerm(Permission p, String explain, String denied) async {
//     var s = await p.status;
//     if (!s.isGranted) {
//       if (s.isPermanentlyDenied) {
//         await voice.speak(t('openSettings'));
//         await openAppSettings();
//         s = await p.status;
//       } else {
//         await voice.speak(t(explain));
//         s = await p.request();
//       }
//     }
//     if (p == Permission.microphone) micOk = s.isGranted;
//     if (p == Permission.camera) camOk = s.isGranted;
//     if (p == Permission.locationWhenInUse) locOk = s.isGranted;
//     if (p == Permission.contacts) contactsOk = s.isGranted;
//     notifyListeners();
//     if (!s.isGranted) await voice.speak(t(denied));
//     return s.isGranted;
//   }

//   Future<bool> ensureMic() async {
//     if (micOk || await Permission.microphone.isGranted) return micOk = true;
//     return requestPerm(Permission.microphone, 'micExplain', 'micDenied');
//   }

//   Future<void> requestPermissionRow(int i) async {
//     await [
//       () => requestPerm(Permission.microphone, 'micExplain', 'micDenied'),
//       () => requestPerm(Permission.camera, 'camExplain', 'camDenied'),
//       () =>
//           requestPerm(Permission.locationWhenInUse, 'locExplain', 'locDenied'),
//       () => requestPerm(Permission.contacts, 'whyContacts', 'whyContacts'),
//     ][i]();
//   }

//   Future<void> requestAllPermissions() async {
//     for (var i = 0; i < 4; i++) {
//       await requestPermissionRow(i);
//     }
//   }

//   // -------------------------------------------------- voice sign-up flow
//   // Rule of this flow: it never gives up on its own. If Kalpana can't hear you she encourages you
//   // and tries again. Only leaving the screen, pressing Restart, or a lost microphone ends it.
//   static final _typeRe = RegExp(r'\btype\b|typing|टाइप|लिख', unicode: true);
//   static final _clearRe = RegExp(
//       r'start over|clear|reset|from the beginning|फिर से शुरू|दोबारा शुरू|पुन्हा सुरू|सुरुवातीपासून',
//       unicode: true);
//   static final _undoRe = RegExp(
//       r'delete last|remove last|undo|last one|आख़िरी हटाओ|आखिरी हटाओ|शेवटचा काढा|मागील काढा',
//       unicode: true);
//   static final _repeatRe = RegExp(
//       r'repeat|read it back|what do you have|दोहराओ|पुन्हा सांगा',
//       unicode: true);
//   static final _doneRe = RegExp(
//       r'^(done|that s all|that is all|finished|that s it|पूरा|पूर्ण|झाले|हो गया)$',
//       unicode: true);

//   String _digitsSpoken(String n) => n
//       .replaceAll(RegExp(r'[^\d+]'), '')
//       .split('')
//       .map((c) => c == '+' ? 'plus' : c)
//       .join(', ');

//   void _flag(Permission p, bool v) {
//     if (p == Permission.microphone) micOk = v;
//     if (p == Permission.camera) camOk = v;
//     if (p == Permission.locationWhenInUse) locOk = v;
//     if (p == Permission.contacts) contactsOk = v;
//     notifyListeners();
//   }

//   bool get _micLost =>
//       voice.lastError == 'permission' || voice.lastError == 'unavailable';

//   Future<void> _encourage(int misses) async {
//     final k = const [
//       'didntCatch',
//       'encourage1',
//       'encourage2',
//       'encourage3'
//     ][misses.clamp(1, 4) - 1];
//     await voice.speak(t(k));
//   }

//   /// One listening attempt. Ignores "okay got it / stop" (those only stop talking).
//   Future<String?> _hearOnce(
//       {Duration max = const Duration(seconds: 9),
//       bool dictation = false,
//       String? locale}) async {
//     for (var i = 0; i < 3; i++) {
//       final h = await voice.listenOnce(
//           max: max, dictation: dictation, localeId: locale);
//       if (h != null && isStopSpeech(h)) {
//         continue;
//       }
//       return h;
//     }
//     return null;
//   }

//   /// Listens until something is heard, encouraging the user after every miss.
//   /// Returns null only if the flow was left/restarted or the microphone is gone.
//   Future<String?> _hear() async {
//     final id = _flow;
//     var misses = 0;
//     while (id == _flow && screen == Screen.onboarding) {
//       final h = await _hearOnce();
//       if (h != null) {
//         return h;
//       }
//       if (id != _flow || _micLost) {
//         return null;
//       }
//       misses++;
//       await _encourage(misses);
//     }
//     return null;
//   }

//   Future<bool?> _askYesNo(String prompt) async {
//     final id = _flow;
//     var misses = 0;
//     while (id == _flow && screen == Screen.onboarding) {
//       await voice.speak(prompt);
//       final h = await _hearOnce(max: const Duration(seconds: 7));
//       if (id != _flow) {
//         return null;
//       }
//       if (h != null) {
//         final yn = CommandRouter.parseYesNo(h);
//         if (yn != null) {
//           return yn;
//         }
//         await voice.speak(t('yesNoPlease'));
//         continue;
//       }
//       if (_micLost) {
//         return null;
//       }
//       misses++;
//       await _encourage(misses);
//     }
//     return null;
//   }

//   String _cleanName(String raw) {
//     final s = raw
//         .trim()
//         .replaceAll(
//             RegExp(
//                 r"^(my name is|i am|i'm|this is|name is|मेरा नाम|माझे नाव|मैं|मी)\s+",
//                 caseSensitive: false),
//             '')
//         .replaceAll(RegExp(r'\s+(है|आहे|hai)$'), '');
//     return s
//         .split(' ')
//         .where((w) => w.isNotEmpty)
//         .map((w) => w[0].toUpperCase() + w.substring(1))
//         .join(' ');
//   }

//   /// Short and fast: one sentence, then straight to the Android permission box.
//   /// [attempts] 2 = if refused, say why it matters and ask once more.
//   Future<bool> _quickPermission(int id, Permission p, String introKey,
//       {String? whyKey, int attempts = 1}) async {
//     if (await p.isGranted) {
//       _flag(p, true);
//       return true;
//     }
//     for (var a = 0; a < attempts; a++) {
//       if (id != _flow) {
//         return false;
//       }
//       await voice.speak(t(a == 0 || whyKey == null ? introKey : whyKey));
//       var s = await p.request();
//       if (!s.isGranted && s.isPermanentlyDenied) {
//         await voice.speak(t('openSettings'));
//         await openAppSettings();
//         s = await p.status;
//       }
//       _flag(p, s.isGranted);
//       if (s.isGranted) {
//         return true;
//       }
//     }
//     return false;
//   }

//   Future<List<AppLang>> _supportedLangs({AppLang? exclude}) async => [
//         for (final l in AppLang.values)
//           if (l != exclude && (await voice.checkSupport(l)).ok) l
//       ];

//   static const _langQ = <AppLang, List<String>>{
//     AppLang.en: [
//       'Which language would you like to use? Say English, Hindi or Marathi.',
//       'English, Hindi or Marathi?'
//     ],
//     AppLang.hi: [
//       'आप किस भाषा में बात करना चाहेंगे? बोलिए अंग्रेज़ी, हिंदी या मराठी।',
//       'अंग्रेज़ी, हिंदी या मराठी?'
//     ],
//     AppLang.mr: [
//       'तुम्हाला कोणत्या भाषेत बोलायचे आहे? म्हणा इंग्रजी, हिंदी किंवा मराठी.',
//       'इंग्रजी, हिंदी की मराठी?'
//     ],
//   };

//   /// Asks the language in ALL three languages (so a user who only knows Hindi or Marathi understands),
//   /// listens with the English, then Hindi, then Marathi recogniser, CHECKS the phone really supports
//   /// the choice (voice + recognition) and, if not, explains honestly and offers what does work.
//   Future<bool> _chooseLanguage(int id, {bool trouble = false}) async {
//     var attempt = 0;
//     var listAlternatives = trouble;
//     while (id == _flow && screen == Screen.onboarding) {
//       if (listAlternatives) {
//         final alts = await _supportedLangs(exclude: trouble ? lang : null);
//         if (alts.isEmpty) {
//           await voice.speak(
//               "No spoken language is fully available on this phone, so I'll continue in English.",
//               forceEn: true);
//           await changeLanguage(AppLang.en);
//           return true;
//         }
//         await voice.speak(
//             'Which language would you like: ${alts.map((e) => e.english).join(' or ')}?',
//             forceEn: true);
//         listAlternatives = false;
//       } else {
//         for (final l in AppLang.values) {
//           await voice.speak(_langQ[l]![attempt == 0 ? 0 : 1], inLang: l);
//         }
//       }
//       final loc = attempt % 3 == 0
//           ? null
//           : await voice.localeFor(attempt % 3 == 1 ? AppLang.hi : AppLang.mr);
//       final h = await _hearOnce(locale: loc);
//       attempt++;
//       if (id != _flow) {
//         return false;
//       }
//       if (h == null) {
//         if (_micLost) {
//           return false;
//         }
//         continue;
//       }
//       final l = router.langIn(CommandRouter.norm(h));
//       if (l == null) {
//         continue;
//       }
//       if (trouble && l == lang) {
//         await voice.speak(
//             '${l.english} is the one that is not working. Please choose another.',
//             forceEn: true);
//         listAlternatives = true;
//         continue;
//       }
//       final chk = await voice.checkSupport(l);
//       if (chk.ok) {
//         await changeLanguage(l);
//         return true;
//       }
//       final missing = [
//         if (!chk.stt) 'speech recognition',
//         if (!chk.tts) 'the ${l.english} voice'
//       ].join(' and ');
//       await voice.speak(
//           "${l.english} isn't fully available on this phone: $missing is missing. I won't pretend otherwise. "
//           "You can add it in the phone's speech settings and restart me.",
//           forceEn: true);
//       listAlternatives = true; // next round lists the languages that do work
//     }
//     return false;
//   }

//   /// One question; the answer is typed live into [ctl], read back, accepted only after a spoken yes.
//   /// [probe]: if a non-English language can't be understood, offer a working one.
//   Future<String?> _askField(
//       int id, String prompt, TextEditingController ctl, int idx,
//       {required String Function(String) clean,
//       bool Function(String)? valid,
//       bool probe = false}) async {
//     activeField = idx;
//     notifyListeners();
//     var misses = 0, rounds = 0;
//     while (id == _flow && screen == Screen.onboarding) {
//       rounds++;
//       await voice.speak(rounds == 1 ? prompt : '${t('retry')} $prompt');
//       void live() => ctl.text = clean(voice.heard);
//       voice.addListener(live);
//       final h = await _hearOnce();
//       voice.removeListener(live);
//       if (id != _flow) {
//         return null;
//       }
//       if (h == null) {
//         if (_micLost) {
//           return null;
//         }
//         misses++;
//         final e = voice.lastError;
//         final langErr = e == 'error_language_not_supported' ||
//             e == 'error_language_unavailable';
//         if (probe && lang != AppLang.en && (langErr || misses >= 2)) {
//           await voice.speak(
//               "I'm having trouble understanding ${lang.english} on this phone.",
//               forceEn: true);
//           if (!await _chooseLanguage(id, trouble: true)) {
//             return null;
//           }
//           misses = 0;
//           rounds = 0;
//           continue;
//         }
//         await _encourage(misses);
//         continue;
//       }
//       misses = 0;
//       if (_typeRe.hasMatch(normText(h))) {
//         await voice.speak(t('noTypeNeeded'));
//         continue;
//       }
//       final v = clean(h);
//       ctl.text = v;
//       if (valid != null && !valid(v)) {
//         await voice.speak(t('didntCatch'));
//         continue;
//       }
//       final ok = await _askYesNo(t('heardSure', {'x': v}));
//       if (ok == true) {
//         return v;
//       }
//       if (ok == null) {
//         return null;
//       }
//     }
//     return null;
//   }

//   /// Phone number by voice, in small groups (dictation mode, longer pauses). Each group is echoed
//   /// digit by digit; unclear words are never guessed; the full number is read back for confirmation.
//   Future<String?> _collectPhone(int id, TextEditingController ctl, int idx,
//       {required String prompt}) async {
//     activeField = idx;
//     notifyListeners();
//     final chunks = <String>[];
//     var plus = false;
//     String all() => chunks.join();
//     String shown() => '${plus ? '+' : ''}${all()}';
//     void sync() => ctl.text = shown();
//     await voice.speak(prompt);
//     var misses = 0;
//     while (id == _flow && screen == Screen.onboarding) {
//       final h =
//           await _hearOnce(max: const Duration(seconds: 12), dictation: true);
//       if (id != _flow) {
//         return null;
//       }
//       if (h == null) {
//         if (_micLost) {
//           return null;
//         }
//         misses++;
//         await _encourage(misses);
//         if (misses % 3 == 0) {
//           await voice.speak(prompt);
//         }
//         continue;
//       }
//       misses = 0;
//       final n = normText(h);
//       if (_typeRe.hasMatch(n)) {
//         await voice.speak(t('noTypeNeeded'));
//         continue;
//       }
//       if (_clearRe.hasMatch(n)) {
//         chunks.clear();
//         plus = false;
//         sync();
//         await voice.speak(t('startedOver'));
//         continue;
//       }
//       if (_undoRe.hasMatch(n)) {
//         if (chunks.isEmpty) {
//           await voice.speak(t('digitsNone'));
//           continue;
//         }
//         final r = chunks.removeLast();
//         sync();
//         await voice.speak('${t('removed', {
//               'x': _digitsSpoken(r)
//             })} ${chunks.isEmpty ? '' : t('phoneSoFar', {
//                 'x': _digitsSpoken(all())
//               })}');
//         continue;
//       }
//       if (_repeatRe.hasMatch(n)) {
//         await voice.speak(all().isEmpty
//             ? t('digitsNone')
//             : t('phoneSoFar', {'x': _digitsSpoken(shown())}));
//         continue;
//       }
//       final doneCmd = _doneRe.hasMatch(n);
//       if (!doneCmd) {
//         final p = parseDigits(h);
//         if (p.unclear.isNotEmpty) {
//           await voice.speak(t('digitUnclear', {'x': p.unclear.join(' ')}));
//           continue;
//         }
//         if (p.digits.isEmpty) {
//           await voice.speak(t('digitsNone'));
//           continue;
//         }
//         if (chunks.isEmpty && p.plus) {
//           plus = true;
//         }
//         chunks.add(p.digits);
//         sync();
//         await voice
//             .speak(_digitsSpoken(p.digits)); // echo this group, digit by digit
//       }
//       final len = all().length;
//       if (doneCmd && len < 10) {
//         await voice.speak(t('phoneShort', {'n': '$len'}));
//         continue;
//       }
//       if (len > 13 || (!plus && len > 10)) {
//         await voice.speak(t('phoneLong', {'n': '$len'}));
//         continue;
//       }
//       if (doneCmd || (plus ? len >= 12 : len == 10)) {
//         final yn =
//             await _askYesNo(t('phoneConfirm', {'x': _digitsSpoken(shown())}));
//         if (yn == true) {
//           return shown();
//         }
//         if (yn == null) {
//           return null;
//         }
//         await voice.speak(t('phoneFix'));
//       }
//     }
//     return null;
//   }

//   Future<int?> _chooseAmong(List<fc.Contact> list, List<int> idxs) async {
//     final shown = idxs.take(5).toList();
//     final names = [
//       for (var i = 0; i < shown.length; i++)
//         '${i + 1}. ${list[shown[i]].displayName}'
//     ].join(', ');
//     for (var a = 0; a < 3; a++) {
//       await voice.speak(t('emMany', {'n': '${shown.length}', 'list': names}));
//       final h = await _hearOnce();
//       if (h == null) {
//         continue;
//       }
//       final ch = parseChoice(h);
//       if (ch == -1) {
//         return null;
//       }
//       if (ch != null && ch >= 1 && ch <= shown.length) {
//         return shown[ch - 1];
//       }
//     }
//     return null;
//   }

//   Future<bool> _manualContact(int id) async {
//     final name = await _askField(id, t('emManualName'), emergencyCtl, 2,
//         clean: _cleanName, valid: (v) => v.isNotEmpty);
//     if (name == null) {
//       return false;
//     }
//     final tmp = TextEditingController();
//     final ph = await _collectPhone(id, tmp, 2,
//         prompt: t('emManualPhone', {'name': name}));
//     if (ph == null) {
//       return false;
//     }
//     emergencyCtl.text = '$name • $ph';
//     return true;
//   }

//   /// Emergency contact. Kalpana explains: say the name exactly as saved in your phone's contacts.
//   /// The heard name appears live, is matched against the real contacts, disambiguated and confirmed.
//   Future<bool> _emergencyStep(int id) async {
//     activeField = 2;
//     notifyListeners();
//     var list = <fc.Contact>[];
//     if (contactsOk || await Permission.contacts.isGranted) {
//       try {
//         list = (await fc.FlutterContacts.getContacts(withProperties: true))
//             .where((c) => c.phones.isNotEmpty)
//             .toList();
//       } catch (_) {}
//     }
//     if (list.isEmpty) {
//       return _manualContact(
//           id); // no contacts access (or none saved): name + number by voice
//     }
//     await voice.speak(t('emIntro'));
//     for (var a = 0; a < 5; a++) {
//       if (id != _flow) {
//         return false;
//       }
//       if (a > 0) {
//         await voice.speak(t(a >= 2 ? 'emPick' : 'emRetry'));
//       }
//       void live() => emergencyCtl.text = voice.heard;
//       voice.addListener(live);
//       final h = await _hear();
//       voice.removeListener(live);
//       if (h == null) {
//         return false;
//       }
//       final n = normText(h);
//       if (RegExp(r'skip|छोड़|छोड|वगळा').hasMatch(n) && a >= 2) {
//         emergencyCtl.clear();
//         await voice.speak(t('noEmergency'));
//         return true;
//       }
//       final idxs = matchNames([for (final c in list) c.displayName], h);
//       if (idxs.isEmpty) {
//         await voice.speak(t('emNone', {'x': h}));
//         continue;
//       }
//       final pick =
//           idxs.length == 1 ? idxs.first : await _chooseAmong(list, idxs);
//       if (pick == null) {
//         continue;
//       }
//       final c = list[pick];
//       final number = c.phones.first.number.replaceAll(RegExp(r'[^\d+]'), '');
//       emergencyCtl.text = '${c.displayName} • $number';
//       final yn = await _askYesNo(
//           t('emOne', {'name': c.displayName, 'num': _digitsSpoken(number)}));
//       if (yn == true) {
//         return true;
//       }
//       if (yn == null) {
//         return false;
//       }
//     }
//     return _manualContact(id);
//   }

//   /// Reads the whole profile back. Nothing is saved until the user says yes.
//   Future<bool> _review(int id) async {
//     while (id == _flow && screen == Screen.onboarding) {
//       final has = emergencyCtl.text.trim().isNotEmpty && contacts.length > 1;
//       final em = has
//           ? '${contacts.first.label}, ${_digitsSpoken(contacts.first.number)}'
//           : t('noEmSaved');
//       await voice.speak('${t('profileSummary', {
//             'name': nameCtl.text,
//             'phone': _digitsSpoken(phoneCtl.text),
//             'contact': em,
//             'lang': lang.label
//           })} ${t('proceedAsk')}');
//       var h = await _hear();
//       if (h == null) {
//         return false;
//       }
//       if (CommandRouter.parseYesNo(h) == true) {
//         return true;
//       }
//       var n = normText(h);
//       if (!RegExp(
//               r'contact|emergency|संपर्क|आपातकाल|आणीबाणी|phone|number|नंबर|फोन|फ़ोन|क्रमांक|name|नाम|नाव')
//           .hasMatch(n)) {
//         await voice.speak(t('changeWhat'));
//         h = await _hear();
//         if (h == null) {
//           return false;
//         }
//         n = normText(h);
//       }
//       if (RegExp(r'contact|emergency|संपर्क|आपातकाल|आणीबाणी').hasMatch(n)) {
//         if (!await _emergencyStep(id)) {
//           return false;
//         }
//       } else if (RegExp(r'phone|number|नंबर|फोन|फ़ोन|क्रमांक').hasMatch(n)) {
//         final ph =
//             await _collectPhone(id, phoneCtl, 1, prompt: t('digitsPrompt'));
//         if (ph == null) {
//           return false;
//         }
//         phoneCtl.text = ph;
//       } else if (RegExp(r'name|नाम|नाव').hasMatch(n)) {
//         if (await _askField(id, t('askName'), nameCtl, 0,
//                 clean: _cleanName, valid: (v) => v.isNotEmpty) ==
//             null) {
//           return false;
//         }
//       }
//     }
//     return false;
//   }

//   Future<void> startSignup() => _exclusive(() async {
//         await voice.stop();
//         final id = ++_flow;
//         bool alive() => id == _flow && screen == Screen.onboarding;
//         Future<void> fail() async {
//           activeField = -1;
//           notifyListeners();
//           if (alive()) {
//             await voice.speak(t('signupFail'));
//           }
//         }

//         voice.bargeEnabled =
//             false; // keeps the recogniser free for answers during sign-up
//         // 1. microphone FIRST: the user needs voice to do everything else
//         if (!await _quickPermission(id, Permission.microphone, 'micExplain',
//             whyKey: 'whyMic', attempts: 2)) {
//           activeField = -1;
//           notifyListeners();
//           if (alive()) {
//             await voice.speak(t('micFallback'));
//           }
//           return;
//         }
//         if (!alive()) {
//           return;
//         }
//         // 2. language, asked in all three languages
//         if (!await _chooseLanguage(id)) {
//           return fail();
//         }
//         // 3. the other permissions, one short sentence each: camera, contacts, location
//         await _quickPermission(id, Permission.camera, 'permCamShort');
//         await _quickPermission(id, Permission.contacts, 'permContactsShort',
//             whyKey: 'whyContacts', attempts: 2);
//         await _quickPermission(
//             id, Permission.locationWhenInUse, 'permLocShort');
//         if (!alive()) {
//           return;
//         }
//         // 4. name (doubles as a live test of the chosen language)
//         final name = await _askField(id, t('askName'), nameCtl, 0,
//             clean: _cleanName, valid: (v) => v.isNotEmpty, probe: true);
//         if (name == null) {
//           return fail();
//         }
//         // 5. phone number
//         final phone =
//             await _collectPhone(id, phoneCtl, 1, prompt: t('digitsPrompt'));
//         if (phone == null) {
//           return fail();
//         }
//         phoneCtl.text = phone;
//         // 6. emergency contact from the device contacts
//         if (!await _emergencyStep(id)) {
//           return fail();
//         }
//         // 7. read everything back; save only after an explicit yes
//         if (!await _review(id)) {
//           return fail();
//         }
//         await finishOnboarding();
//       });

//   /// Saves the profile (this is the ONLY place sign-up data is persisted), goes home, explains Hey Kalpana.
//   Future<void> finishOnboarding() async {
//     _flow++; // cancels any running sign-up flow
//     saveProfile();
//     onboarded = true;
//     activeField = -1;
//     await _prefs?.setBool('onboarded', true);
//     await go(Screen.dashboard, announce: false);
//     await voice.speak(t('signupDone', {'name': _nameOr()}));
//     startLoop();
//   }

//   Future<void> _returnHome() async {
//     if (onboarded && screen != Screen.dashboard) {
//       await go(Screen.dashboard, announce: false);
//     }
//   }

//   // ------------------------------------------------------------- settings
//   Future<void> changeLanguage(AppLang l) async {
//     final note = await voice.setLanguage(l);
//     await _prefs?.setInt('lang', l.index);
//     notifyListeners();
//     await voice.speak(t('langSet', {'lang': l.label}));
//     if (note.isNotEmpty) await voice.speak(note, forceEn: true);
//   }

//   Future<void> adjustRate(double d) async {
//     final r = ((voice.rate + d).clamp(0.5, 1.5) * 10).round() / 10;
//     await voice.setRate(r);
//     await _prefs?.setDouble('rate', r);
//     await voice.speak(t('rateSet', {'r': r.toStringAsFixed(1)}));
//   }

//   void toggleHaptics() {
//     haptics = voice.haptics = !haptics;
//     _prefs?.setBool('haptics', haptics);
//     notifyListeners();
//   }

//   void toggleContrast() {
//     highContrast = !highContrast;
//     K.setContrast(highContrast);
//     _prefs?.setBool('contrast', highContrast);
//     notifyListeners();
//   }

//   void saveProfile() {
//     _prefs?.setString('name', nameCtl.text);
//     _prefs?.setString('phone', phoneCtl.text);
//     _prefs?.setString('emergency', emergencyCtl.text);
//   }

//   void setName(String n) {
//     nameCtl.text = _cleanName(n);
//     saveProfile();
//     notifyListeners();
//     voice.speak('Saved. I will call you ${nameCtl.text}.');
//   }

//   bool setEmergencyContact(String name, String number) {
//     emergencyCtl.text = '$name • ${number.trim()}';
//     saveProfile();
//     notifyListeners();
//     voice.speak(
//         'Saved emergency contact $name, number ${_spell(number)}. Check it on screen if needed.');
//     return true;
//   }

//   // ------------------------------------------------------------ reminders
//   String _remindersSpeech() => reminders.isEmpty
//       ? t('noReminders')
//       : t('remindersAre', {
//           'n': reminders.length.toString(),
//           'list': [
//             for (var i = 0; i < reminders.length; i++)
//               '${i + 1}. ${reminders[i]}.'
//           ].join(' ')
//         });

//   Future<bool> addReminder(String text) async {
//     var x = text.trim();
//     if (x.isEmpty) return false;
//     x = x[0].toUpperCase() + x.substring(1);
//     reminders = [...reminders, x];
//     await _prefs?.setStringList('reminders', reminders);
//     notifyListeners();
//     await voice.speak(t('reminderSaved', {'x': x}));
//     await _returnHome();
//     return true;
//   }

//   Future<bool> clearReminders() async {
//     if (reminders.isEmpty) {
//       await voice.speak(t('noReminders'));
//       return true;
//     }
//     if (!await confirm(t('confirmClear'))) {
//       await voice.speak(t(_confirmTimedOut ? 'noAnswer' : 'cancelled'));
//       return true;
//     }
//     reminders = [];
//     await _prefs?.setStringList('reminders', reminders);
//     notifyListeners();
//     await voice.speak(t('remindersCleared'));
//     await _returnHome();
//     return true;
//   }

//   // --------------------------------------------------------------- camera
//   Future<void> initCamera() => _camFuture ??= _initCam();

//   Future<void> _initCam() async {
//     try {
//       if (!await requestPerm(Permission.camera, 'camExplain', 'camDenied'))
//         return;
//       final cams = await availableCameras();
//       if (cams.isEmpty) throw Exception('none');
//       final back = cams.firstWhere(
//           (c) => c.lensDirection == CameraLensDirection.back,
//           orElse: () => cams.first);
//       final ctl = CameraController(back, ResolutionPreset.medium,
//           enableAudio: false, // audio off: keeps the mic free for speech
//           imageFormatGroup: ImageFormatGroup.yuv420); // needed by live Explore
//       await ctl.initialize();
//       cam = ctl;
//       notifyListeners();
//     } catch (_) {
//       await voice.speak(t('camFail'));
//     } finally {
//       if (!camReady) _camFuture = null;
//     }
//   }

//   Future<void> disposeCamera() async {
//     final c0 = cam;
//     cam = null;
//     _camFuture = null;
//     await _stopExploreEngine(c0); // stream must stop before the controller goes
//     await c0?.dispose();
//     notifyListeners();
//   }

//   String _prompt(Screen s) => switch (s) {
//         Screen.ocr =>
//           'Read all the text visible in this photo, in the order a person would read it. If there is no readable text, say so. Do not describe anything else.',
//         Screen.camera =>
//           'Tell a blind person what the main object in front of the camera is. If it is a medicine or packaged product, read the name, strength or dosage and expiry date if visible. Keep it under 4 sentences.',
//         Screen.explore =>
//           'Describe the surroundings for a blind person who is walking: obstacles, doors, steps, people, and whether the path ahead looks clear. Estimate distances in steps. Keep it under 4 sentences. If you cannot judge safety from a single photo, say so.',
//         _ =>
//           'Name the dominant colour of the main object in the centre of the photo in plain words (for example deep navy blue). Mention any pattern. One or two sentences.',
//       };

//   /// Offline analysis (ML Kit OCR / labels / colour). Gemini only if kUseCloudAi, and only as a bonus.
//   /// (Live Explore never uses Gemini; the still-photo path below is only a fallback for Explore.)
//   Future<String> _analyse(String path, Screen s) async {
//     final bytes = await File(path).readAsBytes();
//     if (kUseCloudAi && ai.configured && online && s == Screen.camera) {
//       try {
//         return await ai.describeImage(bytes, _prompt(s), lang);
//       } catch (_) {}
//     }
//     switch (s) {
//       case Screen.ocr:
//         final txt = await vision.readText(path);
//         if (txt.isNotEmpty) {
//           return t('textIs', {'x': txt});
//         }
//         final seen = await vision.labels(path, lang);
//         return seen.isEmpty
//             ? t('noText')
//             : '${t('noText')} ${t('seeLabels', {'x': seen.join(', ')})}';
//       case Screen.color:
//         return t('colorIs', {'x': await vision.colorName(bytes, lang)});
//       case Screen.explore:
//         final l = await vision.labels(path, lang);
//         return '${l.isEmpty ? t('seeNothing') : t('seeLabels', {
//                 'x': l.join(', ')
//               })} ${t('exploreNote')}';
//       default:
//         final txt = await vision.readText(path);
//         final l = await vision.labels(path, lang);
//         final parts = <String>[
//           if (l.isNotEmpty) t('seeLabels', {'x': l.join(', ')}),
//           if (txt.length >= 4) t('textIs', {'x': txt}),
//         ];
//         return parts.isEmpty ? t('seeNothing') : parts.join(' ');
//     }
//   }

//   /// Takes a photo and analyses it, speaks the answer. Opens the camera first if needed.
//   Future<void> takePicture() => _exclusive(() async {
//         try {
//           // A still photo needs the live stream (if any) to be stopped first.
//           if (screen == Screen.explore && (exploring || _exploreStarting)) {
//             await _stopExploreEngine();
//           }
//           if (!isCapture(screen)) await go(Screen.ocr, announce: false);
//           await initCamera();
//           final ctl = cam;
//           if (ctl == null || !camReady) return;
//           await voice.speak(t('holdSteady'));
//           final shot = await ctl.takePicture();
//           HapticFeedback.mediumImpact();
//           analysing = true;
//           captureBody = null;
//           notifyListeners();
//           unawaited(voice.speak(t('analysing')));
//           final text = await _analyse(shot.path, screen);
//           captureBody = text;
//           analysing = false;
//           notifyListeners();
//           await voice.speak(text);
//         } on AiException catch (e) {
//           await voice.speak(t(e.key));
//         } catch (_) {
//           await voice.speak(t('camFail'));
//         } finally {
//           analysing = false;
//           notifyListeners();
//         }
//       });

//   // ---------------------------------------------- live Explore (on-device)
//   static final _exploreStopRe = RegExp(
//       r'^(?:ok|okay|ओके)\s+(?:stop|स्टॉप|बंद|थांबा|रुको)(?:\s|$)',
//       unicode: true);
//   static final _gotItRe = RegExp(
//       r'^(?:ok|okay|ओके)\s+(?:got it|gotcha|understood|समझ गया|समझ गई|समझी|कळले|समजले)',
//       unicode: true);

//   /// "Okay, stop" ends live Explore; "Okay, got it" silences narration only.
//   /// Returns true if [raw] was one of those two phrases.
//   Future<bool> _exploreControl(String raw) async {
//     if (!exploring) return false;
//     final n = CommandRouter.norm(raw);
//     if (_exploreStopRe.hasMatch(n)) {
//       await exitExplore();
//       return true;
//     }
//     if (_gotItRe.hasMatch(n) || isStopSpeech(raw)) {
//       _muteExplore();
//       await voice.stop();
//       return true;
//     }
//     return false;
//   }

//   /// Heard by the barge-in listener while Kalpana was talking (audio already stopped).
//   void _onBargeWords(String words) {
//     if (!exploring) return;
//     final n = CommandRouter.norm(words);
//     if (_exploreStopRe.hasMatch(n)) {
//       unawaited(exitExplore());
//     } else {
//       _muteExplore();
//     }
//   }

//   void _muteExplore() {
//     exploreMuted = true;
//     notifyListeners();
//   }

//   void toggleExploreMute() {
//     exploreMuted = !exploreMuted;
//     if (exploreMuted) {
//       unawaited(voice.stop());
//     } else {
//       _resetNarration();
//     }
//     notifyListeners();
//   }

//   void _resetNarration() {
//     _narr.reset();
//     for (final t in _tracker.tracks) {
//       t.clearSpoken();
//     }
//   }

//   void _notifyThrottled() {
//     final now = DateTime.now();
//     if (now.difference(_lastNotify).inMilliseconds >= 200) {
//       _lastNotify = now;
//       notifyListeners();
//     }
//   }

//   /// Speaks without blocking the frame loop. An urgent line may interrupt a routine one.
//   void _say(String text, {bool urgent = false}) {
//     final tok = ++_narrTok;
//     _narrating = true;
//     _narrUrgent = urgent;
//     unawaited(voice.speak(text).whenComplete(() {
//       if (tok == _narrTok) _narrating = false;
//     }));
//   }

//   /// Opens live Explore: camera stream + on-device YOLO26n + tracking + narration.
//   /// If already running, it un-mutes and re-describes the scene.
//   Future<void> startExplore({bool quiet = false}) async {
//     if (exploring) {
//       exploreMuted = false;
//       _resetNarration();
//       notifyListeners();
//       if (!quiet) await voice.speak(et('exAgain'));
//       return;
//     }
//     if (_exploreStarting) return;
//     _exploreStarting = true;
//     final gen = ++_exploreGen;
//     exploreError = null;
//     exploreMuted = false;
//     exploreStatus = '';
//     exploreBoxes = const [];
//     captureBody = null;
//     notifyListeners();
//     YoloDetector? det;
//     var handedOver = false;
//     bool stale() => gen != _exploreGen || screen != Screen.explore;
//     try {
//       await initCamera();
//       if (stale()) return;
//       final ctl = cam;
//       if (ctl == null || !camReady) {
//         exploreError =
//             'The camera could not be started (is camera permission allowed?).';
//         notifyListeners();
//         return;
//       }
//       det = YoloDetector();
//       final err = await det.start();
//       if (stale()) return;
//       if (err != null) {
//         exploreError = err;
//         notifyListeners();
//         await voice.speak(et('exFail'));
//         return;
//       }
//       _det = det;
//       handedOver = true;
//       _sensorRot = ctl.description.sensorOrientation;
//       _tracker = Tracker();
//       _narr.reset();
//       _framing.reset();
//       _framingSpoken = false;
//       _detErrors = 0;
//       _frameBusy = false;
//       _narrating = false;
//       exploring = true;
//       notifyListeners();
//       await ctl.startImageStream(_onFrame);
//       if (stale()) return;
//       if (!quiet) _say('${et('exIntro')} ${et('exLimit')}');
//     } catch (e) {
//       if (gen == _exploreGen) {
//         exploreError = 'Live detection could not start: $e';
//         await _stopExploreEngine();
//         notifyListeners();
//         await voice.speak(et('exFail'));
//       }
//     } finally {
//       _exploreStarting = false;
//       if (!handedOver) await det?.dispose();
//     }
//   }

//   void _onFrame(CameraImage img) {
//     final det = _det;
//     if (det == null || !exploring || _frameBusy) return;
//     final now = DateTime.now();
//     if (now.difference(_lastFrameAt).inMilliseconds < 80) return;
//     _lastFrameAt = now;
//     _frameBusy = true;
//     final gen = _exploreGen;
//     det.detect(img, _sensorRot).then((res) {
//       if (gen != _exploreGen || !exploring) return;
//       _detErrors = 0;
//       if (res != null) _onDetections(res);
//     }).catchError((Object e) {
//       if (gen != _exploreGen || !exploring) return;
//       if (++_detErrors >= 3) {
//         exploreError = 'Live detection stopped after repeated errors: $e';
//         unawaited(_stopExploreEngine().then((_) async {
//           notifyListeners();
//           await voice.speak(et('exFail'));
//         }));
//       }
//     }).whenComplete(() => _frameBusy = false);
//   }

//   void _onDetections(DetectResult res) {
//     final now = DateTime.now();
//     final issue = _framing.update(res.luma, res.std);
//     if (issue != null) {
//       _tracker.update(const [], now);
//       exploreBoxes = const [];
//       final due = now.difference(_lastFramingSpeech).inSeconds >= 15;
//       final speak = !_framingSpoken || (!exploreMuted && due);
//       if (speak && !_narrating && _busy == 0) {
//         _framingSpoken = true;
//         _lastFramingSpeech = now;
//         final msg = et(switch (issue) {
//           FrameIssue.dark => 'exDark',
//           FrameIssue.uniform => 'exUniform',
//           FrameIssue.bright => 'exBright'
//         });
//         exploreStatus = msg;
//         _say(msg, urgent: true);
//       }
//       _notifyThrottled();
//       return;
//     }
//     _framingSpoken = false;
//     _tracker.update(res.dets, now);
//     final conf = _tracker.confirmed();
//     exploreBoxes = [
//       for (final t in conf)
//         if (isRelevantClass(t.cls)) boxFor(t, now, lang)
//     ];
//     final userTalking =
//         voice.state == VoiceState.listening && voice.heard.isNotEmpty;
//     if (_busy == 0 && !userTalking) {
//       final n = _narr.plan(conf, now, lang, muted: exploreMuted, quiet: awake);
//       if (n != null && (!_narrating || (n.urgent && !_narrUrgent))) {
//         _narr.commit(n, now);
//         exploreStatus = n.text;
//         _say(n.text, urgent: n.urgent);
//       }
//     }
//     _notifyThrottled();
//   }

//   /// Stops the image stream and the detector. Safe to call repeatedly.
//   Future<void> _stopExploreEngine([CameraController? ctl]) async {
//     _exploreGen++;
//     final wasLive = exploring || _det != null;
//     exploring = false;
//     exploreBoxes = const [];
//     final det = _det;
//     _det = null;
//     final c = ctl ?? cam;
//     if (c != null && c.value.isInitialized && c.value.isStreamingImages) {
//       try {
//         await c.stopImageStream();
//       } catch (_) {}
//     }
//     _frameBusy = false;
//     _narrating = false;
//     _tracker = Tracker();
//     _narr.reset();
//     _framing.reset();
//     await det?.dispose();
//     if (wasLive) notifyListeners();
//   }

//   /// "Okay, stop": end inference, release the camera, go home.
//   Future<void> exitExplore() async {
//     if (_exiting) return;
//     _exiting = true;
//     try {
//       await _stopExploreEngine();
//       if (screen == Screen.explore) {
//         await go(Screen.dashboard, announce: false); // also releases the camera
//       }
//       await voice.speak(et('exStopped'));
//     } finally {
//       _exiting = false;
//     }
//   }

//   // ------------------------------------------------------------- contacts
//   List<Contact> get contacts {
//     final out = <Contact>[];
//     final txt = emergencyCtl.text;
//     final m = RegExp(r'\+?\d[\d\s\-]{6,}\d').firstMatch(txt);
//     if (m != null) {
//       var label = txt
//           .substring(0, m.start)
//           .replaceAll(RegExp(r'[•\-–,:\s]+$'), '')
//           .trim();
//       if (label.isEmpty) label = 'Emergency contact';
//       out.add(Contact(label, m.group(0)!.trim()));
//     }
//     out.add(const Contact('National Helpline', '112'));
//     return out;
//   }

//   Contact? findContact(String query) {
//     final q = query.toLowerCase();
//     if (RegExp(r'112|police|helpline|पोलीस|पुलिस').hasMatch(q))
//       return contacts.last;
//     if (RegExp(r'emergency|contact|आपातकालीन|आणीबाणी').hasMatch(q) &&
//         contacts.length > 1) return contacts.first;
//     final words = q.split(' ').where((w) => w.length > 1);
//     for (final c in contacts) {
//       final l = c.label.toLowerCase();
//       if (words.any(l.contains)) return c;
//     }
//     return null;
//   }

//   String _spell(String n) =>
//       n.replaceAll(RegExp(r'[^\d+]'), '').split('').join(' ');

//   Future<bool> callContact(String name) async {
//     if (name.trim().isEmpty) {
//       await voice.speak(
//           t('dialHint', {'names': contacts.map((e) => e.label).join(', ')}));
//       return true;
//     }
//     final c = findContact(name);
//     if (c == null) {
//       await voice.speak(t('noContact', {'x': name}));
//       return false;
//     }
//     if (!await confirm(
//         t('confirmCall', {'name': c.label, 'number': _spell(c.number)}))) {
//       await voice.speak(t(_confirmTimedOut ? 'noAnswer' : 'cancelled'));
//       return true;
//     }
//     return dial(c.number, name: c.label);
//   }

//   /// Calls directly (Android CALL_PHONE): no dialer, no contacts app. If direct calling isn't
//   /// possible (permission refused, iOS), it falls back to opening the pre-filled dialer.
//   Future<bool> dial(String number, {String? name}) async {
//     final clean = number.replaceAll(RegExp(r'[^\d+]'), '');
//     if (Platform.isAndroid) {
//       var s = await Permission.phone.status;
//       if (!s.isGranted) {
//         await voice.speak(t('callPermAsk'));
//         s = await Permission.phone.request();
//       }
//       if (s.isGranted) {
//         await voice.speak(t('calling', {'name': name ?? _spell(clean)}));
//         try {
//           if (await FlutterPhoneDirectCaller.callNumber(clean) ?? false) {
//             return true;
//           }
//         } catch (_) {}
//       }
//     }
//     var ok = false;
//     try {
//       ok = await launchUrl(Uri(scheme: 'tel', path: clean));
//     } catch (_) {}
//     await voice.speak(t(ok ? 'dialer' : 'dialFail'));
//     return ok;
//   }

//   Future<void> sos() async {
//     final cs = contacts;
//     final target = cs.first;
//     if (cs.length == 1) await voice.speak(t('noEmergency'));
//     if (!await confirm(t('confirmSos', {'name': target.label}))) {
//       await voice.speak(t(_confirmTimedOut ? 'noAnswer' : 'cancelled'));
//       return;
//     }
//     await dial(target.number, name: target.label);
//   }

//   Future<bool> sendLocation() async {
//     final cs = contacts;
//     if (cs.length == 1) {
//       await voice.speak(t('noEmergency'));
//       return false;
//     }
//     final p = await _position();
//     if (p == null) return false;
//     if (!await confirm(t('confirmSms', {'name': cs.first.label}))) {
//       await voice.speak(t(_confirmTimedOut ? 'noAnswer' : 'cancelled'));
//       return true;
//     }
//     final body =
//         'I need help. My location: https://maps.google.com/?q=${p.latitude},${p.longitude}';
//     var ok = false;
//     try {
//       ok = await launchUrl(Uri(
//           scheme: 'sms',
//           path: cs.first.number.replaceAll(RegExp(r'\s'), ''),
//           query: 'body=${Uri.encodeComponent(body)}'));
//     } catch (_) {}
//     await voice.speak(t(ok ? 'smsOpened' : 'dialFail'));
//     return ok;
//   }

//   // ------------------------------------------------------------- location
//   Future<Position?> _position() async {
//     if (!await requestPerm(
//         Permission.locationWhenInUse, 'locExplain', 'locDenied')) return null;
//     if (!await Geolocator.isLocationServiceEnabled()) {
//       await voice.speak(t('locOff'));
//       return null;
//     }
//     try {
//       return await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//         timeLimit: const Duration(seconds: 12),
//       );
//     } catch (_) {
//       await voice.speak(t('locFail'));
//       return null;
//     }
//   }

//   Future<void> whereAmI() async {
//     liveHeading = liveBody = liveSub = null;
//     notifyListeners();
//     unawaited(voice.speak(t('whereWait')));
//     final p = await _position();
//     if (p == null) return;
//     lastPos = p;
//     var place =
//         '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';
//     var detail = place;
//     try {
//       final pm =
//           (await placemarkFromCoordinates(p.latitude, p.longitude)).first;
//       final parts = <String>{
//         for (final s in [
//           pm.name,
//           pm.subLocality,
//           pm.locality,
//           pm.administrativeArea,
//           pm.postalCode
//         ])
//           if (s != null && s.trim().isNotEmpty) s.trim()
//       }.toList();
//       if (parts.isNotEmpty) {
//         place = parts.take(2).join(', ');
//         detail = parts.join(', ');
//       }
//     } catch (_) {}
//     liveHeading = 'Near $place';
//     liveBody = detail;
//     liveSub = 'GPS ACCURACY ±${p.accuracy.round()} METERS';
//     notifyListeners();
//     await voice.speak(t(
//         'whereResult', {'place': place, 'acc': p.accuracy.round().toString()}));
//   }

//   // ----------------------------------------------------------------- chat
//   Future<void> dictate() => _exclusive(() async {
//         if (!await ensureMic()) return;
//         await voice.stop();
//         final h = await voice.listenOnce();
//         if (h == null) {
//           if (!voice.cancelled) await voice.speak(t(voice.errorKey));
//           return;
//         }
//         chatCtl.text = h;
//         voice.flash(VoiceState.success);
//         await voice.speak('Your message: $h');
//       });

//   Future<void> sendChat() async {
//     if (chatCtl.text.trim().isEmpty) {
//       await voice
//           .speak('Your message is empty. Tap the microphone to dictate one.');
//     } else {
//       voice.flash(VoiceState.error);
//       await voice.speak(t('chatOffline'));
//     }
//   }

//   // -------------------------------------------------------------- confirm
//   /// Spoken + on-screen confirmation. Voice yes/no OR the two big buttons.
//   /// Silence twice = cancel (never proceeds without a clear yes).
//   Future<bool> confirm(String prompt) => _exclusive(() async {
//         final ctx = navKey.currentContext;
//         if (ctx == null) return false;
//         _confirmTimedOut = false;
//         final done = Completer<bool>();
//         unawaited(showDialog<void>(
//             context: ctx,
//             barrierDismissible: false,
//             builder: (_) => ConfirmDialog(
//                 prompt: prompt,
//                 onChoice: (v) {
//                   if (!done.isCompleted) done.complete(v);
//                 })));
//         unawaited(() async {
//           for (var i = 0; i < 2 && !done.isCompleted; i++) {
//             await voice.speak(prompt);
//             if (done.isCompleted) return;
//             final h = await voice.listenOnce(max: const Duration(seconds: 7));
//             if (done.isCompleted) return;
//             final yn = h == null ? null : CommandRouter.parseYesNo(h);
//             if (yn != null) {
//               done.complete(yn);
//               return;
//             }
//           }
//           if (!done.isCompleted) {
//             _confirmTimedOut = true;
//             done.complete(false);
//           }
//         }());
//         final res = await done.future;
//         await voice.stop();
//         navKey.currentState?.pop();
//         return res;
//       });

//   // ---------------------------------------------------------- screen data
//   ScreenInfo _cap(IconData i, String sub, String ready, {Color? accent}) =>
//       captureBody != null
//           ? ScreenInfo(sub, i, 'Here is what I see', captureBody!,
//               accent: accent)
//           : ScreenInfo(
//               sub,
//               i,
//               analysing ? 'Looking at your picture…' : ready,
//               analysing
//                   ? 'Please wait a moment.'
//                   : 'Say “take picture” or press Take Picture.',
//               accent: accent);

//   ScreenInfo _exploreInfo() {
//     const sub = 'LIVE ON-DEVICE DETECTION';
//     const accent = Color(0xFFEBF6F1);
//     if (captureBody != null) {
//       return ScreenInfo(sub, Ic.navigation, 'Here is what I see', captureBody!,
//           accent: accent);
//     }
//     if (exploreError != null) {
//       return ScreenInfo(
//           sub, Ic.navigation, 'Live detection unavailable', exploreError!,
//           accent: const Color(0xFFFFF8F8));
//     }
//     if (!exploring) {
//       return const ScreenInfo(sub, Ic.navigation, 'Starting live detection…',
//           'Opening the camera and loading the on-device model.',
//           accent: accent);
//     }
//     return ScreenInfo(
//         sub,
//         Ic.navigation,
//         exploreMuted ? 'Exploring quietly' : 'Exploring live',
//         exploreStatus.isEmpty
//             ? 'Watching the camera. Say “Okay, got it” to quiet me, or “Okay, stop” to finish.'
//             : exploreStatus,
//         accent: accent);
//   }

//   ScreenInfo info(Screen s) {
//     final cs = contacts;
//     final sosLine = cs
//         .map((e) => e.number == '112'
//             ? 'National Helpline • 112'
//             : '${e.label} • ${e.number}')
//         .join(' and ');
//     switch (s) {
//       case Screen.camera:
//         return _cap(Ic.camera, 'VISION AI WITH VERIFICATION',
//             'Ask about what is in front');
//       case Screen.explore:
//         return _exploreInfo();
//       case Screen.ocr:
//         return _cap(Ic.fileText, 'DOCUMENT & SIGN READER', 'Read text aloud');
//       case Screen.color:
//         return _cap(Ic.palette, 'SURFACE SAMPLING', 'Identify a colour');
//       case Screen.location:
//         return liveHeading != null
//             ? ScreenInfo(liveSub!, Ic.mapPin, liveHeading!, liveBody!)
//             : const ScreenInfo(
//                 'GPS LOCATING…',
//                 Ic.mapPin,
//                 'Finding your location…',
//                 'Tap “Speak Result Aloud” to check again.');
//       case Screen.sos:
//         return ScreenInfo('TAP OR SAY “EMERGENCY”', Ic.alert,
//             'Emergency contacts ready', '$sosLine.',
//             accent: const Color(0xFFFFF8F8));
//       case Screen.community:
//         return const ScreenInfo(
//             'PRIVATE & ASSISTED',
//             Ic.message,
//             'Rohit Kulkarni',
//             'Are we meeting at Dadar station at 5 PM today? Your assisted reply is ready.',
//             demo: true);
//       case Screen.help:
//         return const ScreenInfo('SAY “HELP” ANYTIME', Ic.help,
//             'What you can say', 'Tap any command below to try it.');
//       case Screen.settings:
//         return ScreenInfo(
//             'AUDIO & ACCESSIBILITY',
//             Ic.settings,
//             'Speech Rate ${voice.rate.toStringAsFixed(1)}x',
//             'Haptic feedback ${haptics ? 'on' : 'off'} and high contrast borders ${highContrast ? 'on' : 'off'}.');
//       case Screen.daily:
//         return ScreenInfo(
//             'VOICE REMINDERS',
//             Ic.bell,
//             reminders.isEmpty
//                 ? 'No reminders yet'
//                 : '${reminders.length} reminder${reminders.length == 1 ? '' : 's'}',
//             reminders.isEmpty
//                 ? 'Say “Hey Kalpana, remind me to take medicine at 2 PM”.'
//                 : [
//                     for (var i = 0; i < reminders.length; i++)
//                       '${i + 1}. ${reminders[i]}'
//                   ].join('\n'));
//       case Screen.dial:
//         return ScreenInfo(
//             'HANDS-FREE CALLING',
//             Ic.phone,
//             'Say “Call” followed by name',
//             '“Kalpana, call ${cs.first.label}” • Mobile • ${cs.first.number}.');
//       default:
//         return ScreenInfo('', Ic.mic, titleOf(s), '');
//     }
//   }
// }

import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'ai/gemini_service.dart';
import 'config.dart';
import 'vision/explore_logic.dart';
import 'vision/explore_strings.dart';
import 'vision/offline_vision.dart';
import 'vision/yolo_detector.dart';
import 'strings.dart';
import 'theme.dart';
import 'voice/command_router.dart';
import 'voice/speech_utils.dart';
import 'voice/voice_service.dart';
import 'widgets.dart';

/// Same 15 screens as the Bolt `Screen` union. Order matches `screenTitles`.
enum Screen {
  welcome,
  onboarding,
  dashboard,
  camera,
  voice,
  explore,
  ocr,
  location,
  sos,
  community,
  help,
  settings,
  daily,
  dial,
  color
}

class Contact {
  final String label, number;
  const Contact(this.label, this.number);
}

class ScreenInfo {
  final String subtitle, heading, body;
  final IconData icon;
  final Color? accent;
  final bool demo;
  const ScreenInfo(this.subtitle, this.icon, this.heading, this.body,
      {this.accent, this.demo = false});
}

enum _ExCmd { stop, mute, resume, describe }

class AppController extends ChangeNotifier {
  final navKey = GlobalKey<NavigatorState>();
  final voice = VoiceService();
  final ai = GeminiService();
  final vision = OfflineVision();
  bool online = true;
  Timer? _netTimer;
  late final CommandRouter router = CommandRouter(this);
  SharedPreferences? _prefs;

  Screen screen = Screen.welcome;
  final nameCtl = TextEditingController();
  final phoneCtl = TextEditingController();
  final emergencyCtl = TextEditingController();
  final chatCtl = TextEditingController();
  final typedCtl = TextEditingController();
  bool haptics = true, highContrast = true, onboarded = false;
  bool micOk = false, camOk = false, locOk = false, contactsOk = false;
  bool _confirmTimedOut = false;
  String? liveHeading, liveBody, liveSub;
  Position? lastPos;

  // reminders + camera results
  List<String> reminders = [];
  CameraController? cam;
  Future<void>? _camFuture;
  bool analysing = false;
  String? captureBody;

  // ---- live Explore (on-device YOLO26n, no cloud) ----
  bool exploring = false; // engine running (camera stream + detector)
  bool exploreMuted =
      false; // "okay, got it": silent monitoring, urgent hazards only
  String? exploreError; // technical reason live mode is unavailable
  String exploreStatus =
      ''; // last thing said / current status, shown on screen
  List<ExploreBox> exploreBoxes = const [];
  static const _kIntroKey = 'exploreIntroHeard';
  bool _introPlaying = false;

  void _saveIntroHeard() => _prefs?.setBool(_kIntroKey, true);
  void _introHeardIfPlaying() {
    if (_introPlaying) {
      _introPlaying = false;
      _saveIntroHeard();
    }
  }

  YoloDetector? _det;
  Tracker _tracker = Tracker();
  final Narrator _narr = Narrator();
  final FramingMonitor _framing = FramingMonitor();
  bool _exploreStarting = false, _frameBusy = false, _narrating = false;
  bool _narrUrgent = false, _framingSpoken = false, _exiting = false;
  int _exploreGen = 0, _narrTok = 0, _detErrors = 0, _sensorRot = 90;
  DateTime _lastFrameAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastNotify = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastFramingSpeech = DateTime.fromMillisecondsSinceEpoch(0);

  // always-listening state
  bool micOff = false;
  int activeField = -1; // sign-up field being filled by voice
  int _busy = 0, _flow = 0, _loopGen = 0;
  bool _loopOn = false, _sessionEnded = false;
  DateTime _awakeUntil = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _awakeTimer;

  bool get loopOn => _loopOn;
  bool get awake => DateTime.now().isBefore(_awakeUntil);
  bool get camReady => cam?.value.isInitialized ?? false;
  static bool isCapture(Screen s) =>
      s == Screen.camera ||
      s == Screen.ocr ||
      s == Screen.explore ||
      s == Screen.color;

  AppLang get lang => voice.lang;
  String t(String k, [Map<String, String> a = const {}]) =>
      tr(voice.lang, k, a);
  String et(String k, [Map<String, String> a = const {}]) =>
      exploreText(voice.lang, k, a);
  String titleOf(Screen s) => screenTitles[lang.index][s.index];
  String get firstName => nameCtl.text.trim().split(' ').first;
  String _nameOr() => firstName.isNotEmpty
      ? firstName
      : const ['friend', 'दोस्त', 'मित्र'][lang.index];

  AppController() {
    voice.addListener(notifyListeners);
    voice.onBargeWords = _onBargeWords;
  }

  Future<T> _exclusive<T>(Future<T> Function() f) async {
    _busy++;
    try {
      return await f();
    } finally {
      _busy--;
    }
  }

  // ------------------------------------------------------------ lifecycle
  Future<void> _init() async {
    final p = _prefs = await SharedPreferences.getInstance();
    nameCtl.text = p.getString('name') ?? '';
    phoneCtl.text = p.getString('phone') ?? '';
    emergencyCtl.text = p.getString('emergency') ?? '';
    reminders = p.getStringList('reminders') ?? [];
    haptics = p.getBool('haptics') ?? true;
    highContrast = p.getBool('contrast') ?? true;
    onboarded = p.getBool('onboarded') ?? false;
    K.setContrast(highContrast);
    voice.haptics = haptics;
    micOk = await Permission.microphone.isGranted;
    camOk = await Permission.camera.isGranted;
    locOk = await Permission.locationWhenInUse.isGranted;
    contactsOk = await Permission.contacts.isGranted;
    final note = await voice.init(
        AppLang.values[p.getInt('lang') ?? 0], p.getDouble('rate') ?? 1.0);
    notifyListeners();
    _netTimer ??=
        Timer.periodic(const Duration(seconds: 15), (_) => _checkNet());
    unawaited(_checkNet());
    if (note.isNotEmpty) await voice.speak(note, forceEn: true);
  }

  Future<void> _checkNet() async {
    var ok = false;
    try {
      final r = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      ok = r.isNotEmpty && r.first.rawAddress.isNotEmpty;
    } catch (_) {}
    if (ok != online) {
      online = ok;
      notifyListeners();
    }
  }

  /// App open: welcome -> (new user) voice sign-up, or (returning user) straight to listening.
  Future<void> start() async {
    await _init();
    if (onboarded) {
      await voice.speak(t('welcomeBack', {'name': _nameOr()}));
      if (screen != Screen.welcome) return;
      await go(Screen.dashboard, announce: false);
      startLoop();
      return;
    }
    await voice.speak(t('welcome'));
    if (screen != Screen.welcome) return;
    await beginFromButton();
  }

  Future<void> beginFromButton() async {
    if (onboarded) {
      await go(Screen.dashboard, announce: false);
      startLoop();
    } else {
      await go(Screen.onboarding, announce: false);
      await startSignup();
    }
  }

  void onLifecycle(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      if (onboarded && !micOff) startLoop();
      if (isCapture(screen)) {
        unawaited(screen == Screen.explore
            ? startExplore(quiet: true)
            : initCamera());
      }
    } else if (s == AppLifecycleState.paused) {
      stopLoop(); // never listen / talk in the background
      unawaited(disposeCamera()); // also stops live Explore
    }
  }

  // ----------------------------------------------------------- navigation
  Future<void> go(Screen s, {bool announce = true}) async {
    await voice.stop();
    if (screen == Screen.explore && s != Screen.explore) {
      await _stopExploreEngine();
    }
    voice.bargeEnabled = s != Screen.onboarding;
    final leaving = isCapture(screen) && !isCapture(s);
    screen = s;
    if (isCapture(s)) {
      captureBody = null;
      analysing = false;
    }
    notifyListeners();
    if (leaving) unawaited(disposeCamera());
    if (announce) await _announce(s);
  }

  Future<void> back() async {
    if (screen == Screen.onboarding) return go(Screen.welcome, announce: false);
    if (screen != Screen.welcome && screen != Screen.dashboard)
      return go(Screen.dashboard);
  }

  Future<void> openVoice() async {
    if (screen != Screen.voice) await go(Screen.voice, announce: false);
    await listenAndRun();
  }

  String greeting() {
    final h = DateTime.now().hour;
    final g = t(h < 12
        ? 'greetMorning'
        : h < 17
            ? 'greetAfternoon'
            : 'greetEvening');
    return firstName.isEmpty ? g : '$g, $firstName';
  }

  Future<void> _announce(Screen s) async {
    final title = titleOf(s);
    switch (s) {
      case Screen.dashboard:
        await voice.speak('${greeting()}. ${t('dashHint')}');
      case Screen.sos:
        await voice.speak('$title. ${t('sosHint')}');
      case Screen.help:
        await voice.speak('$title. ${t('helpHint')}');
      case Screen.location:
        await whereAmI();
      case Screen.daily:
        await voice.speak('$title. ${_remindersSpeech()}');
      case Screen.dial:
        await voice.speak('$title. ${t('dialHint', {
              'names': contacts.map((e) => e.label).join(', ')
            })}');
      case Screen.explore:
        await startExplore();
      case Screen.camera || Screen.ocr || Screen.color:
        await initCamera();
        if (camReady) await voice.speak('$title. ${t('camReady')}');
      case Screen.community:
        final i = info(s);
        await voice.speak('$title. ${t('demo')} ${i.heading}. ${i.body}');
      default:
        await voice.speak(title);
    }
  }

  Future<void> readCurrent() async {
    switch (screen) {
      case Screen.voice:
        return voice.speak(voice.spoken);
      case Screen.location:
        return whereAmI();
      case Screen.explore:
        return voice
            .speak(exploreStatus.isNotEmpty ? exploreStatus : et('exAgain'));
      case Screen.camera || Screen.ocr || Screen.color:
        return voice.speak(captureBody ?? t('camReady'));
      case Screen.dashboard ||
            Screen.welcome ||
            Screen.onboarding ||
            Screen.help ||
            Screen.daily:
        return _announce(screen);
      default:
        final i = info(screen);
        await voice
            .speak('${i.demo ? '${t('demo')} ' : ''}${i.heading}. ${i.body}');
    }
  }

  // -------------------------------------------- always-listening ("Hey Kalpana")
  // static final _wakeWord = RegExp(r'kalpana|kalpna|calpana|कल्पना|कल्पणा|कलपना',
  //     caseSensitive: false, unicode: true);
  // static final _wakeFull = RegExp(
  //     r'(?:(?:hey|hay|hi|hello|okay|ok|हे|हेय|हाय|हेलो|ओके)\s+)?(?:kalpana|kalpna|calpana|कल्पना|कल्पणा|कलपना)[\s,.!]*',
  //     caseSensitive: false,
  //     unicode: true);

  // Match Kalpana as a whole word, not as part of another word.
  static final _wakeWord = RegExp(
    r'\b(?:kalpana|kalpna|calpana)\b|कल्पना|कल्पणा|कलपना',
    caseSensitive: false,
    unicode: true,
  );

  // Recognize the wake phrase at the beginning of the utterance.
  static final _wakeFull = RegExp(
    r'^(?:(?:hey|hay|hi|hello|okay|ok|हे|हेय|हाय|हेलो|ओके)\s+)?'
    r'(?:kalpana|kalpna|calpana|कल्पना|कल्पणा|कलपना)[\s,.!]*',
    caseSensitive: false,
    unicode: true,
  );

  void startLoop() {
    if (_loopOn || micOff || !onboarded) return;
    _loopOn = true;
    unawaited(_runLoop());
  }

  void stopLoop() {
    _loopGen++;
    _loopOn = false;
    voice.stop();
    notifyListeners();
  }

  Future<void> _runLoop() async {
    if (!await ensureMic()) {
      _loopOn = false;
      micOff = true;
      notifyListeners();
      return;
    }
    final gen = ++_loopGen;
    notifyListeners();
    var fails = 0;
    try {
      while (gen == _loopGen) {
        while (gen == _loopGen &&
            (_busy > 0 || voice.state == VoiceState.speaking)) {
          await Future.delayed(const Duration(milliseconds: 150));
        }
        if (gen != _loopGen) break;
        final heard = await voice.listenOnce(
            max: const Duration(seconds: 8), quiet: true);
        if (gen != _loopGen) break;
        if (heard != null) {
          fails = 0;
          await _onUtterance(heard);
          await Future.delayed(const Duration(milliseconds: 250));
          continue;
        }
        final e = voice.lastError;
        if (voice.cancelled ||
            e == null ||
            e == 'error_no_match' ||
            e == 'error_speech_timeout') {
          await Future.delayed(const Duration(milliseconds: 300));
          continue;
        }
        if (e == 'error_busy' || e == 'error_client' || e == 'error_audio') {
          await Future.delayed(const Duration(milliseconds: 1200));
          continue;
        }
        fails++;
        if (fails >= 3 ||
            e == 'permission' ||
            e == 'unavailable' ||
            e == 'error_network' ||
            e == 'error_language_not_supported') {
          micOff =
              true; // stop honestly instead of looping on a broken recogniser
          _loopGen++;
          await voice.speak('${t(voice.errorKey)} ${t('micOffMsg')}');
          break;
        }
        await Future.delayed(const Duration(milliseconds: 1500));
      }
    } finally {
      if (gen == _loopGen) _loopOn = false;
      notifyListeners();
    }
  }

  void _extendAwake() {
    _awakeUntil = DateTime.now().add(const Duration(seconds: 20));
    _awakeTimer?.cancel();
    _awakeTimer = Timer(const Duration(seconds: 21), notifyListeners);
    notifyListeners();
  }

  bool _awaitingMore = false;
  DateTime _deaf = DateTime.fromMillisecondsSinceEpoch(
      0); // ignore the mic briefly after she says "Hey Kalpana" herself
  static final _thanksRe =
      RegExp(r'thank|धन्यवाद|शुक्रिया|आभार|थैंक', unicode: true);
  static final _noMoreRe = RegExp(
      r'^(?:no|nope|nothing else|nothing|that s all|that is all|nahi|नहीं|नही|नाही|कुछ नहीं|काही नाही|बस)(?:\s|$)',
      unicode: true);

  Future<void> _endSession(String msg) async {
    _sessionEnded = true;
    _awaitingMore = false;
    _awakeUntil = DateTime.fromMillisecondsSinceEpoch(0);
    notifyListeners();
    await voice.speak(msg);
    _deaf = DateTime.now().add(const Duration(milliseconds: 1500));
  }

  Future<void> _onUtterance(String raw) async {
    if (DateTime.now().isBefore(_deaf)) {
      return;
    }
    // Live Explore control phrases work without the wake word.
    if (exploring && await _exploreControl(raw)) return;
    final woke = _wakeWord.hasMatch(raw);
    final wasAwake = awake;
    if (!woke && !wasAwake) {
      return; // not for us: ignore everything without the wake phrase
    }
    if (!wasAwake) {
      _awaitingMore = false;
    }
    final cmd = raw.replaceFirst(_wakeFull, '').trim();
    final n = normText(cmd);
    final words = n.isEmpty ? 0 : n.split(' ').length;
    _sessionEnded = false;
    _extendAwake();
    if (cmd.isEmpty) {
      _awaitingMore = false;

      await voice.speak(
        t('hiName', {'name': _nameOr()}),
      );

      // Briefly ignore residual audio from Kalpana's own greeting.
      _deaf = DateTime.now().add(
        const Duration(milliseconds: 900),
      );
    } else if (_awaitingMore && _noMoreRe.hasMatch(n)) {
      await _endSession(
          t('byeReply')); // "okay, if you need anything say Hey Kalpana"
      return;
    } else if (_awaitingMore &&
        words <= 3 &&
        CommandRouter.parseYesNo(cmd) == true) {
      _awaitingMore = false;
      await voice.speak(t('sureHelp'));
    } else if (words <= 5 && _thanksRe.hasMatch(n)) {
      _awaitingMore =
          true; // "okay thank you" -> you're welcome, anything else?
      await voice.speak(t('thanksReply'));
    } else {
      _awaitingMore = false;
      await handleUtterance(cmd);
      if (screen == Screen.daily || screen == Screen.location) {
        await _returnHome();
      }
    }
    if (!_sessionEnded) {
      _extendAwake();
    }
  }

  Future<void> pauseSession() async {
    _sessionEnded = true;
    _awakeUntil = DateTime.fromMillisecondsSinceEpoch(0);
    _awaitingMore = false;
    notifyListeners();
    await voice.speak(t('pausedMsg'));
    _deaf = DateTime.now().add(const Duration(milliseconds: 1500));
  }

  Future<void> toggleMic() async {
    if (micOff) {
      micOff = false;
      notifyListeners();
      startLoop();
      await voice.speak(t('micOnMsg'));
    } else {
      micOff = true;
      stopLoop();
      await voice.speak(t('micOffMsg'));
    }
  }

  /// Understand a request (Gemini first, offline keyword router as fallback),
  /// then act on it and answer.
  Future<void> handleUtterance(String text) async {
    if (exploring && await _exploreControl(text)) return;
    voice.heard = text;
    voice.markProcessing();
    final r = (kUseCloudAi && online)
        ? await ai.understand(text, lang, screen: screen.name, name: firstName)
        : null;
    if (r != null) {
      if (r.command != null) {
        final ok = await router.route(r.command!);
        voice.flash(ok ? VoiceState.success : VoiceState.error);
        if (!ok) await voice.speak(r.reply ?? t('notUnderstood', {'x': text}));
        return;
      }
      if (r.reply != null) {
        voice.flash(VoiceState.success);
        await voice.speak(r.reply!);
        return;
      }
    }
    final ok = await router.route(text);
    voice.flash(ok ? VoiceState.success : VoiceState.error);
    if (!ok) await voice.speak(t('notUnderstood', {'x': text}));
  }

  /// Orb tap = push-to-talk (works even if the mic loop is off).
  Future<void> listenAndRun() => _exclusive(() async {
        await voice.stop();
        if (!await ensureMic()) return;
        final note = await voice.prepareListening();
        if (note.isNotEmpty) await voice.speak(note, forceEn: true);
        final heard = await voice.listenOnce();
        if (heard == null) {
          if (!voice.cancelled) await voice.speak(t(voice.errorKey));
          return;
        }
        await handleUtterance(heard);
        if (screen == Screen.daily || screen == Screen.location)
          await _returnHome();
      });

  /// Chips / typed commands.
  Future<void> runCommand(String text) async {
    if (text.trim().isEmpty) return;
    await handleUtterance(text);
  }

  // ---------------------------------------------------------- permissions
  Future<bool> requestPerm(Permission p, String explain, String denied) async {
    var s = await p.status;
    if (!s.isGranted) {
      if (s.isPermanentlyDenied) {
        await voice.speak(t('openSettings'));
        await openAppSettings();
        s = await p.status;
      } else {
        await voice.speak(t(explain));
        s = await p.request();
      }
    }
    if (p == Permission.microphone) micOk = s.isGranted;
    if (p == Permission.camera) camOk = s.isGranted;
    if (p == Permission.locationWhenInUse) locOk = s.isGranted;
    if (p == Permission.contacts) contactsOk = s.isGranted;
    notifyListeners();
    if (!s.isGranted) await voice.speak(t(denied));
    return s.isGranted;
  }

  Future<bool> ensureMic() async {
    if (micOk || await Permission.microphone.isGranted) return micOk = true;
    return requestPerm(Permission.microphone, 'micExplain', 'micDenied');
  }

  Future<void> requestPermissionRow(int i) async {
    await [
      () => requestPerm(Permission.microphone, 'micExplain', 'micDenied'),
      () => requestPerm(Permission.camera, 'camExplain', 'camDenied'),
      () =>
          requestPerm(Permission.locationWhenInUse, 'locExplain', 'locDenied'),
      () => requestPerm(Permission.contacts, 'whyContacts', 'whyContacts'),
    ][i]();
  }

  Future<void> requestAllPermissions() async {
    for (var i = 0; i < 4; i++) {
      await requestPermissionRow(i);
    }
  }

  // -------------------------------------------------- voice sign-up flow
  // Rule of this flow: it never gives up on its own. If Kalpana can't hear you she encourages you
  // and tries again. Only leaving the screen, pressing Restart, or a lost microphone ends it.
  static final _typeRe = RegExp(r'\btype\b|typing|टाइप|लिख', unicode: true);
  static final _clearRe = RegExp(
      r'start over|clear|reset|from the beginning|फिर से शुरू|दोबारा शुरू|पुन्हा सुरू|सुरुवातीपासून',
      unicode: true);
  static final _undoRe = RegExp(
      r'delete last|remove last|undo|last one|आख़िरी हटाओ|आखिरी हटाओ|शेवटचा काढा|मागील काढा',
      unicode: true);
  static final _repeatRe = RegExp(
      r'repeat|read it back|what do you have|दोहराओ|पुन्हा सांगा',
      unicode: true);
  static final _doneRe = RegExp(
      r'^(done|that s all|that is all|finished|that s it|पूरा|पूर्ण|झाले|हो गया)$',
      unicode: true);

  String _digitsSpoken(String n) => n
      .replaceAll(RegExp(r'[^\d+]'), '')
      .split('')
      .map((c) => c == '+' ? 'plus' : c)
      .join(', ');

  void _flag(Permission p, bool v) {
    if (p == Permission.microphone) micOk = v;
    if (p == Permission.camera) camOk = v;
    if (p == Permission.locationWhenInUse) locOk = v;
    if (p == Permission.contacts) contactsOk = v;
    notifyListeners();
  }

  bool get _micLost =>
      voice.lastError == 'permission' || voice.lastError == 'unavailable';

  Future<void> _encourage(int misses) async {
    final k = const [
      'didntCatch',
      'encourage1',
      'encourage2',
      'encourage3'
    ][misses.clamp(1, 4) - 1];
    await voice.speak(t(k));
  }

  /// One listening attempt. Ignores "okay got it / stop" (those only stop talking).
  Future<String?> _hearOnce(
      {Duration max = const Duration(seconds: 9),
      bool dictation = false,
      String? locale}) async {
    for (var i = 0; i < 3; i++) {
      final h = await voice.listenOnce(
          max: max, dictation: dictation, localeId: locale);
      if (h != null && isStopSpeech(h)) {
        continue;
      }
      return h;
    }
    return null;
  }

  /// Listens until something is heard, encouraging the user after every miss.
  /// Returns null only if the flow was left/restarted or the microphone is gone.
  Future<String?> _hear() async {
    final id = _flow;
    var misses = 0;
    while (id == _flow && screen == Screen.onboarding) {
      final h = await _hearOnce();
      if (h != null) {
        return h;
      }
      if (id != _flow || _micLost) {
        return null;
      }
      misses++;
      await _encourage(misses);
    }
    return null;
  }

  Future<bool?> _askYesNo(String prompt) async {
    final id = _flow;
    var misses = 0;
    while (id == _flow && screen == Screen.onboarding) {
      await voice.speak(prompt);
      final h = await _hearOnce(max: const Duration(seconds: 7));
      if (id != _flow) {
        return null;
      }
      if (h != null) {
        final yn = CommandRouter.parseYesNo(h);
        if (yn != null) {
          return yn;
        }
        await voice.speak(t('yesNoPlease'));
        continue;
      }
      if (_micLost) {
        return null;
      }
      misses++;
      await _encourage(misses);
    }
    return null;
  }

  String _cleanName(String raw) {
    final s = raw
        .trim()
        .replaceAll(
            RegExp(
                r"^(my name is|i am|i'm|this is|name is|मेरा नाम|माझे नाव|मैं|मी)\s+",
                caseSensitive: false),
            '')
        .replaceAll(RegExp(r'\s+(है|आहे|hai)$'), '');
    return s
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  /// Short and fast: one sentence, then straight to the Android permission box.
  /// [attempts] 2 = if refused, say why it matters and ask once more.
  Future<bool> _quickPermission(int id, Permission p, String introKey,
      {String? whyKey, int attempts = 1}) async {
    if (await p.isGranted) {
      _flag(p, true);
      return true;
    }
    for (var a = 0; a < attempts; a++) {
      if (id != _flow) {
        return false;
      }
      await voice.speak(t(a == 0 || whyKey == null ? introKey : whyKey));
      var s = await p.request();
      if (!s.isGranted && s.isPermanentlyDenied) {
        await voice.speak(t('openSettings'));
        await openAppSettings();
        s = await p.status;
      }
      _flag(p, s.isGranted);
      if (s.isGranted) {
        return true;
      }
    }
    return false;
  }

  Future<List<AppLang>> _supportedLangs({AppLang? exclude}) async => [
        for (final l in AppLang.values)
          if (l != exclude && (await voice.checkSupport(l)).ok) l
      ];

  static const _langQ = <AppLang, List<String>>{
    AppLang.en: [
      'Which language would you like to use? Say English, Hindi or Marathi.',
      'English, Hindi or Marathi?'
    ],
    AppLang.hi: [
      'आप किस भाषा में बात करना चाहेंगे? बोलिए अंग्रेज़ी, हिंदी या मराठी।',
      'अंग्रेज़ी, हिंदी या मराठी?'
    ],
    AppLang.mr: [
      'तुम्हाला कोणत्या भाषेत बोलायचे आहे? म्हणा इंग्रजी, हिंदी किंवा मराठी.',
      'इंग्रजी, हिंदी की मराठी?'
    ],
  };

  /// Asks the language in ALL three languages (so a user who only knows Hindi or Marathi understands),
  /// listens with the English, then Hindi, then Marathi recogniser, CHECKS the phone really supports
  /// the choice (voice + recognition) and, if not, explains honestly and offers what does work.
  Future<bool> _chooseLanguage(int id, {bool trouble = false}) async {
    var attempt = 0;
    var listAlternatives = trouble;
    while (id == _flow && screen == Screen.onboarding) {
      if (listAlternatives) {
        final alts = await _supportedLangs(exclude: trouble ? lang : null);
        if (alts.isEmpty) {
          await voice.speak(
              "No spoken language is fully available on this phone, so I'll continue in English.",
              forceEn: true);
          await changeLanguage(AppLang.en);
          return true;
        }
        await voice.speak(
            'Which language would you like: ${alts.map((e) => e.english).join(' or ')}?',
            forceEn: true);
        listAlternatives = false;
      } else {
        for (final l in AppLang.values) {
          await voice.speak(_langQ[l]![attempt == 0 ? 0 : 1], inLang: l);
        }
      }
      final loc = attempt % 3 == 0
          ? null
          : await voice.localeFor(attempt % 3 == 1 ? AppLang.hi : AppLang.mr);
      final h = await _hearOnce(locale: loc);
      attempt++;
      if (id != _flow) {
        return false;
      }
      if (h == null) {
        if (_micLost) {
          return false;
        }
        continue;
      }
      final l = router.langIn(CommandRouter.norm(h));
      if (l == null) {
        continue;
      }
      if (trouble && l == lang) {
        await voice.speak(
            '${l.english} is the one that is not working. Please choose another.',
            forceEn: true);
        listAlternatives = true;
        continue;
      }
      final chk = await voice.checkSupport(l);
      if (chk.ok) {
        await changeLanguage(l);
        return true;
      }
      final missing = [
        if (!chk.stt) 'speech recognition',
        if (!chk.tts) 'the ${l.english} voice'
      ].join(' and ');
      await voice.speak(
          "${l.english} isn't fully available on this phone: $missing is missing. I won't pretend otherwise. "
          "You can add it in the phone's speech settings and restart me.",
          forceEn: true);
      listAlternatives = true; // next round lists the languages that do work
    }
    return false;
  }

  /// One question; the answer is typed live into [ctl], read back, accepted only after a spoken yes.
  /// [probe]: if a non-English language can't be understood, offer a working one.
  Future<String?> _askField(
      int id, String prompt, TextEditingController ctl, int idx,
      {required String Function(String) clean,
      bool Function(String)? valid,
      bool probe = false}) async {
    activeField = idx;
    notifyListeners();
    var misses = 0, rounds = 0;
    while (id == _flow && screen == Screen.onboarding) {
      rounds++;
      await voice.speak(rounds == 1 ? prompt : '${t('retry')} $prompt');
      void live() => ctl.text = clean(voice.heard);
      voice.addListener(live);
      final h = await _hearOnce();
      voice.removeListener(live);
      if (id != _flow) {
        return null;
      }
      if (h == null) {
        if (_micLost) {
          return null;
        }
        misses++;
        final e = voice.lastError;
        final langErr = e == 'error_language_not_supported' ||
            e == 'error_language_unavailable';
        if (probe && lang != AppLang.en && (langErr || misses >= 2)) {
          await voice.speak(
              "I'm having trouble understanding ${lang.english} on this phone.",
              forceEn: true);
          if (!await _chooseLanguage(id, trouble: true)) {
            return null;
          }
          misses = 0;
          rounds = 0;
          continue;
        }
        await _encourage(misses);
        continue;
      }
      misses = 0;
      if (_typeRe.hasMatch(normText(h))) {
        await voice.speak(t('noTypeNeeded'));
        continue;
      }
      final v = clean(h);
      ctl.text = v;
      if (valid != null && !valid(v)) {
        await voice.speak(t('didntCatch'));
        continue;
      }
      final ok = await _askYesNo(t('heardSure', {'x': v}));
      if (ok == true) {
        return v;
      }
      if (ok == null) {
        return null;
      }
    }
    return null;
  }

  /// Phone number by voice, in small groups (dictation mode, longer pauses). Each group is echoed
  /// digit by digit; unclear words are never guessed; the full number is read back for confirmation.
  Future<String?> _collectPhone(int id, TextEditingController ctl, int idx,
      {required String prompt}) async {
    activeField = idx;
    notifyListeners();
    final chunks = <String>[];
    var plus = false;
    String all() => chunks.join();
    String shown() => '${plus ? '+' : ''}${all()}';
    void sync() => ctl.text = shown();
    await voice.speak(prompt);
    var misses = 0;
    while (id == _flow && screen == Screen.onboarding) {
      final h =
          await _hearOnce(max: const Duration(seconds: 12), dictation: true);
      if (id != _flow) {
        return null;
      }
      if (h == null) {
        if (_micLost) {
          return null;
        }
        misses++;
        await _encourage(misses);
        if (misses % 3 == 0) {
          await voice.speak(prompt);
        }
        continue;
      }
      misses = 0;
      final n = normText(h);
      if (_typeRe.hasMatch(n)) {
        await voice.speak(t('noTypeNeeded'));
        continue;
      }
      if (_clearRe.hasMatch(n)) {
        chunks.clear();
        plus = false;
        sync();
        await voice.speak(t('startedOver'));
        continue;
      }
      if (_undoRe.hasMatch(n)) {
        if (chunks.isEmpty) {
          await voice.speak(t('digitsNone'));
          continue;
        }
        final r = chunks.removeLast();
        sync();
        await voice.speak('${t('removed', {
              'x': _digitsSpoken(r)
            })} ${chunks.isEmpty ? '' : t('phoneSoFar', {
                'x': _digitsSpoken(all())
              })}');
        continue;
      }
      if (_repeatRe.hasMatch(n)) {
        await voice.speak(all().isEmpty
            ? t('digitsNone')
            : t('phoneSoFar', {'x': _digitsSpoken(shown())}));
        continue;
      }
      final doneCmd = _doneRe.hasMatch(n);
      if (!doneCmd) {
        final p = parseDigits(h);
        if (p.unclear.isNotEmpty) {
          await voice.speak(t('digitUnclear', {'x': p.unclear.join(' ')}));
          continue;
        }
        if (p.digits.isEmpty) {
          await voice.speak(t('digitsNone'));
          continue;
        }
        if (chunks.isEmpty && p.plus) {
          plus = true;
        }
        chunks.add(p.digits);
        sync();
        await voice
            .speak(_digitsSpoken(p.digits)); // echo this group, digit by digit
      }
      final len = all().length;
      if (doneCmd && len < 10) {
        await voice.speak(t('phoneShort', {'n': '$len'}));
        continue;
      }
      if (len > 13 || (!plus && len > 10)) {
        await voice.speak(t('phoneLong', {'n': '$len'}));
        continue;
      }
      if (doneCmd || (plus ? len >= 12 : len == 10)) {
        final yn =
            await _askYesNo(t('phoneConfirm', {'x': _digitsSpoken(shown())}));
        if (yn == true) {
          return shown();
        }
        if (yn == null) {
          return null;
        }
        await voice.speak(t('phoneFix'));
      }
    }
    return null;
  }

  Future<int?> _chooseAmong(List<fc.Contact> list, List<int> idxs) async {
    final shown = idxs.take(5).toList();
    final names = [
      for (var i = 0; i < shown.length; i++)
        '${i + 1}. ${list[shown[i]].displayName}'
    ].join(', ');
    for (var a = 0; a < 3; a++) {
      await voice.speak(t('emMany', {'n': '${shown.length}', 'list': names}));
      final h = await _hearOnce();
      if (h == null) {
        continue;
      }
      final ch = parseChoice(h);
      if (ch == -1) {
        return null;
      }
      if (ch != null && ch >= 1 && ch <= shown.length) {
        return shown[ch - 1];
      }
    }
    return null;
  }

  Future<bool> _manualContact(int id) async {
    final name = await _askField(id, t('emManualName'), emergencyCtl, 2,
        clean: _cleanName, valid: (v) => v.isNotEmpty);
    if (name == null) {
      return false;
    }
    final tmp = TextEditingController();
    final ph = await _collectPhone(id, tmp, 2,
        prompt: t('emManualPhone', {'name': name}));
    if (ph == null) {
      return false;
    }
    emergencyCtl.text = '$name • $ph';
    return true;
  }

  /// Emergency contact. Kalpana explains: say the name exactly as saved in your phone's contacts.
  /// The heard name appears live, is matched against the real contacts, disambiguated and confirmed.
  Future<bool> _emergencyStep(int id) async {
    activeField = 2;
    notifyListeners();
    var list = <fc.Contact>[];
    if (contactsOk || await Permission.contacts.isGranted) {
      try {
        list = (await fc.FlutterContacts.getContacts(withProperties: true))
            .where((c) => c.phones.isNotEmpty)
            .toList();
      } catch (_) {}
    }
    if (list.isEmpty) {
      return _manualContact(
          id); // no contacts access (or none saved): name + number by voice
    }
    await voice.speak(t('emIntro'));
    for (var a = 0; a < 5; a++) {
      if (id != _flow) {
        return false;
      }
      if (a > 0) {
        await voice.speak(t(a >= 2 ? 'emPick' : 'emRetry'));
      }
      void live() => emergencyCtl.text = voice.heard;
      voice.addListener(live);
      final h = await _hear();
      voice.removeListener(live);
      if (h == null) {
        return false;
      }
      final n = normText(h);
      if (RegExp(r'skip|छोड़|छोड|वगळा').hasMatch(n) && a >= 2) {
        emergencyCtl.clear();
        await voice.speak(t('noEmergency'));
        return true;
      }
      final idxs = matchNames([for (final c in list) c.displayName], h);
      if (idxs.isEmpty) {
        await voice.speak(t('emNone', {'x': h}));
        continue;
      }
      final pick =
          idxs.length == 1 ? idxs.first : await _chooseAmong(list, idxs);
      if (pick == null) {
        continue;
      }
      final c = list[pick];
      final number = c.phones.first.number.replaceAll(RegExp(r'[^\d+]'), '');
      emergencyCtl.text = '${c.displayName} • $number';
      final yn = await _askYesNo(
          t('emOne', {'name': c.displayName, 'num': _digitsSpoken(number)}));
      if (yn == true) {
        return true;
      }
      if (yn == null) {
        return false;
      }
    }
    return _manualContact(id);
  }

  /// Reads the whole profile back. Nothing is saved until the user says yes.
  Future<bool> _review(int id) async {
    while (id == _flow && screen == Screen.onboarding) {
      final has = emergencyCtl.text.trim().isNotEmpty && contacts.length > 1;
      final em = has
          ? '${contacts.first.label}, ${_digitsSpoken(contacts.first.number)}'
          : t('noEmSaved');
      await voice.speak('${t('profileSummary', {
            'name': nameCtl.text,
            'phone': _digitsSpoken(phoneCtl.text),
            'contact': em,
            'lang': lang.label
          })} ${t('proceedAsk')}');
      var h = await _hear();
      if (h == null) {
        return false;
      }
      if (CommandRouter.parseYesNo(h) == true) {
        return true;
      }
      var n = normText(h);
      if (!RegExp(
              r'contact|emergency|संपर्क|आपातकाल|आणीबाणी|phone|number|नंबर|फोन|फ़ोन|क्रमांक|name|नाम|नाव')
          .hasMatch(n)) {
        await voice.speak(t('changeWhat'));
        h = await _hear();
        if (h == null) {
          return false;
        }
        n = normText(h);
      }
      if (RegExp(r'contact|emergency|संपर्क|आपातकाल|आणीबाणी').hasMatch(n)) {
        if (!await _emergencyStep(id)) {
          return false;
        }
      } else if (RegExp(r'phone|number|नंबर|फोन|फ़ोन|क्रमांक').hasMatch(n)) {
        final ph =
            await _collectPhone(id, phoneCtl, 1, prompt: t('digitsPrompt'));
        if (ph == null) {
          return false;
        }
        phoneCtl.text = ph;
      } else if (RegExp(r'name|नाम|नाव').hasMatch(n)) {
        if (await _askField(id, t('askName'), nameCtl, 0,
                clean: _cleanName, valid: (v) => v.isNotEmpty) ==
            null) {
          return false;
        }
      }
    }
    return false;
  }

  Future<void> startSignup() => _exclusive(() async {
        await voice.stop();
        final id = ++_flow;
        bool alive() => id == _flow && screen == Screen.onboarding;
        Future<void> fail() async {
          activeField = -1;
          notifyListeners();
          if (alive()) {
            await voice.speak(t('signupFail'));
          }
        }

        voice.bargeEnabled =
            false; // keeps the recogniser free for answers during sign-up
        // 1. microphone FIRST: the user needs voice to do everything else
        if (!await _quickPermission(id, Permission.microphone, 'micExplain',
            whyKey: 'whyMic', attempts: 2)) {
          activeField = -1;
          notifyListeners();
          if (alive()) {
            await voice.speak(t('micFallback'));
          }
          return;
        }
        if (!alive()) {
          return;
        }
        // 2. language, asked in all three languages
        if (!await _chooseLanguage(id)) {
          return fail();
        }
        // 3. the other permissions, one short sentence each: camera, contacts, location
        await _quickPermission(id, Permission.camera, 'permCamShort');
        await _quickPermission(id, Permission.contacts, 'permContactsShort',
            whyKey: 'whyContacts', attempts: 2);
        await _quickPermission(
            id, Permission.locationWhenInUse, 'permLocShort');
        if (!alive()) {
          return;
        }
        // 4. name (doubles as a live test of the chosen language)
        final name = await _askField(id, t('askName'), nameCtl, 0,
            clean: _cleanName, valid: (v) => v.isNotEmpty, probe: true);
        if (name == null) {
          return fail();
        }
        // 5. phone number
        final phone =
            await _collectPhone(id, phoneCtl, 1, prompt: t('digitsPrompt'));
        if (phone == null) {
          return fail();
        }
        phoneCtl.text = phone;
        // 6. emergency contact from the device contacts
        if (!await _emergencyStep(id)) {
          return fail();
        }
        // 7. read everything back; save only after an explicit yes
        if (!await _review(id)) {
          return fail();
        }
        await finishOnboarding();
      });

  /// Saves the profile (this is the ONLY place sign-up data is persisted), goes home, explains Hey Kalpana.
  Future<void> finishOnboarding() async {
    _flow++; // cancels any running sign-up flow
    saveProfile();
    onboarded = true;
    activeField = -1;
    await _prefs?.setBool('onboarded', true);
    await go(Screen.dashboard, announce: false);
    await voice.speak(t('signupDone', {'name': _nameOr()}));
    startLoop();
  }

  Future<void> _returnHome() async {
    if (onboarded && screen != Screen.dashboard) {
      await go(Screen.dashboard, announce: false);
    }
  }

  // ------------------------------------------------------------- settings
  Future<void> changeLanguage(AppLang l) async {
    final note = await voice.setLanguage(l);
    await _prefs?.setInt('lang', l.index);
    notifyListeners();
    await voice.speak(t('langSet', {'lang': l.label}));
    if (note.isNotEmpty) await voice.speak(note, forceEn: true);
  }

  Future<void> adjustRate(double d) async {
    final r = ((voice.rate + d).clamp(0.5, 1.5) * 10).round() / 10;
    await voice.setRate(r);
    await _prefs?.setDouble('rate', r);
    await voice.speak(t('rateSet', {'r': r.toStringAsFixed(1)}));
  }

  void toggleHaptics() {
    haptics = voice.haptics = !haptics;
    _prefs?.setBool('haptics', haptics);
    notifyListeners();
  }

  void toggleContrast() {
    highContrast = !highContrast;
    K.setContrast(highContrast);
    _prefs?.setBool('contrast', highContrast);
    notifyListeners();
  }

  void saveProfile() {
    _prefs?.setString('name', nameCtl.text);
    _prefs?.setString('phone', phoneCtl.text);
    _prefs?.setString('emergency', emergencyCtl.text);
  }

  void setName(String n) {
    nameCtl.text = _cleanName(n);
    saveProfile();
    notifyListeners();
    voice.speak('Saved. I will call you ${nameCtl.text}.');
  }

  bool setEmergencyContact(String name, String number) {
    emergencyCtl.text = '$name • ${number.trim()}';
    saveProfile();
    notifyListeners();
    voice.speak(
        'Saved emergency contact $name, number ${_spell(number)}. Check it on screen if needed.');
    return true;
  }

  // ------------------------------------------------------------ reminders
  String _remindersSpeech() => reminders.isEmpty
      ? t('noReminders')
      : t('remindersAre', {
          'n': reminders.length.toString(),
          'list': [
            for (var i = 0; i < reminders.length; i++)
              '${i + 1}. ${reminders[i]}.'
          ].join(' ')
        });

  Future<bool> addReminder(String text) async {
    var x = text.trim();
    if (x.isEmpty) return false;
    x = x[0].toUpperCase() + x.substring(1);
    reminders = [...reminders, x];
    await _prefs?.setStringList('reminders', reminders);
    notifyListeners();
    await voice.speak(t('reminderSaved', {'x': x}));
    await _returnHome();
    return true;
  }

  Future<bool> clearReminders() async {
    if (reminders.isEmpty) {
      await voice.speak(t('noReminders'));
      return true;
    }
    if (!await confirm(t('confirmClear'))) {
      await voice.speak(t(_confirmTimedOut ? 'noAnswer' : 'cancelled'));
      return true;
    }
    reminders = [];
    await _prefs?.setStringList('reminders', reminders);
    notifyListeners();
    await voice.speak(t('remindersCleared'));
    await _returnHome();
    return true;
  }

  // --------------------------------------------------------------- camera
  Future<void> initCamera() => _camFuture ??= _initCam();

  Future<void> _initCam() async {
    try {
      if (!await requestPerm(Permission.camera, 'camExplain', 'camDenied'))
        return;
      final cams = await availableCameras();
      if (cams.isEmpty) throw Exception('none');
      final back = cams.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cams.first);
      final ctl = CameraController(back, ResolutionPreset.high,
          enableAudio: false, // audio off: keeps the mic free for speech
          imageFormatGroup: ImageFormatGroup.yuv420); // needed by live Explore
      await ctl.initialize();
      cam = ctl;
      notifyListeners();
    } catch (_) {
      await voice.speak(t('camFail'));
    } finally {
      if (!camReady) _camFuture = null;
    }
  }

  Future<void> disposeCamera() async {
    final c0 = cam;
    cam = null;
    _camFuture = null;
    await _stopExploreEngine(c0); // stream must stop before the controller goes
    await c0?.dispose();
    notifyListeners();
  }

  String _prompt(Screen s) => switch (s) {
        Screen.ocr =>
          'Read all the text visible in this photo, in the order a person would read it. If there is no readable text, say so. Do not describe anything else.',
        Screen.camera =>
          'Tell a blind person what the main object in front of the camera is. If it is a medicine or packaged product, read the name, strength or dosage and expiry date if visible. Keep it under 4 sentences.',
        Screen.explore =>
          'Describe the surroundings for a blind person who is walking: obstacles, doors, steps, people, and whether the path ahead looks clear. Estimate distances in steps. Keep it under 4 sentences. If you cannot judge safety from a single photo, say so.',
        _ =>
          'Name the dominant colour of the main object in the centre of the photo in plain words (for example deep navy blue). Mention any pattern. One or two sentences.',
      };

  /// Offline analysis (ML Kit OCR / labels / colour). Gemini only if kUseCloudAi, and only as a bonus.
  /// (Live Explore never uses Gemini; the still-photo path below is only a fallback for Explore.)
  Future<String> _analyse(String path, Screen s) async {
    final bytes = await File(path).readAsBytes();
    if (kUseCloudAi && ai.configured && online && s == Screen.camera) {
      try {
        return await ai.describeImage(bytes, _prompt(s), lang);
      } catch (_) {}
    }
    switch (s) {
      case Screen.ocr:
        final txt = await vision.readText(path);
        if (txt.isNotEmpty) {
          return t('textIs', {'x': txt});
        }
        final seen = await vision.labels(path, lang);
        return seen.isEmpty
            ? t('noText')
            : '${t('noText')} ${t('seeLabels', {'x': seen.join(', ')})}';
      case Screen.color:
        return t('colorIs', {'x': await vision.colorName(bytes, lang)});
      case Screen.explore:
        final l = await vision.labels(path, lang);
        return '${l.isEmpty ? t('seeNothing') : t('seeLabels', {
                'x': l.join(', ')
              })} ${t('exploreNote')}';
      default:
        final txt = await vision.readText(path);
        final l = await vision.labels(path, lang);
        final parts = <String>[
          if (l.isNotEmpty) t('seeLabels', {'x': l.join(', ')}),
          if (txt.length >= 4) t('textIs', {'x': txt}),
        ];
        return parts.isEmpty ? t('seeNothing') : parts.join(' ');
    }
  }

  /// Takes a photo and analyses it, speaks the answer. Opens the camera first if needed.
  Future<void> takePicture() => _exclusive(() async {
        try {
          // A still photo needs the live stream (if any) to be stopped first.
          if (screen == Screen.explore && (exploring || _exploreStarting)) {
            await _stopExploreEngine();
          }
          if (!isCapture(screen)) await go(Screen.ocr, announce: false);
          await initCamera();
          final ctl = cam;
          if (ctl == null || !camReady) return;
          await voice.speak(t('holdSteady'));
          final shot = await ctl.takePicture();
          HapticFeedback.mediumImpact();
          analysing = true;
          captureBody = null;
          notifyListeners();
          unawaited(voice.speak(t('analysing')));
          final text = await _analyse(shot.path, screen);
          captureBody = text;
          analysing = false;
          notifyListeners();
          await voice.speak(text);
        } on AiException catch (e) {
          await voice.speak(t(e.key));
        } catch (_) {
          await voice.speak(t('camFail'));
        } finally {
          analysing = false;
          notifyListeners();
        }
      });

  // ---------------------------------------------- live Explore (on-device)
  static final _exStopRe = RegExp(
      r'^(?:(?:ok|okay|ओके)\s+(?:stop(?!\s+(?:speak|talk))|स्टॉप|बंद|थांबा|रुको)|(?:stop|स्टॉप)\s+(?:exploring|explore|the camera|एक्सप्लोर)|exit\s+explore)(?:\s|$)',
      unicode: true);
  static final _exMuteRe = RegExp(
      r'^(?:(?:ok|okay|ओके)\s+)?(?:got it|gotcha|understood|समझ गया|समझ गई|समझी|कळले|समजले|गॉट इट)|^(?:(?:ok|okay|ओके)\s+)?(?:stop|स्टॉप)\s+(?:speaking|talking|स्पीकिंग)|^(?:be\s+)?quiet(?:\s|$)',
      unicode: true);
  static final _exResumeRe = RegExp(
      r'^(?:keep going|keep exploring|continue|resume|go on|carry on|चालू रखो|जारी रखो|चालू ठेवा|सुरू ठेवा)(?:\s|$)',
      unicode: true);
  static final _exDescribeRe = RegExp(
      r'(?:what(?:\s?s|\s+is)\s+(?:in front of me|around me|ahead)|what do you see|^describe|मेरे सामने क्या है|सामने क्या है|समोर काय आहे)',
      unicode: true);

  _ExCmd? _exploreCmd(String raw) {
    final n = CommandRouter.norm(raw);
    if (_exStopRe.hasMatch(n)) return _ExCmd.stop;
    if (_exDescribeRe.hasMatch(n)) return _ExCmd.describe;
    if (_exResumeRe.hasMatch(n)) return _ExCmd.resume;
    if (_exMuteRe.hasMatch(n) || isStopSpeech(raw)) return _ExCmd.mute;
    return null;
  }

  Future<void> _runExploreCmd(_ExCmd c) async {
    switch (c) {
      case _ExCmd.stop:
        _introHeardIfPlaying();
        await exitExplore();
      case _ExCmd.mute:
        _introHeardIfPlaying();
        _muteExplore();
        await voice.stop();
      case _ExCmd.resume:
        exploreMuted = false;
        _resetNarration();
        notifyListeners();
        await voice.stop();
        _say(et('exResume'));
      case _ExCmd.describe:
        await voice.stop();
        await describeNow();
    }
  }

  /// Live Explore phrases work without the wake word. True if [raw] was one.
  Future<bool> _exploreControl(String raw) async {
    if (!exploring) return false;
    final c = _exploreCmd(raw);
    if (c == null) return false;
    await _runExploreCmd(c);
    return true;
  }

  /// Heard by the barge-in listener while Kalpana was talking (audio already stopped).
  /// Unrecognised speech still mutes, as before.
  void _onBargeWords(String words) {
    if (!exploring) return;
    final c = _exploreCmd(words) ?? _ExCmd.mute;
    if (c == _ExCmd.mute) {
      _introHeardIfPlaying();
      _muteExplore();
    } else {
      unawaited(_runExploreCmd(c));
    }
  }

  /// "Tell me what's in front of me now": a fresh description from what is tracked.
  Future<void> describeNow() async {
    if (!exploring) return;
    exploreMuted = false;
    final now = DateTime.now();
    final n = _narr.describe(_tracker.confirmed(), now, lang);
    if (n != null) _narr.commit(n, now);
    final text = n?.text ?? et('exNothing');
    exploreStatus = text;
    notifyListeners();
    _say(text); // not "urgent", so a real hazard can still interrupt it
  }

  void _muteExplore() {
    exploreMuted = true;
    notifyListeners();
  }

  void toggleExploreMute() {
    exploreMuted = !exploreMuted;
    if (exploreMuted) {
      unawaited(voice.stop());
    } else {
      _resetNarration();
    }
    notifyListeners();
  }

  void _resetNarration() {
    _narr.reset();
    for (final t in _tracker.tracks) {
      t.clearSpoken();
    }
  }

  void _notifyThrottled() {
    final now = DateTime.now();
    if (now.difference(_lastNotify).inMilliseconds >= 200) {
      _lastNotify = now;
      notifyListeners();
    }
  }

  /// Speaks without blocking the frame loop. An urgent line may interrupt a routine one.
  Future<bool> _say(String text, {bool urgent = false}) {
    final tok = ++_narrTok;
    _narrating = true;
    _narrUrgent = urgent;
    return voice.speak(text).then((_) {
      if (tok == _narrTok) _narrating = false;
      return tok == _narrTok;
    }).catchError((Object _) {
      if (tok == _narrTok) _narrating = false;
      return false;
    });
  }

  /// Opens live Explore: camera stream + on-device YOLO26n + tracking + narration.
  /// If already running, it un-mutes and re-describes the scene.
  Future<void> startExplore({bool quiet = false}) async {
    if (exploring) {
      exploreMuted = false;
      _resetNarration();
      notifyListeners();
      if (!quiet) await voice.speak(et('exAgain'));
      return;
    }
    if (_exploreStarting) return;
    _exploreStarting = true;
    final gen = ++_exploreGen;
    exploreError = null;
    exploreMuted = false;
    exploreStatus = '';
    exploreBoxes = const [];
    captureBody = null;
    notifyListeners();
    YoloDetector? det;
    var handedOver = false;
    bool stale() => gen != _exploreGen || screen != Screen.explore;
    try {
      await initCamera();
      if (stale()) return;
      final ctl = cam;
      if (ctl == null || !camReady) {
        exploreError =
            'The camera could not be started (is camera permission allowed?).';
        notifyListeners();
        return;
      }
      det = YoloDetector();
      final err = await det.start();
      if (stale()) return;
      if (err != null) {
        exploreError = err;
        notifyListeners();
        await voice.speak(et('exFail'));
        return;
      }
      _det = det;
      handedOver = true;
      _sensorRot = ctl.description.sensorOrientation;
      _tracker = Tracker();
      _narr.reset();
      _framing.reset();
      _framingSpoken = false;
      _detErrors = 0;
      _frameBusy = false;
      _narrating = false;
      exploring = true;
      notifyListeners();
      await ctl.startImageStream(_onFrame);
      if (stale()) {
        await _stopExploreEngine(
            ctl); // don't leave a stream running after a race
        return;
      }
      if (!quiet) {
        HapticFeedback
            .mediumImpact(); // "I'm live" cue; no speech after the first time
        if (!(_prefs?.getBool(_kIntroKey) ?? false)) {
          _introPlaying = true;
          _say('${et('exIntro')} ${et('exLimit')}').then((done) {
            _introPlaying = false;
            if (done)
              _saveIntroHeard(); // saved only once fully heard (or the user said "okay got it/stop")
          });
        }
      }
    } catch (e) {
      if (gen == _exploreGen) {
        exploreError = 'Live detection could not start: $e';
        await _stopExploreEngine();
        notifyListeners();
        await voice.speak(et('exFail'));
      }
    } finally {
      _exploreStarting = false;
      if (!handedOver) await det?.dispose();
    }
  }

  void _onFrame(CameraImage img) {
    final det = _det;
    if (det == null || !exploring || _frameBusy) return;
    final now = DateTime.now();
    if (now.difference(_lastFrameAt).inMilliseconds < 80) return;
    _lastFrameAt = now;
    _frameBusy = true;
    final gen = _exploreGen;
    det.detect(img, _sensorRot).then((res) {
      if (gen != _exploreGen || !exploring) return;
      _detErrors = 0;
      if (res != null) _onDetections(res);
    }).catchError((Object e) {
      if (gen != _exploreGen || !exploring) return;
      if (++_detErrors >= 3) {
        exploreError = 'Live detection stopped after repeated errors: $e';
        unawaited(_stopExploreEngine().then((_) async {
          notifyListeners();
          await voice.speak(et('exFail'));
        }));
      }
    }).whenComplete(() => _frameBusy = false);
  }

  void _onDetections(DetectResult res) {
    final now = DateTime.now();
    final issue = _framing.update(res.luma, res.std);
    if (issue != null) {
      _tracker.update(const [], now);
      exploreBoxes = const [];
      final due = now.difference(_lastFramingSpeech).inSeconds >= 15;
      final speak = !_framingSpoken || (!exploreMuted && due);
      if (speak && !_narrating && _busy == 0) {
        _framingSpoken = true;
        _lastFramingSpeech = now;
        final msg = et(switch (issue) {
          FrameIssue.dark => 'exDark',
          FrameIssue.uniform => 'exUniform',
          FrameIssue.bright => 'exBright'
        });
        exploreStatus = msg;
        _say(msg, urgent: true);
      }
      _notifyThrottled();
      return;
    }
    _framingSpoken = false;
    _tracker.update(res.dets, now);
    final conf = _tracker.confirmed();
    exploreBoxes = [
      for (final t in conf)
        if (isRelevantClass(t.cls)) boxFor(t, now, lang)
    ];
    final userTalking =
        voice.state == VoiceState.listening && voice.heard.isNotEmpty;
    if (_busy == 0 && !userTalking) {
      final n = _narr.plan(conf, now, lang, muted: exploreMuted, quiet: awake);
      if (n != null && (!_narrating || (n.urgent && !_narrUrgent))) {
        _narr.commit(n, now);
        exploreStatus = n.text;
        _say(n.text, urgent: n.urgent);
      }
    }
    _notifyThrottled();
  }

  /// Stops the image stream and the detector. Safe to call repeatedly.
  Future<void> _stopExploreEngine([CameraController? ctl]) async {
    _exploreGen++;
    final wasLive = exploring || _det != null;
    exploring = false;
    exploreBoxes = const [];
    final det = _det;
    _det = null;
    final c = ctl ?? cam;
    if (c != null && c.value.isInitialized && c.value.isStreamingImages) {
      try {
        await c.stopImageStream();
      } catch (_) {}
    }
    _frameBusy = false;
    _narrating = false;
    _tracker = Tracker();
    _narr.reset();
    _framing.reset();
    await det?.dispose();
    if (wasLive) notifyListeners();
  }

  /// "Okay, stop": end inference, release the camera, go home.
  Future<void> exitExplore() async {
    if (_exiting) return;
    _exiting = true;
    try {
      await _stopExploreEngine();
      if (screen == Screen.explore) {
        await go(Screen.dashboard, announce: false); // also releases the camera
      }
      await voice.speak(et('exStopped'));
    } finally {
      _exiting = false;
    }
  }

  // ------------------------------------------------------------- contacts
  List<Contact> get contacts {
    final out = <Contact>[];
    final txt = emergencyCtl.text;
    final m = RegExp(r'\+?\d[\d\s\-]{6,}\d').firstMatch(txt);
    if (m != null) {
      var label = txt
          .substring(0, m.start)
          .replaceAll(RegExp(r'[•\-–,:\s]+$'), '')
          .trim();
      if (label.isEmpty) label = 'Emergency contact';
      out.add(Contact(label, m.group(0)!.trim()));
    }
    out.add(const Contact('National Helpline', '112'));
    return out;
  }

  Contact? findContact(String query) {
    final q = query.toLowerCase();
    if (RegExp(r'112|police|helpline|पोलीस|पुलिस').hasMatch(q))
      return contacts.last;
    if (RegExp(r'emergency|contact|आपातकालीन|आणीबाणी').hasMatch(q) &&
        contacts.length > 1) return contacts.first;
    final words = q.split(' ').where((w) => w.length > 1);
    for (final c in contacts) {
      final l = c.label.toLowerCase();
      if (words.any(l.contains)) return c;
    }
    return null;
  }

  String _spell(String n) =>
      n.replaceAll(RegExp(r'[^\d+]'), '').split('').join(' ');

  Future<bool> callContact(String name) async {
    if (name.trim().isEmpty) {
      await voice.speak(
          t('dialHint', {'names': contacts.map((e) => e.label).join(', ')}));
      return true;
    }
    final c = findContact(name);
    if (c == null) {
      await voice.speak(t('noContact', {'x': name}));
      return false;
    }
    if (!await confirm(
        t('confirmCall', {'name': c.label, 'number': _spell(c.number)}))) {
      await voice.speak(t(_confirmTimedOut ? 'noAnswer' : 'cancelled'));
      return true;
    }
    return dial(c.number, name: c.label);
  }

  /// Calls directly (Android CALL_PHONE): no dialer, no contacts app. If direct calling isn't
  /// possible (permission refused, iOS), it falls back to opening the pre-filled dialer.
  Future<bool> dial(String number, {String? name}) async {
    final clean = number.replaceAll(RegExp(r'[^\d+]'), '');
    if (Platform.isAndroid) {
      var s = await Permission.phone.status;
      if (!s.isGranted) {
        await voice.speak(t('callPermAsk'));
        s = await Permission.phone.request();
      }
      if (s.isGranted) {
        await voice.speak(t('calling', {'name': name ?? _spell(clean)}));
        try {
          if (await FlutterPhoneDirectCaller.callNumber(clean) ?? false) {
            return true;
          }
        } catch (_) {}
      }
    }
    var ok = false;
    try {
      ok = await launchUrl(Uri(scheme: 'tel', path: clean));
    } catch (_) {}
    await voice.speak(t(ok ? 'dialer' : 'dialFail'));
    return ok;
  }

  Future<void> sos() async {
    final cs = contacts;
    final target = cs.first;
    if (cs.length == 1) await voice.speak(t('noEmergency'));
    if (!await confirm(t('confirmSos', {'name': target.label}))) {
      await voice.speak(t(_confirmTimedOut ? 'noAnswer' : 'cancelled'));
      return;
    }
    await dial(target.number, name: target.label);
  }

  Future<bool> sendLocation() async {
    final cs = contacts;
    if (cs.length == 1) {
      await voice.speak(t('noEmergency'));
      return false;
    }
    final p = await _position();
    if (p == null) return false;
    if (!await confirm(t('confirmSms', {'name': cs.first.label}))) {
      await voice.speak(t(_confirmTimedOut ? 'noAnswer' : 'cancelled'));
      return true;
    }
    final body =
        'I need help. My location: https://maps.google.com/?q=${p.latitude},${p.longitude}';
    var ok = false;
    try {
      ok = await launchUrl(Uri(
          scheme: 'sms',
          path: cs.first.number.replaceAll(RegExp(r'\s'), ''),
          query: 'body=${Uri.encodeComponent(body)}'));
    } catch (_) {}
    await voice.speak(t(ok ? 'smsOpened' : 'dialFail'));
    return ok;
  }

  // ------------------------------------------------------------- location
  Future<Position?> _position() async {
    if (!await requestPerm(
        Permission.locationWhenInUse, 'locExplain', 'locDenied')) return null;
    if (!await Geolocator.isLocationServiceEnabled()) {
      await voice.speak(t('locOff'));
      return null;
    }
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );
    } catch (_) {
      await voice.speak(t('locFail'));
      return null;
    }
  }

  Future<void> whereAmI() async {
    liveHeading = liveBody = liveSub = null;
    notifyListeners();
    unawaited(voice.speak(t('whereWait')));
    final p = await _position();
    if (p == null) return;
    lastPos = p;
    var place =
        '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';
    var detail = place;
    try {
      final pm =
          (await placemarkFromCoordinates(p.latitude, p.longitude)).first;
      final parts = <String>{
        for (final s in [
          pm.name,
          pm.subLocality,
          pm.locality,
          pm.administrativeArea,
          pm.postalCode
        ])
          if (s != null && s.trim().isNotEmpty) s.trim()
      }.toList();
      if (parts.isNotEmpty) {
        place = parts.take(2).join(', ');
        detail = parts.join(', ');
      }
    } catch (_) {}
    liveHeading = 'Near $place';
    liveBody = detail;
    liveSub = 'GPS ACCURACY ±${p.accuracy.round()} METERS';
    notifyListeners();
    await voice.speak(t(
        'whereResult', {'place': place, 'acc': p.accuracy.round().toString()}));
  }

  // ----------------------------------------------------------------- chat
  Future<void> dictate() => _exclusive(() async {
        if (!await ensureMic()) return;
        await voice.stop();
        final h = await voice.listenOnce();
        if (h == null) {
          if (!voice.cancelled) await voice.speak(t(voice.errorKey));
          return;
        }
        chatCtl.text = h;
        voice.flash(VoiceState.success);
        await voice.speak('Your message: $h');
      });

  Future<void> sendChat() async {
    if (chatCtl.text.trim().isEmpty) {
      await voice
          .speak('Your message is empty. Tap the microphone to dictate one.');
    } else {
      voice.flash(VoiceState.error);
      await voice.speak(t('chatOffline'));
    }
  }

  // -------------------------------------------------------------- confirm
  /// Spoken + on-screen confirmation. Voice yes/no OR the two big buttons.
  /// Silence twice = cancel (never proceeds without a clear yes).
  Future<bool> confirm(String prompt) => _exclusive(() async {
        final ctx = navKey.currentContext;
        if (ctx == null) return false;
        _confirmTimedOut = false;
        final done = Completer<bool>();
        unawaited(showDialog<void>(
            context: ctx,
            barrierDismissible: false,
            builder: (_) => ConfirmDialog(
                prompt: prompt,
                onChoice: (v) {
                  if (!done.isCompleted) done.complete(v);
                })));
        unawaited(() async {
          for (var i = 0; i < 2 && !done.isCompleted; i++) {
            await voice.speak(prompt);
            if (done.isCompleted) return;
            final h = await voice.listenOnce(max: const Duration(seconds: 7));
            if (done.isCompleted) return;
            final yn = h == null ? null : CommandRouter.parseYesNo(h);
            if (yn != null) {
              done.complete(yn);
              return;
            }
          }
          if (!done.isCompleted) {
            _confirmTimedOut = true;
            done.complete(false);
          }
        }());
        final res = await done.future;
        await voice.stop();
        navKey.currentState?.pop();
        return res;
      });

  // ---------------------------------------------------------- screen data
  ScreenInfo _cap(IconData i, String sub, String ready, {Color? accent}) =>
      captureBody != null
          ? ScreenInfo(sub, i, 'Here is what I see', captureBody!,
              accent: accent)
          : ScreenInfo(
              sub,
              i,
              analysing ? 'Looking at your picture…' : ready,
              analysing
                  ? 'Please wait a moment.'
                  : 'Say “take picture” or press Take Picture.',
              accent: accent);

  ScreenInfo _exploreInfo() {
    const sub = 'LIVE ON-DEVICE DETECTION';
    const accent = Color(0xFFEBF6F1);
    if (captureBody != null) {
      return ScreenInfo(sub, Ic.navigation, 'Here is what I see', captureBody!,
          accent: accent);
    }
    if (exploreError != null) {
      return ScreenInfo(
          sub, Ic.navigation, 'Live detection unavailable', exploreError!,
          accent: const Color(0xFFFFF8F8));
    }
    if (!exploring) {
      return const ScreenInfo(sub, Ic.navigation, 'Starting live detection…',
          'Opening the camera and loading the on-device model.',
          accent: accent);
    }
    return ScreenInfo(
        sub,
        Ic.navigation,
        exploreMuted ? 'Exploring quietly' : 'Exploring live',
        exploreStatus.isEmpty
            ? 'Watching the camera. Say “Okay, got it” to quiet me, or “Okay, stop” to finish.'
            : exploreStatus,
        accent: accent);
  }

  ScreenInfo info(Screen s) {
    final cs = contacts;
    final sosLine = cs
        .map((e) => e.number == '112'
            ? 'National Helpline • 112'
            : '${e.label} • ${e.number}')
        .join(' and ');
    switch (s) {
      case Screen.camera:
        return _cap(Ic.camera, 'VISION AI WITH VERIFICATION',
            'Ask about what is in front');
      case Screen.explore:
        return _exploreInfo();
      case Screen.ocr:
        return _cap(Ic.fileText, 'DOCUMENT & SIGN READER', 'Read text aloud');
      case Screen.color:
        return _cap(Ic.palette, 'SURFACE SAMPLING', 'Identify a colour');
      case Screen.location:
        return liveHeading != null
            ? ScreenInfo(liveSub!, Ic.mapPin, liveHeading!, liveBody!)
            : const ScreenInfo(
                'GPS LOCATING…',
                Ic.mapPin,
                'Finding your location…',
                'Tap “Speak Result Aloud” to check again.');
      case Screen.sos:
        return ScreenInfo('TAP OR SAY “EMERGENCY”', Ic.alert,
            'Emergency contacts ready', '$sosLine.',
            accent: const Color(0xFFFFF8F8));
      case Screen.community:
        return const ScreenInfo(
            'PRIVATE & ASSISTED',
            Ic.message,
            'Rohit Kulkarni',
            'Are we meeting at Dadar station at 5 PM today? Your assisted reply is ready.',
            demo: true);
      case Screen.help:
        return const ScreenInfo('SAY “HELP” ANYTIME', Ic.help,
            'What you can say', 'Tap any command below to try it.');
      case Screen.settings:
        return ScreenInfo(
            'AUDIO & ACCESSIBILITY',
            Ic.settings,
            'Speech Rate ${voice.rate.toStringAsFixed(1)}x',
            'Haptic feedback ${haptics ? 'on' : 'off'} and high contrast borders ${highContrast ? 'on' : 'off'}.');
      case Screen.daily:
        return ScreenInfo(
            'VOICE REMINDERS',
            Ic.bell,
            reminders.isEmpty
                ? 'No reminders yet'
                : '${reminders.length} reminder${reminders.length == 1 ? '' : 's'}',
            reminders.isEmpty
                ? 'Say “Hey Kalpana, remind me to take medicine at 2 PM”.'
                : [
                    for (var i = 0; i < reminders.length; i++)
                      '${i + 1}. ${reminders[i]}'
                  ].join('\n'));
      case Screen.dial:
        return ScreenInfo(
            'HANDS-FREE CALLING',
            Ic.phone,
            'Say “Call” followed by name',
            '“Kalpana, call ${cs.first.label}” • Mobile • ${cs.first.number}.');
      default:
        return ScreenInfo('', Ic.mic, titleOf(s), '');
    }
  }
}
