import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/core/responsive/responsive.dart';
import 'package:grahmitracus/providers/location/location_provider.dart';
import 'package:grahmitracus/screens/location/location_picker_screen.dart';

/// Reusable Delivery Location Banner / Section component used on both Home and Cart screens.
///
/// Behavior:
/// 1. Synchronized with the shared [LocationProvider].
/// 2. If no location has been selected ([LocationProvider.hasSelectedLocation] is false),
///    displays the amber "Set your delivery location" banner with a "Choose location" action.
/// 3. If a location is selected:
///    - When [showSelectedLocation] is true (default on Cart screen):
///      displays the Fast Delivery card showing the selected location address with a "Change" action.
///    - When [showSelectedLocation] is false (default on Home screen):
///      returns [SizedBox.shrink()] because the Home screen top bar already displays the location.
/// 4. Tapping either the action button or the container opens [LocationPickerScreen].
class DeliveryLocationBanner extends StatelessWidget {
  final bool showSelectedLocation;
  final VoidCallback? onLocationTap;
  final EdgeInsetsGeometry? margin;

  const DeliveryLocationBanner({
    super.key,
    this.showSelectedLocation = false,
    this.onLocationTap,
    this.margin,
  });

  static void openLocationPicker(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationProv = context.watch<LocationProvider>();
    final hasLocation = locationProv.hasSelectedLocation &&
        locationProv.currentLocation.displayString.trim().isNotEmpty;
    final handleTap = onLocationTap ?? () => openLocationPicker(context);

    if (hasLocation) {
      if (!showSelectedLocation) {
        return const SizedBox.shrink();
      }

      final address = locationProv.currentLocation.displayString.trim();

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: handleTap,
        child: Container(
          color: Colors.white,
          margin: margin,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFEF08A), Color(0xFFFDE047)],
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  color: const Color(0xFF854D0E),
                  size: 20.sp,
                ),
              ),
              12.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Fast Delivery',
                          style: AppTextStyles.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        6.width,
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 5.w,
                            vertical: 1.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            'FAST',
                            style: AppTextStyles.plusJakartaSans(
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    3.height,
                    Text(
                      address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              8.width,
              InkWell(
                onTap: handleTap,
                child: Text(
                  'Change',
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandPurple,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Unselected state: Display the Home screen's "Set your delivery location" banner
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: handleTap,
      child: Container(
        width: double.infinity,
        margin: margin ?? EdgeInsets.only(bottom: 4.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.locationBannerBg,
          border: Border(
            top: BorderSide(color: AppColors.locationBannerBorder, width: 1.w),
            bottom: BorderSide(color: AppColors.locationBannerBorder, width: 1.w),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 20.sp,
              color: AppColors.locationBannerText,
            ),
            8.width,
            Expanded(
              child: Text(
                'Set your delivery location',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.locationBannerText,
                ),
              ),
            ),
            8.width,
            InkWell(
              onTap: handleTap,
              borderRadius: BorderRadius.circular(8.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: const Color(0xFFFDE68A),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF854D0E).withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  'Choose location',
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.locationBannerText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
