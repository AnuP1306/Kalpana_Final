import 'strings_v2.dart';

/// English / Hindi / Marathi strings. Missing translation => English fallback.
enum AppLang { en, hi, mr }

extension AppLangX on AppLang {
  String get ttsTag => const ['en-IN', 'hi-IN', 'mr-IN'][index];
  String get sttTag => ttsTag.replaceAll('-', '_');
  String get label => const ['English', 'हिंदी', 'मराठी'][index];
  String get english => const ['English', 'Hindi', 'Marathi'][index];
}

String tr(AppLang l, String key, [Map<String, String> args = const {}]) {
  final v = s2[key] ?? _s[key];
  var out = key;
  if (v != null) out = (l.index < v.length && v[l.index].isNotEmpty) ? v[l.index] : v[0];
  args.forEach((k, val) => out = out.replaceAll('{$k}', val));
  return out;
}

// Order MUST match `enum Screen` in app_controller.dart.
const screenTitles = <List<String>>[
  ['Welcome to Kalpana', 'Accessibility setup', 'Home dashboard', 'Ask My Camera', 'Voice Assistant', 'Explore Surroundings', 'Read Text', 'Where Am I?', 'Emergency SOS', 'Community Chat', 'Voice Directory', 'Settings', 'Daily Assistant', 'Voice Dial', 'Color Identifier'],
  ['कल्पना में स्वागत', 'एक्सेसिबिलिटी सेटअप', 'होम डैशबोर्ड', 'कैमरे से पूछें', 'वॉइस असिस्टेंट', 'आसपास देखें', 'पाठ पढ़ें', 'मैं कहाँ हूँ?', 'आपातकालीन एस ओ एस', 'कम्युनिटी चैट', 'वॉइस निर्देशिका', 'सेटिंग्स', 'दैनिक सहायक', 'वॉइस डायल', 'रंग पहचान'],
  ['कल्पनामध्ये स्वागत', 'सुलभता सेटअप', 'होम डॅशबोर्ड', 'कॅमेऱ्याला विचारा', 'व्हॉइस असिस्टंट', 'आजूबाजूचा शोध', 'मजकूर वाचा', 'मी कुठे आहे?', 'आणीबाणी एस ओ एस', 'कम्युनिटी चॅट', 'व्हॉइस निर्देशिका', 'सेटिंग्ज', 'दैनंदिन सहाय्यक', 'व्हॉइस डायल', 'रंग ओळख'],
];

const _s = <String, List<String>>{
  'welcome': [
    "Hello! I'm Kalpana, your voice companion. Say start to begin, or tap the glowing orb in the middle of the screen. To change my language, say Hindi or Marathi.",
    'नमस्ते! मैं कल्पना हूँ, आपकी आवाज़ की साथी। शुरू करने के लिए बोलिए शुरू, या स्क्रीन के बीच के चमकते गोले को छुएँ। भाषा बदलने के लिए बोलिए अंग्रेज़ी या मराठी।',
    'नमस्कार! मी कल्पना, तुमची आवाजाची सोबती. सुरू करण्यासाठी म्हणा सुरू, किंवा स्क्रीनच्या मध्यभागी असलेल्या चमकणाऱ्या गोलाला स्पर्श करा. भाषा बदलण्यासाठी म्हणा इंग्रजी किंवा हिंदी.'
  ],
  'micExplain': [
    'I need microphone access so I can hear you. Please choose Allow on the next screen.',
    'आपकी बात सुनने के लिए मुझे माइक्रोफ़ोन की अनुमति चाहिए। अगली स्क्रीन पर अनुमति दें चुनें।',
    'तुमचे बोलणे ऐकण्यासाठी मला मायक्रोफोनची परवानगी हवी आहे. पुढच्या स्क्रीनवर परवानगी द्या निवडा.'
  ],
  'micDenied': [
    "Microphone access is off, so I can't hear you. Please use the buttons on screen, or allow the microphone in the app settings.",
    'माइक्रोफ़ोन की अनुमति बंद है, इसलिए मैं सुन नहीं सकती। कृपया स्क्रीन के बटन इस्तेमाल करें, या ऐप सेटिंग में माइक्रोफ़ोन की अनुमति दें।',
    'मायक्रोफोनची परवानगी बंद आहे, त्यामुळे मला ऐकू येत नाही. कृपया स्क्रीनवरील बटणे वापरा, किंवा अॅप सेटिंगमध्ये परवानगी द्या.'
  ],
  'camExplain': [
    'I need the camera to read labels and describe what is in front of you. Please choose Allow.',
    'लेबल पढ़ने और आपके सामने की चीज़ें बताने के लिए मुझे कैमरे की अनुमति चाहिए। अनुमति दें चुनें।',
    'लेबल वाचण्यासाठी आणि तुमच्या समोरचे सांगण्यासाठी मला कॅमेऱ्याची परवानगी हवी आहे. परवानगी द्या निवडा.'
  ],
  'camDenied': ['Camera access is off. Camera features will not work until you allow it in the app settings.'],
  'locExplain': [
    'I need your location to tell you where you are, and for emergencies. Please choose Allow.',
    'आप कहाँ हैं यह बताने और आपातकाल के लिए मुझे आपकी लोकेशन चाहिए। अनुमति दें चुनें।',
    'तुम्ही कुठे आहात हे सांगण्यासाठी आणि आणीबाणीसाठी मला तुमचे स्थान हवे आहे. परवानगी द्या निवडा.'
  ],
  'locDenied': [
    'Location access is off, so I cannot tell where you are. Please allow location in the app settings.',
    'लोकेशन की अनुमति बंद है, इसलिए मैं नहीं बता सकती कि आप कहाँ हैं। ऐप सेटिंग में अनुमति दें।',
    'स्थानाची परवानगी बंद आहे, त्यामुळे तुम्ही कुठे आहात हे सांगता येत नाही. अॅप सेटिंगमध्ये परवानगी द्या.'
  ],
  'locOff': ['Location services are turned off on this phone. Please turn on GPS and try again.'],
  'locFail': ["I couldn't get your location. Please move to an open area and try again."],
  'openSettings': ['That permission is blocked. I am opening the app settings so you can allow it.'],
  'noHear': [
    "I didn't hear anything. Tap the orb and try again, or use the buttons on screen.",
    'मुझे कुछ सुनाई नहीं दिया। गोले को छूकर फिर कोशिश करें, या स्क्रीन के बटन इस्तेमाल करें।',
    'मला काही ऐकू आले नाही. गोलाला स्पर्श करून पुन्हा प्रयत्न करा, किंवा स्क्रीनवरील बटणे वापरा.'
  ],
  'notUnderstood': [
    'Sorry, I did not understand “{x}”. Say help to hear what I can do.',
    'माफ़ कीजिए, मैं “{x}” नहीं समझी। मैं क्या कर सकती हूँ यह सुनने के लिए बोलिए मदद।',
    'क्षमा करा, मला “{x}” समजले नाही. मी काय करू शकते हे ऐकण्यासाठी म्हणा मदत.'
  ],
  'offline': [
    'Speech recognition needs an internet connection for this language and you seem to be offline. Please use the buttons on screen.',
    'इस भाषा में आवाज़ पहचान के लिए इंटरनेट चाहिए और आप ऑफ़लाइन लगते हैं। कृपया स्क्रीन के बटन इस्तेमाल करें।',
    'या भाषेत आवाज ओळखण्यासाठी इंटरनेट लागते आणि तुम्ही ऑफलाइन दिसता. कृपया स्क्रीनवरील बटणे वापरा.'
  ],
  'sttUnavailable': [
    "Speech recognition isn't available right now. Please use the buttons on screen.",
    'अभी आवाज़ पहचान उपलब्ध नहीं है। कृपया स्क्रीन के बटन इस्तेमाल करें।',
    'सध्या आवाज ओळख उपलब्ध नाही. कृपया स्क्रीनवरील बटणे वापरा.'
  ],
  'langUnsupported': ["Speech recognition isn't available for this language on this phone. Please use the buttons, or switch language."],
  'langSet': ['Language changed to {lang}.', 'भाषा {lang} कर दी गई है।', 'भाषा {lang} केली आहे.'],
  'confirmCall': [
    'Call {name} on {number}? Say yes to confirm, or no to cancel.',
    '{name} को {number} पर कॉल करें? पुष्टि के लिए बोलिए हाँ, रद्द करने के लिए नहीं।',
    '{name} यांना {number} वर कॉल करायचा? पुष्टीसाठी म्हणा हो, रद्द करण्यासाठी नाही.'
  ],
  'confirmSos': [
    'Emergency. I will open the phone dialer for {name}. Say yes to continue, or no to cancel.',
    'आपातकाल। मैं {name} के लिए फ़ोन डायलर खोलूँगी। जारी रखने के लिए बोलिए हाँ, रद्द करने के लिए नहीं।',
    'आणीबाणी. मी {name} साठी फोन डायलर उघडेन. पुढे जाण्यासाठी म्हणा हो, रद्द करण्यासाठी नाही.'
  ],
  'confirmSms': ['Send {name} a text message with your location? Say yes to open the message, or no to cancel.'],
  'cancelled': ['Okay, cancelled. Nothing was done.', 'ठीक है, रद्द किया। कुछ नहीं किया गया।', 'ठीक आहे, रद्द केले. काहीही केले नाही.'],
  'noAnswer': [
    "I didn't hear a clear yes, so I cancelled. Nothing was done.",
    'मुझे साफ़ हाँ नहीं सुनाई दिया, इसलिए रद्द कर दिया। कुछ नहीं किया गया।',
    'मला स्पष्ट होकार ऐकू आला नाही, म्हणून रद्द केले. काहीही केले नाही.'
  ],
  'dialer': [
    'Opening the phone dialer. Press the call button to connect.',
    'फ़ोन डायलर खोल रही हूँ। जोड़ने के लिए कॉल बटन दबाएँ।',
    'फोन डायलर उघडत आहे. जोडण्यासाठी कॉल बटण दाबा.'
  ],
  'dialFail': ["I couldn't open the phone dialer on this device."],
  'smsOpened': ['The message is ready with your location. Please press send.'],
  'noContact': [
    "I couldn't find a contact named {x}. You can save an emergency contact in setup.",
    'मुझे {x} नाम का संपर्क नहीं मिला। आप सेटअप में आपातकालीन संपर्क सहेज सकते हैं।',
    '{x} नावाचा संपर्क सापडला नाही. तुम्ही सेटअपमध्ये आणीबाणी संपर्क जतन करू शकता.'
  ],
  'noEmergency': ['No emergency contact is saved yet. Open setup to add one. I can still call the national helpline, 112.'],
  'whereWait': ['Checking your location.', 'आपकी लोकेशन देख रही हूँ।', 'तुमचे स्थान तपासत आहे.'],
  'whereResult': [
    'You are near {place}. Accuracy is about {acc} meters.',
    'आप {place} के पास हैं। सटीकता लगभग {acc} मीटर है।',
    'तुम्ही {place} जवळ आहात. अचूकता सुमारे {acc} मीटर आहे.'
  ],
  'demo': [
    "This is sample content. Live analysis isn't connected yet.",
    'यह नमूना सामग्री है। लाइव विश्लेषण अभी जुड़ा नहीं है।',
    'ही नमुना माहिती आहे. थेट विश्लेषण अजून जोडलेले नाही.'
  ],
  'chatOffline': ["Community chat isn't connected to a server yet, so I couldn't send this message. It stays in the box."],
  'helpHint': [
    'You can say: where am I, read this, what is in front of me, open my reminders, call a contact, change language, or emergency. If this is an emergency, say emergency.',
    'आप बोल सकते हैं: मैं कहाँ हूँ, यह पढ़ो, मेरे सामने क्या है, मेरे रिमाइंडर खोलो, किसी को कॉल करो, भाषा बदलो, या इमरजेंसी। अगर यह आपातकाल है तो बोलिए इमरजेंसी।',
    'तुम्ही म्हणू शकता: मी कुठे आहे, हे वाचा, माझ्या समोर काय आहे, माझे रिमाइंडर उघडा, कोणाला कॉल करा, भाषा बदला, किंवा आणीबाणी. ही आणीबाणी असल्यास म्हणा आणीबाणी.'
  ],
  'greetMorning': ['Good morning', 'सुप्रभात', 'शुभ प्रभात'],
  'greetAfternoon': ['Good afternoon', 'नमस्कार', 'शुभ दुपार'],
  'greetEvening': ['Good evening', 'शुभ संध्या', 'शुभ संध्याकाळ'],
  'dashHint': [
    'How can I help you today? Tap the orb and speak.',
    'मैं आपकी कैसे मदद कर सकती हूँ? गोले को छूकर बोलिए।',
    'मी तुम्हाला कशी मदत करू? गोलाला स्पर्श करून बोला.'
  ],
  'onbHint': [
    'Say English, Hindi or Marathi to choose my language. Say allow to grant permissions. Say confirm when you are ready.',
    'मेरी भाषा चुनने के लिए बोलिए अंग्रेज़ी, हिंदी या मराठी। अनुमतियों के लिए बोलिए अनुमति। तैयार होने पर बोलिए पुष्टि।',
    'माझी भाषा निवडण्यासाठी म्हणा इंग्रजी, हिंदी किंवा मराठी. परवानगीसाठी म्हणा परवानगी. तयार झाल्यावर म्हणा पुष्टी.'
  ],
  'sosHint': ['Tap the big red button, or say emergency. I will always ask you to confirm first.'],
  'dialHint': ['Say call, then a name. Saved contacts: {names}.', 'बोलिए कॉल, फिर नाम। सहेजे गए संपर्क: {names}।', 'म्हणा कॉल, मग नाव. जतन केलेले संपर्क: {names}.'],
  'listening': ["I'm listening.", 'मैं सुन रही हूँ।', 'मी ऐकत आहे.'],
  'rateSet': ['Speech rate is now {r}.'],
};
