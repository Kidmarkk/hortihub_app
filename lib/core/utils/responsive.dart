import 'package:flutter/material.dart';

class Responsive {
  static bool isVerySmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 480;
  }

  static bool isMediumScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 480 && MediaQuery.of(context).size.width < 768;
  }

  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 768;
  }

  static double getResponsiveFontSize(BuildContext context, {double baseSize = 14}) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return baseSize * 0.7;
    if (width < 480) return baseSize * 0.85;
    if (width < 768) return baseSize * 0.95;
    return baseSize;
  }

  static double getResponsivePadding(BuildContext context, {double basePadding = 16}) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return basePadding * 0.5;
    if (width < 480) return basePadding * 0.7;
    if (width < 768) return basePadding * 0.9;
    return basePadding;
  }

  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 1;
    if (width < 480) return 2;
    if (width < 768) return 3;
    return 4;
  }
}