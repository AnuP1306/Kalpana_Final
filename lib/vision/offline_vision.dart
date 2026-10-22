// import 'dart:typed_data';
// import 'dart:ui' as ui;
// import 'package:flutter/painting.dart';
// import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// import '../strings.dart';

// /// Everything here runs ON THE PHONE (Google ML Kit + pixel maths): no internet, no quota.
// class OfflineVision {
//   /// OCR for English, Hindi and Marathi print (Latin + Devanagari models).
//   Future<String> readText(String path) async {
//     final input = InputImage.fromFilePath(path);
//     final out = <String, String>{};
//     final scripts = TextRecognitionScript.values.where((s) => const ['latin', 'devanagiri', 'devanagari'].contains(s.name));
//     for (final script in scripts) {
//       final rec = TextRecognizer(script: script);
//       try {
//         final r = await rec.processImage(input);
//         out[script.name] = r.text.replaceAll(RegExp(r'\s+'), ' ').trim();
//       } catch (_) {
//       } finally {
//         await rec.close();
//       }
//     }
//     final dev = out.entries.where((e) => e.key.startsWith('dev')).map((e) => e.value).join(' ');
//     final lat = out['latin'] ?? '';
//     final devChars = RegExp(r'[\u0900-\u097F]').allMatches(dev).length;
//     final best = devChars >= 3 ? dev : (lat.length >= dev.length ? lat : dev);
//     return best.length > 700 ? best.substring(0, 700) : best;
//   }

//   /// Object names (on-device image labelling). Names only: no distances.
//   Future<List<String>> labels(String path, AppLang lang) async {
//     final labeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.6));
//     try {
//       final ls = await labeler.processImage(InputImage.fromFilePath(path));
//       ls.sort((a, b) => b.confidence.compareTo(a.confidence));
//       return ls.take(5).map((l) => _tr(l.label, lang)).toList();
//     } catch (_) {
//       return [];
//     } finally {
//       await labeler.close();
//     }
//   }

//   /// Dominant colour of the centre of the photo, named in the chosen language.
//   Future<String> colorName(Uint8List bytes, AppLang lang) async {
//     final codec = await ui.instantiateImageCodec(bytes, targetWidth: 80);
//     final img = (await codec.getNextFrame()).image;
//     final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
//     if (bd == null) return _colors['gray']![lang.index];
//     final w = img.width, h = img.height;
//     double r = 0, g = 0, b = 0;
//     var n = 0;
//     for (var y = (h * .3).toInt(); y < (h * .7).toInt(); y++) {
//       for (var x = (w * .3).toInt(); x < (w * .7).toInt(); x++) {
//         final i = (y * w + x) * 4;
//         r += bd.getUint8(i);
//         g += bd.getUint8(i + 1);
//         b += bd.getUint8(i + 2);
//         n++;
//       }
//     }
//     if (n == 0) n = 1;
//     final hsv = HSVColor.fromColor(ui.Color.fromARGB(255, (r / n).round(), (g / n).round(), (b / n).round()));
//     final v = hsv.value, s = hsv.saturation, hue = hsv.hue;
//     String key;
//     if (v < 0.18) {
//       key = 'black';
//     } else if (s < 0.12) {
//       key = v > 0.85 ? 'white' : 'gray';
//     } else if (hue < 15 || hue >= 345) {
//       key = 'red';
//     } else if (hue < 40) {
//       key = v < 0.6 ? 'brown' : 'orange';
//     } else if (hue < 65) {
//       key = 'yellow';
//     } else if (hue < 165) {
//       key = 'green';
//     } else if (hue < 200) {
//       key = 'turquoise';
//     } else if (hue < 255) {
//       key = 'blue';
//     } else if (hue < 290) {
//       key = 'purple';
//     } else {
//       key = 'pink';
//     }
//     final name = _colors[key]![lang.index];
//     if (key == 'black' || key == 'white' || key == 'gray') return name;
//     if (v < 0.4) return '${_shade[0][lang.index]} $name';
//     if (v > 0.85 && s < 0.5) return '${_shade[1][lang.index]} $name';
//     return name;
//   }

//   static const _shade = [
//     ['dark', 'गहरा', 'गडद'],
//     ['light', 'हल्का', 'फिकट'],
//   ];
//   static const _colors = <String, List<String>>{
//     'black': ['black', 'काला', 'काळा'],
//     'white': ['white', 'सफ़ेद', 'पांढरा'],
//     'gray': ['gray', 'स्लेटी', 'राखाडी'],
//     'red': ['red', 'लाल', 'लाल'],
//     'orange': ['orange', 'नारंगी', 'नारंगी'],
//     'yellow': ['yellow', 'पीला', 'पिवळा'],
//     'green': ['green', 'हरा', 'हिरवा'],
//     'turquoise': ['turquoise', 'फ़िरोज़ी', 'पिरोजी'],
//     'blue': ['blue', 'नीला', 'निळा'],
//     'purple': ['purple', 'बैंगनी', 'जांभळा'],
//     'pink': ['pink', 'गुलाबी', 'गुलाबी'],
//     'brown': ['brown', 'भूरा', 'तपकिरी'],
//   };

//   static const _obj = <String, List<String>>{
//     'bottle': ['बोतल', 'बाटली'], 'cup': ['कप', 'कप'], 'table': ['मेज़', 'टेबल'], 'chair': ['कुर्सी', 'खुर्ची'],
//     'book': ['किताब', 'पुस्तक'], 'mobile phone': ['मोबाइल फ़ोन', 'मोबाइल फोन'], 'food': ['खाना', 'अन्न'],
//     'plant': ['पौधा', 'रोप'], 'person': ['व्यक्ति', 'व्यक्ती'], 'door': ['दरवाज़ा', 'दरवाजा'], 'window': ['खिड़की', 'खिडकी'],
//     'car': ['गाड़ी', 'गाडी'], 'bag': ['बैग', 'बॅग'], 'shoe': ['जूता', 'बूट'], 'clothing': ['कपड़े', 'कपडे'],
//     'laptop': ['लैपटॉप', 'लॅपटॉप'], 'fruit': ['फल', 'फळ'], 'vegetable': ['सब्ज़ी', 'भाजी'], 'cat': ['बिल्ली', 'मांजर'],
//     'dog': ['कुत्ता', 'कुत्रा'], 'flower': ['फूल', 'फूल'], 'furniture': ['फ़र्नीचर', 'फर्निचर'], 'building': ['इमारत', 'इमारत'],
//     'tree': ['पेड़', 'झाड'], 'floor': ['फ़र्श', 'फरशी'], 'wall': ['दीवार', 'भिंत'], 'stairs': ['सीढ़ियाँ', 'पायऱ्या'],
//     'glasses': ['चश्मा', 'चष्मा'], 'watch': ['घड़ी', 'घड्याळ'], 'bicycle': ['साइकिल', 'सायकल'], 'paper': ['काग़ज़', 'कागद'],
//   };

//   String _tr(String label, AppLang lang) {
//     if (lang == AppLang.en) return label;
//     return _obj[label.toLowerCase()]?[lang.index - 1] ?? label;
//   }
// }

// import 'dart:typed_data';
// import 'dart:io';
// import 'dart:ui' as ui;
// import 'package:flutter/painting.dart';
// import 'package:flutter/foundation.dart';
// import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// import '../strings.dart';

// /// Everything here runs ON THE PHONE (Google ML Kit + pixel maths): no internet, no quota.
// class OfflineVision {
//   /// OCR for English, Hindi and Marathi print (Latin + Devanagari models).
//   // Future<String> readText(String path) async {
//   //   // Validate the captured file before passing it to the native ML Kit plugin.
//   //   final file = File(path);
//   //   if (!await file.exists()) {
//   //     throw StateError('Captured image does not exist: $path');
//   //   }
//   //   if (await file.length() == 0) {
//   //     throw StateError('Captured image is empty: $path');
//   //   }

//   //   final input = InputImage.fromFilePath(path);
//   //   final results = <String, String>{};
//   //   Object? lastFailure;
//   //   var recognizersAttempted = 0;
//   //   var recognizersSucceeded = 0;

//   //   // Run the on-device Latin and Devanagari recognizers independently.
//   //   // A failure in one script must not prevent the other from reading text.
//   //   for (final script in TextRecognitionScript.values.where(
//   //     (s) => const ['latin', 'devanagiri', 'devanagari'].contains(s.name),
//   //   )) {
//   //     final recognizer = TextRecognizer(script: script);
//   //     recognizersAttempted++;
//   //     try {
//   //       final result = await recognizer.processImage(input);
//   //       recognizersSucceeded++;
//   //       results[script.name] =
//   //           result.text.replaceAll(RegExp(r'\s+'), ' ').trim();
//   //     } catch (error, stackTrace) {
//   //       lastFailure = error;
//   //       // Keep the error visible in logcat for diagnosis; don't hide all failures.
//   //       debugPrint(
//   //           'Kalpana OCR failed for ${script.name}: $error\n$stackTrace');
//   //     } finally {
//   //       try {
//   //         await recognizer.close();
//   //       } catch (error) {
//   //         debugPrint('Kalpana OCR recognizer cleanup failed: $error');
//   //       }
//   //     }
//   //   }

//   //   if (recognizersAttempted == 0 || recognizersSucceeded == 0) {
//   //     throw StateError('All on-device OCR recognizers failed: $lastFailure');
//   //   }

//   //   final devanagari = results.entries
//   //       .where((entry) => entry.key.startsWith('dev'))
//   //       .map((entry) => entry.value)
//   //       .where((value) => value.isNotEmpty)
//   //       .join(' ');
//   //   final latin = results['latin'] ?? '';
//   //   final devanagariChars =
//   //       RegExp(r'[\u0900-\u097F]').allMatches(devanagari).length;
//   //   final best = devanagariChars >= 3
//   //       ? devanagari
//   //       : (latin.length >= devanagari.length ? latin : devanagari);

//   //   // Empty means OCR completed successfully but no readable text was found.
//   //   return best.length > 700 ? best.substring(0, 700) : best;
//   // }

//   Future<String> readText(String path) async {
//     final file = File(path);
//     if (!await file.exists() || await file.length() == 0) {
//       throw StateError('Captured image is missing or empty.');
//     }

//     final input = InputImage.fromFilePath(path);
//     final candidates = <_OcrCandidate>[];
//     Object? lastError;
//     var succeeded = 0;

//     for (final script in [
//       TextRecognitionScript.latin,
//       TextRecognitionScript.devanagiri,
//     ]) {
//       final recognizer = TextRecognizer(script: script);

//       try {
//         final result = await recognizer.processImage(input);
//         succeeded++;

//         for (final block in result.blocks) {
//           for (final line in block.lines) {
//             final text = line.text.trim();
//             if (text.isEmpty) continue;

//             candidates.add(
//               _OcrCandidate(
//                 text: text,
//                 height: line.boundingBox.height.toDouble(),
//                 script: script,
//               ),
//             );
//           }
//         }
//       } catch (e, st) {
//         lastError = e;
//         debugPrint('OCR ${script.name} failed: $e\n$st');
//       } finally {
//         await recognizer.close();
//       }
//     }

//     if (succeeded == 0) {
//       throw StateError('All OCR recognizers failed: $lastError');
//     }

//     if (candidates.isEmpty) return '';

//     // Prefer coherent sentences, not a concatenation of every OCR fragment.
//     candidates.sort((a, b) => _scoreCandidate(b).compareTo(_scoreCandidate(a)));

//     final best = candidates.first;
//     final cleaned = _bestReadableSpan(best.text);

//     if (cleaned.isEmpty || _scoreText(cleaned) < 1.5) {
//       return '';
//     }

//     debugPrint(
//       'Kalpana OCR selected: "$cleaned" '
//       '(line height: ${best.height}, script: ${best.script.name})',
//     );

//     return cleaned.length > 700 ? cleaned.substring(0, 700) : cleaned;
//   }

//   double _scoreCandidate(_OcrCandidate candidate) {
//     final textScore = _scoreText(candidate.text);

//     // Larger text is a useful signal, but never the only signal.
//     return textScore + (candidate.height.clamp(0, 100) / 100);
//   }

//   double _scoreText(String text) {
//     final words = text
//         .toLowerCase()
//         .split(RegExp(r'\s+'))
//         .where((w) => w.isNotEmpty)
//         .toList();

//     if (words.isEmpty) return 0;

//     final letters = RegExp(r'[a-zA-Z\u0900-\u097F]');
//     final singleLetters = words
//         .where(
//           (w) =>
//               w.replaceAll(RegExp(r'[^a-zA-Z\u0900-\u097F]'), '').length <= 1,
//         )
//         .length;

//     final keyboardLabels = words
//         .where(
//           (w) => RegExp(r'^(f([1-9]|1[0-2])|esc|ctrl|alt|shift|tab|enter|com)$')
//               .hasMatch(w.replaceAll(RegExp(r'[^a-z0-9]'), '')),
//         )
//         .length;

//     final digitHeavy = words
//         .where(
//           (w) => RegExp(r'\d').hasMatch(w),
//         )
//         .length;

//     final alphabeticCount = letters.allMatches(text).length;

//     var score = words.length.toDouble();
//     score += alphabeticCount / text.length.clamp(1, 10000) * 2;
//     score -= singleLetters * 1.2;
//     score -= keyboardLabels * 2.0;
//     score -= digitHeavy * 0.8;

//     // Reward sentence-like language without requiring punctuation.
//     final commonWords = {
//       'the',
//       'is',
//       'are',
//       'was',
//       'were',
//       'and',
//       'this',
//       'that',
//       'it',
//       'you',
//       'your',
//       'in',
//       'on',
//       'of',
//       'to',
//       'a',
//       'an',
//       'i',
//       'we',
//       'he',
//       'she',
//       'they',
//       'cute',
//       'read',
//       'text',
//       'है',
//       'और',
//       'यह',
//       'वह',
//       'मेरा',
//       'मुझे',
//       'आहे',
//       'आणि',
//       'हे',
//       'मला',
//       'तुम्ही',
//     };

//     score += words.where((w) => commonWords.contains(w)).length * 1.5;

//     if (text.length < 3) score -= 4;
//     return score;
//   }

//   String _bestReadableSpan(String line) {
//     final words = line
//         .replaceAll(RegExp(r'[|{}<>]'), ' ')
//         .split(RegExp(r'\s+'))
//         .where((w) => w.isNotEmpty)
//         .toList();

//     if (words.length <= 3) return line.trim();

//     // Test contiguous phrases so a good sentence can survive beside OCR noise.
//     String best = line.trim();
//     var bestScore = _scoreText(best);

//     for (var start = 0; start < words.length; start++) {
//       for (var length = 3;
//           length <= 10 && start + length <= words.length;
//           length++) {
//         final phrase = words.sublist(start, start + length).join(' ');
//         final score = _scoreText(phrase);

//         if (score > bestScore) {
//           bestScore = score;
//           best = phrase;
//         }
//       }
//     }

//     return best.trim();
//   }

//   /// Object names (on-device image labelling). Names only: no distances.
//   Future<List<String>> labels(String path, AppLang lang) async {
//     final labeler =
//         ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.6));
//     try {
//       final ls = await labeler.processImage(InputImage.fromFilePath(path));
//       ls.sort((a, b) => b.confidence.compareTo(a.confidence));
//       return ls.take(5).map((l) => _tr(l.label, lang)).toList();
//     } catch (_) {
//       return [];
//     } finally {
//       await labeler.close();
//     }
//   }

//   /// Dominant colour of the centre of the photo, named in the chosen language.
//   Future<String> colorName(Uint8List bytes, AppLang lang) async {
//     final codec = await ui.instantiateImageCodec(bytes, targetWidth: 80);
//     final img = (await codec.getNextFrame()).image;
//     final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
//     if (bd == null) return _colors['gray']![lang.index];
//     final w = img.width, h = img.height;
//     double r = 0, g = 0, b = 0;
//     var n = 0;
//     for (var y = (h * .3).toInt(); y < (h * .7).toInt(); y++) {
//       for (var x = (w * .3).toInt(); x < (w * .7).toInt(); x++) {
//         final i = (y * w + x) * 4;
//         r += bd.getUint8(i);
//         g += bd.getUint8(i + 1);
//         b += bd.getUint8(i + 2);
//         n++;
//       }
//     }
//     if (n == 0) n = 1;
//     final hsv = HSVColor.fromColor(ui.Color.fromARGB(
//         255, (r / n).round(), (g / n).round(), (b / n).round()));
//     final v = hsv.value, s = hsv.saturation, hue = hsv.hue;
//     String key;
//     if (v < 0.18) {
//       key = 'black';
//     } else if (s < 0.12) {
//       key = v > 0.85 ? 'white' : 'gray';
//     } else if (hue < 15 || hue >= 345) {
//       key = 'red';
//     } else if (hue < 40) {
//       key = v < 0.6 ? 'brown' : 'orange';
//     } else if (hue < 65) {
//       key = 'yellow';
//     } else if (hue < 165) {
//       key = 'green';
//     } else if (hue < 200) {
//       key = 'turquoise';
//     } else if (hue < 255) {
//       key = 'blue';
//     } else if (hue < 290) {
//       key = 'purple';
//     } else {
//       key = 'pink';
//     }
//     final name = _colors[key]![lang.index];
//     if (key == 'black' || key == 'white' || key == 'gray') return name;
//     if (v < 0.4) return '${_shade[0][lang.index]} $name';
//     if (v > 0.85 && s < 0.5) return '${_shade[1][lang.index]} $name';
//     return name;
//   }

//   static const _shade = [
//     ['dark', 'गहरा', 'गडद'],
//     ['light', 'हल्का', 'फिकट'],
//   ];
//   static const _colors = <String, List<String>>{
//     'black': ['black', 'काला', 'काळा'],
//     'white': ['white', 'सफ़ेद', 'पांढरा'],
//     'gray': ['gray', 'स्लेटी', 'राखाडी'],
//     'red': ['red', 'लाल', 'लाल'],
//     'orange': ['orange', 'नारंगी', 'नारंगी'],
//     'yellow': ['yellow', 'पीला', 'पिवळा'],
//     'green': ['green', 'हरा', 'हिरवा'],
//     'turquoise': ['turquoise', 'फ़िरोज़ी', 'पिरोजी'],
//     'blue': ['blue', 'नीला', 'निळा'],
//     'purple': ['purple', 'बैंगनी', 'जांभळा'],
//     'pink': ['pink', 'गुलाबी', 'गुलाबी'],
//     'brown': ['brown', 'भूरा', 'तपकिरी'],
//   };

//   static const _obj = <String, List<String>>{
//     'bottle': ['बोतल', 'बाटली'],
//     'cup': ['कप', 'कप'],
//     'table': ['मेज़', 'टेबल'],
//     'chair': ['कुर्सी', 'खुर्ची'],
//     'book': ['किताब', 'पुस्तक'],
//     'mobile phone': ['मोबाइल फ़ोन', 'मोबाइल फोन'],
//     'food': ['खाना', 'अन्न'],
//     'plant': ['पौधा', 'रोप'],
//     'person': ['व्यक्ति', 'व्यक्ती'],
//     'door': ['दरवाज़ा', 'दरवाजा'],
//     'window': ['खिड़की', 'खिडकी'],
//     'car': ['गाड़ी', 'गाडी'],
//     'bag': ['बैग', 'बॅग'],
//     'shoe': ['जूता', 'बूट'],
//     'clothing': ['कपड़े', 'कपडे'],
//     'laptop': ['लैपटॉप', 'लॅपटॉप'],
//     'fruit': ['फल', 'फळ'],
//     'vegetable': ['सब्ज़ी', 'भाजी'],
//     'cat': ['बिल्ली', 'मांजर'],
//     'dog': ['कुत्ता', 'कुत्रा'],
//     'flower': ['फूल', 'फूल'],
//     'furniture': ['फ़र्नीचर', 'फर्निचर'],
//     'building': ['इमारत', 'इमारत'],
//     'tree': ['पेड़', 'झाड'],
//     'floor': ['फ़र्श', 'फरशी'],
//     'wall': ['दीवार', 'भिंत'],
//     'stairs': ['सीढ़ियाँ', 'पायऱ्या'],
//     'glasses': ['चश्मा', 'चष्मा'],
//     'watch': ['घड़ी', 'घड्याळ'],
//     'bicycle': ['साइकिल', 'सायकल'],
//     'paper': ['काग़ज़', 'कागद'],
//   };

//   String _tr(String label, AppLang lang) {
//     if (lang == AppLang.en) return label;
//     return _obj[label.toLowerCase()]?[lang.index - 1] ?? label;
//   }
// }

// class _OcrCandidate {
//   final String text;
//   final double height;
//   final TextRecognitionScript script;

//   const _OcrCandidate({
//     required this.text,
//     required this.height,
//     required this.script,
//   });
// }

import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../strings.dart';

class _OcrLine {
  final String text;
  final double top;
  final double left;
  const _OcrLine(this.text, this.top, this.left);
}

/// Everything here runs ON THE PHONE (Google ML Kit + pixel maths): no internet, no quota.
class OfflineVision {
  /// OCR for English, Hindi and Marathi print (Latin + Devanagari models).
  Future<String> readText(String path, [AppLang? language]) async {
    final file = File(path);
    if (!await file.exists() || await file.length() == 0) {
      throw StateError('Captured image is missing or empty: $path');
    }

    final input = InputImage.fromFilePath(path);
    final outputs = <TextRecognitionScript, String>{};
    Object? lastFailure;

    // Keep each script's result separate. Combining Latin and Devanagari output
    // duplicates words and can turn one good paragraph into OCR noise.
    for (final script in <TextRecognitionScript>[
      TextRecognitionScript.latin,
      TextRecognitionScript.devanagiri,
    ]) {
      final recognizer = TextRecognizer(script: script);
      try {
        final result = await recognizer.processImage(input);
        final lines = <_OcrLine>[];
        for (final block in result.blocks) {
          for (final line in block.lines) {
            final text = line.text.trim();
            if (text.isEmpty) continue;
            lines.add(_OcrLine(
              text,
              line.boundingBox.top,
              line.boundingBox.left,
            ));
          }
        }
        // Reading order: top to bottom, then left to right for lines on a row.
        lines.sort((a, b) {
          final vertical = a.top.compareTo(b.top);
          if (vertical.abs() > 3) return vertical;
          return a.left.compareTo(b.left);
        });
        outputs[script] = lines.map((line) => line.text).join('\n').trim();
      } catch (error, stackTrace) {
        lastFailure = error;
        debugPrint(
            'Kalpana OCR failed for ${script.name}: $error\n$stackTrace');
      } finally {
        try {
          await recognizer.close();
        } catch (error) {
          debugPrint('Kalpana OCR recognizer cleanup failed: $error');
        }
      }
    }

    if (outputs.isEmpty) {
      throw StateError('All on-device OCR recognizers failed: $lastFailure');
    }

    final latin = outputs[TextRecognitionScript.latin] ?? '';
    final devanagari = outputs[TextRecognitionScript.devanagiri] ?? '';
    final selectedLanguage = language ?? AppLang.en;
    final preferred = selectedLanguage == AppLang.en ? latin : devanagari;
    final fallback = selectedLanguage == AppLang.en ? devanagari : latin;

    // Use the recognizer matching the user's selected language when it returned
    // text; otherwise fall back to the other recognizer. Never truncate a page
    // or select just one phrase: the caller needs the complete passage to resume.
    final best = preferred.trim().isNotEmpty ? preferred : fallback;
    debugPrint(
      'Kalpana OCR complete: ${best.length} characters; '
      'language=${selectedLanguage.name}',
    );
    return best.trim();
  }

  /// Object names (on-device image labelling). Names only: no distances.
  Future<List<String>> labels(String path, AppLang lang) async {
    final labeler =
        ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.6));
    try {
      final ls = await labeler.processImage(InputImage.fromFilePath(path));
      ls.sort((a, b) => b.confidence.compareTo(a.confidence));
      return ls.take(5).map((l) => _tr(l.label, lang)).toList();
    } catch (_) {
      return [];
    } finally {
      await labeler.close();
    }
  }

  /// Dominant colour of the centre of the photo, named in the chosen language.
  Future<String> colorName(Uint8List bytes, AppLang lang) async {
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 80);
    final img = (await codec.getNextFrame()).image;
    final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bd == null) return _colors['gray']![lang.index];
    final w = img.width, h = img.height;
    double r = 0, g = 0, b = 0;
    var n = 0;
    for (var y = (h * .3).toInt(); y < (h * .7).toInt(); y++) {
      for (var x = (w * .3).toInt(); x < (w * .7).toInt(); x++) {
        final i = (y * w + x) * 4;
        r += bd.getUint8(i);
        g += bd.getUint8(i + 1);
        b += bd.getUint8(i + 2);
        n++;
      }
    }
    if (n == 0) n = 1;
    final hsv = HSVColor.fromColor(ui.Color.fromARGB(
        255, (r / n).round(), (g / n).round(), (b / n).round()));
    final v = hsv.value, s = hsv.saturation, hue = hsv.hue;
    String key;
    if (v < 0.18) {
      key = 'black';
    } else if (s < 0.12) {
      key = v > 0.85 ? 'white' : 'gray';
    } else if (hue < 15 || hue >= 345) {
      key = 'red';
    } else if (hue < 40) {
      key = v < 0.6 ? 'brown' : 'orange';
    } else if (hue < 65) {
      key = 'yellow';
    } else if (hue < 165) {
      key = 'green';
    } else if (hue < 200) {
      key = 'turquoise';
    } else if (hue < 255) {
      key = 'blue';
    } else if (hue < 290) {
      key = 'purple';
    } else {
      key = 'pink';
    }
    final name = _colors[key]![lang.index];
    if (key == 'black' || key == 'white' || key == 'gray') return name;
    if (v < 0.4) return '${_shade[0][lang.index]} $name';
    if (v > 0.85 && s < 0.5) return '${_shade[1][lang.index]} $name';
    return name;
  }

  static const _shade = [
    ['dark', 'गहरा', 'गडद'],
    ['light', 'हल्का', 'फिकट'],
  ];
  static const _colors = <String, List<String>>{
    'black': ['black', 'काला', 'काळा'],
    'white': ['white', 'सफ़ेद', 'पांढरा'],
    'gray': ['gray', 'स्लेटी', 'राखाडी'],
    'red': ['red', 'लाल', 'लाल'],
    'orange': ['orange', 'नारंगी', 'नारंगी'],
    'yellow': ['yellow', 'पीला', 'पिवळा'],
    'green': ['green', 'हरा', 'हिरवा'],
    'turquoise': ['turquoise', 'फ़िरोज़ी', 'पिरोजी'],
    'blue': ['blue', 'नीला', 'निळा'],
    'purple': ['purple', 'बैंगनी', 'जांभळा'],
    'pink': ['pink', 'गुलाबी', 'गुलाबी'],
    'brown': ['brown', 'भूरा', 'तपकिरी'],
  };

  static const _obj = <String, List<String>>{
    'bottle': ['बोतल', 'बाटली'],
    'cup': ['कप', 'कप'],
    'table': ['मेज़', 'टेबल'],
    'chair': ['कुर्सी', 'खुर्ची'],
    'book': ['किताब', 'पुस्तक'],
    'mobile phone': ['मोबाइल फ़ोन', 'मोबाइल फोन'],
    'food': ['खाना', 'अन्न'],
    'plant': ['पौधा', 'रोप'],
    'person': ['व्यक्ति', 'व्यक्ती'],
    'door': ['दरवाज़ा', 'दरवाजा'],
    'window': ['खिड़की', 'खिडकी'],
    'car': ['गाड़ी', 'गाडी'],
    'bag': ['बैग', 'बॅग'],
    'shoe': ['जूता', 'बूट'],
    'clothing': ['कपड़े', 'कपडे'],
    'laptop': ['लैपटॉप', 'लॅपटॉप'],
    'fruit': ['फल', 'फळ'],
    'vegetable': ['सब्ज़ी', 'भाजी'],
    'cat': ['बिल्ली', 'मांजर'],
    'dog': ['कुत्ता', 'कुत्रा'],
    'flower': ['फूल', 'फूल'],
    'furniture': ['फ़र्नीचर', 'फर्निचर'],
    'building': ['इमारत', 'इमारत'],
    'tree': ['पेड़', 'झाड'],
    'floor': ['फ़र्श', 'फरशी'],
    'wall': ['दीवार', 'भिंत'],
    'stairs': ['सीढ़ियाँ', 'पायऱ्या'],
    'glasses': ['चश्मा', 'चष्मा'],
    'watch': ['घड़ी', 'घड्याळ'],
    'bicycle': ['साइकिल', 'सायकल'],
    'paper': ['काग़ज़', 'कागद'],
  };

  String _tr(String label, AppLang lang) {
    if (lang == AppLang.en) return label;
    return _obj[label.toLowerCase()]?[lang.index - 1] ?? label;
  }
}
