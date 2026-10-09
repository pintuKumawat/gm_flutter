import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/core/responsive/responsive.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  final List<Map<String, dynamic>> _coupons = const [
    {
      'code': 'GRAHMITRA50',
      'title': 'Flat ₹50 OFF',
      'desc': 'On your first grocery order above ₹299',
      'expiry': 'Valid till 31 Aug',
      'discount': '50 OFF',
    },
    {
      'code': 'FREEDELIVERY',
      'title': 'Free Delivery',
      'desc': 'Free doorstep delivery on orders above ₹199',
      'expiry': 'Valid today',
      'discount': 'FREE DEL',
    },
    {
      'code': 'DAILY20',
      'title': '20% Super Saver',
      'desc': 'Get 20% discount on Daily Needs & Dairy items',
      'expiry': 'Valid on orders > ₹399',
      'discount': '20% OFF',
    },
    {
      'code': 'FESTIVE100',
      'title': 'Festival Mega Savings',
      'desc': 'Save ₹100 on bulk grocery basket above ₹999',
      'expiry': 'Limited period offer',
      'discount': '₹100 OFF',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Offers & Deals',
          style: AppTextStyles.screenTitle,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Offer Banner
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(18.r),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.promoGradientStart,
                      AppColors.promoGradientMiddle,
                      AppColors.promoGradientEnd,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandPurple.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        '🔥 TODAY\'S MEGA DEAL',
                        style: AppTextStyles.plusJakartaSans(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    12.height,
                    Text(
                      'Get Up To 40% OFF\non Household Essentials',
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                        height: 1.25,
                      ),
                    ),
                    6.height,
                    Text(
                      'Use code MEGA40 at checkout',
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),

              24.height,
              Text(
                'Available Coupons',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              12.height,

              // Coupon Cards List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _coupons.length,
                separatorBuilder: (_, _) => 12.height,
                itemBuilder: (context, index) {
                  final coupon = _coupons[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.subtleBackground,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    padding: EdgeInsets.all(14.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 5.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.brandPurple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6.r),
                                border: Border.all(
                                  color: AppColors.brandPurple.withValues(alpha: 0.3),
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.confirmation_number_outlined,
                                    size: 14.sp,
                                    color: AppColors.brandPurple,
                                  ),
                                  6.width,
                                  Text(
                                    coupon['code']!,
                                    style: AppTextStyles.plusJakartaSans(
                                      fontSize: 12.5.sp,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.brandPurple,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Coupon ${coupon['code']} copied!'),
                                    duration: const Duration(milliseconds: 1000),
                                    backgroundColor: AppColors.brandPurple,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                child: Text(
                                  'COPY CODE',
                                  style: AppTextStyles.plusJakartaSans(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.brandOrange,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        10.height,
                        Text(
                          coupon['title']!,
                          style: AppTextStyles.cardTitle,
                        ),
                        4.height,
                        Text(
                          coupon['desc']!,
                          style: AppTextStyles.plusJakartaSans(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        8.height,
                        const Divider(color: AppColors.borderSubtle, height: 1),
                        8.height,
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 13.sp,
                              color: AppColors.iconSubtle,
                            ),
                            4.width,
                            Text(
                              coupon['expiry']!,
                              style: AppTextStyles.plusJakartaSans(
                                fontSize: 11.sp,
                                color: AppColors.textHint,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              20.height,
            ],
          ),
        ),
      ),
    );
  }
}
