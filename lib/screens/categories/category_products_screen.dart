import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/core/responsive/responsive.dart';
import 'package:grahmitracus/core/services/api_endpoints.dart';
import 'package:grahmitracus/core/services/api_service.dart';
import 'package:grahmitracus/models/product/home_product_model.dart';
import 'package:grahmitracus/providers/cart/cart_provider.dart';
import 'package:grahmitracus/screens/cart/cart_screen.dart';
import 'package:grahmitracus/screens/product/product_detail_screen.dart';
import 'package:grahmitracus/widgets/product_card.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Screen listing products for a specific category using GET /api/products?categoryId={categoryId}
class CategoryProductsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<HomeProductModel> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.instance.get(
        ApiEndpoints.products,
        queryParameters: {'categoryId': widget.categoryId},
      );

      List<HomeProductModel> fetched = [];
      if (response.data is List) {
        fetched = (response.data as List)
            .map((e) => HomeProductModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        final dynamic rawList = map['data'] ?? map['products'] ?? map['result'];
        if (rawList is List) {
          fetched = rawList
              .map((e) => HomeProductModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }

      // If categoryId filter returned empty list, try fallback query by category name
      if (fetched.isEmpty) {
        final fallbackResp = await ApiService.instance.get(
          ApiEndpoints.products,
          queryParameters: {'search': widget.categoryName},
        );
        if (fallbackResp.data is List) {
          fetched = (fallbackResp.data as List)
              .map((e) => HomeProductModel.fromJson(e as Map<String, dynamic>))
              .toList();
        } else if (fallbackResp.data is Map<String, dynamic>) {
          final map = fallbackResp.data as Map<String, dynamic>;
          final dynamic rawList =
              map['data'] ?? map['products'] ?? map['result'];
          if (rawList is List) {
            fetched = rawList
                .map(
                  (e) => HomeProductModel.fromJson(e as Map<String, dynamic>),
                )
                .toList();
          }
        }
      }

      if (mounted) {
        setState(() {
          _products = fetched;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Same add-to-cart handler as HomeScreen._updateCart — shows the same
  /// SnackBar popup when a product is first added (qty delta > 0 && new qty == 1).
  void _updateCart(
    String id,
    int qty,
    String name, {
    double? sellPrice,
    double? mrpPrice,
    String? imgPath,
    String? weight,
    String? category,
    String? storeName,
    String? productId,
    String? variationId,
  }) {
    HapticFeedback.selectionClick();
    final cart = context.read<CartProvider>();
    final current = cart.getQuantity(id);

    // qty here is the target quantity (same as CategoryProductsScreen passes it)
    cart.updateQuantity(
      id,
      qty,
      title: name,
      sellPrice: sellPrice,
      mrpPrice: mrpPrice,
      imageUrl: imgPath,
      weight: weight,
      category: category,
      storeName: storeName,
      productId: productId,
      variationId: variationId,
    );

    // Show popup only when item is first added (same behaviour as Home)
    final delta = qty - current;
    if (delta > 0 && qty == 1) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: const BoxDecoration(
                  color: AppColors.brandPurple,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              10.width,
              if (imgPath != null && imgPath.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.network(
                    imgPath,
                    width: 36.w,
                    height: 36.w,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 36.w,
                      height: 36.w,
                      color: AppColors.subtleBackground,
                      child: const Icon(
                        Icons.image_not_supported_rounded,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                10.width,
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    2.height,
                    Text(
                      'added to cart',
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              8.width,
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CartScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: AppColors.brandPurple,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: const Icon(
                    Icons.visibility_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 6,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 2500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: const BorderSide(color: Color(0xFFE5E9F0), width: 1),
          ),
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final totalCartCount = cart.totalQuantity;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: const Color(0xFF0F172A),
            size: 22.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryName,
          style: AppTextStyles.screenTitle.copyWith(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        actions: [
          // Cart icon with badge — same style as Home header
          GestureDetector(
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
              width: 40.r,
              height: 40.r,
              margin: EdgeInsets.only(right: 10.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FB),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E9F0)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.cartShopping,
                    size: 16.sp,
                    color: const Color(0xFF0F172A),
                  ),
                  if (totalCartCount > 0)
                    Positioned(
                      top: 2.h,
                      right: 2.w,
                      child: Container(
                        padding: EdgeInsets.all(3.r),
                        decoration: const BoxDecoration(
                          color: AppColors.brandOrange,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16.r,
                          minHeight: 16.r,
                        ),
                        child: Text(
                          '$totalCartCount',
                          style: AppTextStyles.plusJakartaSans(
                            fontSize: 8.5.sp,
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
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brandPurple),
            )
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Failed to load products',
                    style: AppTextStyles.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  12.height,
                  ElevatedButton(
                    onPressed: _fetchProducts,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPurple,
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          : _products.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 50.sp,
                    color: AppColors.textHint,
                  ),
                  12.height,
                  Text(
                    'No products available in ${widget.categoryName}',
                    style: AppTextStyles.plusJakartaSans(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchProducts,
              color: AppColors.brandPurple,
              child: GridView.builder(
                padding: EdgeInsets.all(12.r),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10.h,
                  crossAxisSpacing: 10.w,
                  childAspectRatio: 0.75,
                ),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];
                  final id = product.id.toString();
                  final quantity = cart.getQuantity(id);

                  return ProductCard(
                    product: product,
                    quantity: quantity,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(
                            productIdOrSlug:
                                product.slag ?? product.id.toString(),
                            initialProduct: product,
                          ),
                        ),
                      );
                    },
                    onQuantityChanged: (qty) {
                      _updateCart(
                        id,
                        qty,
                        product.title ?? '',
                        sellPrice: product.sellPrice,
                        mrpPrice: product.mrpPrice,
                        imgPath: product.imgPath,
                        weight: product.variationName,
                        category: product.subcategory,
                        storeName: product.storeName,
                        productId: product.id.toString(),
                        variationId: product.variationId?.toString(),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}
