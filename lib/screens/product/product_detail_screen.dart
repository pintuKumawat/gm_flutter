import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/core/responsive/responsive.dart';
import 'package:grahmitracus/models/product/home_product_model.dart';
import 'package:grahmitracus/models/product/product_detail_model.dart';
import 'package:grahmitracus/providers/cart/cart_provider.dart';
import 'package:grahmitracus/providers/product/product_detail_provider.dart';
import 'package:grahmitracus/screens/cart/cart_screen.dart';
import 'package:grahmitracus/widgets/product_card.dart';

/// Product Details Screen designed to match the Next.js Frontend ProductDetails view
class ProductDetailScreen extends StatefulWidget {
  final String productIdOrSlug;
  final HomeProductModel? initialProduct;

  const ProductDetailScreen({
    super.key,
    required this.productIdOrSlug,
    this.initialProduct,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isAddedFeedback = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductDetailProvider>().loadProduct(widget.productIdOrSlug);
    });
  }

  void _triggerAddFeedback({bool navigateToCart = false}) {
    HapticFeedback.mediumImpact();
    final provider = context.read<ProductDetailProvider>();
    final product = provider.product;
    final homeProd = widget.initialProduct;

    final title = product?.title ?? homeProd?.title ?? 'Product';
    final sellPrice = product?.sellPrice ?? homeProd?.sellPrice ?? 0.0;
    final mrpPrice = product?.mrpPrice ?? homeProd?.mrpPrice ?? sellPrice;
    final imgPath = product?.allImages.firstOrNull ?? homeProd?.imgPath;
    final weight = product?.variationName ?? homeProd?.variationName;
    final category = product?.category ?? homeProd?.brand;
    final productId = product?.id.toString() ?? homeProd?.id.toString() ?? widget.productIdOrSlug;
    final variationId = provider.selectedVariation?.id?.toString() ?? product?.variationId?.toString() ?? homeProd?.variationId?.toString();
    final id = "${productId}_${variationId ?? 'default'}";

    context.read<CartProvider>().addToCart(
      id: id,
      title: title,
      sellPrice: sellPrice,
      mrpPrice: mrpPrice,
      imageUrl: imgPath,
      weight: weight,
      category: category,
      productId: productId,
      variationId: variationId,
      quantity: provider.quantity,
    );

    if (navigateToCart) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CartScreen()),
      );
      return;
    }

    setState(() => _isAddedFeedback = true);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$title added to cart!',
                style: AppTextStyles.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              },
              child: Text(
                'VIEW CART',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandOrange,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF168A35),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      ),
    );
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _isAddedFeedback = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Consumer<ProductDetailProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingProduct) {
            return _buildLoadingSkeleton();
          }

          if (provider.errorMessage != null && provider.product == null) {
            return _buildErrorState(provider);
          }

          final product = provider.product;
          if (product == null) {
            return const SizedBox.shrink();
          }

          return Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(bottom: 100.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Main Hero Image & Gallery Section
                    _buildImageGallery(context, provider, product),

                    14.height,

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 2. Category & Brand Header Tag
                          _buildBrandCategoryHeader(product),

                          6.height,

                          // 3. Product Title
                          Text(
                            product.title,
                            style: AppTextStyles.plusJakartaSans(
                              fontSize: 19.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              height: 1.25,
                            ),
                          ),

                          10.height,

                          // 4. Pricing & Savings Highlight
                          _buildPricingSection(provider),

                          16.height,

                          // 5. Pack / Variation Selector
                          if (product.variations.isNotEmpty)
                            _buildVariationSelector(provider, product),

                          16.height,

                          // 6. Stock & Fast Delivery Badges
                          _buildStockAndDeliveryStatus(provider, product),

                          16.height,

                          // 7. Quantity Selector, Add to Cart & Buy Now Buttons
                          _buildActionButtons(provider, product),

                          20.height,

                          // 8. Trust Features Badges (Fast delivery, Support, Genuine)
                          _buildTrustFeaturesStrip(),

                          20.height,

                          // 9. About the Product / Specifications Card
                          _buildAboutProductSection(product),
                        ],
                      ),
                    ),

                    24.height,

                    // 10. Related Products Rail
                    _buildRelatedProductsSection(provider),

                    20.height,
                  ],
                ),
              ),

              // 11. Sticky Bottom Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildStickyBottomBar(provider, product),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Custom App Bar with Category Title & Action Icons
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: EdgeInsets.all(8.r),
        child: InkWell(
          onTap: () => Navigator.maybePop(context),
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0F172A),
              size: 16,
            ),
          ),
        ),
      ),
      title: Consumer<ProductDetailProvider>(
        builder: (context, provider, child) {
          final title = provider.product?.category ?? 'Product Details';
          return Text(
            title.toUpperCase(),
            style: AppTextStyles.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF64748B),
              letterSpacing: 0.8,
            ),
          );
        },
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Link copied to clipboard!')),
            );
          },
          icon: const Icon(
            Icons.share_outlined,
            color: Color(0xFF334155),
            size: 20,
          ),
        ),
        Consumer<CartProvider>(
          builder: (context, cart, _) {
            final totalCartCount = cart.totalQuantity;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CartScreen(),
                  ),
                );
              },
              child: Container(
                width: 38.r,
                height: 38.r,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.cartShopping,
                      size: 15.sp,
                      color: const Color(0xFF334155),
                    ),
                    if (totalCartCount > 0)
                      Positioned(
                        top: 2.h,
                        right: 2.w,
                        child: Container(
                          padding: EdgeInsets.all(2.5.r),
                          decoration: const BoxDecoration(
                            color: AppColors.brandOrange,
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 15.r,
                            minHeight: 15.r,
                          ),
                          child: Text(
                            '$totalCartCount',
                            style: AppTextStyles.plusJakartaSans(
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        8.width,
      ],
    );
  }

  /// 1. Hero Image & Gallery Showcase
  Widget _buildImageGallery(
    BuildContext context,
    ProductDetailProvider provider,
    ProductDetailModel product,
  ) {
    final images = product.allImages;
    final activeImg = provider.activeImage.isNotEmpty
        ? provider.activeImage
        : (product.heroImageUrl ?? '');
    final discount = provider.effectiveDiscountPercent;

    return Container(
      color: const Color(0xFFFAFAFA),
      child: Column(
        children: [
          // Main Preview Box
          Stack(
            children: [
              Container(
                height: 250.h,
                width: double.infinity,
                padding: EdgeInsets.all(16.r),
                child: activeImg.isNotEmpty
                    ? Image.network(
                        activeImg,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.brandPurple,
                            ),
                          );
                        },
                      )
                    : _buildFallbackImage(),
              ),

              // Top-Left Discount Badge
              if (discount > 0)
                Positioned(
                  top: 12.h,
                  left: 12.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B21A8),
                      borderRadius: BorderRadius.circular(6.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6B21A8).withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '$discount% OFF',
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),

              // Lightbox / Fullscreen Button
              Positioned(
                bottom: 12.h,
                right: 12.w,
                child: GestureDetector(
                  onTap: () => _openLightbox(context, activeImg, product.title),
                  child: Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.fullscreen_rounded,
                      size: 20,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Thumbnails List
          if (images.length > 1) ...[
            10.height,
            SizedBox(
              height: 56.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: images.length,
                separatorBuilder: (context, index) => 10.width,
                itemBuilder: (context, index) {
                  final img = images[index];
                  final isSelected = activeImg == img;
                  return GestureDetector(
                    onTap: () => provider.setActiveImage(img),
                    child: Container(
                      width: 56.w,
                      height: 56.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.brandPurple
                              : const Color(0xFFE2E8F0),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      padding: EdgeInsets.all(4.r),
                      child: Image.network(
                        img,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.shopping_basket_outlined,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            12.height,
          ],
        ],
      ),
    );
  }

  /// 2. Brand & Subcategory Header Tag
  Widget _buildBrandCategoryHeader(ProductDetailModel product) {
    final categoryText = [
      if (product.brand != null && product.brand!.isNotEmpty)
        product.brand!.toUpperCase(),
      if (product.subcategory != null && product.subcategory!.isNotEmpty)
        product.subcategory!.toUpperCase()
      else if (product.category != null && product.category!.isNotEmpty)
        product.category!.toUpperCase(),
    ].join(' • ');

    if (categoryText.isEmpty) return const SizedBox.shrink();

    return Text(
      categoryText,
      style: AppTextStyles.plusJakartaSans(
        fontSize: 10.sp,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF6B21A8),
        letterSpacing: 0.6,
      ),
    );
  }

  /// 4. Pricing & Savings
  Widget _buildPricingSection(ProductDetailProvider provider) {
    final price = provider.effectivePrice;
    final mrp = provider.effectiveMrp;
    final savings = provider.effectiveSavings;
    final discount = provider.effectiveDiscountPercent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '₹${price.toStringAsFixed(0)}',
              style: AppTextStyles.plusJakartaSans(
                fontSize: 26.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
              ),
            ),
            if (mrp > price) ...[
              10.width,
              Text(
                '₹${mrp.toStringAsFixed(0)}',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
            if (savings > 0) ...[
              10.width,
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.5.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF5FF),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: const Color(0xFFE9D5FF), width: 0.8),
                ),
                child: Text(
                  'SAVE ₹${savings.toStringAsFixed(0)} ($discount%)',
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF6B21A8),
                  ),
                ),
              ),
            ],
          ],
        ),
        4.height,
        Text(
          'Inclusive of all taxes',
          style: AppTextStyles.plusJakartaSans(
            fontSize: 10.5.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  /// 5. Variation / Pack Size Selector
  Widget _buildVariationSelector(
    ProductDetailProvider provider,
    ProductDetailModel product,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECT WEIGHT / PACK',
          style: AppTextStyles.plusJakartaSans(
            fontSize: 10.5.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF64748B),
            letterSpacing: 0.6,
          ),
        ),
        10.height,
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: product.variations.map((v) {
            final isSelected = provider.selectedVariation?.id == v.id;
            final isOutOfStock = v.isOutOfStock;
            final disc = v.discountPercent;

            return GestureDetector(
              onTap: isOutOfStock ? null : () => provider.selectVariation(v),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFAF5FF) : Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF6B21A8)
                        : isOutOfStock
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFFCBD5E1),
                    width: isSelected ? 1.8 : 1.1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF6B21A8).withValues(alpha: 0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      v.name,
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? const Color(0xFF6B21A8)
                            : isOutOfStock
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF1E293B),
                      ),
                    ),
                    if (disc > 0 && !isOutOfStock) ...[
                      4.height,
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 5.w,
                          vertical: 1.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF6B21A8)
                              : const Color(0xFF0C831F),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          '$disc% OFF',
                          style: AppTextStyles.plusJakartaSans(
                            fontSize: 7.5.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 6. Stock Status Indicator
  Widget _buildStockAndDeliveryStatus(
    ProductDetailProvider provider,
    ProductDetailModel product,
  ) {
    final inStock = provider.isInStock;
    final stockQty = provider.availableStock;

    final String statusText = inStock
        ? (stockQty > 0 && stockQty <= 5
            ? 'In stock (Only $stockQty left!)'
            : 'In stock')
        : 'Currently Out of Stock';

    return Row(
      children: [
        Icon(
          inStock ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
          color: inStock ? const Color(0xFF6B21A8) : const Color(0xFFDC2626),
          size: 18.sp,
        ),
        6.width,
        Text(
          statusText,
          style: AppTextStyles.plusJakartaSans(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: inStock ? const Color(0xFF6B21A8) : const Color(0xFFDC2626),
          ),
        ),
      ],
    );
  }

  /// 7. Quantity Stepper, Add to Cart & Buy Now Action Row
  Widget _buildActionButtons(
    ProductDetailProvider provider,
    ProductDetailModel product,
  ) {
    final inStock = provider.isInStock;

    return Column(
      children: [
        Row(
          children: [
            // Quantity Stepper
            Container(
              height: 46.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.1),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: inStock ? provider.decrementQuantity : null,
                    icon: const Icon(Icons.remove_rounded, size: 16),
                    color: const Color(0xFF334155),
                    splashRadius: 18,
                  ),
                  Text(
                    '${provider.quantity}',
                    style: AppTextStyles.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    onPressed: inStock ? provider.incrementQuantity : null,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    color: const Color(0xFF334155),
                    splashRadius: 18,
                  ),
                ],
              ),
            ),

            10.width,

            // BUY NOW BUTTON
            Expanded(
              child: SizedBox(
                height: 46.h,
                child: OutlinedButton(
                  onPressed: inStock
                      ? () {
                          _triggerAddFeedback(navigateToCart: true);
                        }
                      : null,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFFAF5FF),
                    foregroundColor: const Color(0xFF6B21A8),
                    side: const BorderSide(color: Color(0xFFE9D5FF), width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bolt_rounded, size: 18.sp, color: const Color(0xFF6B21A8)),
                      6.width,
                      Text(
                        'BUY NOW',
                        style: AppTextStyles.plusJakartaSans(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 8. Trust Features Badges Strip
  Widget _buildTrustFeaturesStrip() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          _buildTrustBadgeItem(
            icon: Icons.support_agent_rounded,
            title: 'Customer',
            subtitle: 'Support',
            hasRightBorder: true,
          ),
          _buildTrustBadgeItem(
            icon: Icons.verified_user_outlined,
            title: 'Premium',
            subtitle: 'Quality',
            hasRightBorder: false,
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadgeItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool hasRightBorder,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: hasRightBorder
              ? const Border(
                  right: BorderSide(color: Color(0xFFE2E8F0), width: 0.9),
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18.sp, color: const Color(0xFF6B21A8)),
            6.width,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1E293B),
                    height: 1,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 8.5.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                    height: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 9. About the Product / Specifications Card
  Widget _buildAboutProductSection(ProductDetailModel product) {
    final desc = (product.description ?? product.shortDesc ?? '')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About the Product',
            style: AppTextStyles.plusJakartaSans(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          8.height,
          Text(
            desc.isNotEmpty
                ? desc
                : 'Fresh and verified quality grocery item delivered to your doorstep in minutes with 100% guarantee.',
            style: AppTextStyles.plusJakartaSans(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF475569),
              height: 1.45,
            ),
          ),
          12.height,
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          10.height,
          if (product.brand != null && product.brand!.isNotEmpty)
            _buildSpecRow('Brand', product.brand!),
          if (product.category != null && product.category!.isNotEmpty)
            _buildSpecRow('Category', product.category!),
          if (product.subcategory != null && product.subcategory!.isNotEmpty)
            _buildSpecRow('Type', product.subcategory!),
          _buildSpecRow('Country of Origin', 'India'),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.plusJakartaSans(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.plusJakartaSans(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  /// 10. Related Products Rail matching Frontend
  Widget _buildRelatedProductsSection(ProductDetailProvider provider) {
    final related = provider.relatedProducts;
    final isLoading = provider.isLoadingRelated;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 14.h),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.brandOrange,
                  size: 18.sp,
                ),
                6.width,
                Text(
                  'RELATED PRODUCTS',
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          12.height,
          if (isLoading && related.isEmpty)
            SizedBox(
              height: 190.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: 4,
                separatorBuilder: (context, index) => 12.width,
                itemBuilder: (context, index) => Container(
                  width: 150.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.brandPurple,
                    ),
                  ),
                ),
              ),
            )
          else if (related.isNotEmpty)
            SizedBox(
              height: 190.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: related.length,
                separatorBuilder: (context, index) => 10.width,
                itemBuilder: (context, index) {
                  final relProduct = related[index];
                  return Consumer<CartProvider>(
                    builder: (context, cart, _) {
                      final id = relProduct.id.toString();
                      final quantity = cart.getQuantity(id);

                      return SizedBox(
                        width: 146.w,
                        height: 180.h,
                        child: ProductCard(
                          product: relProduct,
                          quantity: quantity,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(
                                  productIdOrSlug: relProduct.slag ?? id,
                                  initialProduct: relProduct,
                                ),
                              ),
                            );
                          },
                          onQuantityChanged: (qty) {
                            cart.updateQuantity(
                              id,
                              qty,
                              title: relProduct.title,
                              sellPrice: relProduct.sellPrice,
                              mrpPrice: relProduct.mrpPrice,
                              imageUrl: relProduct.imgPath,
                              weight: relProduct.variationName,
                              category: relProduct.subcategory,
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            )
          else
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Text(
                'No related products available in this category.',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 11. Sticky Bottom Bar
  Widget _buildStickyBottomBar(
    ProductDetailProvider provider,
    ProductDetailModel product,
  ) {
    final price = provider.effectivePrice;
    final inStock = provider.isInStock;
    final variationName = provider.selectedVariation?.name ?? 'Standard Pack';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${price.toStringAsFixed(0)}',
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  variationName,
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            16.width,
            Expanded(
              child: SizedBox(
                height: 44.h,
                child: ElevatedButton(
                  onPressed: inStock ? _triggerAddFeedback : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAddedFeedback
                        ? const Color(0xFF168A35)
                        : const Color(0xFF6B21A8),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text(
                    _isAddedFeedback ? 'ADDED TO CART' : 'ADD TO CART',
                    style: AppTextStyles.plusJakartaSans(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Lightbox Modal Preview
  void _openLightbox(BuildContext context, String imageUrl, String title) {
    if (imageUrl.isEmpty) return;
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) {
        return Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 3.5,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
                ),
              ),
            ),
            Positioned(
              top: 40.h,
              right: 16.w,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFallbackImage() {
    return Center(
      child: Icon(
        Icons.shopping_basket_outlined,
        size: 64.sp,
        color: AppColors.brandPurple.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: AppColors.brandPurple,
      ),
    );
  }

  Widget _buildErrorState(ProductDetailProvider provider) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48.sp,
              color: Colors.redAccent,
            ),
            12.height,
            Text(
              provider.errorMessage ?? 'Product not found',
              style: AppTextStyles.plusJakartaSans(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            16.height,
            ElevatedButton(
              onPressed: () => provider.loadProduct(widget.productIdOrSlug),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
