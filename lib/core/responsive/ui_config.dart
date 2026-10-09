import 'package:flutter/material.dart';
import 'package:grahmitracus/core/responsive/my_responsive.dart';



class UIConfig {
  static double cardAspectRatio(BuildContext context) {
    return MyResponsive.value(
      context: context,
      mobile: 3.5,
      tablet: 2.75,
      desktop: 3.7,
    );
  }

  static double imageHeight(BuildContext context) {
    return MyResponsive.value(
      context: context,
      mobile: 180,
      tablet: 220,
      desktop: 260,
    );
  }

  static int categoryCount(BuildContext context) {
    return MyResponsive.value(
      context: context,
      mobile: 4,
      tablet: 6,
      desktop: 8,
    );
  }
}
