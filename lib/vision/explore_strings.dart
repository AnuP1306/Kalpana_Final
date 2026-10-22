import '../strings.dart' show AppLang;
import 'yolo_detector.dart' show kCocoLabels;

/// Explore-mode strings: [English, Hindi, Marathi]. Kept separate from strings.dart.
const _x = <String, List<String>>{
  'exIntro': [
    'Live exploring is on. I will tell you about people, vehicles and objects near you, and warn you about anything close. You can interrupt me at any time.',
    'लाइव एक्सप्लोर चालू है। मैं आपके पास के लोगों, वाहनों और चीज़ों के बारे में बताऊँगी, और कुछ भी पास हो तो सावधान करूँगी। आप मुझे कभी भी रोक सकते हैं।',
    'लाइव एक्सप्लोर सुरू आहे. मी तुमच्या जवळच्या व्यक्ती, वाहने आणि वस्तूंबद्दल सांगेन, आणि काही जवळ असल्यास सावध करेन. तुम्ही मला केव्हाही थांबवू शकता.'
  ],
  'exLimit': [
    'I only recognise common objects, so steps, kerbs and holes may not be noticed. Please keep using your cane or other aids.',
    'मैं केवल आम वस्तुएँ पहचानती हूँ, इसलिए सीढ़ियाँ, किनारे और गड्ढे छूट सकते हैं। कृपया अपनी छड़ी या अन्य सहायता का उपयोग जारी रखें।',
    'मी फक्त सामान्य वस्तू ओळखते, त्यामुळे पायऱ्या, कडा आणि खड्डे चुकू शकतात. कृपया तुमची काठी किंवा इतर साधने वापरत राहा.'
  ],
  'exAgain': [
    'Exploring is on. I will describe what I see.',
    'एक्सप्लोर चालू है। जो दिखेगा मैं बताऊँगी।',
    'एक्सप्लोर सुरू आहे. जे दिसेल ते मी सांगेन.'
  ],
  'exStopped': [
    'Okay, I stopped exploring.',
    'ठीक है, एक्सप्लोर करना बंद किया।',
    'ठीक आहे, एक्सप्लोर करणे थांबवले.'
  ],
  'exFail': [
    "Live detection isn't available right now, so I can't explore your surroundings. You can still use Take Picture.",
    'लाइव पहचान अभी उपलब्ध नहीं है, इसलिए मैं आसपास नहीं देख सकती। आप तस्वीर लेने का विकल्प इस्तेमाल कर सकते हैं।',
    'लाइव ओळख सध्या उपलब्ध नाही, त्यामुळे मी आजूबाजूचे पाहू शकत नाही. तुम्ही फोटो काढण्याचा पर्याय वापरू शकता.'
  ],
  'exHz': [
    '{obj} {dir}, {prox}.',
    '{obj} {dir}, {prox}।',
    '{obj} {dir}, {prox}.'
  ],
  'exHzMany': [
    '{obj}, {n} of them, {dir}, {prox}.',
    '{obj}, कुल {n}, {dir}, {prox}।',
    '{obj}, एकूण {n}, {dir}, {prox}.'
  ],
  'exApproach': [
    'Careful, {obj} approaching, {dir}.',
    'सावधान! {obj} {dir} पास आ रहे हैं।',
    'सावधान! {obj} {dir} जवळ येत आहे.'
  ],
  'exLeft': ['on your left', 'बाईं ओर', 'डावीकडे'],
  'exAhead': ['ahead', 'सामने', 'समोर'],
  'exRight': ['on your right', 'दाईं ओर', 'उजवीकडे'],
  'exVeryClose': ['very close', 'बहुत पास', 'अगदी जवळ'],
  'exClose': ['close', 'पास', 'जवळ'],
  'exNear': ['nearby', 'आसपास', 'आसपास'],
  'exDark': [
    "The camera view is very dark, so I can't see well. Try a brighter place or check the lens.",
    'कैमरे का दृश्य बहुत अंधेरा है, इसलिए मुझे ठीक से दिख नहीं रहा। रोशनी वाली जगह जाएँ या लेंस देखें।',
    'कॅमेऱ्याचे दृश्य खूप अंधारे आहे, त्यामुळे नीट दिसत नाही. उजेडाच्या जागी जा किंवा लेन्स तपासा.'
  ],
  'exUniform': [
    'The camera sees almost no detail. It may be covered or too close to a surface.',
    'कैमरे को लगभग कुछ दिखाई नहीं दे रहा। वह ढका हो सकता है या किसी सतह के बहुत पास हो सकता है।',
    'कॅमेऱ्याला जवळपास काहीच तपशील दिसत नाही. तो झाकलेला असू शकतो किंवा पृष्ठभागाच्या खूप जवळ असू शकतो.'
  ],
  'exBright': [
    'The camera view is overexposed. Try turning away from the strong light.',
    'कैमरे का दृश्य बहुत चमकीला है। तेज़ रोशनी से हटकर घुमाएँ।',
    'कॅमेऱ्याचे दृश्य खूप तेजस्वी आहे. तीव्र प्रकाशापासून दूर वळा.'
  ],
};

String exploreText(AppLang l, String key,
    [Map<String, String> args = const {}]) {
  final v = _x[key];
  var out = key;
  if (v != null) {
    out = (l.index < v.length && v[l.index].isNotEmpty) ? v[l.index] : v[0];
  }
  args.forEach((k, val) => out = out.replaceAll('{$k}', val));
  return out;
}

// [Hindi, Marathi] names for the classes Kalpana narrates; others fall back to English.
const _loc = <int, List<String>>{
  0: ['व्यक्ति', 'व्यक्ती'],
  1: ['साइकिल', 'सायकल'],
  2: ['कार', 'कार'],
  3: ['मोटरसाइकिल', 'मोटारसायकल'],
  5: ['बस', 'बस'],
  6: ['ट्रेन', 'ट्रेन'],
  7: ['ट्रक', 'ट्रक'],
  9: ['ट्रैफ़िक सिग्नल', 'ट्रॅफिक सिग्नल'],
  10: ['फ़ायर हाइड्रेंट', 'फायर हायड्रंट'],
  11: ['स्टॉप साइन', 'स्टॉप साइन'],
  13: ['बेंच', 'बेंच'],
  15: ['बिल्ली', 'मांजर'],
  16: ['कुत्ता', 'कुत्रा'],
  17: ['घोड़ा', 'घोडा'],
  19: ['गाय', 'गाय'],
  24: ['बैग', 'बॅग'],
  28: ['सूटकेस', 'सूटकेस'],
  56: ['कुर्सी', 'खुर्ची'],
  57: ['सोफ़ा', 'सोफा'],
  58: ['गमले का पौधा', 'कुंडीतील रोप'],
  59: ['बिस्तर', 'पलंग'],
  60: ['मेज़', 'टेबल'],
  61: ['शौचालय', 'शौचालय'],
  62: ['टीवी', 'टीव्ही'],
  71: ['सिंक', 'सिंक'],
  72: ['फ्रिज', 'फ्रिज'],
};

String exploreLabel(AppLang l, int cls) {
  final en =
      (cls >= 0 && cls < kCocoLabels.length) ? kCocoLabels[cls] : 'object';
  if (l == AppLang.en) return en;
  final loc = _loc[cls];
  return loc == null ? en : loc[l.index - 1];
}
