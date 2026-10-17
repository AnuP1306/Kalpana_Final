import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../strings.dart';

/// Everything here runs ON THE PHONE (Google ML Kit + pixel maths): no internet, no quota.
class OfflineVision {
  /// OCR for English, Hindi and Marathi print (Latin + Devanagari models).
  Future<String> readText(String path) async {
    final input = InputImage.fromFilePath(path);
    final out = <String, String>{};
    final scripts = TextRecognitionScript.values.where((s) => const ['latin', 'devanagiri', 'devanagari'].contains(s.name));
    for (final script in scripts) {
      final rec = TextRecognizer(script: script);
      try {
        final r = await rec.processImage(input);
        out[script.name] = r.text.replaceAll(RegExp(r'\s+'), ' ').trim();
      } catch (_) {
      } finally {
        await rec.close();
      }
    }
    final dev = out.entries.where((e) => e.key.startsWith('dev')).map((e) => e.value).join(' ');
    final lat = out['latin'] ?? '';
    final devChars = RegExp(r'[\u0900-\u097F]').allMatches(dev).length;
    final best = devChars >= 3 ? dev : (lat.length >= dev.length ? lat : dev);
    return best.length > 700 ? best.substring(0, 700) : best;
  }

  /// Object names (on-device image labelling). Names only: no distances.
  Future<List<String>> labels(String path, AppLang lang) async {
    final labeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.6));
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
    final hsv = HSVColor.fromColor(ui.Color.fromARGB(255, (r / n).round(), (g / n).round(), (b / n).round()));
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
    'bottle': ['बोतल', 'बाटली'], 'cup': ['कप', 'कप'], 'table': ['मेज़', 'टेबल'], 'chair': ['कुर्सी', 'खुर्ची'],
    'book': ['किताब', 'पुस्तक'], 'mobile phone': ['मोबाइल फ़ोन', 'मोबाइल फोन'], 'food': ['खाना', 'अन्न'],
    'plant': ['पौधा', 'रोप'], 'person': ['व्यक्ति', 'व्यक्ती'], 'door': ['दरवाज़ा', 'दरवाजा'], 'window': ['खिड़की', 'खिडकी'],
    'car': ['गाड़ी', 'गाडी'], 'bag': ['बैग', 'बॅग'], 'shoe': ['जूता', 'बूट'], 'clothing': ['कपड़े', 'कपडे'],
    'laptop': ['लैपटॉप', 'लॅपटॉप'], 'fruit': ['फल', 'फळ'], 'vegetable': ['सब्ज़ी', 'भाजी'], 'cat': ['बिल्ली', 'मांजर'],
    'dog': ['कुत्ता', 'कुत्रा'], 'flower': ['फूल', 'फूल'], 'furniture': ['फ़र्नीचर', 'फर्निचर'], 'building': ['इमारत', 'इमारत'],
    'tree': ['पेड़', 'झाड'], 'floor': ['फ़र्श', 'फरशी'], 'wall': ['दीवार', 'भिंत'], 'stairs': ['सीढ़ियाँ', 'पायऱ्या'],
    'glasses': ['चश्मा', 'चष्मा'], 'watch': ['घड़ी', 'घड्याळ'], 'bicycle': ['साइकिल', 'सायकल'], 'paper': ['काग़ज़', 'कागद'],
  };

  String _tr(String label, AppLang lang) {
    if (lang == AppLang.en) return label;
    return _obj[label.toLowerCase()]?[lang.index - 1] ?? label;
  }
}
