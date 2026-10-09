import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/core/responsive/responsive.dart';
import 'package:grahmitracus/models/product/home_product_model.dart';

/// Clean, modern Product Card matching Next.js Frontend Product.js
///
/// Features:
/// - Green top-left discount tag with curved corner (`#0C831F`)
/// - Top-right circular Premium badge / Trending pill / Featured pill
/// - High-res product image with drop shadow & fallback
/// - Brand & Subcategory uppercase header (`BRAND • SUBCATEGORY`)
/// - 2-line title case Product Title
/// - Purple Weight / Variation Pill + Red Low Stock Alert Pill (`Only X left!`)
/// - Price display (Bold Sell Price + Strikethrough MRP)
/// - Interactive Add to Cart button (Purple `ADD | [Cart]` -> Green `[-] [Qty] [+]`)
class ProductCard extends StatelessWidget {
  final HomeProductModel product;
  final int quantity;
  final ValueChanged<int>? onQuantityChanged;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.quantity = 0,
    this.onQuantityChanged,
    this.onTap,
  });

  String _toTitleCase(String? str) {
    if (str == null || str.isEmpty) return '';
    return str
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  String _formatPrice(double price) {
    if (price == price.roundToDouble()) {
      return price.toInt().toString();
    }
    return price.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final discountPercent = product.discountPercent;
    final isSoldOut = product.isSoldOut;
    final sellPrice = product.sellPrice;
    final mrpPrice = product.mrpPrice;
    final imgUrl = product.imgPath;
    final weightText = product.weightText;
    final brand = product.brand;
    final subcategory = product.subcategory;
    final isLowStock = product.stockQuantity > 0 && product.stockQuantity <= 5;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7.5.r),
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.brandPurple.withValues(alpha: 0.05),
          highlightColor: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Stack: Image + Discount Tag + Badges
              Stack(
                children: [
                  // Product Image Area
                  Container(
                    height: 84.h,
                    width: double.infinity,
                    color: const Color(0xFFF8FAFC),
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 4.h,
                    ),
                    child: (imgUrl != null && imgUrl.isNotEmpty)
                        ? Image.network(
                            imgUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildImageFallback(),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: SizedBox(
                                  width: 16.w,
                                  height: 16.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.brandPurple.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : _buildImageFallback(),
                  ),

                  // Top-Left Discount Tag (#0C831F)
                  if (discountPercent > 0)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0C831F),
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(10.r),
                          ),
                        ),
                        child: Text(
                          '$discountPercent% OFF',
                          style: AppTextStyles.plusJakartaSans(
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ),

                  // Top-Right Badges
                  if (product.isPremium == 1)
                    Positioned(
                      top: 5.h,
                      right: 5.w,
                      child: Container(
                        width: 26.w,
                        height: 26.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF5FF),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xFFE9D5FF,
                            ).withValues(alpha: 0.8),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF7C3AED,
                              ).withValues(alpha: 0.08),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 9.sp,
                              color: const Color(0xFF7C3AED),
                            ),
                            Text(
                              'Premium',
                              style: AppTextStyles.plusJakartaSans(
                                fontSize: 5.sp,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF6B21A8),
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (product.isTrending == 1)
                    Positioned(
                      top: 5.h,
                      right: 5.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 5.w,
                          vertical: 1.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA580C),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          'TRENDING',
                          style: AppTextStyles.plusJakartaSans(
                            fontSize: 6.5.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    )
                  else if (product.isFeatured == 1)
                    Positioned(
                      top: 5.h,
                      right: 5.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 5.w,
                          vertical: 1.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          'FEATURED',
                          style: AppTextStyles.plusJakartaSans(
                            fontSize: 6.5.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Content Area
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 6.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            // Brand & Subcategory Header (e.g., FORTUNE • OILS)
                            SizedBox(
                              height: 11.h,
                              child: ((brand != null && brand.isNotEmpty) ||
                                      (subcategory != null && subcategory.isNotEmpty))
                                  ? Padding(
                                      padding: EdgeInsets.only(bottom: 2.h),
                                      child: Text(
                                        [
                                          if (brand != null && brand.isNotEmpty)
                                            brand.toUpperCase(),
                                          if (subcategory != null &&
                                              subcategory.isNotEmpty)
                                            subcategory.toUpperCase(),
                                        ].join(' • '),
                                        style: AppTextStyles.plusJakartaSans(
                                          fontSize: 7.5.sp,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF64748B),
                                          letterSpacing: 0.4,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),

                            // Product Title
                            SizedBox(
                              height: 29.h,
                              child: Text(
                                _toTitleCase(product.title),
                                style: AppTextStyles.plusJakartaSans(
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E293B),
                                  height: 1.15,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            const Spacer(),
                            2.height,

                            // Pills Row: Weight/Variation + Low Stock
                            Row(
                              children: [
                                // Weight Pill
                                Flexible(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4.5.w,
                                      vertical: 1.2.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFAF5FF),
                                      borderRadius: BorderRadius.circular(4.r),
                                      border: Border.all(
                                        color: const Color(0xFFE9D5FF),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.shopping_bag_outlined,
                                          size: 7.5.sp,
                                          color: const Color(0xFF7E22CE),
                                        ),
                                        2.5.width,
                                        Flexible(
                                          child: Text(
                                            _toTitleCase(weightText),
                                            style:
                                                AppTextStyles.plusJakartaSans(
                                                  fontSize: 7.5.sp,
                                                  fontWeight: FontWeight.w800,
                                                  color: const Color(
                                                    0xFF6B21A8,
                                                  ),
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Low Stock Warning Pill
                                if (isLowStock) ...[
                                  3.width,
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4.w,
                                      vertical: 1.2.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(4.r),
                                      border: Border.all(
                                        color: const Color(0xFFFECACA),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      'Only ${product.stockQuantity} left!',
                                      style: AppTextStyles.plusJakartaSans(
                                        fontSize: 6.5.sp,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFDC2626),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      5.height,

                      // Price & Add to Cart Row (Pinned close to weight pill)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Pricing (Sell Price & MRP)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '₹${_formatPrice(sellPrice)}',
                                  style: AppTextStyles.plusJakartaSans(
                                    fontSize: 12.5.sp,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF0F172A),
                                    height: 1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (mrpPrice > sellPrice) ...[
                                  1.5.height,
                                  Text(
                                    '₹${_formatPrice(mrpPrice)}',
                                    style: AppTextStyles.plusJakartaSans(
                                      fontSize: 8.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF94A3B8),
                                      decoration: TextDecoration.lineThrough,
                                      height: 1,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          4.width,

                          // Action Button: Sold Out / Add with Cart Icon / Quantity Stepper
                          _buildActionButton(context, isSoldOut),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Action Button: Sold Out / Purple ADD | [Cart] / Green Quantity Stepper
  Widget _buildActionButton(BuildContext context, bool isSoldOut) {
    if (isSoldOut) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          'SOLD OUT',
          style: AppTextStyles.plusJakartaSans(
            fontSize: 8.5.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF94A3B8),
          ),
        ),
      );
    }

    if (quantity <= 0) {
      // Purple "ADD | [Cart]" Button
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onQuantityChanged?.call(1);
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 5.5.w, vertical: 3.5.h),
          decoration: BoxDecoration(
            color: AppColors.brandPurple,
            borderRadius: BorderRadius.circular(7.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandPurple.withValues(alpha: 0.28),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ADD',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 3.5.w),
                width: 1,
                height: 9.h,
                color: Colors.white.withValues(alpha: 0.4),
              ),
              Icon(
                Icons.shopping_cart_outlined,
                size: 10.sp,
                color: Colors.white,
              ),
            ],
          ),
        ),
      );
    }

    // Green Qty Stepper (#168a35)
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF168A35),
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF168A35).withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onQuantityChanged?.call(quantity - 1);
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.5.h),
              child: Icon(
                Icons.remove_rounded,
                color: Colors.white,
                size: 11.5.sp,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: Text(
              '$quantity',
              style: AppTextStyles.plusJakartaSans(
                fontSize: 9.5.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onQuantityChanged?.call(quantity + 1);
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.5.h),
              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 11.5.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageFallback() {
    return Center(
      child: Icon(
        Icons.shopping_basket_outlined,
        size: 38.sp,
        color: AppColors.brandPurple.withValues(alpha: 0.4),
      ),
    );
  }
}
