import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/core/responsive/responsive.dart';
import 'package:grahmitracus/models/product/category_model.dart';
import 'package:grahmitracus/providers/product/category_group_provider.dart';
import 'package:grahmitracus/providers/product/category_provider.dart';
import 'package:grahmitracus/screens/categories/category_products_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  int _selectedCategoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _fallbackCategories = const [
    {
      'title': 'Grocery & Staples',
      'icon': Icons.shopping_basket_outlined,
      'color': AppColors.catAmberBg,
      'iconColor': AppColors.catAmberIcon,
      'subcategories': [
        'Aata, Flours & Sooji',
        'Rice & Rice Products',
        'Dals & Pulses',
        'Edible Oils & Ghee',
        'Salt, Sugar & Jaggery',
        'Masalas & Spices',
        'Dry Fruits & Nuts',
      ],
    },
    {
      'title': 'Daily Needs',
      'icon': Icons.breakfast_dining_outlined,
      'color': AppColors.catOrangeBg,
      'iconColor': AppColors.catOrangeIcon,
      'subcategories': [
        'Bread & Bakery',
        'Milk & Dairy',
        'Eggs & Breakfast',
        'Cookies & Biscuits',
        'Tea, Coffee & More',
      ],
    },
    {
      'title': 'Fruits & Vegetables',
      'icon': Icons.eco_outlined,
      'color': AppColors.catEmeraldBg,
      'iconColor': AppColors.catEmeraldIcon,
      'subcategories': [
        'Fresh Vegetables',
        'Fresh Fruits',
        'Exotic & Organic',
        'Herbs & Seasonings',
        'Cuts & Sprouts',
      ],
    },
    {
      'title': 'Beverages & Drinks',
      'icon': Icons.local_drink_outlined,
      'color': AppColors.catBlueBg,
      'iconColor': AppColors.catBlueIcon,
      'subcategories': [
        'Cold Drinks & Juices',
        'Energy & Health Drinks',
        'Water & Soda',
        'Syrups & Concentrates',
      ],
    },
    {
      'title': 'Snacks & Packaged',
      'icon': Icons.fastfood_outlined,
      'color': AppColors.catRedBg,
      'iconColor': AppColors.catRedIcon,
      'subcategories': [
        'Chips & Crisps',
        'Namkeen & Savouries',
        'Noodles & Pasta',
        'Chocolates & Candies',
        'Sauces & Spreads',
      ],
    },
    {
      'title': 'Personal Care',
      'icon': Icons.clean_hands_rounded,
      'color': AppColors.catPurpleBg,
      'iconColor': AppColors.catPurpleIcon,
      'subcategories': [
        'Bath & Body',
        'Hair Care',
        'Skin Care',
        'Oral Care',
        'Fragrances & Deos',
      ],
    },
    {
      'title': 'Household Needs',
      'icon': Icons.cleaning_services_rounded,
      'color': AppColors.catGreenBg,
      'iconColor': AppColors.catGreenIcon,
      'subcategories': [
        'Detergents & Fabric Care',
        'Cleaners & Disinfectants',
        'Pooja Essentials',
        'Pest Control',
        'Disposable Items',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CategoryGroupProvider>().fetchGroups();
        context.read<CategoryProvider>().fetchCategories();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String? name, String? slag) {
    final text = '${name ?? ''} ${slag ?? ''}'.toLowerCase();
    if (text.contains('food') || text.contains('beverage') || text.contains('drink')) {
      return Icons.local_drink_outlined;
    } else if (text.contains('grocery') || text.contains('staple')) {
      return Icons.shopping_basket_outlined;
    } else if (text.contains('fruit') || text.contains('veg')) {
      return Icons.eco_outlined;
    } else if (text.contains('daily') || text.contains('need') || text.contains('bread') || text.contains('milk')) {
      return Icons.breakfast_dining_outlined;
    } else if (text.contains('snack') || text.contains('chocolate') || text.contains('sweet')) {
      return Icons.fastfood_outlined;
    } else if (text.contains('care') || text.contains('personal')) {
      return Icons.clean_hands_rounded;
    } else if (text.contains('house') || text.contains('clean')) {
      return Icons.cleaning_services_rounded;
    }
    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CategoryGroupProvider, CategoryProvider>(
      builder: (context, groupProvider, catProvider, child) {
        final groups = groupProvider.groups.where((g) => g.active).toList();
        final hasLiveGroups = groups.isNotEmpty;

        final int currentGroupId = hasLiveGroups
            ? (_selectedCategoryIndex < groups.length
                ? groups[_selectedCategoryIndex].id
                : groups.first.id)
            : 0;

        final String currentTitle = hasLiveGroups
            ? (_selectedCategoryIndex < groups.length
                ? groups[_selectedCategoryIndex].name
                : groups.first.name)
            : _fallbackCategories[_selectedCategoryIndex % _fallbackCategories.length]['title'] as String;

        // Subcategories for selected group
        List<CategoryModel> liveSubcategories = [];
        if (hasLiveGroups) {
          liveSubcategories = catProvider.categoriesForGroup(currentGroupId);
          if (_searchQuery.isNotEmpty) {
            liveSubcategories = liveSubcategories
                .where((c) => c.name.toLowerCase().contains(_searchQuery))
                .toList();
          }
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            title: Text(
              'All Categories',
              style: AppTextStyles.screenTitle.copyWith(
                fontSize: 19.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            actions: [
              Container(
                margin: EdgeInsets.only(right: 16.w),
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: AppColors.brandPurple.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.brandPurple,
                  size: 20.sp,
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Modern Search Input
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F5F9),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: const Color(0xFFE5E9F0)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 13.5.sp,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search categories or products...',
                        hintStyle: AppTextStyles.plusJakartaSans(
                          fontSize: 13.sp,
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w500,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppColors.brandPurple,
                          size: 20.sp,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 12.h,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 1,
                  color: const Color(0xFFEAEFF5),
                ),

                // Split View: Categories on Left Rail, Subcategories Grid on Right
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Left Side Category Rail
                      Container(
                        width: 96.w,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF4F6FA),
                          border: Border(
                            right: BorderSide(color: Color(0xFFE5E9F0), width: 1),
                          ),
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(vertical: 6.h),
                          itemCount: hasLiveGroups ? groups.length : _fallbackCategories.length,
                          itemBuilder: (context, index) {
                            final isSelected = index == _selectedCategoryIndex;

                            final String title = hasLiveGroups
                                ? groups[index].name
                                : _fallbackCategories[index]['title'] as String;
                            final String? imgUrl = hasLiveGroups
                                ? groups[index].imgPath
                                : null;
                            final IconData icon = hasLiveGroups
                                ? _getCategoryIcon(groups[index].name, groups[index].slag)
                                : _fallbackCategories[index]['icon'] as IconData;

                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedCategoryIndex = index;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: EdgeInsets.symmetric(vertical: 3.h, horizontal: 4.w),
                                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6.r),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.04),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (isSelected)
                                      Positioned(
                                        left: 0,
                                        child: Container(
                                          width: 3.5.w,
                                          height: 24.h,
                                          decoration: BoxDecoration(
                                            color: AppColors.brandPurple,
                                            borderRadius: BorderRadius.circular(4.r),
                                          ),
                                        ),
                                      ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Category Avatar / Icon
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: 46.r,
                                          height: 46.r,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.brandPurple.withValues(alpha: 0.08)
                                                : Colors.white,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.brandPurple
                                                  : const Color(0xFFE2E7EE),
                                              width: isSelected ? 1.8 : 1.0,
                                            ),
                                          ),
                                          child: (imgUrl != null && imgUrl.isNotEmpty)
                                              ? ClipOval(
                                                  child: Padding(
                                                    padding: EdgeInsets.all(5.r),
                                                    child: Image.network(
                                                      imgUrl,
                                                      fit: BoxFit.contain,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Icon(
                                                          icon,
                                                          color: isSelected
                                                              ? AppColors.brandPurple
                                                              : AppColors.iconSubtle,
                                                          size: 20.sp,
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                )
                                              : Icon(
                                                  icon,
                                                  color: isSelected
                                                      ? AppColors.brandPurple
                                                      : AppColors.iconSubtle,
                                                  size: 20.sp,
                                                ),
                                        ),
                                        6.height,
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 2.w),
                                          child: Text(
                                            title,
                                            textAlign: TextAlign.center,
                                            style: AppTextStyles.plusJakartaSans(
                                              fontSize: 10.sp,
                                              height: 1.15,
                                              fontWeight: isSelected
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                              color: isSelected
                                                  ? AppColors.brandPurple
                                                  : AppColors.textSecondary,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // 2. Right Side Subcategories Grid
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 8.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Group Header Banner
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      currentTitle,
                                      style: AppTextStyles.plusJakartaSans(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 3.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandPurple.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                    child: Text(
                                      hasLiveGroups
                                          ? '${liveSubcategories.length} items'
                                          : 'Items',
                                      style: AppTextStyles.plusJakartaSans(
                                        fontSize: 10.5.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.brandPurple,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              10.height,

                              // Subcategory Cards Grid
                              if (catProvider.isLoading && liveSubcategories.isEmpty)
                                Expanded(child: _buildShimmerGrid())
                              else if (hasLiveGroups && liveSubcategories.isNotEmpty)
                                Expanded(
                                  child: GridView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.84,
                                      crossAxisSpacing: 10.w,
                                      mainAxisSpacing: 10.h,
                                    ),
                                    itemCount: liveSubcategories.length,
                                    itemBuilder: (context, idx) {
                                      final sub = liveSubcategories[idx];
                                      return _buildSubcategoryCard(
                                        name: sub.name,
                                        imgUrl: sub.imgPath,
                                        slag: sub.slag,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CategoryProductsScreen(
                                                categoryId: sub.slag ?? sub.id.toString(),
                                                categoryName: sub.name,
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                )
                              else if (hasLiveGroups && liveSubcategories.isEmpty)
                                Expanded(
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.inventory_2_outlined,
                                          size: 42.sp,
                                          color: AppColors.textHint,
                                        ),
                                        8.height,
                                        Text(
                                          'No subcategories found',
                                          style: AppTextStyles.plusJakartaSans(
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                // Fallback mock subcategories
                                Expanded(
                                  child: GridView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.84,
                                      crossAxisSpacing: 10.w,
                                      mainAxisSpacing: 10.h,
                                    ),
                                    itemCount: (_fallbackCategories[_selectedCategoryIndex % _fallbackCategories.length]['subcategories'] as List).length,
                                    itemBuilder: (context, idx) {
                                      final subName = (_fallbackCategories[_selectedCategoryIndex % _fallbackCategories.length]['subcategories'] as List)[idx] as String;
                                      return _buildSubcategoryCard(
                                        name: subName,
                                        imgUrl: null,
                                        slag: null,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CategoryProductsScreen(
                                                categoryId: subName,
                                                categoryName: subName,
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Modern, attractive Subcategory Card Widget
  Widget _buildSubcategoryCard({
    required String name,
    required String? imgUrl,
    required String? slag,
    required VoidCallback onTap,
  }) {
    final iconData = _getCategoryIcon(name, slag);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7.r),
          border: Border.all(
            color: const Color(0xFFE9EDF4),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B273A).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Preview Container
            Expanded(
              flex: 5,
              child: Center(
                child: (imgUrl != null && imgUrl.isNotEmpty)
                      ? Padding(
                          padding: EdgeInsets.all(8.r),
                          child: Image.network(
                              imgUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  iconData,
                                  color: AppColors.brandPurple,
                                  size: 28.sp,
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: AppColors.brandPurple,
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                      : Icon(
                          iconData,
                          color: AppColors.brandPurple,
                          size: 28.sp,
                        ),
              ),
            ),

            // Bottom Name Label
            Expanded(
              flex: 3,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                child: Center(
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.plusJakartaSans(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.18,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
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

  /// Shimmer loading grid placeholder
  Widget _buildShimmerGrid() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.84,
        crossAxisSpacing: 10.w,
        mainAxisSpacing: 10.h,
      ),
      itemCount: 6,
      itemBuilder: (context, idx) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: const Color(0xFFE9EDF4)),
          ),
          padding: EdgeInsets.all(8.r),
          child: Column(
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F5F9),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              8.height,
              Container(
                height: 12.h,
                width: 60.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F5F9),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
