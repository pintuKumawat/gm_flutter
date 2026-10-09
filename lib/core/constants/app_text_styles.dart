import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grahmitracus/core/constants/app_colors.dart';
import 'package:grahmitracus/core/responsive/responsive.dart';

/// Centralized typography and text styling definitions for GrahMitra
class AppTextStyles {
  AppTextStyles._();

  // Primary Font (Plus Jakarta Sans)
  static TextStyle plusJakartaSans({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    FontStyle? fontStyle,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
      fontStyle: fontStyle,
    );
  }

  // Secondary / Brand Font (Poppins)
  static TextStyle poppins({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    FontStyle? fontStyle,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
      fontStyle: fontStyle,
    );
  }

  // Common Predefined Styles
  static TextStyle get screenTitle => plusJakartaSans(
        fontSize: 20.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      );

  static TextStyle get sectionTitle => plusJakartaSans(
        fontSize: 16.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      );

  static TextStyle get cardTitle => plusJakartaSans(
        fontSize: 14.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => plusJakartaSans(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => plusJakartaSans(
        fontSize: 13.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodySmall => plusJakartaSans(
        fontSize: 11.5.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get caption => plusJakartaSans(
        fontSize: 10.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textHint,
      );

  static TextStyle get buttonText => plusJakartaSans(
        fontSize: 14.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      );
}
