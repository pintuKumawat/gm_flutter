import 'package:flutter/material.dart';

class MyResponsive {
  static double width(BuildContext context)=>
      MediaQuery.of(context).size.width;

  static double height(BuildContext context)=>
      MediaQuery.of(context).size.height;

  /// Generic value picker
  static T value<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    double width = MediaQuery.of(context).size.width;

    if (width >= 1024) {
      return desktop ?? tablet ?? mobile;
    } else if (width >= 600) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }

  /// Grid auto-fit (best method)
  static SliverGridDelegate gridDelegate({
    required double itemWidth,
    double crossSpacing = 10,
    double mainSpacing = 10,
    double aspectRatio = 0.75,
  }) {
    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: itemWidth,
      crossAxisSpacing: crossSpacing,
      mainAxisSpacing: mainSpacing,
      childAspectRatio: aspectRatio,
    );
  }
}