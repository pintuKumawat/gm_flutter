import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

extension CustomSizeBoxExtensions on num {
  SizedBox get height => SizedBox(height: ScreenUtil().setHeight(toDouble()));
  SizedBox get width => SizedBox(width: ScreenUtil().setWidth(toDouble()));
}
