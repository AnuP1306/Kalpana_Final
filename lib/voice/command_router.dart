import '../app_controller.dart';
import '../strings.dart';
import 'speech_utils.dart';

typedef _Handler = Future<bool> Function(String text, RegExpMatch m);

class _Rule {
  final RegExp re;
  final _Handler run;
  _Rule(String pattern, this.run)
      : re = RegExp(pattern, caseSensitive: false, unicode: true);
}

/// Offline command understanding. Ordered rule table, first match wins; each rule
/// lists many English / Hindi / Marathi phrasings (incl. common mis-hearings).
/// Handlers return true ONLY when the action really happened.
class CommandRouter {
  final AppController c;
  late final List<_Rule> _rules;

  CommandRouter(this.c) {
    Future<bool> open(Screen s) async {
      await c.go(s);
      return true;
    }

    _rules = [
      _Rule(
          r"stop (?:listening|listing|lessening|hearing)|stop listen|do not listen|don t listen|go to sleep|that s all|that is all|thats all|मत सुनो|सुनना बंद|सुनना बन्द|ऐकणे बंद|ऐकू नको|ऐकू नका|ऐकणे थांबवा|बस करो",
          (t, m) async {
        await c.pauseSession();
        return true;
      }),
      _Rule(
          r'take (a |the )?(picture|photo|pic|snap)|click (a |the )?(picture|photo|pic)|capture|snap|shoot|तस्वीर|फोटो|फ़ोटो|फोटू',
          (t, m) async {
        await c.takePicture();
        return true;
      }),
      _Rule(
          r'(?:clear|delete|remove) (?:all )?(?:my )?reminders?|रिमाइंडर (?:हटाओ|मिटाओ|हटवा)',
          (t, m) => c.clearReminders()),
      _Rule(
          r'^(?:add (?:a )?reminder|set (?:a )?reminder|remind me|remember)(?: to| that| about)?\s+(.+)$',
          (t, m) => c.addReminder(m.group(1)!)),
      _Rule(r'(?:मुझे|मला)\s+(.+?)\s+(?:याद दिला|आठवण)',
          (t, m) => c.addReminder(m.group(1)!)),
      _Rule(
          r'^(stop|cancel|quiet|silence|enough|रुको|रुकिए|बंद करो|थांबा|बंद करा)',
          (t, m) async {
        await c.voice.stop();
        return true;
      }),
      _Rule(r'(?:my name is|मेरा नाम|माझे नाव)\s+(.+?)(?:\s+(?:है|आहे))?$',
          (t, m) async {
        c.setName(m.group(1)!);
        return true;
      }),
      _Rule(
          r'emergency contact (?:is )?([a-z ]+?)(?: number)?\s+(\+?[\d ]{8,})$',
          (t, m) async {
        return c.setEmergencyContact(m.group(1)!.trim(), m.group(2)!.trim());
      }),
      _Rule(r'allow|permissions?|grant|अनुमति|परवानगी', (t, m) async {
        await c.requestAllPermissions();
        return true;
      }),
      _Rule(r'^(confirm|done|finish|open kalpana|पुष्टि|पुष्टी|पूर्ण)',
          (t, m) async {
        if (c.screen != Screen.onboarding) return false;
        await c.finishOnboarding();
        return true;
      }),
      _Rule(r"^(start|begin|get started|let's start|शुरू|सुरू|शुरुआत)",
          (t, m) async {
        if (c.screen == Screen.welcome)
          return open(c.onboarded ? Screen.dashboard : Screen.onboarding);
        return false;
      }),
      _Rule(
          r'sos|emergency|urgent help|आपातकाल|इमरजेंसी|इमर्जेंसी|आणीबाणी|बचाओ|वाचवा|मुझे बचाओ',
          (t, m) async {
        await c.sos();
        return true;
      }),
      _Rule(r'(send|share).*location|लोकेशन (भेज|शेयर)|स्थान पाठव',
          (t, m) => c.sendLocation()),
      _Rule(r'(^|\s)(call|dial|phone|ring)(\s|$)|कॉल|फोन|डायल|लगाओ',
          (t, m) async {
        final name = t
            .replaceAll(
                RegExp(
                    r'(^|\s)(call|dial|phone|ring|to|please|me|कॉल|फोन|डायल|को|करो|करा|कर|लगाओ|लगा)(?=\s|$)'),
                ' ')
            .trim();
        return c.callContact(name);
      }),
      _Rule(
          r'where am i|where are we|my location|my position|current location|current place|मैं कहाँ|मैं कहां|कहां हूं|कहाँ हूँ|मी कुठे|कुठे आहे|माझे स्थान|आता कुठे|लोकेशन',
          (t, m) => open(Screen.location)),
      _Rule(
          r'reminders?|remainders?|remind|schedule|daily|appointment|to do|todo|my tasks|रिमाइंडर|याद|स्मरण|दैनिक|दैनंदिन',
          (t, m) => open(Screen.daily)),
      _Rule(
          r'read|reading|text|sign|notice|document|label|paper|letter|newspaper|what does it say|what is written|पढ़|पढ|वाच|मजकूर|टेक्स्ट|लिखा|लिहिले',
          (t, m) => open(Screen.ocr)),
      _Rule(
          r'in front|front of me|around me|surround|explore|obstacle|ahead|nearby|आसपास|आस-पास|आजूबाजू|सामने|समोर|एक्सप्लोर',
          (t, m) => open(Screen.explore)),
      _Rule(r'colou?r|रंग', (t, m) => open(Screen.color)),
      _Rule(
          r"what is this|what's this|what is that|describe (this|it)|identify|medicine|tablet|pill|camera|कैमरा|कॅमेरा|दवा|दवाई|गोली|औषध|गोळी|यह क्या|ये क्या|हे काय",
          (t, m) => open(Screen.camera)),
      _Rule(r'chat|community|message|चैट|चॅट|कम्युनिटी|संदेश|मैसेज',
          (t, m) => open(Screen.community)),
      _Rule(r'setting|सेटिंग', (t, m) => open(Screen.settings)),
      _Rule(
          r'help|commands?|instructions?|what can you|how do i|मदद|सहायता|मदत|सहाय्य',
          (t, m) => open(Screen.help)),
      _Rule(r'home|dashboard|main menu|होम|डैशबोर्ड|डॅशबोर्ड|मुख्य',
          (t, m) => open(Screen.dashboard)),
      _Rule(r'back|पीछे|वापस|मागे|परत जा', (t, m) async {
        await c.back();
        return true;
      }),
      _Rule(r'repeat|say again|once more|again|फिर से|दोबारा|पुन्हा',
          (t, m) async {
        await c.readCurrent();
        return true;
      }),
      _Rule(r'slow|धीरे|हळू', (t, m) async {
        await c.adjustRate(-0.2);
        return true;
      }),
      _Rule(r'fast|तेज|वेगाने|जलद', (t, m) async {
        await c.adjustRate(0.2);
        return true;
      }),
    ];
  }

  static String norm(String s) {
    var t = s
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{M}\p{N}\s+]', unicode: true), ' ');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t.replaceFirst(RegExp(r'^(hey |ok |okay )?(kalpana|कल्पना)\s*'), '');
  }

  AppLang? langIn(String t) {
    if (RegExp(r'english|अंग्रेज़ी|अंग्रेजी|इंग्रजी|इंग्लिश').hasMatch(t))
      return AppLang.en;
    if (RegExp(r'hindi|हिंदी|हिन्दी').hasMatch(t)) return AppLang.hi;
    if (RegExp(r'marathi|मराठी').hasMatch(t)) return AppLang.mr;
    return null;
  }

  /// Returns true if the command was understood AND carried out.
  Future<bool> route(String raw) async {
    final t = norm(raw);
    if (t.isEmpty) return false;
    if (isStopSpeech(raw)) {
      await c.voice.stop(); // "okay got it" / "okay stop": only stops talking
      return true;
    }
    final l = langIn(t);
    if (l != null &&
        (RegExp(r'language|भाषा|bhasha|change|switch|बदल|set').hasMatch(t) ||
            t.split(' ').length <= 2)) {
      await c.changeLanguage(l);
      return true;
    }
    for (final r in _rules) {
      final m = r.re.firstMatch(t);
      if (m != null) return r.run(t, m);
    }
    return false;
  }

  /// Yes/no for spoken confirmations. null = unclear.
  static bool? parseYesNo(String raw) {
    const yes = {
      'allow',
      'अनुमति',
      'परवानगी',
      'yes',
      'yeah',
      'yep',
      'sure',
      'ok',
      'okay',
      'confirm',
      'proceed',
      'haan',
      'ha',
      'ho',
      'hoy',
      'हाँ',
      'हां',
      'हा',
      'जी',
      'ठीक',
      'होय',
      'हो',
      'ओके'
    };
    const no = {
      'deny',
      'मना',
      'नकार',
      'no',
      'nope',
      'cancel',
      'stop',
      'nahi',
      'nako',
      'नहीं',
      'नही',
      'नाही',
      'नको',
      'रद्द'
    };
    final w = norm(raw).split(' ').toSet();
    if (w.intersection(no).isNotEmpty) return false;
    if (w.intersection(yes).isNotEmpty) return true;
    return null;
  }
}
