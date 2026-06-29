import 'package:flutter/material.dart';

class ResponsiveHelper {
  // Common breakpoints
  static const double mobileSmall = 360;
  static const double mobileMedium = 420;
  static const double tablet = 600;

  static bool isSmallPhone(BuildContext context) {
    return MediaQuery.sizeOf(context).width <= mobileSmall;
  }

  static bool isMediumPhone(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width > mobileSmall && width <= mobileMedium;
  }

  static bool isLargePhone(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width > mobileMedium && width < tablet;
  }

  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= tablet;
  }

  /// Calculates a reasonable grid aspect ratio based on screen width.
  /// For instance, on very wide screens the items might stretch too much
  /// if the ratio is static, and on very narrow screens they'd be squished.
  static double getGridAspectRatio(BuildContext context, {int crossAxisCount = 2, double itemHeight = 120}) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = 32.0; // Assume standard padding around grid
    final spacing = (crossAxisCount - 1) * 10.0; // Assume 10px spacing
    
    final availableWidth = width - horizontalPadding - spacing;
    final itemWidth = availableWidth / crossAxisCount;
    
    // Calculate aspect ratio: width / height
    return itemWidth / itemHeight;
  }

  /// Returns constrained width for dialogs so they don't stretch fully on tablets
  static double getDialogWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= tablet) {
      return 500.0;
    }
    return width * 0.9;
  }
}
