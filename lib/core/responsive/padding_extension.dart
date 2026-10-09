import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

extension PaddingExtensions on num {
  EdgeInsets get all => EdgeInsets.all(ScreenUtil().setWidth(toDouble()));
  EdgeInsets get horizontal =>
      EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(toDouble()));
  EdgeInsets get vertical =>
      EdgeInsets.symmetric(vertical: ScreenUtil().setHeight(toDouble()));
  EdgeInsets hv(double v) => EdgeInsets.symmetric(
    horizontal: ScreenUtil().setWidth(toDouble()),
    vertical: ScreenUtil().setHeight(v),
  );
}
