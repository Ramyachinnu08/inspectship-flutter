import 'package:flutter/material.dart';

/// Screen-size helpers.
/// Tablet threshold = shortest side >= 600dp (Android tablet convention).
class Responsive {
  static bool isTablet(BuildContext c) =>
      MediaQuery.of(c).size.shortestSide >= 600;

  static bool isLandscape(BuildContext c) =>
      MediaQuery.of(c).orientation == Orientation.landscape;

  /// Content max-width so lines don't stretch too wide on tablets/desktops.
  static double contentMaxWidth(BuildContext c) => isTablet(c) ? 900 : 600;

  /// Scale base font by device.
  static double fontScale(BuildContext c) => isTablet(c) ? 1.10 : 1.0;

  /// Horizontal padding for pages.
  static double pagePad(BuildContext c) => isTablet(c) ? 24 : 16;
}

/// Wraps a scrollable/list with a max-width column so tablet-landscape doesn't
/// stretch cards across the whole screen.
class ConstrainedContent extends StatelessWidget {
  final Widget child;
  const ConstrainedContent({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints:
        BoxConstraints(maxWidth: Responsive.contentMaxWidth(context)),
        child: child,
      ),
    );
  }
}
