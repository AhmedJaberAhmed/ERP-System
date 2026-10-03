import 'package:flutter/material.dart';

/// Material 3 window-size classes.
enum ScreenSize { compact, medium, expanded }

class Responsive {
  Responsive._();

  /// Widest the app content ever gets; on tablets/desktop/web it is centred.
  static const double maxContentWidth = 1080;

  static ScreenSize of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  static ScreenSize fromWidth(double w) {
    if (w < 600) return ScreenSize.compact; // phones
    if (w < 900) return ScreenSize.medium; // large phones / small tablets
    return ScreenSize.expanded; // tablets, desktop, web
  }
}

/// Wrap the whole app (MaterialApp.builder) so that:
///  * content is centred and capped to [Responsive.maxContentWidth],
///  * system text scaling is clamped so layouts never overflow,
///  * the area around the content uses the page background.
class AppViewport extends StatelessWidget {
  const AppViewport({super.key, required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final scale = mq.textScaler.clamp(
      minScaleFactor: 0.9,
      maxScaleFactor: 1.3,
    );

    return MediaQuery(
      data: mq.copyWith(textScaler: scale),
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Responsive.maxContentWidth),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
