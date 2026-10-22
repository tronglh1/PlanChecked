import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-app live camera behind a small interface so widget tests never touch the
/// real plugin. One instance = one init/dispose cycle.
abstract class CheckinCamera {
  /// Opens the rear camera. Throws when permission is denied or there is no
  /// usable camera.
  Future<void> initialize();

  /// Takes a still photo and returns its JPEG bytes.
  Future<Uint8List> capture();

  /// Width / height of the preview as displayed (portrait: < 1).
  double get previewAspect;

  /// The live preview, unsized; the caller scales and crops it.
  Widget buildPreview();

  Future<void> dispose();
}

class PluginCheckinCamera implements CheckinCamera {
  CameraController? _controller;

  CameraController get _c {
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      throw StateError('Camera is not initialized');
    }
    return c;
  }

  @override
  Future<void> initialize() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) throw StateError('No camera available');
    final desc = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    final controller = CameraController(
      desc,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _controller = controller;
    await controller.initialize();
    try {
      await controller.setFlashMode(FlashMode.off);
    } catch (_) {
      // Not every camera supports setting the flash mode; off is the default.
    }
  }

  @override
  Future<Uint8List> capture() async => (await _c.takePicture()).readAsBytes();

  @override
  double get previewAspect {
    final v = _c.value;
    final landscape =
        v.deviceOrientation == DeviceOrientation.landscapeLeft ||
        v.deviceOrientation == DeviceOrientation.landscapeRight;
    return landscape ? v.aspectRatio : 1 / v.aspectRatio;
  }

  @override
  Widget buildPreview() => CameraPreview(_c);

  @override
  Future<void> dispose() async {
    final c = _controller;
    _controller = null;
    await c?.dispose();
  }
}

/// Creates a fresh camera per init cycle. Overridden in tests.
final checkinCameraFactoryProvider = Provider<CheckinCamera Function()>(
  (ref) => PluginCheckinCamera.new,
);
