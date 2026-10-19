import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:vuon_nha/features/checkin/domain/image_quality.dart';

import '../../helpers/checkin_fakes.dart';

void main() {
  group('resize and re-encode', () {
    test('landscape: longest side 768, aspect kept, valid JPEG', () {
      final p = processImageBytes(jpegOf(sharpImage(1600, 1200)));
      expect(p.width, 768);
      expect(p.height, 576);
      final out = img.decodeJpg(p.jpeg!)!;
      expect(out.width, 768);
      expect(out.height, 576);
      expect(p.jpeg!.sublist(0, 3), [0xFF, 0xD8, 0xFF]);
    });

    test('portrait: height becomes 768', () {
      final p = processImageBytes(jpegOf(sharpImage(1200, 1600)));
      expect(p.width, 576);
      expect(p.height, 768);
    });

    test('small images are not upscaled', () {
      final p = processImageBytes(jpegOf(sharpImage(400, 300)));
      expect(p.width, 400);
      expect(p.height, 300);
    });

    test('EXIF orientation is baked in and metadata is stripped', () {
      final src = sharpImage(800, 400);
      src.exif.imageIfd.make = 'SecretPhoneMaker';
      src.exif.imageIfd.orientation = 6; // rotate 90 deg
      final bytes = jpegOf(src);
      expect(String.fromCharCodes(bytes).contains('SecretPhoneMaker'), isTrue);

      final p = processImageBytes(bytes);
      // 800x400 rotated -> 400x800, then fitted to 768.
      expect(p.width, 384);
      expect(p.height, 768);
      expect(
        String.fromCharCodes(p.jpeg!).contains('SecretPhoneMaker'),
        isFalse,
      );
      final out = img.decodeJpg(p.jpeg!)!;
      expect(out.exif.imageIfd.hasOrientation, isFalse);
      expect(out.exif.imageIfd.hasMake, isFalse);
    });

    test('garbage bytes are reported as unreadable', () {
      final p = processImageBytes(Uint8List.fromList([1, 2, 3, 4]));
      expect(p.issue, ImageIssue.unreadable);
      expect(p.jpeg, isNull);
      expect(p.ok, isFalse);
    });
  });

  group('blur and darkness', () {
    test('sharp synthetic image passes', () {
      final p = processImageBytes(jpegOf(sharpImage(800, 600)));
      expect(p.issue, isNull);
      expect(p.blurScore, greaterThan(kBlurVarianceThreshold * 4));
      expect(p.brightness, inInclusiveRange(90, 170));
    });

    test('a blurred copy scores far lower and is rejected as blur', () {
      final sharp = sharpImage(800, 600);
      final blurred = img.gaussianBlur(sharp.clone(), radius: 24);
      final s = processImageBytes(jpegOf(sharp));
      final b = processImageBytes(jpegOf(blurred));
      expect(b.blurScore, lessThan(s.blurScore / 10));
      expect(b.blurScore, lessThan(kBlurVarianceThreshold));
      expect(b.issue, ImageIssue.blur);
    });

    test('too dark image is rejected as dark', () {
      final p = processImageBytes(jpegOf(darkImage(800, 600)));
      expect(p.brightness, lessThan(kDarkMeanLuma));
      expect(p.issue, ImageIssue.dark);
    });

    test('laplacianVariance is 0 for a flat image and tiny inputs', () {
      expect(
        laplacianVariance(Uint8List(100)..fillRange(0, 100, 77), 10, 10),
        0,
      );
      expect(laplacianVariance(Uint8List(4), 2, 2), 0);
    });

    test('laplacianVariance grows with edges', () {
      final flat = Uint8List(64)..fillRange(0, 64, 100);
      final checker = Uint8List.fromList([
        for (var y = 0; y < 8; y++)
          for (var x = 0; x < 8; x++) (x + y).isEven ? 0 : 255,
      ]);
      expect(
        laplacianVariance(checker, 8, 8),
        greaterThan(laplacianVariance(flat, 8, 8)),
      );
    });
  });
}
