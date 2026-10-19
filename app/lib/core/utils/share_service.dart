import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Thin wrapper over share_plus so screens can be tested with a fake.
abstract class ShareService {
  Future<void> shareText(String text, {String? subject});

  Future<void> shareImage(
    Uint8List png, {
    required String fileName,
    String? text,
  });
}

class SharePlusService implements ShareService {
  const SharePlusService();

  @override
  Future<void> shareText(String text, {String? subject}) async {
    await SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }

  @override
  Future<void> shareImage(
    Uint8List png, {
    required String fileName,
    String? text,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        files: [XFile.fromData(png, mimeType: 'image/png', name: fileName)],
        fileNameOverrides: [fileName],
      ),
    );
  }
}

final shareServiceProvider = Provider<ShareService>(
  (ref) => const SharePlusService(),
);
