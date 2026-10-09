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
              // Coupon Cards List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _coupons.length,
                separatorBuilder: (_, _) => 12.height,
                itemBuilder: (context, index) {
                  final coupon = _coupons[index];
                  
                  // Define distinct vibrant themes for each coupon
                  final List<Map<String, Color>> ticketThemes = [
                    {
                      'primary': const Color(0xFF19408C), // Blue
                      'highlight': const Color(0xFF4A80F5),
                      'dot': const Color(0xFFD6EEFB),
                    },
                    {
                      'primary': const Color(0xFF4C1D95), // Purple
                      'highlight': const Color(0xFF8B5CF6),
                      'dot': const Color(0xFFE9D5FF),
                    },
                    {
                      'primary': const Color(0xFF9A3412), // Orange
                      'highlight': const Color(0xFFF97316),
                      'dot': const Color(0xFFFFEDD5),
                    },
                    {
                      'primary': const Color(0xFF064E3B), // Green
                      'highlight': const Color(0xFF10B981),
                      'dot': const Color(0xFFD1FAE5),
                    },
                  ];
                  
                  final theme = ticketThemes[index % ticketThemes.length];
                  final Color primaryColor = theme['primary']!;
                  final Color highlightColor = theme['highlight']!;
                  final Color dotColor = theme['dot']!;
                  final Color textColor = theme['primary']!;
                  
                  return ClipPath(
                    clipper: TicketClipper(),
                    child: Container(
                      height: 125.h,
                      color: Colors.white,
                      child: Row(
                        children: [
                          // Left Section
                          Container(
                            width: 85.w,
                            color: primaryColor,
                            child: Padding(
                              padding: EdgeInsets.all(8.w),
                              child: CustomPaint(
                                painter: DashedRectPainter(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  strokeWidth: 1.5,
                                  dashWidth: 6.0,
                                  dashSpace: 4.0,
                                ),
                                child: Center(
                                  child: RotatedBox(
                                    quarterTurns: 3,
                                    child: Text(
                                      'DISCOUNT\nCOUPON',
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.plusJakartaSans(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 1.2,
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Right Section
                          Expanded(
                            child: CustomPaint(
                              painter: DottedBackgroundPainter(
                                color: dotColor,
                              ),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'VOUCHER SHOPPING',
                                      style: AppTextStyles.plusJakartaSans(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w900,
                                        color: textColor,
                                        letterSpacing: 0.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    4.height,
                                    Text(
                                      coupon['discount']!,
                                      style: AppTextStyles.plusJakartaSans(
                                        fontSize: 26.sp,
                                        fontWeight: FontWeight.w900,
                                        color: highlightColor,
                                        height: 1.0,
                                      ),
                                      maxLines: 1,
                                    ),
                                    6.height,
                                    InkWell(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: coupon['code']!));
                                        HapticFeedback.selectionClick();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Coupon code ${coupon['code']} copied!'),
                                            duration: const Duration(milliseconds: 1500),
                                            backgroundColor: primaryColor,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8.r),
                                            ),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(4.r),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4.r),
                                          border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              coupon['code']!,
                                              style: AppTextStyles.plusJakartaSans(
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.w800,
                                                color: primaryColor,
                                              ),
                                            ),
                                            6.width,
                                            Icon(
                                              Icons.copy_rounded,
                                              size: 11.sp,
                                              color: primaryColor,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    6.height,
                                    CustomPaint(
                                      painter: DashedRectPainter(
                                        color: primaryColor,
                                        strokeWidth: 1.0,
                                        dashWidth: 4.0,
                                        dashSpace: 3.0,
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                                        child: Column(
                                          children: [
                                            Text(
                                              'VALID UNTIL: ${coupon['expiry']!.replaceAll('Valid ', '').toUpperCase()}',
                                              style: AppTextStyles.plusJakartaSans(
                                                fontSize: 7.sp,
                                                fontWeight: FontWeight.w800,
                                                color: primaryColor,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                            ),
                                            2.height,
                                            Text(
                                              'WWW.GRAHMITRA.IN',
                                              style: AppTextStyles.plusJakartaSans(
                                                fontSize: 6.sp,
                                                fontWeight: FontWeight.w700,
                                                color: primaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

class TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    
    // Top edge scalloped
    int scallops = 15;
    double scallopWidth = size.width / scallops;
    path.lineTo(0, 0);
    for (int i = 0; i < scallops; i++) {
      path.arcToPoint(
        Offset(scallopWidth * (i + 1), 0),
        radius: Radius.circular(scallopWidth / 2),
        clockwise: true,
      );
    }
    
    // Right edge with center cutout
    path.lineTo(size.width, size.height / 2 - 15);
    path.arcToPoint(
      Offset(size.width, size.height / 2 + 15),
      radius: const Radius.circular(15),
      clockwise: true,
    );
    path.lineTo(size.width, size.height);
    
    // Bottom edge scalloped
    for (int i = scallops; i > 0; i--) {
      path.arcToPoint(
        Offset(scallopWidth * (i - 1), size.height),
        radius: Radius.circular(scallopWidth / 2),
        clockwise: true,
      );
    }
    
    // Left edge with center cutout
    path.lineTo(0, size.height / 2 + 15);
    path.arcToPoint(
      Offset(0, size.height / 2 - 15),
      radius: const Radius.circular(15),
      clockwise: true,
    );
    path.lineTo(0, 0);
    
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedRectPainter({
    this.color = Colors.white,
    this.strokeWidth = 2.0,
    this.dashWidth = 6.0,
    this.dashSpace = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Draw dashed rectangle
    _drawDashedLine(canvas, paint, const Offset(0, 0), Offset(size.width, 0)); // Top
    _drawDashedLine(canvas, paint, Offset(size.width, 0), Offset(size.width, size.height)); // Right
    _drawDashedLine(canvas, paint, Offset(size.width, size.height), Offset(0, size.height)); // Bottom
    _drawDashedLine(canvas, paint, Offset(0, size.height), const Offset(0, 0)); // Left
  }

  void _drawDashedLine(Canvas canvas, Paint paint, Offset start, Offset end) {
    var length = (end - start).distance;
    var direction = (end - start) / length;
    var currentPoint = start;

    while (length > 0) {
      var drawLength = dashWidth < length ? dashWidth : length;
      canvas.drawLine(currentPoint, currentPoint + direction * drawLength, paint);
      length -= (dashWidth + dashSpace);
      currentPoint += direction * (dashWidth + dashSpace);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DottedBackgroundPainter extends CustomPainter {
  final Color color;

  DottedBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    double spacing = 16.0;
    double rowSpacing = spacing * 0.866; // Perfect hexagonal staggered grid
    double radius = 2.5;

    // Draw slightly past the edges to ensure complete coverage
    for (double y = 0; y <= size.height + rowSpacing; y += rowSpacing) {
      for (double x = 0; x <= size.width + spacing; x += spacing) {
        // Offset alternate rows for a staggered dot pattern
        double offsetX = (y / rowSpacing).round() % 2 == 0 ? 0 : spacing / 2;
        canvas.drawCircle(Offset(x + offsetX, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
