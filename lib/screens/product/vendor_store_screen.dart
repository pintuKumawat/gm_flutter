import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/core/responsive/responsive.dart';
import 'package:grahmitracus/models/product/vendor_model.dart';
import 'package:grahmitracus/providers/cart/cart_provider.dart';
import 'package:grahmitracus/providers/location/location_provider.dart';
import 'package:grahmitracus/providers/product/vendor_provider.dart';
import 'package:grahmitracus/screens/cart/cart_screen.dart';
import 'package:grahmitracus/screens/product/product_detail_screen.dart';
import 'package:grahmitracus/widgets/product_card.dart';

/// Storefront screen displaying details and products for a specific vendor
class VendorStoreScreen extends StatefulWidget {
  final VendorModel vendor;

  const VendorStoreScreen({
    super.key,
    required this.vendor,
  });

  @override
  State<VendorStoreScreen> createState() => _VendorStoreScreenState();
}

class _VendorStoreScreenState extends State<VendorStoreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _fetchStore();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _fetchStore({bool forceRefresh = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final areaId = context.read<LocationProvider>().activeAreaId;
      final slug = widget.vendor.slug ?? widget.vendor.vendorId.toString();
      context.read<VendorProvider>().fetchStoreDetails(
            slug,
            areaId: areaId,
            forceRefresh: forceRefresh,
          );
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 250) {
      final areaId = context.read<LocationProvider>().activeAreaId;
      context.read<VendorProvider>().loadMoreStoreProducts(areaId: areaId);
    }
  }

  void _onSearchChanged(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final areaId = context.read<LocationProvider>().activeAreaId;
      context.read<VendorProvider>().searchStoreProducts(
            text,
            areaId: areaId,
          );
    });
  }

  void _updateCart(
    String id,
    int qty,
    String name, {
    required double sellPrice,
    required double mrpPrice,
    String? imgPath,
    String? weight,
    String? category,
    String? storeName,
    String? productId,
    String? variationId,
  }) {
    HapticFeedback.selectionClick();
    final cart = context.read<CartProvider>();
    final effectiveProductId = productId ?? id;
    final current = cart.getProductQuantity(
      effectiveProductId,
      variationId: variationId,
    );
    final key = CartProvider.buildCartKey(
      effectiveProductId,
      variationId: variationId,
    );

    cart.updateQuantity(
      key,
      qty,
      title: name,
      sellPrice: sellPrice,
      mrpPrice: mrpPrice,
      imageUrl: imgPath,
      weight: weight,
      category: category,
      storeName: storeName,
      productId: effectiveProductId,
      variationId: variationId,
    );

    if (current == 0 && qty > 0 && mounted) {
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
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.brandPurple,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'View Cart',
                    style: AppTextStyles.plusJakartaSans(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Consumer<VendorProvider>(
        builder: (context, vendorProv, child) {
          if (vendorProv.isStoreLoading && vendorProv.storeProducts.isEmpty) {
            return _buildLoadingState();
          }

          if (vendorProv.hasStoreError && vendorProv.storeProducts.isEmpty) {
            return _buildErrorState(vendorProv.storeError!);
          }

          final store = vendorProv.currentStore ?? widget.vendor;
          final products = vendorProv.storeProducts;
          final categories = vendorProv.storeCategories;
          final selectedCategory = vendorProv.selectedCategory;

          return RefreshIndicator(
            onRefresh: () async => _fetchStore(forceRefresh: true),
            color: AppColors.brandPurple,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // Store Info Card & Search
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStoreProfileCard(store, vendorProv),
                        12.height,
                        _buildSearchBar(),
                        if (categories.isNotEmpty) ...[
                          14.height,
                          _buildCategoryFilters(categories, selectedCategory),
                        ],
                        14.height,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedCategory.isEmpty
                                  ? 'All Products'
                                  : selectedCategory,
                              style: AppTextStyles.poppins(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              '${vendorProv.storeDetail?.totalProducts ?? products.length} items',
                              style: AppTextStyles.plusJakartaSans(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        8.height,
                      ],
                    ),
                  ),
                ),

                // Products Grid or Empty State
                if (products.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10.h,
                        crossAxisSpacing: 10.w,
                        childAspectRatio: 0.72,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = products[index];
                          final cart = context.watch<CartProvider>();
                          final quantity = cart.getProductQuantity(
                            product.id.toString(),
                            variationId: product.variationId?.toString(),
                          );

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
                                product.id.toString(),
                                qty,
                                product.title,
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
                        childCount: products.length,
                      ),
                    ),
                  ),

                // Bottom Pagination Loading Spinner
                if (vendorProv.isLoadingMore)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.brandPurple,
                          ),
                        ),
                      ),
                    ),
                  ),

                SliverToBoxAdapter(child: SizedBox(height: 30.h)),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Color(0xFF1E293B),
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.vendor.storeName,
        style: AppTextStyles.poppins(
          fontSize: 17.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1E293B),
        ),
      ),
      actions: [
        Consumer<CartProvider>(
          builder: (context, cart, child) {
            final itemCount = cart.totalQuantity;
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.shopping_bag_outlined,
                    color: Color(0xFF1E293B),
                    size: 24,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CartScreen(),
                      ),
                    );
                  },
                ),
                if (itemCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.brandPurple,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        itemCount > 99 ? '99+' : itemCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        8.width,
      ],
    );
  }

  Widget _buildStoreProfileCard(VendorModel store, VendorProvider provider) {
    final logoUrl = store.fullLogoUrl ?? widget.vendor.fullLogoUrl;
    final total = provider.storeDetail?.totalProducts ?? 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Store Logo
          Container(
            width: 58.w,
            height: 58.w,
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
            ),
            child: Center(
              child: logoUrl != null && logoUrl.isNotEmpty
                  ? Image.network(
                      logoUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          _buildStoreAvatar(store.storeName),
                    )
                  : _buildStoreAvatar(store.storeName),
            ),
          ),
          14.width,
          // Store Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.storeName,
                  style: AppTextStyles.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (store.storeDescription != null &&
                    store.storeDescription!.trim().isNotEmpty) ...[
                  2.height,
                  Text(
                    store.storeDescription!.trim(),
                    style: AppTextStyles.plusJakartaSans(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                6.height,
                Wrap(
                  spacing: 6.w,
                  runSpacing: 4.h,
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 11.sp,
                            color: const Color(0xFF475569),
                          ),
                          4.width,
                          Text(
                            '$total Products',
                            style: AppTextStyles.plusJakartaSans(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF5FF),
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(
                          color: const Color(0xFFE9D5FF),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 11.sp,
                            color: AppColors.brandPurple,
                          ),
                          4.width,
                          Text(
                            'Verified Vendor',
                            style: AppTextStyles.plusJakartaSans(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brandPurple,
                            ),
                          ),
                        ],
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

  Widget _buildStoreAvatar(String storeName) {
    final initial = storeName.trim().isNotEmpty
        ? storeName.trim().substring(0, 1).toUpperCase()
        : 'S';
    return Container(
      width: 36.w,
      height: 36.w,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.subtleBackground,
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: AppTextStyles.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.brandPurple,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: AppTextStyles.plusJakartaSans(
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          hintText: 'Search products in this store...',
          hintStyle: AppTextStyles.plusJakartaSans(
            fontSize: 12.5.sp,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF94A3B8),
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF94A3B8),
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12.h),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters(
      List<String> categories, String selectedCategory) {
    return SizedBox(
      height: 34.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => 8.width,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final catName = isAll ? 'All Products' : categories[index - 1];
          final isSelected =
              isAll ? selectedCategory.isEmpty : selectedCategory == catName;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              final areaId = context.read<LocationProvider>().activeAreaId;
              context.read<VendorProvider>().setStoreCategory(
                    isAll ? '' : catName,
                    areaId: areaId,
                  );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.brandPurple : Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isSelected
                      ? AppColors.brandPurple
                      : const Color(0xFFE2E8F0),
                  width: 1.0,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                catName,
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 11.5.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 90.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
          16.height,
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10.h,
                crossAxisSpacing: 10.w,
                childAspectRatio: 0.72,
              ),
              itemCount: 6,
              itemBuilder: (_, _) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 54.sp,
              color: const Color(0xFF94A3B8),
            ),
            12.height,
            Text(
              'No items found in this store',
              style: AppTextStyles.poppins(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            4.height,
            Text(
              'Try clearing search or selecting another category.',
              textAlign: TextAlign.center,
              style: AppTextStyles.plusJakartaSans(
                fontSize: 12.sp,
                color: const Color(0xFF64748B),
              ),
            ),
            16.height,
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                final areaId = context.read<LocationProvider>().activeAreaId;
                context.read<VendorProvider>().clearStoreFilters(areaId: areaId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                padding:
                    EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
              ),
              child: const Text(
                'Clear Filters',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48.sp,
              color: Colors.red.shade400,
            ),
            12.height,
            Text(
              'Unable to load store',
              style: AppTextStyles.poppins(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            4.height,
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTextStyles.plusJakartaSans(
                fontSize: 12.sp,
                color: const Color(0xFF64748B),
              ),
            ),
            16.height,
            ElevatedButton(
              onPressed: () => _fetchStore(forceRefresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
