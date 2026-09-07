import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class VisionClassificationResult {
  const VisionClassificationResult({required this.label, required this.confidence, required this.topK});
  final String label;
  final double confidence;
  final List<MapEntry<String, double>> topK;
}

/// Runs the trained weather image classifier fully on-device — no network
/// call, works offline. This is the integration that was missing: the
/// model itself was trained and exported (see the ML training notebook),
/// but nothing in the app called it until this file.
///
/// CRITICAL preprocessing note, read before touching this file:
/// The training notebook applies `tf.keras.applications.efficientnet.preprocess_input`
/// to inputs before they reach the model. In current TensorFlow/Keras, EfficientNet's
/// `preprocess_input` is a PASS-THROUGH (identity function) — EfficientNet's own first
/// layers already include a Rescaling(1/255) + Normalization step baked into the model
/// graph itself, unlike ResNet/VGG-style preprocessing which does external mean
/// subtraction. That means this Dart code should feed the model RAW pixel values in
/// [0, 255] as float32 — NOT normalized to [-1, 1] or [0, 1] — because the model already
/// normalizes internally.
///
/// This is stated with confidence but not 100% certainty for every TF version — if
/// classifications come back looking close to random (roughly 1/14 chance per class,
/// so confidently wrong or evenly spread confidences), the first thing to check is
/// exactly this: try normalizing to [0, 1] (divide by 255) as the most likely alternative
/// and see if results improve. Do not guess further than that without checking the
/// actual Colab notebook's preprocessing output on a known test image.
class VisionInferenceService {
  static const _modelAsset = 'assets/models/weathergpt_vision.tflite';
  static const _labelsAsset = 'assets/models/labels.txt';
  static const _imgSize = 224;

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isReady = false;

  bool get isReady => _isReady;

  Future<bool> initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset(_modelAsset);
      final labelsText = await rootBundle.loadString(_labelsAsset);
      _labels = labelsText.split('\n').where((l) => l.trim().isNotEmpty).toList();
      _isReady = true;
      return true;
    } catch (_) {
      // Model assets not bundled yet, or failed to load — degrade gracefully.
      // Callers must check isReady before calling classify() and show a
      // clear "photo classification isn't available" message instead of
      // crashing the chat screen.
      _isReady = false;
      return false;
    }
  }

  Future<VisionClassificationResult?> classify(File imageFile) async {
    if (!_isReady || _interpreter == null) return null;

    try {
      final rawBytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(rawBytes);
      if (decoded == null) return null;

      final resized = img.copyResize(decoded, width: _imgSize, height: _imgSize);

      // Build the input tensor: [1, 224, 224, 3], float32, RAW 0-255 values.
      // See the class doc above for why this is NOT normalized further.
      final input = List.generate(
        1,
        (_) => List.generate(
          _imgSize,
          (y) => List.generate(_imgSize, (x) {
            final pixel = resized.getPixel(x, y);
            return [pixel.r.toDouble(), pixel.g.toDouble(), pixel.b.toDouble()];
          }),
        ),
      );

      final outputShape = _interpreter!.getOutputTensor(0).shape;
      final output = List.generate(outputShape[0], (_) => List.filled(outputShape[1], 0.0));

      _interpreter!.run(input, output);

      final predictions = (output[0] as List<double>);
      final indexed = List.generate(predictions.length, (i) => MapEntry(_labels[i], predictions[i]));
      indexed.sort((a, b) => b.value.compareTo(a.value));

      return VisionClassificationResult(
        label: indexed.first.key,
        confidence: indexed.first.value,
        topK: indexed.take(3).toList(),
      );
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _interpreter?.close();
  }
}
