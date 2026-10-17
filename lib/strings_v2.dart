// /// Overrides / additions to strings.dart (looked up first).
// const s2 = <String, List<String>>{
//   'welcome': [
//     "Hello! I'm Kalpana, your voice companion. Before we begin, you need to sign up. It only takes a minute, and you can do all of it by speaking. I'll ask you questions, and you just answer.",
//     'नमस्ते! मैं कल्पना हूँ, आपकी आवाज़ की साथी। शुरू करने से पहले आपको साइन अप करना होगा। इसमें बस एक मिनट लगेगा, और आप सब कुछ बोलकर कर सकते हैं। मैं सवाल पूछूँगी, आप बस जवाब दीजिए।',
//     'नमस्कार! मी कल्पना, तुमची आवाजाची सोबती. सुरू करण्यापूर्वी तुम्हाला साइन अप करावे लागेल. यासाठी फक्त एक मिनिट लागेल, आणि तुम्ही सर्व काही बोलून करू शकता. मी प्रश्न विचारेन, तुम्ही फक्त उत्तर द्या.'
//   ],
//   'welcomeBack': [
//     'Welcome back, {name}. Say Hey Kalpana whenever you need me.',
//     'वापसी पर स्वागत है, {name}। जब भी ज़रूरत हो, बोलिए Hey Kalpana।',
//     'पुन्हा स्वागत, {name}. गरज असेल तेव्हा म्हणा Hey Kalpana.'
//   ],
//   'askLang': [
//     'Which language would you like me to speak: English, Hindi or Marathi?',
//     'आप मुझसे किस भाषा में बात करना चाहेंगे: अंग्रेज़ी, हिंदी या मराठी?',
//     'तुम्हाला मी कोणत्या भाषेत बोलावे: इंग्रजी, हिंदी की मराठी?'
//   ],
//   'askPerms': [
//     'I also need access to your camera and your location. Say allow to continue, or say skip.',
//     'मुझे आपके कैमरे और लोकेशन की अनुमति भी चाहिए। जारी रखने के लिए बोलिए अनुमति, या बोलिए छोड़ो।',
//     'मला तुमच्या कॅमेऱ्याची आणि स्थानाची परवानगी पण हवी आहे. पुढे जाण्यासाठी म्हणा परवानगी, किंवा म्हणा वगळा.'
//   ],
//   'permsLater': [
//     'Okay. You can allow the camera and location later by saying allow permissions.',
//     'ठीक है। आप बाद में अनुमति बोलकर कैमरा और लोकेशन की अनुमति दे सकते हैं।',
//     'ठीक आहे. तुम्ही नंतर परवानगी म्हणून कॅमेरा आणि स्थानाची परवानगी देऊ शकता.'
//   ],
//   'askName': ["What's your name?", 'आपका नाम क्या है?', 'तुमचे नाव काय आहे?'],
//   'askPhone': [
//     "What's your phone number? Say the digits slowly.",
//     'आपका फ़ोन नंबर क्या है? अंक धीरे-धीरे बोलिए।',
//     'तुमचा फोन नंबर काय आहे? अंक हळू हळू सांगा.'
//   ],
//   'askEmName': [
//     'Who is your emergency contact? Say their name and relation, or say skip.',
//     'आपका आपातकालीन संपर्क कौन है? उनका नाम और रिश्ता बोलिए, या बोलिए छोड़ो।',
//     'तुमचा आणीबाणी संपर्क कोण आहे? त्यांचे नाव आणि नाते सांगा, किंवा म्हणा वगळा.'
//   ],
//   'askEmPhone': [
//     "What's {name}'s phone number?",
//     '{name} का फ़ोन नंबर क्या है?',
//     '{name} यांचा फोन नंबर काय आहे?'
//   ],
//   'heardSure': [
//     'I heard {x}. Is that right? Say yes or no.',
//     'मैंने सुना {x}। क्या यह सही है? हाँ या नहीं बोलिए।',
//     'मी ऐकले {x}. बरोबर आहे का? हो किंवा नाही म्हणा.'
//   ],
//   'retry': ["Okay, let's try again.", 'ठीक है, फिर से कोशिश करते हैं।', 'ठीक आहे, पुन्हा प्रयत्न करूया.'],
//   'didntCatch': ["Sorry, I didn't catch that.", 'माफ़ कीजिए, मैं समझ नहीं पाई।', 'क्षमा करा, मला नीट ऐकू आले नाही.'],
//   'signupFail': ["I couldn't hear you clearly. You can type the details on the screen, then press Confirm."],
//   'signupDone': [
//     "You're all set, {name}. From now on, just say Hey Kalpana whenever you need me. Say help to hear what I can do.",
//     'सब तैयार है, {name}। जब भी ज़रूरत हो, बस बोलिए Hey Kalpana। मैं क्या कर सकती हूँ यह सुनने के लिए बोलिए मदद।',
//     'सर्व तयार आहे, {name}. गरज असेल तेव्हा फक्त म्हणा Hey Kalpana. मी काय करू शकते ऐकण्यासाठी म्हणा मदत.'
//   ],
//   'hiName': [
//     'Hi {name}, how can I help you?',
//     'नमस्ते {name}, मैं आपकी कैसे मदद कर सकती हूँ?',
//     'नमस्कार {name}, मी तुम्हाला कशी मदत करू?'
//   ],
//   'pausedMsg': [
//     "Okay, I've stopped listening. Say Hey Kalpana when you need me.",
//     'ठीक है, मैंने सुनना बंद कर दिया है। ज़रूरत हो तो बोलिए Hey Kalpana।',
//     'ठीक आहे, मी ऐकणे थांबवले आहे. गरज असेल तर म्हणा Hey Kalpana.'
//   ],
//   'micOffMsg': [
//     'The microphone is off. Press Mic on when you want me to hear you.',
//     'माइक्रोफ़ोन बंद है। जब चाहें मुझे सुनाने के लिए माइक ऑन दबाएँ।',
//     'मायक्रोफोन बंद आहे. मला ऐकवायचे असेल तेव्हा माइक ऑन दाबा.'
//   ],
//   'micOnMsg': ['Listening again. Say Hey Kalpana.', 'फिर से सुन रही हूँ। बोलिए Hey Kalpana।', 'पुन्हा ऐकत आहे. म्हणा Hey Kalpana.'],
//   'noReminders': [
//     'You have no reminders yet. You can say, remind me to take medicine at 2 PM.',
//     'आपके पास अभी कोई रिमाइंडर नहीं है। आप बोल सकते हैं, मुझे दोपहर 2 बजे दवा लेना याद दिलाओ।',
//     'तुमचे अजून कोणतेही रिमाइंडर नाहीत. तुम्ही म्हणू शकता, मला दुपारी 2 वाजता औषध घ्यायची आठवण करून द्या.'
//   ],
//   'remindersAre': ['You have {n} reminders. {list}', 'आपके {n} रिमाइंडर हैं। {list}', 'तुमचे {n} रिमाइंडर आहेत. {list}'],
//   'reminderSaved': ['Saved reminder: {x}.', 'रिमाइंडर सहेजा: {x}।', 'रिमाइंडर जतन केले: {x}.'],
//   'confirmClear': ['Delete all your reminders? Say yes or no.', 'क्या आपके सभी रिमाइंडर हटा दूँ? हाँ या नहीं बोलिए।', 'तुमचे सर्व रिमाइंडर हटवू का? हो किंवा नाही म्हणा.'],
//   'remindersCleared': ['All reminders deleted.', 'सभी रिमाइंडर हटा दिए गए।', 'सर्व रिमाइंडर हटवले.'],
//   'camReady': [
//     'Camera is ready. Point it at what you want, then say take picture, or press the button.',
//     'कैमरा तैयार है। जिसे देखना है उस पर कैमरा रखें, फिर बोलिए तस्वीर लो, या बटन दबाएँ।',
//     'कॅमेरा तयार आहे. ज्याकडे पाहायचे त्यावर कॅमेरा धरा, मग म्हणा फोटो घ्या, किंवा बटण दाबा.'
//   ],
//   'holdSteady': ['Hold steady.', 'स्थिर रहिए।', 'स्थिर राहा.'],
//   'analysing': ['Got it. Let me look at the picture.', 'ठीक है, तस्वीर देख रही हूँ।', 'ठीक आहे, फोटो पाहत आहे.'],
//   'camFail': ["The camera isn't available right now."],
//   'noKey': ["My AI service isn't set up yet. Please add the Gemini key in the config file."],
//   'aiKeyBad': ["My AI service didn't accept the key. Please check the Gemini key in the config file."],
//   'aiOffline': [
//     "I couldn't reach the internet, so I can't do that right now.",
//     'मैं इंटरनेट से जुड़ नहीं पाई, इसलिए अभी यह नहीं कर सकती।',
//     'मला इंटरनेटशी जोडता आले नाही, त्यामुळे आत्ता हे करता येत नाही.'
//   ],
//   'aiFail': ['Something went wrong while analysing. Please try again.', 'विश्लेषण में कुछ गड़बड़ हुई। कृपया फिर कोशिश करें।', 'विश्लेषणात काहीतरी चूक झाली. कृपया पुन्हा प्रयत्न करा.'],
//   'helpHint': [
//     'Here is what you can say. To open reminders, say: open my reminders. To save one, say: remind me to take medicine at 2 PM. To read text, say: read this text. To identify an object or medicine, say: what is this. To hear your surroundings, say: describe my surroundings. To find where you are, say: where am I. To call someone, say: call, then the name. For an emergency, say: emergency. To change language, say: change language to Hindi or Marathi. To make me stop listening, say: stop listening. To wake me again, say: Hey Kalpana.',
//     'आप ये बोल सकते हैं। रिमाइंडर खोलने के लिए बोलिए: मेरे रिमाइंडर खोलो। नया रिमाइंडर बनाने के लिए बोलिए: मुझे दो बजे दवा लेना याद दिलाओ। लिखा हुआ पढ़ने के लिए बोलिए: यह पढ़ो। किसी चीज़ या दवा को पहचानने के लिए बोलिए: यह क्या है। आसपास जानने के लिए बोलिए: मेरे आसपास क्या है। अपनी जगह जानने के लिए बोलिए: मैं कहाँ हूँ। कॉल करने के लिए बोलिए: कॉल, फिर नाम। आपातकाल में बोलिए: इमरजेंसी। भाषा बदलने के लिए बोलिए: भाषा मराठी करो। मुझे चुप कराने के लिए बोलिए: सुनना बंद करो। दोबारा बुलाने के लिए बोलिए: Hey Kalpana।',
//     'तुम्ही हे म्हणू शकता. रिमाइंडर उघडण्यासाठी म्हणा: माझे रिमाइंडर उघडा. नवीन रिमाइंडरसाठी म्हणा: मला दोन वाजता औषध घ्यायची आठवण करून द्या. मजकूर वाचण्यासाठी म्हणा: हे वाचा. वस्तू किंवा औषध ओळखण्यासाठी म्हणा: हे काय आहे. आजूबाजूचे जाणण्यासाठी म्हणा: माझ्या आजूबाजूला काय आहे. तुम्ही कुठे आहात हे जाणण्यासाठी म्हणा: मी कुठे आहे. कॉल करण्यासाठी म्हणा: कॉल करा, मग नाव. आणीबाणीत म्हणा: आणीबाणी. भाषा बदलण्यासाठी म्हणा: भाषा हिंदी करा. मला गप्प करण्यासाठी म्हणा: ऐकणे बंद करा. पुन्हा बोलावण्यासाठी म्हणा: Hey Kalpana.'
//   ],
//   'notUnderstood': [
//     "Sorry, I didn't understand “{x}”. You can say: open my reminders, read this text, or where am I.",
//     'माफ़ कीजिए, मैं “{x}” नहीं समझी। आप बोल सकते हैं: मेरे रिमाइंडर खोलो, यह पढ़ो, या मैं कहाँ हूँ।',
//     'क्षमा करा, मला “{x}” समजले नाही. तुम्ही म्हणू शकता: माझे रिमाइंडर उघडा, हे वाचा, किंवा मी कुठे आहे.'
//   ],
//   'textIs': ['The text says: {x}', 'लिखा है: {x}', 'मजकूर असा आहे: {x}'],
//   'noText': [
//     "I couldn't find readable text. Hold the camera closer, in good light, and try again.",
//     'मुझे पढ़ने लायक लिखावट नहीं मिली। कैमरा पास लाएँ, अच्छी रोशनी में फिर कोशिश करें।',
//     'वाचता येईल असा मजकूर सापडला नाही. कॅमेरा जवळ धरा, चांगल्या प्रकाशात पुन्हा प्रयत्न करा.'
//   ],
//   'seeLabels': ['I can see: {x}.', 'मुझे दिख रहा है: {x}।', 'मला दिसत आहे: {x}.'],
//   'seeNothing': ["I couldn't recognise anything clearly.", 'मैं कुछ साफ़ पहचान नहीं पाई।', 'मला काही स्पष्ट ओळखता आले नाही.'],
//   'exploreNote': [
//     "I can name objects, but I can't judge distances or whether the path is safe. Please use your cane or ask someone nearby.",
//     'मैं चीज़ों के नाम बता सकती हूँ, पर दूरी या रास्ता सुरक्षित है या नहीं यह नहीं बता सकती। कृपया छड़ी का उपयोग करें या किसी से पूछें।',
//     'मी वस्तूंची नावे सांगू शकते, पण अंतर किंवा रस्ता सुरक्षित आहे का हे सांगू शकत नाही. कृपया काठी वापरा किंवा कोणाला विचारा.'
//   ],
//   'colorIs': ['The main colour looks {x}.', 'मुख्य रंग {x} लग रहा है।', 'मुख्य रंग {x} दिसतो आहे.'],
// };

/// Overrides / additions to strings.dart (looked up first).
const s2 = <String, List<String>>{
  'welcome': [
    "Hello! I'm Kalpana, your voice companion. Before we begin, you need to sign up. It only takes a minute, and you can do all of it by speaking. I'll ask you questions, and you just answer.",
    'नमस्ते! मैं कल्पना हूँ, आपकी आवाज़ की साथी। शुरू करने से पहले आपको साइन अप करना होगा। इसमें बस एक मिनट लगेगा, और आप सब कुछ बोलकर कर सकते हैं। मैं सवाल पूछूँगी, आप बस जवाब दीजिए।',
    'नमस्कार! मी कल्पना, तुमची आवाजाची सोबती. सुरू करण्यापूर्वी तुम्हाला साइन अप करावे लागेल. यासाठी फक्त एक मिनिट लागेल, आणि तुम्ही सर्व काही बोलून करू शकता. मी प्रश्न विचारेन, तुम्ही फक्त उत्तर द्या.'
  ],
  'welcomeBack': [
    'Welcome back, {name}. Say Hey Kalpana whenever you need me.',
    'वापसी पर स्वागत है, {name}। जब भी ज़रूरत हो, बोलिए Hey Kalpana।',
    'पुन्हा स्वागत, {name}. गरज असेल तेव्हा म्हणा Hey Kalpana.'
  ],
  'askLang': [
    'Which language would you like me to speak: English, Hindi or Marathi?',
    'आप मुझसे किस भाषा में बात करना चाहेंगे: अंग्रेज़ी, हिंदी या मराठी?',
    'तुम्हाला मी कोणत्या भाषेत बोलावे: इंग्रजी, हिंदी की मराठी?'
  ],
  'askPerms': [
    'I also need access to your camera and your location. Say allow to continue, or say skip.',
    'मुझे आपके कैमरे और लोकेशन की अनुमति भी चाहिए। जारी रखने के लिए बोलिए अनुमति, या बोलिए छोड़ो।',
    'मला तुमच्या कॅमेऱ्याची आणि स्थानाची परवानगी पण हवी आहे. पुढे जाण्यासाठी म्हणा परवानगी, किंवा म्हणा वगळा.'
  ],
  'permsLater': [
    'Okay. You can allow the camera and location later by saying allow permissions.',
    'ठीक है। आप बाद में अनुमति बोलकर कैमरा और लोकेशन की अनुमति दे सकते हैं।',
    'ठीक आहे. तुम्ही नंतर परवानगी म्हणून कॅमेरा आणि स्थानाची परवानगी देऊ शकता.'
  ],
  'askName': ["What's your name?", 'आपका नाम क्या है?', 'तुमचे नाव काय आहे?'],
  'askPhone': [
    "What's your phone number? Say the digits slowly.",
    'आपका फ़ोन नंबर क्या है? अंक धीरे-धीरे बोलिए।',
    'तुमचा फोन नंबर काय आहे? अंक हळू हळू सांगा.'
  ],
  'askEmName': [
    'Who is your emergency contact? Say their name and relation, or say skip.',
    'आपका आपातकालीन संपर्क कौन है? उनका नाम और रिश्ता बोलिए, या बोलिए छोड़ो।',
    'तुमचा आणीबाणी संपर्क कोण आहे? त्यांचे नाव आणि नाते सांगा, किंवा म्हणा वगळा.'
  ],
  'askEmPhone': [
    "What's {name}'s phone number?",
    '{name} का फ़ोन नंबर क्या है?',
    '{name} यांचा फोन नंबर काय आहे?'
  ],
  'heardSure': [
    'I heard {x}. Is that right? Say yes or no.',
    'मैंने सुना {x}। क्या यह सही है? हाँ या नहीं बोलिए।',
    'मी ऐकले {x}. बरोबर आहे का? हो किंवा नाही म्हणा.'
  ],
  'retry': [
    "Okay, let's try again.",
    'ठीक है, फिर से कोशिश करते हैं।',
    'ठीक आहे, पुन्हा प्रयत्न करूया.'
  ],
  'didntCatch': [
    "Sorry, I didn't catch that.",
    'माफ़ कीजिए, मैं समझ नहीं पाई।',
    'क्षमा करा, मला नीट ऐकू आले नाही.'
  ],
  'signupFail': [
    "I couldn't hear you clearly. You can type the details on the screen, then press Confirm."
  ],
  'hiName': [
    'Hi {name}, how can I help you?',
    'नमस्ते {name}, मैं आपकी कैसे मदद कर सकती हूँ?',
    'नमस्कार {name}, मी तुम्हाला कशी मदत करू?'
  ],
  'pausedMsg': [
    "Okay, I've stopped listening. Say Hey Kalpana when you need me.",
    'ठीक है, मैंने सुनना बंद कर दिया है। ज़रूरत हो तो बोलिए Hey Kalpana।',
    'ठीक आहे, मी ऐकणे थांबवले आहे. गरज असेल तर म्हणा Hey Kalpana.'
  ],
  'micOffMsg': [
    'The microphone is off. Press Mic on when you want me to hear you.',
    'माइक्रोफ़ोन बंद है। जब चाहें मुझे सुनाने के लिए माइक ऑन दबाएँ।',
    'मायक्रोफोन बंद आहे. मला ऐकवायचे असेल तेव्हा माइक ऑन दाबा.'
  ],
  'micOnMsg': [
    'Listening again. Say Hey Kalpana.',
    'फिर से सुन रही हूँ। बोलिए Hey Kalpana।',
    'पुन्हा ऐकत आहे. म्हणा Hey Kalpana.'
  ],
  'noReminders': [
    'You have no reminders yet. You can say, remind me to take medicine at 2 PM.',
    'आपके पास अभी कोई रिमाइंडर नहीं है। आप बोल सकते हैं, मुझे दोपहर 2 बजे दवा लेना याद दिलाओ।',
    'तुमचे अजून कोणतेही रिमाइंडर नाहीत. तुम्ही म्हणू शकता, मला दुपारी 2 वाजता औषध घ्यायची आठवण करून द्या.'
  ],
  'remindersAre': [
    'You have {n} reminders. {list}',
    'आपके {n} रिमाइंडर हैं। {list}',
    'तुमचे {n} रिमाइंडर आहेत. {list}'
  ],
  'reminderSaved': [
    'Saved reminder: {x}.',
    'रिमाइंडर सहेजा: {x}।',
    'रिमाइंडर जतन केले: {x}.'
  ],
  'confirmClear': [
    'Delete all your reminders? Say yes or no.',
    'क्या आपके सभी रिमाइंडर हटा दूँ? हाँ या नहीं बोलिए।',
    'तुमचे सर्व रिमाइंडर हटवू का? हो किंवा नाही म्हणा.'
  ],
  'remindersCleared': [
    'All reminders deleted.',
    'सभी रिमाइंडर हटा दिए गए।',
    'सर्व रिमाइंडर हटवले.'
  ],
  'camReady': [
    'Camera is ready. Point it at what you want, then say take picture, or press the button.',
    'कैमरा तैयार है। जिसे देखना है उस पर कैमरा रखें, फिर बोलिए तस्वीर लो, या बटन दबाएँ।',
    'कॅमेरा तयार आहे. ज्याकडे पाहायचे त्यावर कॅमेरा धरा, मग म्हणा फोटो घ्या, किंवा बटण दाबा.'
  ],
  'holdSteady': ['Hold steady.', 'स्थिर रहिए।', 'स्थिर राहा.'],
  'analysing': [
    'Got it. Let me look at the picture.',
    'ठीक है, तस्वीर देख रही हूँ।',
    'ठीक आहे, फोटो पाहत आहे.'
  ],
  'camFail': ["The camera isn't available right now."],
  'noKey': [
    "My AI service isn't set up yet. Please add the Gemini key in the config file."
  ],
  'aiKeyBad': [
    "My AI service didn't accept the key. Please check the Gemini key in the config file."
  ],
  'aiOffline': [
    "I couldn't reach the internet, so I can't do that right now.",
    'मैं इंटरनेट से जुड़ नहीं पाई, इसलिए अभी यह नहीं कर सकती।',
    'मला इंटरनेटशी जोडता आले नाही, त्यामुळे आत्ता हे करता येत नाही.'
  ],
  'aiFail': [
    'Something went wrong while analysing. Please try again.',
    'विश्लेषण में कुछ गड़बड़ हुई। कृपया फिर कोशिश करें।',
    'विश्लेषणात काहीतरी चूक झाली. कृपया पुन्हा प्रयत्न करा.'
  ],
  'helpHint': [
    'Here is what you can say. To open reminders, say: open my reminders. To save one, say: remind me to take medicine at 2 PM. To read text, say: read this text. To identify an object or medicine, say: what is this. To hear your surroundings, say: describe my surroundings. To find where you are, say: where am I. To call someone, say: call, then the name. For an emergency, say: emergency. To change language, say: change language to Hindi or Marathi. To make me stop listening, say: stop listening. To wake me again, say: Hey Kalpana.',
    'आप ये बोल सकते हैं। रिमाइंडर खोलने के लिए बोलिए: मेरे रिमाइंडर खोलो। नया रिमाइंडर बनाने के लिए बोलिए: मुझे दो बजे दवा लेना याद दिलाओ। लिखा हुआ पढ़ने के लिए बोलिए: यह पढ़ो। किसी चीज़ या दवा को पहचानने के लिए बोलिए: यह क्या है। आसपास जानने के लिए बोलिए: मेरे आसपास क्या है। अपनी जगह जानने के लिए बोलिए: मैं कहाँ हूँ। कॉल करने के लिए बोलिए: कॉल, फिर नाम। आपातकाल में बोलिए: इमरजेंसी। भाषा बदलने के लिए बोलिए: भाषा मराठी करो। मुझे चुप कराने के लिए बोलिए: सुनना बंद करो। दोबारा बुलाने के लिए बोलिए: Hey Kalpana।',
    'तुम्ही हे म्हणू शकता. रिमाइंडर उघडण्यासाठी म्हणा: माझे रिमाइंडर उघडा. नवीन रिमाइंडरसाठी म्हणा: मला दोन वाजता औषध घ्यायची आठवण करून द्या. मजकूर वाचण्यासाठी म्हणा: हे वाचा. वस्तू किंवा औषध ओळखण्यासाठी म्हणा: हे काय आहे. आजूबाजूचे जाणण्यासाठी म्हणा: माझ्या आजूबाजूला काय आहे. तुम्ही कुठे आहात हे जाणण्यासाठी म्हणा: मी कुठे आहे. कॉल करण्यासाठी म्हणा: कॉल करा, मग नाव. आणीबाणीत म्हणा: आणीबाणी. भाषा बदलण्यासाठी म्हणा: भाषा हिंदी करा. मला गप्प करण्यासाठी म्हणा: ऐकणे बंद करा. पुन्हा बोलावण्यासाठी म्हणा: Hey Kalpana.'
  ],
  'notUnderstood': [
    "Sorry, I didn't understand “{x}”. You can say: open my reminders, read this text, or where am I.",
    'माफ़ कीजिए, मैं “{x}” नहीं समझी। आप बोल सकते हैं: मेरे रिमाइंडर खोलो, यह पढ़ो, या मैं कहाँ हूँ।',
    'क्षमा करा, मला “{x}” समजले नाही. तुम्ही म्हणू शकता: माझे रिमाइंडर उघडा, हे वाचा, किंवा मी कुठे आहे.'
  ],
  'textIs': ['The text says: {x}', 'लिखा है: {x}', 'मजकूर असा आहे: {x}'],
  'noText': [
    "I couldn't find readable text. Hold the camera closer, in good light, and try again.",
    'मुझे पढ़ने लायक लिखावट नहीं मिली। कैमरा पास लाएँ, अच्छी रोशनी में फिर कोशिश करें।',
    'वाचता येईल असा मजकूर सापडला नाही. कॅमेरा जवळ धरा, चांगल्या प्रकाशात पुन्हा प्रयत्न करा.'
  ],
  'seeLabels': [
    'I can see: {x}.',
    'मुझे दिख रहा है: {x}।',
    'मला दिसत आहे: {x}.'
  ],
  'seeNothing': [
    "I couldn't recognise anything clearly.",
    'मैं कुछ साफ़ पहचान नहीं पाई।',
    'मला काही स्पष्ट ओळखता आले नाही.'
  ],
  'exploreNote': [
    "I can name objects, but I can't judge distances or whether the path is safe. Please use your cane or ask someone nearby.",
    'मैं चीज़ों के नाम बता सकती हूँ, पर दूरी या रास्ता सुरक्षित है या नहीं यह नहीं बता सकती। कृपया छड़ी का उपयोग करें या किसी से पूछें।',
    'मी वस्तूंची नावे सांगू शकते, पण अंतर किंवा रस्ता सुरक्षित आहे का हे सांगू शकत नाही. कृपया काठी वापरा किंवा कोणाला विचारा.'
  ],
  'colorIs': [
    'The main colour looks {x}.',
    'मुख्य रंग {x} लग रहा है।',
    'मुख्य रंग {x} दिसतो आहे.'
  ],
  'signupDone': [
    "You're all set, {name}. Your details are saved. To talk to me, just say Hey Kalpana. To make me stop listening, say stop listening, or press the Mic off button. To stop me talking, say okay got it, or tap the top bar. Say help to hear everything I can do.",
    'सब तैयार है, {name}। आपकी जानकारी सेव हो गई है। मुझसे बात करने के लिए बस बोलिए Hey Kalpana। मुझे सुनना बंद कराने के लिए बोलिए सुनना बंद करो, या माइक ऑफ़ बटन दबाइए। मुझे बोलने से रोकने के लिए बोलिए ठीक है समझ गया, या ऊपर की पट्टी को छुएँ। मैं क्या-क्या कर सकती हूँ यह सुनने के लिए बोलिए मदद।',
    'सर्व तयार आहे, {name}. तुमची माहिती सेव्ह झाली आहे. माझ्याशी बोलण्यासाठी फक्त म्हणा Hey Kalpana. मला ऐकणे थांबवायला लावण्यासाठी म्हणा ऐकणे बंद करा, किंवा माइक ऑफ बटण दाबा. मला बोलणे थांबवण्यासाठी म्हणा समजले, किंवा वरच्या पट्टीला स्पर्श करा. मी काय करू शकते ऐकण्यासाठी म्हणा मदत.'
  ],
  'langAskAgain': [
    'Please say English, Hindi or Marathi.',
    'कृपया बोलिए अंग्रेज़ी, हिंदी या मराठी।',
    'कृपया म्हणा इंग्रजी, हिंदी किंवा मराठी.'
  ],
  'dialogHint': [
    'A box will appear on the screen asking: Allow Kalpana to {what}? Double tap the Allow button, or While using the app.',
    'स्क्रीन पर एक बॉक्स आएगा: क्या कल्पना को {what} की अनुमति दें? अनुमति दें बटन पर दो बार टैप करें।',
    'स्क्रीनवर एक बॉक्स येईल: कल्पनाला {what} परवानगी द्यायची का? परवानगी द्या बटणावर दोनदा टॅप करा.'
  ],
  'whatMic': ['record audio', 'ऑडियो रिकॉर्ड करने', 'ऑडिओ रेकॉर्ड करण्याची'],
  'whatContacts': [
    'access your contacts',
    'आपके संपर्क देखने',
    'तुमचे संपर्क पाहण्याची'
  ],
  'whatCamera': ['take pictures', 'तस्वीरें लेने', 'फोटो काढण्याची'],
  'whatLoc': [
    "access this device's location",
    'आपकी लोकेशन देखने',
    'तुमचे स्थान पाहण्याची'
  ],
  'askContactsPerm': [
    'Do you want to give Kalpana access to your contacts, so I can find your emergency contact by name? Say allow or deny.',
    'क्या आप कल्पना को अपने संपर्कों की अनुमति देंगे, ताकि मैं नाम से आपका आपातकालीन संपर्क ढूँढ सकूँ? बोलिए अनुमति या मना।',
    'तुम्ही कल्पनाला तुमच्या संपर्कांची परवानगी द्याल का, म्हणजे मी नावाने तुमचा आणीबाणी संपर्क शोधू शकेन? म्हणा परवानगी किंवा नकार.'
  ],
  'askCamPerm': [
    'Do you want to allow the camera? I use it to read text and name things for you. Say allow or deny.',
    'क्या कैमरे की अनुमति देंगे? मैं इससे लिखा हुआ पढ़ती हूँ और चीज़ों के नाम बताती हूँ। बोलिए अनुमति या मना।',
    'कॅमेऱ्याची परवानगी द्याल का? मी त्याने मजकूर वाचते आणि वस्तूंची नावे सांगते. म्हणा परवानगी किंवा नकार.'
  ],
  'askLocPerm': [
    'Do you want to allow your location? I use it to tell you where you are, and to share it in an emergency. Say allow or deny.',
    'क्या लोकेशन की अनुमति देंगे? मैं इससे बताती हूँ कि आप कहाँ हैं, और आपातकाल में इसे भेजती हूँ। बोलिए अनुमति या मना।',
    'स्थानाची परवानगी द्याल का? तुम्ही कुठे आहात हे सांगण्यासाठी आणि आणीबाणीत पाठवण्यासाठी मी ते वापरते. म्हणा परवानगी किंवा नकार.'
  ],
  'whyMic': [
    'The microphone is how you talk to me. Without it you can only use the buttons on screen.',
    'माइक्रोफ़ोन से ही आप मुझसे बात करते हैं। इसके बिना आप सिर्फ़ स्क्रीन के बटन इस्तेमाल कर पाएँगे।',
    'मायक्रोफोनमुळेच तुम्ही माझ्याशी बोलू शकता. त्याशिवाय तुम्हाला फक्त स्क्रीनवरील बटणे वापरता येतील.'
  ],
  'whyContacts': [
    'Contacts access lets me find your emergency contact by name, so I can call them quickly when you need help. Without it you would have to type the number yourself.',
    'संपर्कों की अनुमति से मैं नाम से आपका आपातकालीन संपर्क ढूँढ पाती हूँ, ताकि मदद की ज़रूरत पर जल्दी कॉल हो सके। इसके बिना आपको नंबर खुद टाइप करना होगा।',
    'संपर्कांच्या परवानगीमुळे मी नावाने तुमचा आणीबाणी संपर्क शोधू शकते, म्हणजे मदत हवी असताना लवकर कॉल करता येईल. त्याशिवाय तुम्हाला नंबर स्वतः टाइप करावा लागेल.'
  ],
  'whyCamera': [
    "The camera lets me read text and name things in front of you. Without it, those features won't work.",
    'कैमरे से मैं लिखा हुआ पढ़ती हूँ और आपके सामने की चीज़ों के नाम बताती हूँ। इसके बिना ये सुविधाएँ नहीं चलेंगी।',
    'कॅमेऱ्यामुळे मी मजकूर वाचते आणि तुमच्या समोरच्या वस्तूंची नावे सांगते. त्याशिवाय ही सुविधा चालणार नाही.'
  ],
  'whyLoc': [
    "Location lets me tell you where you are and share it in an emergency. Without it, those features won't work.",
    'लोकेशन से मैं बताती हूँ कि आप कहाँ हैं और आपातकाल में उसे भेज सकती हूँ। इसके बिना ये सुविधाएँ नहीं चलेंगी।',
    'स्थानामुळे मी तुम्ही कुठे आहात ते सांगते आणि आणीबाणीत पाठवू शकते. त्याशिवाय ही सुविधा चालणार नाही.'
  ],
  'micFallback': [
    "I'll continue without voice input. Please fill in the form on the screen, then press Confirm and Open Kalpana.",
    'मैं बिना आवाज़ के आगे बढ़ती हूँ। कृपया स्क्रीन पर फ़ॉर्म भरें, फिर Confirm and Open Kalpana दबाएँ।',
    'मी आवाजाशिवाय पुढे जाते. कृपया स्क्रीनवरील फॉर्म भरा, मग Confirm and Open Kalpana दाबा.'
  ],
  'digitsPrompt': [
    "What's your phone number? Say it in parts if you like, and I'll repeat each part back.",
    'आपका फ़ोन नंबर क्या है? चाहें तो हिस्सों में बोलिए, मैं हर हिस्सा दोहराऊँगी।',
    'तुमचा फोन नंबर काय आहे? हवे तर भागांमध्ये सांगा, मी प्रत्येक भाग पुन्हा सांगेन.'
  ],
  'digitUnclear': [
    "I wasn't sure about “{x}”. Please say those digits again, one by one.",
    'मुझे “{x}” साफ़ समझ नहीं आया। कृपया वे अंक एक-एक करके फिर बोलिए।',
    '“{x}” नीट समजले नाही. कृपया ते अंक एक-एक करून पुन्हा सांगा.'
  ],
  'digitsNone': [
    "I didn't catch any digits. Please say them again.",
    'मुझे कोई अंक सुनाई नहीं दिया। कृपया फिर बोलिए।',
    'मला कोणतेही अंक ऐकू आले नाहीत. कृपया पुन्हा सांगा.'
  ],
  'phoneConfirm': [
    'I have {x}. Is that correct? Say yes, or no to fix it.',
    'मेरे पास है {x}। क्या यह सही है? सही हो तो हाँ, बदलना हो तो नहीं बोलिए।',
    'माझ्याकडे आहे {x}. बरोबर आहे का? बरोबर असल्यास हो, बदलायचे असल्यास नाही म्हणा.'
  ],
  'phoneFix': [
    'Okay. Say start over, or say delete last to remove the last part. Then carry on.',
    'ठीक है। फिर से शुरू के लिए बोलिए फिर से शुरू, या आख़िरी हिस्सा हटाने के लिए बोलिए आख़िरी हटाओ। फिर आगे बोलिए।',
    'ठीक आहे. पुन्हा सुरू करण्यासाठी म्हणा पुन्हा सुरू, किंवा शेवटचा भाग काढण्यासाठी म्हणा शेवटचा काढा. मग पुढे सांगा.'
  ],
  'phoneShort': [
    'I have only {n} digits so far. Please continue.',
    'अभी तक सिर्फ़ {n} अंक हैं। कृपया आगे बोलिए।',
    'अजून फक्त {n} अंक आहेत. कृपया पुढे सांगा.'
  ],
  'phoneLong': [
    "That's {n} digits, which is too many. Say delete last, or start over.",
    'यह {n} अंक हैं, जो ज़्यादा हैं। आख़िरी हटाओ या फिर से शुरू बोलिए।',
    'हे {n} अंक आहेत, जे जास्त आहेत. शेवटचा काढा किंवा पुन्हा सुरू म्हणा.'
  ],
  'removed': ['Removed {x}.', 'हटाया: {x}।', 'काढले: {x}.'],
  'startedOver': [
    'Okay, starting over.',
    'ठीक है, फिर से शुरू करते हैं।',
    'ठीक आहे, पुन्हा सुरू करूया.'
  ],
  'phoneSoFar': [
    'So far I have {x}.',
    'अब तक मेरे पास है {x}।',
    'आतापर्यंत माझ्याकडे आहे {x}.'
  ],
  'emPick': [
    'Say the name of your emergency contact, as it is saved in your phone. Or say skip.',
    'अपने आपातकालीन संपर्क का नाम बोलिए, जैसा आपके फ़ोन में सेव है। या बोलिए छोड़ो।',
    'तुमच्या आणीबाणी संपर्काचे नाव सांगा, जसे फोनमध्ये सेव्ह आहे. किंवा म्हणा वगळा.'
  ],
  'emNone': [
    "I couldn't find a contact named {x}. Please say the name again, or say skip.",
    'मुझे {x} नाम का संपर्क नहीं मिला। कृपया नाम फिर बोलिए, या बोलिए छोड़ो।',
    '{x} नावाचा संपर्क सापडला नाही. कृपया नाव पुन्हा सांगा, किंवा म्हणा वगळा.'
  ],
  'emOne': [
    'I found {name}, number {num}. Is that your emergency contact? Say yes or no.',
    'मुझे {name} मिला, नंबर {num}। क्या यही आपका आपातकालीन संपर्क है? हाँ या नहीं बोलिए।',
    'मला {name} सापडले, नंबर {num}. हाच तुमचा आणीबाणी संपर्क आहे का? हो किंवा नाही म्हणा.'
  ],
  'emMany': [
    'I found {n} contacts: {list}. Say the number of the one you want, or say none.',
    'मुझे {n} संपर्क मिले: {list}। जिसे चुनना है उसका नंबर बोलिए, या बोलिए कोई नहीं।',
    'मला {n} संपर्क सापडले: {list}. हवा तो क्रमांक सांगा, किंवा म्हणा एकही नाही.'
  ],
  'emManualName': [
    "Okay, let's do it by hand. What is your emergency contact's name?",
    'ठीक है, हाथ से करते हैं। आपके आपातकालीन संपर्क का नाम क्या है?',
    'ठीक आहे, हाताने करूया. तुमच्या आणीबाणी संपर्काचे नाव काय आहे?'
  ],
  'emManualPhone': [
    "What is {name}'s phone number? Say it in parts if you like.",
    '{name} का फ़ोन नंबर क्या है? चाहें तो हिस्सों में बोलिए।',
    '{name} यांचा फोन नंबर काय आहे? हवे तर भागांमध्ये सांगा.'
  ],
  'noEmSaved': [
    'none saved, I will use the national helpline, 112',
    'कोई सहेजा नहीं, मैं राष्ट्रीय हेल्पलाइन 112 इस्तेमाल करूँगी',
    'कोणताही जतन केलेला नाही, मी राष्ट्रीय हेल्पलाइन 112 वापरेन'
  ],
  'profileSummary': [
    'Here is your profile. Name: {name}. Phone: {phone}. Emergency contact: {contact}. Language: {lang}.',
    'आपकी प्रोफ़ाइल। नाम: {name}। फ़ोन: {phone}। आपातकालीन संपर्क: {contact}। भाषा: {lang}।',
    'तुमची प्रोफाइल. नाव: {name}. फोन: {phone}. आणीबाणी संपर्क: {contact}. भाषा: {lang}.'
  ],
  'proceedAsk': [
    'Shall I save this and continue? Say yes, or say change name, change phone, or change contact.',
    'क्या मैं इसे सेव करके आगे बढ़ूँ? हाँ बोलिए, या बोलिए नाम बदलो, फ़ोन बदलो, या संपर्क बदलो।',
    'मी हे सेव्ह करून पुढे जाऊ का? हो म्हणा, किंवा म्हणा नाव बदला, फोन बदला, किंवा संपर्क बदला.'
  ],
  'changeWhat': [
    'Which one would you like to change: name, phone or contact?',
    'आप कौन सा बदलना चाहेंगे: नाम, फ़ोन या संपर्क?',
    'तुम्हाला कोणते बदलायचे आहे: नाव, फोन की संपर्क?'
  ],
  'manualMsg': [
    'Okay. Please type the details on the screen, then press Confirm and Open Kalpana.',
    'ठीक है। कृपया स्क्रीन पर जानकारी टाइप करें, फिर Confirm and Open Kalpana दबाएँ।',
    'ठीक आहे. कृपया स्क्रीनवर माहिती टाइप करा, मग Confirm and Open Kalpana दाबा.'
  ],
};
