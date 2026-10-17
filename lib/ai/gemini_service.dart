import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../strings.dart';

/// [key] is a strings.dart key that can be spoken to the user.
class AiException implements Exception {
  final String key;
  AiException(this.key);
}

class AiResult {
  final String? command, reply;
  const AiResult(this.command, this.reply);
}

class GeminiService {
  bool get configured => kGeminiApiKey.isNotEmpty && !kGeminiApiKey.startsWith('PASTE');
  static const _lang = ['English', 'Hindi (Devanagari script)', 'Marathi (Devanagari script)'];

  Future<String> _generate(Map<String, dynamic> body, Duration timeout) async {
    if (!configured) throw AiException('noKey');
    try {
      final r = await http
          .post(
            Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$kGeminiModel:generateContent'),
            headers: {'Content-Type': 'application/json', 'x-goog-api-key': kGeminiApiKey},
            body: jsonEncode(body),
          )
          .timeout(timeout);
      if (r.statusCode != 200) {
        throw AiException(r.statusCode == 400 || r.statusCode == 401 || r.statusCode == 403 ? 'aiKeyBad' : 'aiFail');
      }
      final j = jsonDecode(utf8.decode(r.bodyBytes));
      final parts = j['candidates']?[0]?['content']?['parts'] as List?;
      final text = (parts ?? []).map((p) => p['text'] ?? '').join('').toString().trim();
      if (text.isEmpty) throw AiException('aiFail');
      return text;
    } on SocketException {
      throw AiException('aiOffline');
    } on TimeoutException {
      throw AiException('aiOffline');
    } on http.ClientException {
      throw AiException('aiOffline');
    }
  }

  String _system(AppLang l, String screen, String name) => '''
You are the intent engine of Kalpana, a voice assistant for blind and low-vision users in India.
The user speaks English, Hindi or Marathi (sometimes romanised). Map their request to exactly ONE canonical command below, or answer briefly yourself.
Return ONLY JSON: {"command": string or null, "reply": string or null}

Canonical commands (write them exactly in English):
- open reminders
- add reminder: <the reminder text, kept in the user's own language>
- clear reminders
- read text            (user wants printed text, a sign, a label or a document read)
- what is this         (identify an object, product or medicine)
- describe surroundings (what is around / in front of me)
- identify color
- take picture
- where am i
- send my location
- emergency
- call <name>
- help                 (what can you do, how do I use this)
- open settings
- open chat
- go home
- go back
- repeat
- speak slower
- speak faster
- change language to english|hindi|marathi
- stop listening       (user wants you to stop listening / go quiet)

Rules:
- If the request matches a command, set "command" and set "reply" to null.
- If it is a general question or small talk, set "command" to null and "reply" to a short helpful answer (max 2 sentences) in ${_lang[l.index]}.
- If unclear, set "command" to null and "reply" to a short question asking them to rephrase, in ${_lang[l.index]}.
- Never invent contact names. For calls use only the name the user said.
Current screen: $screen. User name: $name.''';

  /// Returns null when AI is unavailable (no key / offline / error) so the
  /// caller can fall back to the offline keyword router.
  Future<AiResult?> understand(String text, AppLang lang, {String screen = '', String name = ''}) async {
    if (!configured) return null;
    try {
      final out = await _generate({
        'systemInstruction': {'parts': [{'text': _system(lang, screen, name)}]},
        'contents': [{'role': 'user', 'parts': [{'text': text}]}],
        'generationConfig': {'temperature': 0.2, 'responseMimeType': 'application/json'},
      }, const Duration(seconds: 10));
      final m = jsonDecode(out) as Map<String, dynamic>;
      String? s(dynamic v) {
        final x = (v is String) ? v.trim() : null;
        return (x == null || x.isEmpty || x == 'null') ? null : x;
      }
      return AiResult(s(m['command']), s(m['reply']));
    } catch (_) {
      return null;
    }
  }

  Future<String> describeImage(Uint8List bytes, String prompt, AppLang lang) async {
    final out = await _generate({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'inline_data': {'mime_type': 'image/jpeg', 'data': base64Encode(bytes)}},
            {'text': '$prompt\nReply in ${_lang[lang.index]}. Use plain spoken sentences only: no markdown, no bullet symbols, no asterisks.'},
          ]
        }
      ],
      'generationConfig': {'temperature': 0.3},
    }, const Duration(seconds: 8));
    return out.replaceAll(RegExp(r'[*#`_]'), '').trim();
  }
}
