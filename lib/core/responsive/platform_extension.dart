import 'package:flutter/material.dart';

class AppBreakpoints {
  static const double smallMobile = 360;
  static const double mobile = 600;
  static const double tablet = 768;
  static const double largeTablet = 1024;
  static const double laptop = 1280;
  static const double desktop = 1440;
}

extension PlatformExtensions on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;

  bool get isSmallMobile => screenWidth < AppBreakpoints.smallMobile;

  bool get isMobile =>
      screenWidth >= AppBreakpoints.smallMobile &&
      screenWidth < AppBreakpoints.mobile;

  bool get isSmallTablet =>
      screenWidth >= AppBreakpoints.mobile &&
      screenWidth < AppBreakpoints.tablet;

  bool get isTablet =>
      screenWidth >= AppBreakpoints.tablet &&
      screenWidth < AppBreakpoints.largeTablet;

  bool get isSmallLaptop =>
      screenWidth >= AppBreakpoints.largeTablet &&
      screenWidth < AppBreakpoints.laptop;

  bool get isLaptop =>
      screenWidth >= AppBreakpoints.laptop &&
      screenWidth < AppBreakpoints.desktop;

  bool get isDesktop => screenWidth >= AppBreakpoints.desktop;
}
