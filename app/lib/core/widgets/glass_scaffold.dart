import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Scaffold with the mockup canvas: 170deg cream->mint linear gradient under
/// three radial blobs (spec §1.2). Blobs are painted, no ImageFilter.
class GlassScaffold extends StatelessWidget {
  const GlassScaffold({
    super.key,
    this.appBar,
    this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.safeArea = true,
  });

  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.background),
      child: Stack(
        children: [
          const Positioned.fill(child: CanvasBlobs()),
          Scaffold(
            backgroundColor: Colors.transparent,
            extendBody: true,
            appBar: appBar,
            body: safeArea && body != null
                ? SafeArea(bottom: false, child: body!)
                : body,
            bottomNavigationBar: bottomNavigationBar,
            floatingActionButton: floatingActionButton,
          ),
        ],
      ),
    );
  }
}

/// One CSS `radial-gradient(circle at x% y%, color 0, transparent r%)`.
/// [x]/[y] are fractions of the box; [stop] is the fraction of the
/// farthest-corner distance where the color has faded out.
class BlobSpec {
  const BlobSpec(this.x, this.y, this.stop, this.color);
  final double x;
  final double y;
  final double stop;
  final Color color;
}

/// Mockup blob positions: (8%,4%) peach 40%, (96%,30%) coral 42%,
/// (18%,92%) mint 46%.
const List<BlobSpec> canvasBlobs = [
  BlobSpec(0.08, 0.04, 0.40, AppColors.blobPeach),
  BlobSpec(0.96, 0.30, 0.42, AppColors.blobCoral),
  BlobSpec(0.18, 0.92, 0.46, AppColors.blobMint),
];

class CanvasBlobs extends StatelessWidget {
  const CanvasBlobs({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: CustomPaint(painter: _BlobPainter(canvasBlobs)),
    );
  }
}

class _BlobPainter extends CustomPainter {
  const _BlobPainter(this.blobs);
  final List<BlobSpec> blobs;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    for (final b in blobs) {
      final c = Offset(b.x * size.width, b.y * size.height);
      final farthest = math.sqrt(
        math.pow(math.max(c.dx, size.width - c.dx), 2) +
            math.pow(math.max(c.dy, size.height - c.dy), 2),
      );
      final r = farthest * b.stop;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [b.color, b.color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: c, radius: r));
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.blobs != blobs;
}
