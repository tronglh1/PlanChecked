import 'package:flutter/widgets.dart';

/// Provides the app-wide "blur enabled" flag so low-end devices can turn off
/// BackdropFilter. Widgets may override with their own `blur` parameter.
class GlassConfig extends InheritedWidget {
  const GlassConfig({super.key, required this.blur, required super.child});

  final bool blur;

  static bool blurOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GlassConfig>()?.blur ?? true;

  @override
  bool updateShouldNotify(GlassConfig oldWidget) => blur != oldWidget.blur;
}
