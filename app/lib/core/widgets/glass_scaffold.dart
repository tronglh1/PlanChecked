import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Scaffold with the cream->mint gradient and soft blurred color blobs.
/// Blobs are painted as radial gradients (no ImageFilter) so they stay cheap.
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
          const Positioned.fill(child: _Blobs()),
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

class _Blobs extends StatelessWidget {
  const _Blobs();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Stack(
        children: [
          _Blob(
            alignment: Alignment(-1.1, -0.9),
            size: 320,
            color: AppColors.blobYellow,
          ),
          _Blob(
            alignment: Alignment(1.2, -0.2),
            size: 300,
            color: AppColors.blobPeach,
          ),
          _Blob(
            alignment: Alignment(-0.8, 1.0),
            size: 360,
            color: AppColors.blobMint,
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.alignment,
    required this.size,
    required this.color,
  });

  final Alignment alignment;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.85), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
