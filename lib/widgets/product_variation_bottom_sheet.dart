import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/core/responsive/responsive.dart';
import 'package:grahmitracus/models/product/product_detail_model.dart';
import 'package:grahmitracus/providers/cart/cart_provider.dart';
import 'package:grahmitracus/repositories/product/product_detail_repo.dart';

class ProductVariationBottomSheet extends StatelessWidget {
  final ProductDetailModel product;

  const ProductVariationBottomSheet({super.key, required this.product});

  static Future<void> handleAddTapped(BuildContext context, String productId) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          color: AppColors.brandPurple,
          strokeWidth: 2.0,
        ),
      ),
    );

    try {
      final repo = ProductDetailRepo();
      print('[PVBS] Fetching product detail for id: $productId');
      final detail = await repo.getProductDetail(productId);
      
      print('[PVBS] detail is null: ${detail == null}');
      if (detail != null) {
        print('[PVBS] title: ${detail.title}');
        print('[PVBS] variations count: ${detail.variations.length}');
        for (final v in detail.variations) {
          print('[PVBS]   variation: id=${v.id}, name=${v.name}, sell=${v.sellPrice}, stock=${v.stockQuantity}');
        }
      }

      // Hide loading indicator
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

      if (detail == null) {
        print('[PVBS] detail is null, nothing to show');
        return;
      }

      if (!context.mounted) {
        print('[PVBS] context not mounted after pop');
        return;
      }

      // Show bottom sheet for ANY number of variations (including 1)
      // so user can always see the weight/packing options
      if (detail.variations.isNotEmpty) {
        print('[PVBS] Showing bottom sheet with ${detail.variations.length} variations');
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          builder: (_) => ProductVariationBottomSheet(product: detail),
        );
      } else {
        // No variations at all — add to cart directly
        print('[PVBS] No variations, adding to cart directly');
        final cart = context.read<CartProvider>();
        cart.addToCart(
          id: detail.id.toString(),
          title: detail.title,
          sellPrice: detail.sellPrice,
          mrpPrice: detail.mrpPrice,
          quantity: 1,
          imageUrl: detail.heroImageUrl,
          weight: detail.variationName,
          category: detail.category,
          storeName: detail.storeName,
          variationId: detail.variationId?.toString(),
          productId: detail.id.toString(),
        );
      }
    } catch (e, st) {
      print('[PVBS] Exception: $e');
      print('[PVBS] Stack: $st');
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop(); // hide loading on error
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──────────────────────────────────────────
          Padding(
            padding: EdgeInsets.only(top: 10.h, bottom: 6.h),
            child: Container(
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header row ───────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 4.h, 4.w, 12.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: product.heroImageUrl != null
                      ? Image.network(
                          product.heroImageUrl!,
                          width: 44.w,
                          height: 44.w,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholderImage(),
                        )
                      : _placeholderImage(),
                ),
                10.width,
                // Product name
                Expanded(
                  child: Text(
                    product.title,
                    style: AppTextStyles.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Close button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32.w,
                    height: 32.w,
                    margin: EdgeInsets.only(left: 4.w),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: const Color(0xFF64748B),
                      size: 16.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Divider + section label ───────────────────────────────
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'SELECT PACKING SIZE / WEIGHT',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),

          // ── Variation list ────────────────────────────────────────
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.only(
                left: 16.w,
                right: 16.w,
                bottom: 8.h,
              ),
              itemCount: product.variations.length,
              itemBuilder: (context, index) {
                final variation = product.variations[index];
                final isLast = index == product.variations.length - 1;
                return _buildVariationRow(context, variation, isLast);
              },
            ),
          ),

          // ── Footer ────────────────────────────────────────────────
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h + bottomPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      size: 13.sp,
                      color: AppColors.brandPurple,
                    ),
                    5.width,
                    Text(
                      'Prices are inclusive of GST',
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.flash_on_rounded,
                      size: 13.sp,
                      color: AppColors.brandOrange,
                    ),
                    3.width,
                    Text(
                      'Fast Delivery',
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandOrange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(
        Icons.shopping_basket_outlined,
        color: AppColors.brandPurple.withValues(alpha: 0.4),
        size: 20.sp,
      ),
    );
  }

  Widget _buildVariationRow(
      BuildContext context, ProductVariationModel variation, bool isLast) {
    final cart = context.watch<CartProvider>();
    final cartItemId = product.id.toString();
    final quantity = cart.getQuantity(cartItemId);
    final inCartVariationId = cart.items[cartItemId]?.variationId;
    final isThisVariationInCart = inCartVariationId == variation.id.toString();

    final sellPrice = variation.sellPrice;
    final mrpPrice = variation.mrpPrice;
    final hasDiscount = mrpPrice > sellPrice && mrpPrice > 0;
    final savings = hasDiscount ? (mrpPrice - sellPrice) : 0.0;

    // Format price — show integer if .00, else 2dp
    String fmt(double v) =>
        v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 11.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Weight + price info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      variation.name,
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    4.height,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '₹${fmt(sellPrice)}',
                          style: AppTextStyles.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        if (hasDiscount) ...[
                          6.width,
                          Text(
                            '₹${fmt(mrpPrice)}',
                            style: AppTextStyles.plusJakartaSans(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFADB5BD),
                              decoration: TextDecoration.lineThrough,
                              decorationColor: const Color(0xFFADB5BD),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (hasDiscount && savings > 0) ...[
                      4.height,
                      Text(
                        'Save ₹${fmt(savings)}',
                        style: AppTextStyles.plusJakartaSans(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandPurple,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ADD button or quantity stepper
              if (quantity <= 0 || !isThisVariationInCart)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    cart.addToCart(
                      id: cartItemId,
                      title: product.title,
                      sellPrice: sellPrice,
                      mrpPrice: mrpPrice,
                      quantity: 1,
                      imageUrl: product.heroImageUrl,
                      weight: variation.name,
                      category: product.category,
                      storeName: product.storeName,
                      variationId: variation.id.toString(),
                      productId: product.id.toString(),
                    );
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 18.w, vertical: 7.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6.r),
                      border:
                          Border.all(color: AppColors.brandPurple, width: 1.5),
                    ),
                    child: Text(
                      'ADD +',
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.brandPurple,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF168A35),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          cart.updateQuantity(cartItemId, quantity - 1);
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 9.w, vertical: 7.h),
                          child:
                              Icon(Icons.remove, color: Colors.white, size: 13.sp),
                        ),
                      ),
                      Text(
                        '$quantity',
                        style: AppTextStyles.plusJakartaSans(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          cart.updateQuantity(cartItemId, quantity + 1);
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 9.w, vertical: 7.h),
                          child:
                              Icon(Icons.add, color: Colors.white, size: 13.sp),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, color: Color(0xFFF8F9FA), thickness: 1),
      ],
    );
  }
}
