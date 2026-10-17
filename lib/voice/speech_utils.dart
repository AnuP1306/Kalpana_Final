/// Pure helpers (no Flutter): text normalising, spoken-digit parsing, name matching.

String normText(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[^\p{L}\p{M}\p{N}\s+]', unicode: true), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

final _stopRe = RegExp(
    r'^(?:ok(?:ay)?\s+)?(?:got it|stop|stop talking|enough|that s enough|thats enough|be quiet|समझ गया|समझ गई|ठीक है बस|बस|चुप|रुको|थांबा|समजले|पुरे)$',
    caseSensitive: false,
    unicode: true);

/// "okay got it", "okay stop", "enough"... = stop TALKING only. Never cancels or deletes anything.
bool isStopSpeech(String raw) => _stopRe.hasMatch(normText(raw));

class DigitParse {
  final String digits;
  final bool plus;
  final List<String> unclear;
  const DigitParse(this.digits, this.plus, this.unclear);
}

const _words = <String, String>{
  'zero': '0', 'oh': '0', 'one': '1', 'two': '2', 'three': '3', 'four': '4', 'five': '5', 'six': '6', 'seven': '7', 'eight': '8', 'nine': '9', 'niner': '9',
  'शून्य': '0', 'ज़ीरो': '0', 'जीरो': '0', 'एक': '1', 'दो': '2', 'तीन': '3', 'चार': '4', 'पाँच': '5', 'पांच': '5', 'पाच': '5',
  'छह': '6', 'छः': '6', 'छे': '6', 'छ': '6', 'सात': '7', 'आठ': '8', 'नौ': '9',
  'दोन': '2', 'सहा': '6', 'नऊ': '9',
  'ek': '1', 'do': '2', 'teen': '3', 'char': '4', 'paanch': '5', 'panch': '5', 'chhe': '6', 'chhah': '6', 'saat': '7', 'aath': '8', 'nau': '9',
};
const _rep = <String, int>{'double': 2, 'dable': 2, 'डबल': 2, 'दुहेरी': 2, 'triple': 3, 'ट्रिपल': 3, 'तिहेरी': 3};
const _fill = {'my', 'number', 'is', 'phone', 'mobile', 'it', 'its', 'the', 'and', 'please', 'मेरा', 'मेरी', 'माझा', 'माझी', 'नंबर', 'है', 'आहे', 'क्रमांक', 'फोन', 'फ़ोन', 'मोबाइल'};

/// Turns speech into digits. Anything ambiguous ("to", "for", "ninety", an unknown word)
/// goes into [DigitParse.unclear] so the caller can ask again instead of guessing.
DigitParse parseDigits(String raw) {
  var s = raw.toLowerCase();
  const dev = '०१२३४५६७८९';
  for (var i = 0; i < 10; i++) {
    s = s.replaceAll(dev[i], '$i');
  }
  final tokens = RegExp(r'[\p{L}\p{M}]+|\d+|\+', unicode: true).allMatches(s).map((m) => m.group(0)!).toList();
  final sb = StringBuffer();
  var plus = false;
  var rep = 1;
  final unclear = <String>[];
  for (final t in tokens) {
    if (t == '+' || t == 'plus' || t == 'प्लस') {
      if (sb.isEmpty) plus = true;
      continue;
    }
    if (_fill.contains(t)) continue;
    if (_rep.containsKey(t)) {
      rep = _rep[t]!;
      continue;
    }
    final w = _words[t];
    if (w != null) {
      sb.write(w * rep);
      rep = 1;
      continue;
    }
    if (RegExp(r'^\d+$').hasMatch(t)) {
      if (rep > 1 && t.length != 1) {
        unclear.add(t);
      } else {
        sb.write(t * rep);
      }
      rep = 1;
      continue;
    }
    unclear.add(t);
  }
  if (rep > 1) unclear.add('double');
  return DigitParse(sb.toString(), plus, unclear);
}

int editDistance(String a, String b) {
  if (a == b) return 0;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = <int>[i];
    for (var j = 1; j <= b.length; j++) {
      final c = a[i - 1] == b[j - 1] ? 0 : 1;
      cur.add([prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + c].reduce((x, y) => x < y ? x : y));
    }
    prev = cur;
  }
  return prev.last;
}

/// Indices of the best-matching names (exact > prefix > fuzzy). Empty if nothing is close enough.
List<int> matchNames(List<String> names, String spoken) {
  var q = normText(spoken)
      .replaceAll(RegExp(r'\b(call|my|contact|named|name|is|the|please|emergency)\b'), ' ')
      .replaceAll(RegExp(r'(?:^|\s)(?:मेरा|मेरी|संपर्क|है|माझा|माझी|आहे)(?=\s|$)'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (q.isEmpty) return [];
  final qt = q.split(' ');
  var best = 0;
  final scores = <int>[];
  for (final n in names) {
    final nn = normText(n);
    final nt = nn.split(' ');
    var sc = 0;
    if (nn == q) {
      sc = 100;
    } else if (qt.every((x) => nt.any((y) => y == x || (x.length >= 2 && y.startsWith(x))))) {
      sc = 80;
    } else if (qt.every((x) => nt.any((y) => editDistance(x, y) <= (x.length >= 7 ? 2 : (x.length >= 4 ? 1 : 0))))) {
      sc = 60;
    }
    scores.add(sc);
    if (sc > best) best = sc;
  }
  if (best < 60) return [];
  return [for (var i = 0; i < names.length; i++) if (scores[i] == best) i];
}

/// 1..9 from "2", "two", "second", "दो", "दोन"; -1 for "none"; null if unclear.
int? parseChoice(String raw) {
  const m = {
    '1': 1, 'one': 1, 'first': 1, 'एक': 1, '2': 2, 'two': 2, 'second': 2, 'दो': 2, 'दोन': 2, '3': 3, 'three': 3, 'third': 3, 'तीन': 3,
    '4': 4, 'four': 4, 'fourth': 4, 'चार': 4, '5': 5, 'five': 5, 'fifth': 5, 'पांच': 5, 'पाँच': 5, 'पाच': 5,
  };
  final n = normText(raw);
  if (RegExp(r'none|neither|no one|कोई नहीं|एकही नाही|नको|नहीं').hasMatch(n)) return -1;
  for (final t in n.split(' ')) {
    if (m.containsKey(t)) return m[t];
  }
  return null;
}
