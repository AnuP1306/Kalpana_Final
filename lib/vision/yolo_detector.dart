import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_litert/flutter_litert.dart';

const String kYoloAsset = 'assets/models/yolo26n.tflite';
const double kConfThreshold = 0.35;
const double kNmsIou = 0.45;
const int kMaxDetections = 40;

/// COCO-80 class names, in the order used by the official YOLO26 COCO weights.
const List<String> kCocoLabels = [
  'person',
  'bicycle',
  'car',
  'motorcycle',
  'airplane',
  'bus',
  'train',
  'truck',
  'boat',
  'traffic light',
  'fire hydrant',
  'stop sign',
  'parking meter',
  'bench',
  'bird',
  'cat',
  'dog',
  'horse',
  'sheep',
  'cow',
  'elephant',
  'bear',
  'zebra',
  'giraffe',
  'backpack',
  'umbrella',
  'handbag',
  'tie',
  'suitcase',
  'frisbee',
  'skis',
  'snowboard',
  'sports ball',
  'kite',
  'baseball bat',
  'baseball glove',
  'skateboard',
  'surfboard',
  'tennis racket',
  'bottle',
  'wine glass',
  'cup',
  'fork',
  'knife',
  'spoon',
  'bowl',
  'banana',
  'apple',
  'sandwich',
  'orange',
  'broccoli',
  'carrot',
  'hot dog',
  'pizza',
  'donut',
  'cake',
  'chair',
  'couch',
  'potted plant',
  'bed',
  'dining table',
  'toilet',
  'TV',
  'laptop',
  'mouse',
  'remote',
  'keyboard',
  'cell phone',
  'microwave',
  'oven',
  'toaster',
  'sink',
  'refrigerator',
  'book',
  'clock',
  'vase',
  'scissors',
  'teddy bear',
  'hair drier',
  'toothbrush'
];

/// A detection in normalised coordinates (0..1) of the UPRIGHT camera frame.
class Detection {
  final double x1, y1, x2, y2, conf;
  final int cls;
  const Detection(this.x1, this.y1, this.x2, this.y2, this.conf, this.cls);
}

class DetectResult {
  final List<Detection> dets;
  final double luma,
      std; // mean / std-dev of the Y plane (0..255), for framing checks
  final int ms; // preprocessing + inference time in the worker
  const DetectResult(this.dets, this.luma, this.std, this.ms);
}

/// Runs the model in a background isolate. Camera frames are copied in, results
/// come back as plain numbers. One frame in flight at a time.
class YoloDetector {
  Isolate? _iso;
  ReceivePort? _rx;
  StreamSubscription<dynamic>? _sub;
  SendPort? _tx;
  Uint8List? _modelBytes;
  Completer<Map>? _ready;
  Completer<void>? _closeAck;
  Completer<Map>? _pending;
  int _seq = 0, _pendingId = -1;

  /// Human-readable description of the loaded model's tensors (for debugging).
  String modelInfo = '';

  /// Returns null on success, or a technical error message.
  Future<String?> start() async {
    try {
      final bd = await rootBundle.load(kYoloAsset);
      _modelBytes = bd.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes);
    } catch (_) {
      return 'The model file $kYoloAsset is missing from the app. Add it and list it under flutter > assets in pubspec.yaml.';
    }
    final ready = _ready = Completer<Map>();
    final rx = _rx = ReceivePort();
    _sub = rx.listen(_onMsg);
    try {
      _iso = await Isolate.spawn(_workerMain, rx.sendPort);
    } catch (e) {
      return 'Could not start the detector: $e';
    }
    final m = await ready.future.timeout(const Duration(seconds: 25),
        onTimeout: () =>
            {'t': 'initError', 'e': 'Loading the model timed out.'});
    _modelBytes = null;
    if (m['t'] == 'ready') {
      modelInfo = m['info'] as String? ?? '';
      return null;
    }
    return m['e'] as String? ?? 'The model could not be loaded.';
  }

  void _onMsg(dynamic m) {
    if (m is SendPort) {
      _tx = m;
      m.send({
        't': 'init',
        'model': TransferableTypedData.fromList([_modelBytes!]),
        'threads': 4,
      });
      return;
    }
    if (m is! Map) return;
    switch (m['t']) {
      case 'ready' || 'initError':
        final r = _ready;
        if (r != null && !r.isCompleted) r.complete(m);
      case 'result' || 'frameError':
        final p = _pending;
        if (p != null && !p.isCompleted && m['id'] == _pendingId) p.complete(m);
      case 'closed':
        final a = _closeAck;
        if (a != null && !a.isCompleted) a.complete();
    }
  }

  /// Returns null if a frame is already being processed (the frame is dropped).
  /// Throws if the frame format is unsupported or the worker reports an error.
  /// The camera buffers are copied synchronously, so the caller may return
  /// from its image-stream callback right away.
  Future<DetectResult?> detect(CameraImage img, int rotation) async {
    final tx = _tx;
    if (tx == null || _pending != null) return null;
    if (img.planes.length != 3) {
      throw StateError(
          'Camera frames are not 3-plane YUV420 (got ${img.planes.length} planes).');
    }
    final id = ++_seq;
    final c = _pending = Completer<Map>();
    _pendingId = id;
    tx.send({
      't': 'frame',
      'id': id,
      'w': img.width,
      'h': img.height,
      'rot': rotation,
      'p': [
        for (final p in img.planes) TransferableTypedData.fromList([p.bytes])
      ],
      'rs': [for (final p in img.planes) p.bytesPerRow],
      'ps': [for (final p in img.planes) p.bytesPerPixel ?? 1],
    });
    final m = await c.future.timeout(const Duration(seconds: 6),
        onTimeout: () => {'t': 'frameError', 'e': 'The detector timed out.'});
    if (identical(_pending, c)) _pending = null;
    if (m['t'] != 'result') {
      throw StateError(m['e'] as String? ?? 'Detection failed.');
    }
    final flat = (m['d'] as List).cast<double>();
    final dets = <Detection>[
      for (var i = 0; i + 5 < flat.length; i += 6)
        Detection(flat[i], flat[i + 1], flat[i + 2], flat[i + 3], flat[i + 4],
            flat[i + 5].round())
    ];
    return DetectResult(dets, (m['luma'] as num).toDouble(),
        (m['std'] as num).toDouble(), m['ms'] as int);
  }

  Future<void> dispose() async {
    final p = _pending;
    _pending = null;
    if (p != null && !p.isCompleted)
      p.complete({'t': 'frameError', 'e': 'closed'});
    final tx = _tx;
    _tx = null;
    if (tx != null) {
      final ack = _closeAck = Completer<void>();
      tx.send({'t': 'close'});
      await ack.future.timeout(const Duration(seconds: 1), onTimeout: () {});
    }
    _iso?.kill(priority: Isolate.immediate);
    _iso = null;
    await _sub?.cancel();
    _sub = null;
    _rx?.close();
    _rx = null;
  }
}

// ======================================================= worker isolate

class _ModelError implements Exception {
  final String message;
  _ModelError(this.message);
}

// Output layouts.
const _e2eRowMajor = 0; // [1, N, 6]  x1 y1 x2 y2 conf cls
const _e2eColMajor = 1; // [1, 6, N]
const _rawChannelsFirst = 2; // [1, 4+nc, N]  cx cy w h scores...
const _rawChannelsLast = 3; // [1, N, 4+nc]

class _Model {
  final Interpreter interp;
  final int inW, inH, layout, n, c;
  final bool nhwc;
  final Float32List input;
  final String info;
  _Model(this.interp, this.inW, this.inH, this.nhwc, this.layout, this.n,
      this.c, this.info)
      : input = Float32List(inW * inH * 3);
}

_Model _load(Uint8List bytes, int threads) {
  final interp = Interpreter.fromBuffer(bytes,
      options: InterpreterOptions()..threads = threads);
  try {
    final inT = interp.getInputTensor(0);
    final inShape = inT.shape;
    final inType = inT.type.toString().toLowerCase();
    if (!inType.contains('float32')) {
      throw _ModelError(
          'Unsupported model input type ($inType). Only float32 input is supported; export the model without int8 quantisation.');
    }
    if (inShape.length != 4) {
      throw _ModelError('Unexpected model input shape $inShape.');
    }
    final nhwc = inShape[3] == 3;
    if (!nhwc && inShape[1] != 3) {
      throw _ModelError(
          'Unexpected model input shape $inShape (expected [1,H,W,3] or [1,3,H,W]).');
    }
    final inH = nhwc ? inShape[1] : inShape[2];
    final inW = nhwc ? inShape[2] : inShape[3];

    final outT = interp.getOutputTensor(0);
    final os = outT.shape;
    final outType = outT.type.toString().toLowerCase();
    if (!outType.contains('float32')) {
      throw _ModelError(
          'Unsupported model output type ($outType); expected float32.');
    }
    int layout, n, c;
    if (os.length == 3 && os[2] == 6 && os[1] > 6) {
      layout = _e2eRowMajor;
      n = os[1];
      c = 6;
    } else if (os.length == 3 && os[1] == 6 && os[2] > 6) {
      layout = _e2eColMajor;
      n = os[2];
      c = 6;
    } else if (os.length == 3 && os[1] >= 5 && os[1] < os[2]) {
      layout = _rawChannelsFirst;
      n = os[2];
      c = os[1];
    } else if (os.length == 3 && os[2] >= 5 && os[2] < os[1]) {
      layout = _rawChannelsLast;
      n = os[1];
      c = os[2];
    } else {
      throw _ModelError('Unrecognised model output shape $os.');
    }
    final info =
        'input $inShape ${nhwc ? 'NHWC' : 'NCHW'}, output $os (layout $layout)';
    return _Model(interp, inW, inH, nhwc, layout, n, c, info);
  } catch (_) {
    interp.close();
    rethrow;
  }
}

void _workerMain(SendPort main) {
  final rx = ReceivePort();
  main.send(rx.sendPort);
  _Model? model;
  rx.listen((dynamic raw) {
    final msg = raw as Map;
    switch (msg['t']) {
      case 'init':
        try {
          final bytes = (msg['model'] as TransferableTypedData)
              .materialize()
              .asUint8List();
          final m = _load(bytes, msg['threads'] as int);
          model = m;
          main.send({'t': 'ready', 'info': m.info});
        } on _ModelError catch (e) {
          main.send({'t': 'initError', 'e': e.message});
        } catch (e) {
          main.send({'t': 'initError', 'e': 'Could not load the model: $e'});
        }
      case 'frame':
        final id = msg['id'] as int;
        final m = model;
        if (m == null) {
          main.send({'t': 'frameError', 'id': id, 'e': 'Model is not loaded.'});
          return;
        }
        try {
          main.send(_infer(m, msg, id));
        } catch (e) {
          main.send({'t': 'frameError', 'id': id, 'e': '$e'});
        }
      case 'close':
        try {
          model?.interp.close();
        } catch (_) {}
        model = null;
        main.send({'t': 'closed'});
        rx.close();
    }
  });
}

class _Box {
  double x1, y1, x2, y2;
  final double conf;
  final int cls;
  _Box(this.x1, this.y1, this.x2, this.y2, this.conf, this.cls);
}

Map<String, Object?> _infer(_Model m, Map msg, int id) {
  final sw = Stopwatch()..start();
  final srcW = msg['w'] as int, srcH = msg['h'] as int, rot = msg['rot'] as int;
  final planes = [
    for (final p in msg['p'] as List)
      (p as TransferableTypedData).materialize().asUint8List()
  ];
  final rs = (msg['rs'] as List).cast<int>();
  final ps = (msg['ps'] as List).cast<int>();
  final yP = planes[0], uP = planes[1], vP = planes[2];

  // Framing statistics from a 24x24 grid of luma samples.
  double sum = 0, sum2 = 0;
  var cnt = 0;
  for (var gy = 0; gy < 24; gy++) {
    final sy = ((gy + 0.5) * srcH / 24).floor();
    for (var gx = 0; gx < 24; gx++) {
      final sx = ((gx + 0.5) * srcW / 24).floor();
      final v = yP[sy * rs[0] + sx * ps[0]].toDouble();
      sum += v;
      sum2 += v * v;
      cnt++;
    }
  }
  final mean = sum / cnt;
  final std = math.sqrt(math.max(0.0, sum2 / cnt - mean * mean));

  // Letterbox the rotated (upright) frame into the model input.
  final sideways = rot == 90 || rot == 270;
  final upW = sideways ? srcH : srcW;
  final upH = sideways ? srcW : srcH;
  final scale = math.min(m.inW / upW, m.inH / upH);
  final newW = math.min(m.inW, math.max(1, (upW * scale).round()));
  final newH = math.min(m.inH, math.max(1, (upH * scale).round()));
  final padX = (m.inW - newW) ~/ 2, padY = (m.inH - newH) ~/ 2;
  final inp = m.input;
  inp.fillRange(0, inp.length, 114 / 255);
  final uxT = List<int>.generate(
      newW, (ox) => math.min(upW - 1, ((ox + 0.5) / scale).floor()));
  final uyT = List<int>.generate(
      newH, (oy) => math.min(upH - 1, ((oy + 0.5) / scale).floor()));
  final plane = m.inW * m.inH;
  for (var oy = 0; oy < newH; oy++) {
    final uy = uyT[oy];
    for (var ox = 0; ox < newW; ox++) {
      final ux = uxT[ox];
      int sx, sy;
      switch (rot) {
        case 90:
          sx = uy;
          sy = srcH - 1 - ux;
        case 180:
          sx = srcW - 1 - ux;
          sy = srcH - 1 - uy;
        case 270:
          sx = srcW - 1 - uy;
          sy = ux;
        default:
          sx = ux;
          sy = uy;
      }
      final yv = yP[sy * rs[0] + sx * ps[0]].toDouble();
      final cy = sy >> 1, cx = sx >> 1;
      final u = uP[cy * rs[1] + cx * ps[1]] - 128.0;
      final v = vP[cy * rs[2] + cx * ps[2]] - 128.0;
      var r = yv + 1.402 * v;
      var g = yv - 0.344136 * u - 0.714136 * v;
      var b = yv + 1.772 * u;
      r = r < 0 ? 0 : (r > 255 ? 255 : r);
      g = g < 0 ? 0 : (g > 255 ? 255 : g);
      b = b < 0 ? 0 : (b > 255 ? 255 : b);
      final o = (padY + oy) * m.inW + padX + ox;
      if (m.nhwc) {
        final k = o * 3;
        inp[k] = r / 255;
        inp[k + 1] = g / 255;
        inp[k + 2] = b / 255;
      } else {
        inp[o] = r / 255;
        inp[plane + o] = g / 255;
        inp[2 * plane + o] = b / 255;
      }
    }
  }

  m.interp.getInputTensor(0).data = inp.buffer.asUint8List();
  m.interp.invoke();
  final outBytes = Uint8List.fromList(m.interp.getOutputTensor(0).data);
  final out = outBytes.buffer.asFloat32List();

  final boxes = _decode(m, out);
  // Some exports give coordinates normalised to 0..1, others in input pixels.
  var maxC = 0.0;
  for (final b in boxes) {
    maxC = math.max(maxC, math.max(b.x2, b.y2));
  }
  final norm = boxes.isNotEmpty && maxC <= 1.5;
  final res = <double>[];
  for (final b in boxes) {
    final x1 = norm ? b.x1 * m.inW : b.x1, x2 = norm ? b.x2 * m.inW : b.x2;
    final y1 = norm ? b.y1 * m.inH : b.y1, y2 = norm ? b.y2 * m.inH : b.y2;
    final nx1 = (((x1 - padX) / scale) / upW).clamp(0.0, 1.0);
    final nx2 = (((x2 - padX) / scale) / upW).clamp(0.0, 1.0);
    final ny1 = (((y1 - padY) / scale) / upH).clamp(0.0, 1.0);
    final ny2 = (((y2 - padY) / scale) / upH).clamp(0.0, 1.0);
    if (nx2 - nx1 < 0.01 || ny2 - ny1 < 0.01) continue;
    res.addAll([nx1, ny1, nx2, ny2, b.conf, b.cls.toDouble()]);
  }
  return {
    't': 'result',
    'id': id,
    'd': res,
    'luma': mean,
    'std': std,
    'ms': sw.elapsedMilliseconds,
  };
}

List<_Box> _decode(_Model m, Float32List o) {
  final boxes = <_Box>[];
  final cf = m.layout == _e2eColMajor || m.layout == _rawChannelsFirst;
  final stride = cf ? m.n : 1;
  if (m.layout <= _e2eColMajor) {
    for (var i = 0; i < m.n; i++) {
      final base = cf ? i : i * 6;
      final conf = o[base + 4 * stride];
      if (conf < kConfThreshold) continue;
      boxes.add(_Box(o[base], o[base + stride], o[base + 2 * stride],
          o[base + 3 * stride], conf, o[base + 5 * stride].round()));
    }
    boxes.sort((a, b) => b.conf.compareTo(a.conf));
    return boxes.length > kMaxDetections
        ? boxes.sublist(0, kMaxDetections)
        : boxes;
  }
  final nc = m.c - 4;
  for (var i = 0; i < m.n; i++) {
    final base = cf ? i : i * m.c;
    var best = 0.0;
    var bc = -1;
    for (var k = 0; k < nc; k++) {
      final s = o[base + (4 + k) * stride];
      if (s > best) {
        best = s;
        bc = k;
      }
    }
    if (bc < 0 || best < kConfThreshold) continue;
    final cx = o[base], cy = o[base + stride];
    final w = o[base + 2 * stride], h = o[base + 3 * stride];
    boxes.add(_Box(cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2, best, bc));
  }
  return _nms(boxes);
}

double _iouBox(_Box a, _Box b) {
  final ix = math.max(0.0, math.min(a.x2, b.x2) - math.max(a.x1, b.x1));
  final iy = math.max(0.0, math.min(a.y2, b.y2) - math.max(a.y1, b.y1));
  final inter = ix * iy;
  final u =
      (a.x2 - a.x1) * (a.y2 - a.y1) + (b.x2 - b.x1) * (b.y2 - b.y1) - inter;
  return u <= 0 ? 0 : inter / u;
}

List<_Box> _nms(List<_Box> bs) {
  bs.sort((a, b) => b.conf.compareTo(a.conf));
  final keep = <_Box>[];
  for (final b in bs) {
    var ok = true;
    for (final k in keep) {
      if (k.cls == b.cls && _iouBox(k, b) > kNmsIou) {
        ok = false;
        break;
      }
    }
    if (ok) {
      keep.add(b);
      if (keep.length >= kMaxDetections) break;
    }
  }
  return keep;
}
