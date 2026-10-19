/// Client-side image pipeline for check-in photos (CHK-02, CHK-06). Pure
/// Dart (package:image) so it can run in an isolate via `compute` and be unit
/// tested without a device.
///
/// Steps: decode, bake EXIF orientation, resize to a 768 px long edge, drop
/// every EXIF/GPS tag, re-encode as JPEG, and measure blur and brightness on
/// a small grayscale copy.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as img;

/// Longest side of the uploaded JPEG (AI doc: 768 px).
const int kUploadLongestSide = 768;

/// JPEG quality of the uploaded file (task brief: about 80).
const int kUploadJpegQuality = 80;

/// Longest side of the grayscale copy used for blur / brightness checks.
const int kAnalysisLongestSide = 256;

/// Variance of the Laplacian below this value counts as blurry. Measured on
/// the 256 px grayscale copy (0..255 luma). Tune with real photos.
const double kBlurVarianceThreshold = 40;

/// Mean luma (0..255) below this value counts as too dark.
const double kDarkMeanLuma = 45;

enum ImageIssue { blur, dark, unreadable }

class ProcessedImage {
  const ProcessedImage({
    required this.jpeg,
    required this.width,
    required this.height,
    required this.blurScore,
    required this.brightness,
    this.issue,
  });

  const ProcessedImage.unreadable()
    : jpeg = null,
      width = 0,
      height = 0,
      blurScore = 0,
      brightness = 0,
      issue = ImageIssue.unreadable;

  /// Upload-ready bytes; null when the input could not be decoded.
  final Uint8List? jpeg;
  final int width;
  final int height;

  /// Variance of the Laplacian (higher is sharper).
  final double blurScore;

  /// Mean luma 0..255.
  final double brightness;
  final ImageIssue? issue;

  bool get ok => issue == null;
}

/// Variance of the 4-neighbour Laplacian of a grayscale buffer
/// (`gray.length == width * height`). 0 for images smaller than 3x3.
double laplacianVariance(Uint8List gray, int width, int height) {
  if (width < 3 || height < 3) return 0;
  var sum = 0.0;
  var sumSq = 0.0;
  var n = 0;
  for (var y = 1; y < height - 1; y++) {
    final row = y * width;
    for (var x = 1; x < width - 1; x++) {
      final i = row + x;
      final v =
          4 * gray[i] -
          gray[i - 1] -
          gray[i + 1] -
          gray[i - width] -
          gray[i + width];
      sum += v;
      sumSq += v * v;
      n++;
    }
  }
  final mean = sum / n;
  return sumSq / n - mean * mean;
}

/// Mean of a grayscale buffer.
double meanLuma(Uint8List gray) {
  if (gray.isEmpty) return 0;
  var s = 0;
  for (final v in gray) {
    s += v;
  }
  return s / gray.length;
}

Uint8List _grayscaleBytes(img.Image image) {
  final out = Uint8List(image.width * image.height);
  var i = 0;
  for (final p in image) {
    out[i++] = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round().clamp(0, 255);
  }
  return out;
}

img.Image _fitLongest(img.Image src, int longest) {
  final w = src.width;
  final h = src.height;
  if (math.max(w, h) <= longest) return src;
  return w >= h
      ? img.copyResize(
          src,
          width: longest,
          interpolation: img.Interpolation.average,
        )
      : img.copyResize(
          src,
          height: longest,
          interpolation: img.Interpolation.average,
        );
}

/// Runs the whole pipeline synchronously. Prefer [processCheckinImage] in UI
/// code (isolate).
ProcessedImage processImageBytes(Uint8List input) {
  final img.Image? decoded;
  try {
    decoded = img.decodeImage(input);
  } catch (_) {
    return const ProcessedImage.unreadable();
  }
  if (decoded == null) return const ProcessedImage.unreadable();

  final oriented = img.bakeOrientation(decoded);
  final resized = _fitLongest(oriented, kUploadLongestSide);
  // Drop EXIF (GPS, device, timestamps): encodeJpg writes whatever `exif`
  // holds.
  resized.exif = img.ExifData();
  resized.iccProfile = null;
  resized.textData = null;
  final jpeg = Uint8List.fromList(
    img.encodeJpg(resized, quality: kUploadJpegQuality),
  );

  final small = _fitLongest(resized, kAnalysisLongestSide);
  final gray = _grayscaleBytes(small);
  final brightness = meanLuma(gray);
  final blur = laplacianVariance(gray, small.width, small.height);

  ImageIssue? issue;
  if (brightness < kDarkMeanLuma) {
    issue = ImageIssue.dark;
  } else if (blur < kBlurVarianceThreshold) {
    issue = ImageIssue.blur;
  }
  return ProcessedImage(
    jpeg: jpeg,
    width: resized.width,
    height: resized.height,
    blurScore: blur,
    brightness: brightness,
    issue: issue,
  );
}

/// [processImageBytes] in a background isolate.
Future<ProcessedImage> processCheckinImage(Uint8List input) =>
    compute(processImageBytes, input);
