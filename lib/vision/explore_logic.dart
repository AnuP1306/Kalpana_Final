import '../strings.dart' show AppLang;
import 'explore_strings.dart';
import 'yolo_detector.dart';

enum Lane { left, ahead, right }

enum FrameIssue { dark, uniform, bright }

const _vehicles = {
  1,
  2,
  3,
  5,
  6,
  7
}; // bicycle, car, motorcycle, bus, train, truck
const _living = {0, 15, 16, 17, 18, 19, 20, 21}; // person + animals
const _signs = {9, 11}; // traffic light, stop sign (information only)
const _obstacles = {10, 13, 24, 26, 28, 56, 57, 58, 59, 60, 61, 62, 71, 72};

bool isRelevantClass(int c) =>
    _vehicles.contains(c) ||
    _living.contains(c) ||
    _signs.contains(c) ||
    _obstacles.contains(c);

class _Sample {
  final DateTime t;
  final double area;
  _Sample(this.t, this.area);
}

class Track {
  final int id;
  final int cls;
  double cx, cy, w, h, conf;
  int hits = 1;
  int misses = 0;
  DateTime firstSeen;
  DateTime lastSeen;
  final List<_Sample> samples = [];

  // What has already been said about this track (avoids repetition).
  int spokenLevel = 0;
  Lane? spokenLane;
  DateTime? spokenAt;
  bool spokenApproach = false;

  Track(this.id, this.cls, this.cx, this.cy, this.w, this.h, this.conf,
      DateTime now)
      : firstSeen = now,
        lastSeen = now {
    samples.add(_Sample(now, w * h));
  }

  double get area => w * h;
  double get x1 => cx - w / 2;
  double get y1 => cy - h / 2;
  double get x2 => cx + w / 2;
  double get y2 => cy + h / 2;
  Lane get lane =>
      cx < 0.33 ? Lane.left : (cx > 0.67 ? Lane.right : Lane.ahead);

  void markSpoken(int level, bool approaching, DateTime now) {
    spokenLevel = level;
    spokenLane = lane;
    spokenApproach = approaching;
    spokenAt = now;
  }

  void clearSpoken() {
    spokenLevel = 0;
    spokenLane = null;
    spokenAt = null;
    spokenApproach = false;
  }
}

/// Greedy IoU tracker with exponential smoothing of the boxes.
class Tracker {
  final List<Track> tracks = [];
  int _next = 1;

  void update(List<Detection> dets, DateTime now) {
    final cand = <(double, int, int)>[];
    for (var i = 0; i < tracks.length; i++) {
      for (var j = 0; j < dets.length; j++) {
        if (tracks[i].cls != dets[j].cls) continue;
        final v = _iou(tracks[i], dets[j]);
        if (v >= 0.25) cand.add((v, i, j));
      }
    }
    cand.sort((a, b) => b.$1.compareTo(a.$1));
    final usedT = <int>{}, usedD = <int>{};
    for (final c in cand) {
      if (usedT.contains(c.$2) || usedD.contains(c.$3)) continue;
      usedT.add(c.$2);
      usedD.add(c.$3);
      _apply(tracks[c.$2], dets[c.$3], now);
    }
    for (var i = 0; i < tracks.length; i++) {
      if (!usedT.contains(i)) tracks[i].misses++;
    }
    for (var j = 0; j < dets.length; j++) {
      if (usedD.contains(j)) continue;
      final d = dets[j];
      tracks.add(Track(_next++, d.cls, (d.x1 + d.x2) / 2, (d.y1 + d.y2) / 2,
          d.x2 - d.x1, d.y2 - d.y1, d.conf, now));
    }
    tracks.removeWhere((t) =>
        t.misses > 6 || now.difference(t.lastSeen).inMilliseconds > 1500);
  }

  void _apply(Track t, Detection d, DateTime now) {
    const a = 0.6;
    t.cx = t.cx * (1 - a) + (d.x1 + d.x2) / 2 * a;
    t.cy = t.cy * (1 - a) + (d.y1 + d.y2) / 2 * a;
    t.w = t.w * (1 - a) + (d.x2 - d.x1) * a;
    t.h = t.h * (1 - a) + (d.y2 - d.y1) * a;
    t.conf = d.conf;
    t.hits++;
    t.misses = 0;
    t.lastSeen = now;
    t.samples.add(_Sample(now, t.area));
    t.samples.removeWhere((s) => now.difference(s.t).inMilliseconds > 2200);
  }

  double _iou(Track t, Detection d) {
    final ix = _max0(_min(t.x2, d.x2) - _max(t.x1, d.x1));
    final iy = _max0(_min(t.y2, d.y2) - _max(t.y1, d.y1));
    final inter = ix * iy;
    final u = t.w * t.h + (d.x2 - d.x1) * (d.y2 - d.y1) - inter;
    return u <= 0 ? 0 : inter / u;
  }

  static double _min(double a, double b) => a < b ? a : b;
  static double _max(double a, double b) => a > b ? a : b;
  static double _max0(double a) => a > 0 ? a : 0;

  List<Track> confirmed() => [
        for (final t in tracks)
          if (t.hits >= 3 && t.misses <= 2) t
      ];
}

/// Box growth over roughly the last second. Untested starting thresholds.
bool isApproaching(Track t, DateTime now) {
  if (!(_vehicles.contains(t.cls) || _living.contains(t.cls)) || t.hits < 4) {
    return false;
  }
  _Sample? ref;
  for (final s in t.samples) {
    final age = now.difference(s.t).inMilliseconds;
    if (age >= 600 && age <= 1800) ref = s;
  }
  if (ref == null || ref.area <= 0) return false;
  return t.area >= 0.03 && t.area / ref.area >= 1.35;
}

/// 3 = urgent, 2 = warning, 1 = information.
int hazardLevel(Track t, bool approaching) {
  final h = t.h;
  final ahead = t.lane == Lane.ahead;
  if (_signs.contains(t.cls)) return 1;
  final vehicle = _vehicles.contains(t.cls);
  final living = _living.contains(t.cls);
  if (vehicle && (approaching || h > 0.45)) return 3;
  if (ahead && h > 0.65) return 3;
  if (vehicle && h > 0.2) return 2;
  if ((living || _obstacles.contains(t.cls)) && ahead && h > 0.3) return 2;
  if (approaching) return 2;
  return 1;
}

String _proxKey(double h) =>
    h > 0.6 ? 'exVeryClose' : (h > 0.3 ? 'exClose' : 'exNear');
String _laneKey(Lane l) => switch (l) {
      Lane.left => 'exLeft',
      Lane.ahead => 'exAhead',
      Lane.right => 'exRight'
    };

class NarrationItem {
  final Track track;
  final int level;
  final bool approaching;
  NarrationItem(this.track, this.level, this.approaching);
}

class Narration {
  final String text;
  final bool urgent;
  final List<NarrationItem> items;
  Narration(this.text, this.urgent, this.items);
}

class ExploreBox {
  final double x1, y1, x2, y2;
  final String label;
  final int level;
  const ExploreBox(this.x1, this.y1, this.x2, this.y2, this.label, this.level);
}

ExploreBox boxFor(Track t, DateTime now, AppLang lang) => ExploreBox(
    t.x1.clamp(0.0, 1.0),
    t.y1.clamp(0.0, 1.0),
    t.x2.clamp(0.0, 1.0),
    t.y2.clamp(0.0, 1.0),
    exploreLabel(lang, t.cls),
    hazardLevel(t, isApproaching(t, now)));

/// Decides WHAT to say and WHEN, so the same object is not repeated.
class Narrator {
  DateTime _lastAt = DateTime.fromMillisecondsSinceEpoch(0);
  final Map<String, DateTime> _recent = {};

  void reset() {
    _lastAt = DateTime.fromMillisecondsSinceEpoch(0);
    _recent.clear();
  }

  /// [muted]/[quiet]: only urgent items are spoken.
  Narration? plan(Iterable<Track> confirmed, DateTime now, AppLang lang,
      {required bool muted, required bool quiet}) {
    final items = <NarrationItem>[];
    for (final t in confirmed) {
      if (!isRelevantClass(t.cls)) continue;
      final appr = isApproaching(t, now);
      final lvl = hazardLevel(t, appr);
      final escalated = lvl > t.spokenLevel;
      final newAppr = appr && !t.spokenApproach;
      final moved = t.spokenLane != null &&
          t.spokenLane != t.lane &&
          lvl >= 2 &&
          t.spokenAt != null &&
          now.difference(t.spokenAt!).inSeconds >= 6;
      if (!(escalated || newAppr || moved)) continue;
      if ((muted || quiet) && lvl < 3) continue;
      if (lvl < 3 && t.spokenLevel == 0) {
        // A "new" track for something just announced (e.g. after a brief occlusion).
        final at = _recent['${t.cls}:${t.lane.index}'];
        if (at != null && now.difference(at).inSeconds < 10) {
          t.markSpoken(lvl, appr, now);
          continue;
        }
      }
      items.add(NarrationItem(t, lvl, appr));
    }
    if (items.isEmpty) return null;
    final urgent = items.any((i) => i.level >= 3);
    if (now.difference(_lastAt).inMilliseconds < (urgent ? 1200 : 3000)) {
      return null;
    }
    items.sort((a, b) => b.level != a.level
        ? b.level - a.level
        : b.track.h.compareTo(a.track.h));

    final groups = <String, List<NarrationItem>>{};
    for (final i in items) {
      groups
          .putIfAbsent(
              '${i.track.cls}:${i.track.lane.index}:${i.approaching}', () => [])
          .add(i);
    }
    final picked = groups.values.take(2).toList();
    final parts = <String>[];
    final used = <NarrationItem>[];
    for (final g in picked) {
      final f = g.first;
      final args = {
        'obj': exploreLabel(lang, f.track.cls),
        'dir': exploreText(lang, _laneKey(f.track.lane)),
        'prox': exploreText(lang, _proxKey(f.track.h)),
        'n': '${g.length}',
      };
      if (f.approaching) {
        parts.add(exploreText(lang, 'exApproach', args));
      } else if (g.length > 1) {
        parts.add(exploreText(lang, 'exHzMany', args));
      } else {
        parts.add(exploreText(lang, 'exHz', args));
      }
      used.addAll(g);
    }
    return Narration(parts.join(' '), used.any((i) => i.level >= 3), used);
  }

  void commit(Narration n, DateTime now) {
    for (final i in n.items) {
      i.track.markSpoken(i.level, i.approaching, now);
      _recent['${i.track.cls}:${i.track.lane.index}'] = now;
    }
    _lastAt = now;
  }
}

/// Flags a camera view that is reliably unusable (dark, uniform/covered, washed out).
class FramingMonitor {
  int _bad = 0, _good = 0;
  FrameIssue? _issue;

  void reset() {
    _bad = 0;
    _good = 0;
    _issue = null;
  }

  FrameIssue? update(double mean, double std) {
    FrameIssue? cur;
    if (mean < 28) {
      cur = FrameIssue.dark;
    } else if (std < 6) {
      cur = FrameIssue.uniform;
    } else if (mean > 238 && std < 25) {
      cur = FrameIssue.bright;
    }
    if (cur != null) {
      _good = 0;
      if (++_bad >= 6) _issue = cur;
    } else {
      _bad = 0;
      if (++_good >= 4) _issue = null;
    }
    return _issue;
  }
}
