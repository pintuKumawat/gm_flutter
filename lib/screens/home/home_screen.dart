import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/core/responsive/responsive.dart';
import 'package:grahmitracus/models/product/home_product_model.dart';
import 'package:grahmitracus/models/product/spotlight_banner_model.dart';
import 'package:grahmitracus/models/product/trending_product_model.dart';
import 'package:grahmitracus/providers/product/category_group_provider.dart';
import 'package:grahmitracus/providers/product/category_provider.dart';
import 'package:grahmitracus/providers/product/home_group_products_provider.dart';
import 'package:grahmitracus/providers/product/spotlight_banner_provider.dart';
import 'package:grahmitracus/providers/product/trending_product_provider.dart';
import 'package:grahmitracus/models/product/category_model.dart';
import 'package:grahmitracus/providers/location/location_provider.dart';
import 'package:grahmitracus/screens/location/location_picker_screen.dart';
import 'package:grahmitracus/screens/product/product_detail_screen.dart';
import 'package:grahmitracus/screens/search/search_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:grahmitracus/providers/cart/cart_provider.dart';
import 'package:grahmitracus/screens/cart/cart_screen.dart';
import 'package:grahmitracus/widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int index)? onTabChange;

  const HomeScreen({super.key, this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _bannerPageController = PageController(
    initialPage: 3000,
  );
  final ScrollController _scrollController = ScrollController();
  Timer? _bannerTimer;
  Timer? _typewriterTimer;
  Timer? _cursorTimer;

  int _currentBannerIndex = 0;
  int _currentHintIndex = 0;
  String _currentTypedText = '';
  bool _isDeleting = false;
  int _charIndex = 0;
  bool _showCursor = true;

  bool _showScrollToTop = false;
  int? _lastAreaId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Listen to active area changes to dynamically refetch products
    final locationProv = context.watch<LocationProvider>();
    final currentAreaId = locationProv.activeAreaId;

    if (_lastAreaId != currentAreaId) {
      _lastAreaId = currentAreaId;

      // Fetch fresh products for the new location
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<TrendingProductProvider>().fetchTrendingProducts(
          areaId: currentAreaId,
          forceRefresh: true,
        );

        context.read<HomeGroupProductsProvider>().fetchCategoryGroupsProducts(
          areaId: currentAreaId,
          forceRefresh: true,
        );
      });
    }
  }

  // Typewriter animated search hints
  final List<String> _animatedHints = const [
    'Grocery',
    'Daily Needs',
    'Milk & Bread',
    'Fresh Fruits',
    'Vegetables',
    'Atta & Rice',
    'Dry Fruits',
    'Chips & Namkeen',
    'Tea & Coffee',
    'Mustard Oil & Ghee',
  ];

  // Promotional Offer Banners List
  final List<Map<String, dynamic>> _promoBanners = const [
    {
      'title': 'LAUNCHING OFFER!',
      'discount': 'FLAT 20% OFF',
      'tagline': 'Har Order me Apna Pan',
      'gradient': [Color(0xFF6B21A8), Color(0xFF7E22CE), Color(0xFF9333EA)],
    },
    {
      'title': 'PREMIUM DRY FRUITS',
      'discount': 'UP TO 40% OFF',
      'tagline': 'Fresh Almonds & Cashews',
      'gradient': [Color(0xFFEA580C), Color(0xFFF97316), Color(0xFFFB923C)],
    },
    {
      'title': 'DAILY ESSENTIALS',
      'discount': 'FLAT ₹50 OFF',
      'tagline': 'Fresh Milk, Bread & Bakery',
      'gradient': [Color(0xFF0D9488), Color(0xFF059669), Color(0xFF10B981)],
    },
  ];

  final List<Map<String, dynamic>> _groceryCategories = [
    {
      'title': 'Aata & Rice',
      'icon': Icons.grain_rounded,
      'color': AppColors.catAmberBg,
      'iconColor': AppColors.catAmberIcon,
    },
    {
      'title': 'Daal & Beans',
      'icon': Icons.spa_rounded,
      'color': AppColors.catEmeraldBg,
      'iconColor': AppColors.catEmeraldIcon,
    },
    {
      'title': 'Dry Fruits',
      'icon': Icons.energy_savings_leaf_rounded,
      'color': AppColors.catOrangeBg,
      'iconColor': AppColors.catOrangeIcon,
    },
    {
      'title': 'Masala & Salts',
      'icon': Icons.whatshot_rounded,
      'color': AppColors.catRedBg,
      'iconColor': AppColors.catRedIcon,
    },
    {
      'title': 'Oils & Ghee',
      'icon': Icons.opacity_rounded,
      'color': AppColors.catYellowBg,
      'iconColor': AppColors.catYellowIcon,
    },
    {
      'title': 'Packed Foods',
      'icon': Icons.fastfood_rounded,
      'color': AppColors.catBlueBg,
      'iconColor': AppColors.catBlueIcon,
    },
    {
      'title': 'Personal Care\nProduct',
      'icon': Icons.clean_hands_rounded,
      'color': AppColors.catPurpleBg,
      'iconColor': AppColors.catPurpleIcon,
    },
    {
      'title': 'Pooja & Worship\nNeeds',
      'icon': Icons.wb_sunny_rounded,
      'color': AppColors.catGoldBg,
      'iconColor': AppColors.catAmberIcon,
    },
    {
      'title': 'Seeds',
      'icon': Icons.eco_rounded,
      'color': AppColors.catGreenBg,
      'iconColor': AppColors.catGreenIcon,
    },
    {
      'title': 'Tea Coffee',
      'icon': Icons.coffee_rounded,
      'color': AppColors.catVioletBg,
      'iconColor': AppColors.catVioletIcon,
    },
  ];

  final List<Map<String, dynamic>> _trendingProducts = [
    {
      'id': 'p1',
      'name': 'Besan',
      'category': 'Besan',
      'seller': 'MLPC KIRANA',
      'weight': '250 Gm',
      'price': 25.00,
      'mrp': 28.00,
      'discount': '11% OFF',
      'icon': Icons.grain_rounded,
      'color': AppColors.catAmberBg,
      'iconColor': AppColors.catAmberIcon,
    },
    {
      'id': 'p2',
      'name': 'Anjeer',
      'category': 'Anjir',
      'seller': 'MLPC KIRANA',
      'weight': '250 Gm',
      'price': 300.00,
      'mrp': 320.00,
      'discount': '6% OFF',
      'icon': Icons.energy_savings_leaf_rounded,
      'color': AppColors.catOrangeBg,
      'iconColor': AppColors.catOrangeIcon,
    },
    {
      'id': 'p3',
      'name': 'Sabut Dhania',
      'category': 'Spices',
      'seller': 'MLPC KIRANA',
      'weight': '1 Kg',
      'price': 350.00,
      'mrp': 360.00,
      'discount': '3% OFF',
      'icon': Icons.spa_rounded,
      'color': AppColors.catGreenBg,
      'iconColor': AppColors.catGreenIcon,
    },
    {
      'id': 'p4',
      'name': 'Mustard Oil',
      'category': 'Kachi Ghani',
      'seller': 'MLPC KIRANA',
      'weight': '1 Ltr',
      'price': 145.00,
      'mrp': 170.00,
      'discount': '14% OFF',
      'icon': Icons.opacity_rounded,
      'color': AppColors.catYellowBg,
      'iconColor': AppColors.catYellowIcon,
    },
  ];

  final List<Map<String, dynamic>> _groceryProducts = [
    {
      'id': 'gp1',
      'name': 'Daily Good Raw Peanut Singdana',
      'category': 'Daily Good Raw Peanut Singdana',
      'price': 85.00,
      'mrp': 100.00,
      'badge': 'BESTSELLER',
      'isSoldOut': false,
      'icon': Icons.grass_rounded,
      'color': AppColors.catEmeraldBg,
      'iconColor': AppColors.catEmeraldIcon,
    },
    {
      'id': 'gp2',
      'name': 'Bim Power Of Lemon Liquid',
      'category': 'Bim power soap',
      'price': 55.00,
      'mrp': 65.00,
      'badge': null,
      'isSoldOut': false,
      'icon': Icons.sanitizer_rounded,
      'color': AppColors.catYellowBg,
      'iconColor': AppColors.catYellowIcon,
    },
    {
      'id': 'gp3',
      'name': 'Rin Detergent Bar',
      'category': 'Shop',
      'price': 20.00,
      'mrp': 22.00,
      'badge': null,
      'isSoldOut': false,
      'icon': Icons.dry_cleaning_rounded,
      'color': AppColors.catBlueBg,
      'iconColor': AppColors.catBlueIcon,
    },
    {
      'id': 'gp4',
      'name': 'Fortune Basmati Rice',
      'category': 'Rice',
      'price': 120.00,
      'mrp': 140.00,
      'badge': 'PREMIUM',
      'isSoldOut': false,
      'icon': Icons.rice_bowl_rounded,
      'color': AppColors.catGoldBg,
      'iconColor': AppColors.catAmberIcon,
    },
    {
      'id': 'gp5',
      'name': 'Broom Shink',
      'category': 'Cleaning',
      'price': 150.00,
      'mrp': 180.00,
      'badge': null,
      'isSoldOut': false,
      'icon': Icons.cleaning_services_rounded,
      'color': AppColors.catBlueBg,
      'iconColor': AppColors.catBlueIcon,
    },
    {
      'id': 'gp6',
      'name': 'Soft Floor Broom',
      'category': 'Household',
      'price': 120.00,
      'mrp': 140.00,
      'badge': null,
      'isSoldOut': false,
      'icon': Icons.brush_rounded,
      'color': AppColors.catGreenBg,
      'iconColor': AppColors.catGreenIcon,
    },
  ];

  @override
  void initState() {
    super.initState();
    _startBannerAutoScroll();
    _startTypewriterAnimation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CategoryGroupProvider>().fetchGroups();
        context.read<CategoryProvider>().fetchCategories();
        // Products are fetched dynamically via didChangeDependencies()
        context.read<SpotlightBannerProvider>().fetchBanners(
          displayLocation: 'home',
          forceRefresh: true,
        );
      }
    });
    _scrollController.addListener(() {
      final show = _scrollController.offset > 300;
      if (show != _showScrollToTop) {
        setState(() {
          _showScrollToTop = show;
        });
      }
    });
  }

  /// Auto-scroll promo banner carousel continuously forward every 3 seconds
  void _startBannerAutoScroll() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_bannerPageController.hasClients && _promoBanners.length > 1) {
        _bannerPageController.nextPage(
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  /// Typewriter animation for search hint text
  void _startTypewriterAnimation() {
    _typewriterTimer?.cancel();
    _cursorTimer?.cancel();

    // Blinking cursor toggle
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 530), (timer) {
      if (mounted) {
        setState(() {
          _showCursor = !_showCursor;
        });
      }
    });

    _scheduleNextTypewriterTick();
  }

  void _scheduleNextTypewriterTick() {
    if (!mounted) return;

    final currentWord = _animatedHints[_currentHintIndex];

    if (!_isDeleting) {
      // Typing forward
      if (_charIndex < currentWord.length) {
        _charIndex++;
        setState(() {
          _currentTypedText = currentWord.substring(0, _charIndex);
        });
        _typewriterTimer = Timer(
          const Duration(milliseconds: 85),
          _scheduleNextTypewriterTick,
        );
      } else {
        // Hold full word for 1.4 seconds before backspacing
        _typewriterTimer = Timer(const Duration(milliseconds: 1400), () {
          if (mounted) {
            _isDeleting = true;
            _scheduleNextTypewriterTick();
          }
        });
      }
    } else {
      // Backspacing
      if (_charIndex > 0) {
        _charIndex--;
        setState(() {
          _currentTypedText = currentWord.substring(0, _charIndex);
        });
        _typewriterTimer = Timer(
          const Duration(milliseconds: 40),
          _scheduleNextTypewriterTick,
        );
      } else {
        // Switch to next word
        _isDeleting = false;
        _currentHintIndex = (_currentHintIndex + 1) % _animatedHints.length;
        _typewriterTimer = Timer(
          const Duration(milliseconds: 250),
          _scheduleNextTypewriterTick,
        );
      }
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _typewriterTimer?.cancel();
    _cursorTimer?.cancel();
    _searchController.dispose();
    _bannerPageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    HapticFeedback.selectionClick();
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _updateCart(
    String id,
    int delta,
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
    final updated = current + delta;
    cart.updateQuantity(
      id,
      updated,
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

    if (delta > 0 && updated == 1) {
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
                      builder: (_) =>
                          CartScreen(onNavigateTab: widget.onTabChange),
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

  // void _showPolicySheet(String title, String content) {
  //   HapticFeedback.selectionClick();
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.white,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
  //     ),
  //     builder: (context) {
  //       return DraggableScrollableSheet(
  //         initialChildSize: 0.65,
  //         minChildSize: 0.4,
  //         maxChildSize: 0.9,
  //         expand: false,
  //         builder: (context, scrollController) {
  //           return Padding(
  //             padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
  //             child: ListView(
  //               controller: scrollController,
  //               children: [
  //                 Center(
  //                   child: Container(
  //                     width: 40.w,
  //                     height: 4.h,
  //                     decoration: BoxDecoration(
  //                       color: AppColors.borderSubtle,
  //                       borderRadius: BorderRadius.circular(2.r),
  //                     ),
  //                   ),
  //                 ),
  //                 18.height,
  //                 Text(
  //                   title,
  //                   style: AppTextStyles.plusJakartaSans(
  //                     fontSize: 18.sp,
  //                     fontWeight: FontWeight.w800,
  //                     color: AppColors.textPrimary,
  //                   ),
  //                 ),
  //                 14.height,
  //                 Text(
  //                   content,
  //                   style: AppTextStyles.plusJakartaSans(
  //                     fontSize: 13.sp,
  //                     fontWeight: FontWeight.w500,
  //                     color: AppColors.textSecondary,
  //                     height: 1.5,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Modern Header & Fast Delivery Badge
              _buildTopHeader(),
              6.height,

              // 2. Modern Elevated Search Bar
              _buildSearchBar(),
              10.height,

              // 4. API Connected Category Groups Bar
              _buildTopCategoryTabs(),
              12.height,

              // 5. Seamless Infinite Auto-Scroll Promo Offers Carousel
              _buildPromoBannerCarousel(),
              14.height,

              // 6. Dynamic Subcategories Grid
              _buildGroceryCategorySection(),
              18.height,

              // 7. Trending & Flash Deals Horizontal Carousel
              _buildTrendingSection(),
              18.height,

              // 8. Super Saver Product Grid Section
              _buildGroceryProductGridSection(),
              24.height,

              // // 10. Footer Policy Links
              // _buildFooterPolicyLinks(),
              20.height,
            ],
          ),
        ),
      ),
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton(
              mini: true,
              backgroundColor: AppColors.brandPurple,
              onPressed: _scrollToTop,
              elevation: 4,
              child: const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Colors.white,
                size: 26,
              ),
            )
          : null,
    );
  }

  void _openLocationPicker() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );
  }

  /// 1. Top Header: Modern Brand Bar, 10 Min Delivery Pill, Location & Action Badges
  Widget _buildTopHeader() {
    final cart = context.watch<CartProvider>();
    final totalCartCount = cart.totalQuantity;
    final locationProv = context.watch<LocationProvider>();
    final currentAddress = locationProv.currentLocation.displayString;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Brand Logo
              Image.asset(
                'assets/images/Grahmitra_logo.png',
                height: 25.h,
                fit: BoxFit.contain,
              ),

              // Action Buttons: Cart + Profile
              Row(
                children: [
                  // Cart Button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CartScreen(onNavigateTab: widget.onTabChange),
                        ),
                      );
                    },
                    child: Container(
                      width: 40.r,
                      height: 40.r,
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
                            color: AppColors.textPrimary,
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
                  8.width,

                  // Profile Button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onTabChange?.call(4);
                    },
                    child: Container(
                      width: 40.r,
                      height: 40.r,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6FB),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE5E9F0)),
                      ),
                      child: Icon(
                        Icons.person_outline_rounded,
                        size: 21.sp,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          3.height,
          // Location Header
          GestureDetector(
            onTap: _openLocationPicker,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 15.sp,
                  color: AppColors.brandPurple,
                ),
                3.width,
                Flexible(
                  child: Text(
                    currentAddress,
                    style: AppTextStyles.plusJakartaSans(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 17.sp,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openSearchScreen({String? query, bool startVoice = false}) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SearchScreen(initialQuery: query, startVoice: startVoice),
      ),
    );
  }

  /// 2. Modern Elevated Search Bar with Voice and Animated Typewriter Hints
  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: GestureDetector(
        onTap: () => _openSearchScreen(
          query: _searchController.text.isNotEmpty
              ? _searchController.text
              : null,
        ),
        child: Container(
          height: 40.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFE5E9F0), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B273A).withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.search_rounded,
                color: AppColors.brandPurple,
                size: 22.sp,
              ),
              8.width,
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Search ',
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textHint,
                      ),
                    ),
                    Flexible(
                      child: RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '"$_currentTypedText',
                              style: AppTextStyles.plusJakartaSans(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandPurple,
                              ),
                            ),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 150),
                                opacity: _showCursor ? 1.0 : 0.0,
                                child: Container(
                                  width: 1.8.w,
                                  height: 14.h,
                                  margin: EdgeInsets.symmetric(horizontal: 1.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandPurple,
                                    borderRadius: BorderRadius.circular(1.r),
                                  ),
                                ),
                              ),
                            ),
                            TextSpan(
                              text: '"',
                              style: AppTextStyles.plusJakartaSans(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _openSearchScreen(startVoice: true),
                child: Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: AppColors.brandPurple.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mic_none_rounded,
                    color: AppColors.brandPurple,
                    size: 18.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 3. Quick Trust Features Bar: 12 Min Delivery, 100% Quality, Easy Return
  Widget _buildQuickTrustFeatures() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          _buildTrustPill(
            Icons.verified_user_rounded,
            '100% Quality',
            const Color(0xFFDCFCE7),
            const Color(0xFF15803D),
          ),
          8.width,
          _buildTrustPill(
            Icons.currency_rupee_rounded,
            'Best Prices',
            const Color(0xFFE0E7FF),
            const Color(0xFF4338CA),
          ),
          8.width,
          _buildTrustPill(
            Icons.published_with_changes_rounded,
            'Easy Return',
            const Color(0xFFF3E8FF),
            const Color(0xFF7E22CE),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustPill(
    IconData icon,
    String title,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: textColor),
          4.width,
          Text(
            title,
            style: AppTextStyles.plusJakartaSans(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper to resolve icon for Category Groups dynamically
  IconData _getGroupIcon(String? name, String? slag) {
    final text = '${name ?? ''} ${slag ?? ''}'.toLowerCase();
    if (text.contains('food') ||
        text.contains('beverage') ||
        text.contains('drink')) {
      return Icons.local_drink_outlined;
    } else if (text.contains('grocery') || text.contains('groceries')) {
      return Icons.shopping_basket_outlined;
    } else if (text.contains('fruit') || text.contains('veg')) {
      return Icons.eco_outlined;
    } else if (text.contains('daily') || text.contains('need')) {
      return Icons.breakfast_dining_outlined;
    } else if (text.contains('snack') || text.contains('packed')) {
      return Icons.fastfood_rounded;
    } else if (text.contains('care') || text.contains('personal')) {
      return Icons.clean_hands_rounded;
    } else if (text.contains('dry') || text.contains('nuts')) {
      return Icons.energy_savings_leaf_rounded;
    } else if (text.contains('spice') || text.contains('masala')) {
      return Icons.whatshot_rounded;
    } else if (text.contains('oil') || text.contains('ghee')) {
      return Icons.opacity_rounded;
    } else if (text.contains('tea') || text.contains('coffee')) {
      return Icons.coffee_rounded;
    }
    return Icons.grid_view_rounded;
  }

  /// 4. Horizontal Quick Category Tabs: "All" + dynamically fetched groups from /api/groups
  Widget _buildTopCategoryTabs() {
    return Consumer<CategoryGroupProvider>(
      builder: (context, groupProvider, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final horizontalPadding = 16.w;
        final availableWidth = screenWidth - (horizontalPadding * 2);

        if (groupProvider.isLoading && groupProvider.groups.isEmpty) {
          final itemWidth = availableWidth / 4;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (index) {
                return SizedBox(
                  width: itemWidth,
                  child: Column(
                    children: [
                      Container(
                        width: 52.w,
                        height: 52.w,
                        decoration: const BoxDecoration(
                          color: AppColors.subtleBackground,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.brandPurple,
                            ),
                          ),
                        ),
                      ),
                      6.height,
                      Container(
                        width: 44.w,
                        height: 10.h,
                        decoration: BoxDecoration(
                          color: AppColors.subtleBackground,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          );
        }

        final activeGroups = groupProvider.groups
            .where((g) => g.active)
            .toList();

        final totalCount = 1 + activeGroups.length;

        Widget buildCategoryItem(int index) {
          final isAll = index == 0;
          final isSelected = isAll
              ? groupProvider.selectedGroupId == null
              : groupProvider.selectedGroupId == activeGroups[index - 1].id;

          final String title = isAll ? 'All' : activeGroups[index - 1].name;
          final String formattedTitle = title.replaceFirst(' & ', ' &\n');
          final IconData iconData = isAll
              ? Icons.all_inclusive_rounded
              : _getGroupIcon(
                  activeGroups[index - 1].name,
                  activeGroups[index - 1].slag,
                );

          final String? imgUrl = !isAll
              ? activeGroups[index - 1].imgPath
              : null;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              if (isAll) {
                groupProvider.selectGroup(null);
                context.read<HomeGroupProductsProvider>().clearSelectedGroup();
              } else {
                final grp = activeGroups[index - 1];
                groupProvider.selectGroup(grp.id);
                if (grp.slag != null && grp.slag!.isNotEmpty) {
                  final currentAreaId = context
                      .read<LocationProvider>()
                      .activeAreaId;
                  context
                      .read<HomeGroupProductsProvider>()
                      .fetchProductsForGroupSlug(
                        slug: grp.slag!,
                        areaId: currentAreaId,
                      );
                }
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Minimal Icon / Image
                SizedBox(
                  height: 26.h,
                  child: Center(
                    child: isAll
                        ? SizedBox(
                            width: 30.w,
                            height: 30.w,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.refresh_rounded,
                                  size: 35.w,
                                  color: const Color(0xFFE86F52),
                                ),
                                Transform.translate(
                                  offset: Offset(1.5.w, 1.w),
                                  child: Text(
                                    'ALL',
                                    style: AppTextStyles.plusJakartaSans(
                                      fontSize: 7.sp,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : (imgUrl != null && imgUrl.isNotEmpty)
                        ? Image.network(
                            imgUrl,
                            width: 24.w,
                            height: 24.w,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                iconData,
                                color: isSelected
                                    ? AppColors.brandPurple
                                    : AppColors.textPrimary,
                                size: 22.sp,
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: AppColors.brandPurple,
                                ),
                              );
                            },
                          )
                        : Icon(
                            iconData,
                            color: isSelected
                                ? AppColors.brandPurple
                                : AppColors.textPrimary,
                            size: 22.sp,
                          ),
                  ),
                ),
                4.height,
                // Category Title
                Text(
                  formattedTitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 10.5.sp,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? AppColors.brandPurple
                        : AppColors.textSecondary,
                  ),
                ),
                4.height,
                // Active indicator bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 22.w : 0,
                  height: 2.h,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.brandPurple
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalCount, buildCategoryItem),
          ),
        );
      },
    );
  }

  /// 5. Promotional Banner Carousel: API-Connected Spotlight Banners with Fallback
  Widget _buildPromoBannerCarousel() {
    return Consumer<SpotlightBannerProvider>(
      builder: (context, spotlightProvider, child) {
        final apiBanners = spotlightProvider.banners;
        final bool hasApiBanners = apiBanners.isNotEmpty;
        final int bannerCount = hasApiBanners
            ? apiBanners.length
            : _promoBanners.length;

        return Column(
          children: [
            SizedBox(
              height: 128.h,
              child: PageView.builder(
                controller: _bannerPageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentBannerIndex = index % bannerCount;
                  });
                },
                itemBuilder: (context, index) {
                  final realIndex = index % bannerCount;
                  if (hasApiBanners) {
                    final banner = apiBanners[realIndex];
                    return _buildSpotlightBannerCard(banner);
                  }
                  final banner = _promoBanners[realIndex];
                  return _buildPromoBannerCard(
                    title: banner['title'] as String,
                    discount: banner['discount'] as String,
                    tagline: banner['tagline'] as String,
                    gradient: banner['gradient'] as List<Color>,
                  );
                },
              ),
            ),
            8.height,
            // Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(bannerCount, (index) {
                final isActive = _currentBannerIndex == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: EdgeInsets.symmetric(horizontal: 3.w),
                  width: isActive ? 16.w : 5.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.brandPurple
                        : const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  /// Dynamic API Spotlight Banner Card
  Widget _buildSpotlightBannerCard(SpotlightBannerModel banner) {
    final imgUrl = banner.fullImageUrl;
    final List<List<Color>> gradients = [
      [
        const Color(0xFF6B21A8),
        const Color(0xFF7E22CE),
        const Color(0xFF9333EA),
      ],
      [
        const Color(0xFFEA580C),
        const Color(0xFFF97316),
        const Color(0xFFFB923C),
      ],
      [
        const Color(0xFF0D9488),
        const Color(0xFF059669),
        const Color(0xFF10B981),
      ],
    ];
    final gradient = gradients[banner.id % gradients.length];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: gradient[1].withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: (imgUrl != null && imgUrl.isNotEmpty)
          ? Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  imgUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPromoBannerContent(
                      title: banner.title,
                      discount: 'MEGA OFFER',
                      tagline: 'Har Order me Apna Pan',
                      gradient: gradient,
                    );
                  },
                ),
              ],
            )
          : _buildPromoBannerContent(
              title: banner.title,
              discount: 'SPECIAL OFFER',
              tagline: 'Best prices & fast delivery',
              gradient: gradient,
            ),
    );
  }

  Widget _buildPromoBannerContent({
    required String title,
    required String discount,
    required String tagline,
    required List<Color> gradient,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade300,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    discount,
                    style: AppTextStyles.plusJakartaSans(
                      fontSize: 9.5.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
                4.height,
                Text(
                  title,
                  style: AppTextStyles.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                2.height,
                Text(
                  tagline,
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          8.width,
          Expanded(
            flex: 3,
            child: Container(
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_shipping_rounded,
                      size: 28.sp,
                      color: Colors.white,
                    ),
                    3.height,
                    Text(
                      '12 MINS',
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBannerCard({
    required String title,
    required String discount,
    required String tagline,
    required List<Color> gradient,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: gradient[1].withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade300,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      discount,
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1E293B),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  4.height,
                  Text(
                    title,
                    style: AppTextStyles.poppins(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  2.height,
                  Text(
                    tagline,
                    style: AppTextStyles.plusJakartaSans(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                  8.height,
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shopping_bag_rounded,
                          size: 11.sp,
                          color: gradient[0],
                        ),
                        4.width,
                        Text(
                          'SHOP NOW',
                          style: AppTextStyles.plusJakartaSans(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w800,
                            color: gradient[0],
                          ),
                        ),
                        2.width,
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 11.sp,
                          color: gradient[0],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          8.width,
          Expanded(
            flex: 3,
            child: Container(
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_shipping_rounded,
                        size: 30.sp,
                        color: Colors.white,
                      ),
                      4.height,
                      Text(
                        '12 MINS',
                        style: AppTextStyles.plusJakartaSans(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 6. Grocery Category Grid: Dynamic Subcategories from API or default categories
  Widget _buildGroceryCategorySection() {
    return Consumer2<CategoryGroupProvider, CategoryProvider>(
      builder: (context, groupProvider, catProvider, child) {
        final selectedGroupId = groupProvider.selectedGroupId;

        // Helper to build the circular category item
        Widget buildCircularCategoryItem(dynamic cat) {
          final isDynamic = cat is CategoryModel;
          final title = isDynamic ? cat.name : cat['title'] as String;
          final imgPath = isDynamic ? cat.imgPath : null;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              if (isDynamic && cat.catGroupId != null) {
                groupProvider.selectGroup(cat.catGroupId);
              }
              widget.onTabChange?.call(1);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60.r,
                  height: 60.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200, width: 1.5),
                    color: Colors.white,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imgPath != null && imgPath.isNotEmpty
                      ? Image.network(
                          imgPath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(Icons.category, color: Colors.grey, size: 24.sp),
                        )
                      : Icon(isDynamic ? Icons.category : cat['icon'] as IconData, color: Colors.grey, size: 24.sp),
                ),
                8.height,
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          );
        }

        if (selectedGroupId != null) {
          // Specific group selected ("Explore X")
          final dynamicCats = catProvider.categoriesForGroup(selectedGroupId);
          
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Explore ${groupProvider.selectedGroup!.name}',
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                14.height,
                if (dynamicCats.isNotEmpty)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dynamicCats.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16.h,
                      crossAxisSpacing: 8.w,
                      childAspectRatio: 0.7,
                    ),
                    itemBuilder: (context, index) {
                      return buildCircularCategoryItem(dynamicCats[index]);
                    },
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _groceryCategories.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16.h,
                      crossAxisSpacing: 8.w,
                      childAspectRatio: 0.7,
                    ),
                    itemBuilder: (context, index) {
                      return buildCircularCategoryItem(_groceryCategories[index]);
                    },
                  ),
              ],
            ),
          );
        }

        // "All" selected - Show grouped Popular Categories
        final groups = groupProvider.groups;
        if (groups.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Popular Categories',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              16.height,
              ...groups.map((group) {
                final subcats = catProvider.categoriesForGroup(group.id);
                if (subcats.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: AppTextStyles.plusJakartaSans(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      12.height,
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: subcats.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 8.h,
                          crossAxisSpacing: 4.w,
                          childAspectRatio: 0.85,
                        ),
                        itemBuilder: (context, index) {
                          return buildCircularCategoryItem(subcats[index]);
                        },
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  /// 7. "Trending Near You" Product Section connected to GET /api/products/trendings?area_id=101
  Widget _buildTrendingSection() {
    return Consumer<TrendingProductProvider>(
      builder: (context, trendingProvider, child) {
        final apiProducts = trendingProvider.products;
        final bool isLoading =
            trendingProvider.isLoading && apiProducts.isEmpty;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trending Near You',
                        style: AppTextStyles.plusJakartaSans(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      2.height,
                      Text(
                        'Handpicked fresh deals & daily essentials',
                        style: AppTextStyles.plusJakartaSans(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: 14.sp,
                          color: AppColors.brandOrange,
                        ),
                        2.width,
                        Text(
                          'HOT',
                          style: AppTextStyles.plusJakartaSans(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              12.height,
              // Horizontal Product Card Slider
              if (isLoading)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: List.generate(4, (index) {
                      return Container(
                        width: 142.w,
                        height: 210.h,
                        margin: EdgeInsets.only(right: 12.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: const Color(0xFFE9EDF4)),
                        ),
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
                      );
                    }),
                  ),
                )
              else if (apiProducts.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  clipBehavior: Clip.none,
                  child: Row(
                    children: List.generate(apiProducts.length, (index) {
                      final product = apiProducts[index];
                      return Padding(
                        padding: EdgeInsets.only(right: 12.w),
                        child: _buildApiTrendingProductCard(product, index),
                      );
                    }),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  clipBehavior: Clip.none,
                  child: Row(
                    children: List.generate(_trendingProducts.length, (index) {
                      final product = _trendingProducts[index];
                      return Padding(
                        padding: EdgeInsets.only(right: 12.w),
                        child: _buildTrendingProductCard(product),
                      );
                    }),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Modern Quick-Commerce Trending Product Card (API connected, Next.js ProductCard design)
  Widget _buildApiTrendingProductCard(TrendingProductModel product, int index) {
    final id = product.id.toString();
    final quantity = context.watch<CartProvider>().getQuantity(id);
    final homeProd = HomeProductModel(
      id: product.id,
      title: product.title,
      sellPrice: product.sellPrice,
      mrpPrice: product.mrpPrice,
      productImg: product.imgPath,
      variationName: product.weight ?? '1 Pack',
      storeName: product.storeName,
      brand: product.categoryName,
      isTrending: 1,
      stockQuantity: 15,
    );

    return SizedBox(
      width: 146.w,
      height: 180.h,
      child: ProductCard(
        product: homeProd,
        quantity: quantity,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(
                productIdOrSlug: product.id.toString(),
                initialProduct: homeProd,
              ),
            ),
          );
        },
        onQuantityChanged: (qty) => _updateCart(
          id,
          qty - quantity,
          product.title,
          sellPrice: product.sellPrice,
          mrpPrice: product.mrpPrice,
          imgPath: product.imgPath,
          weight: product.weight,
          category: product.categoryName,
          storeName: product.storeName,
          productId: product.id.toString(),
          variationId: product.variationId?.toString(),
        ),
      ),
    );
  }

  /// Compact Trending Product Card (Fallback mock model, Next.js ProductCard design)
  Widget _buildTrendingProductCard(Map<String, dynamic> product) {
    final id = product['id'] as String;
    final quantity = context.watch<CartProvider>().getQuantity(id);
    final homeProd = HomeProductModel(
      id: int.tryParse(id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1,
      title: product['name'] as String? ?? '',
      sellPrice: (product['price'] as num?)?.toDouble() ?? 0.0,
      mrpPrice: (product['mrp'] as num?)?.toDouble() ?? 0.0,
      brand: product['category'] as String?,
      storeName: product['seller'] as String?,
      variationName: product['weight'] as String? ?? '250 Grams',
      isTrending: 1,
      stockQuantity: 20,
    );

    return SizedBox(
      width: 146.w,
      height: 180.h,
      child: ProductCard(
        product: homeProd,
        quantity: quantity,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(
                productIdOrSlug: homeProd.id.toString(),
                initialProduct: homeProd,
              ),
            ),
          );
        },
        onQuantityChanged: (qty) => _updateCart(
          id,
          qty - quantity,
          product['name'] as String? ?? '',
          sellPrice: (product['price'] as num?)?.toDouble() ?? 0.0,
          mrpPrice: (product['mrp'] as num?)?.toDouble() ?? 0.0,
          weight: product['weight'] as String?,
          category: product['category'] as String?,
          storeName: product['seller'] as String?,
          productId: homeProd.id.toString(),
          variationId: homeProd.variationId?.toString(),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getItemsForCategoryGroup(
    String groupName, [
    String? slag,
  ]) {
    final lowerName = groupName.toLowerCase();
    final lowerSlug = slag?.toLowerCase() ?? '';
    final filtered = _groceryProducts.where((p) {
      final cat = (p['category'] as String? ?? '').toLowerCase();
      final name = (p['name'] as String? ?? '').toLowerCase();
      return cat.contains(lowerName) ||
          name.contains(lowerName) ||
          (lowerSlug.isNotEmpty &&
              (cat.contains(lowerSlug) || name.contains(lowerSlug)));
    }).toList();
    return filtered.isNotEmpty ? filtered : _groceryProducts;
  }

  /// 8. Dynamic Super Saver / Category Product Grid Section (API Connected)
  Widget _buildGroceryProductGridSection() {
    return Consumer2<CategoryGroupProvider, HomeGroupProductsProvider>(
      builder: (context, groupProvider, homeGroupProvider, child) {
        final selectedGroup = groupProvider.selectedGroup;
        final bool hasSelectedCategory = selectedGroup != null;

        // Dynamic Section Title: Selected category name or "Super Saver Deals" when "All"
        final String sectionTitle = hasSelectedCategory
            ? selectedGroup.name
            : 'Super Saver Deals';

        final String sectionBadge = hasSelectedCategory
            ? '${selectedGroup.name.toUpperCase()} SPECIAL'
            : 'UP TO 30% OFF';

        // Check if API has returned products for this selected category
        final apiProductsForGroup = hasSelectedCategory
            ? (homeGroupProvider.selectedGroupProducts.isNotEmpty
                  ? homeGroupProvider.selectedGroupProducts
                  : homeGroupProvider.getProductsForGroup(
                      selectedGroup.name,
                      selectedGroup.slag,
                    ))
            : <HomeProductModel>[];

        final fallbackItems = hasSelectedCategory
            ? _getItemsForCategoryGroup(selectedGroup.name, selectedGroup.slag)
            : _groceryProducts;

        final bool useApiProducts = apiProductsForGroup.isNotEmpty;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // If viewing "All" and API category groups products are available, show grouped rails
              if (!hasSelectedCategory &&
                  homeGroupProvider.groupProducts.isNotEmpty)
                ...homeGroupProvider.groupProducts.map((group) {
                  if (group.products.isEmpty) return const SizedBox.shrink();
                  return Container(
                    margin: EdgeInsets.only(bottom: 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sub-header for group
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              group.groupName,
                              style: AppTextStyles.plusJakartaSans(
                                fontSize: 14.5.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${group.products.length} items',
                              style: AppTextStyles.plusJakartaSans(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.brandPurple,
                              ),
                            ),
                          ],
                        ),
                        8.height,
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: group.products.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 10.h,
                                crossAxisSpacing: 10.w,
                                mainAxisExtent: 185.h,
                              ),
                          itemBuilder: (context, index) {
                            return _buildApiHomeProductCard(
                              group.products[index],
                            );
                          },
                        ),
                      ],
                    ),
                  );
                })
              else if (useApiProducts)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: apiProductsForGroup.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10.h,
                    crossAxisSpacing: 10.w,
                    mainAxisExtent: 185.h,
                  ),
                  itemBuilder: (context, index) {
                    return _buildApiHomeProductCard(apiProductsForGroup[index]);
                  },
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: fallbackItems.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10.h,
                    crossAxisSpacing: 10.w,
                    mainAxisExtent: 185.h,
                  ),
                  itemBuilder: (context, index) {
                    return _buildGroceryGridCard(fallbackItems[index]);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  /// Modern API Product Card matching Next.js Frontend Design
  Widget _buildApiHomeProductCard(HomeProductModel product) {
    final id = product.id.toString();
    final quantity = context.watch<CartProvider>().getQuantity(id);

    return ProductCard(
      product: product,
      quantity: quantity,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              productIdOrSlug: product.slag ?? product.id.toString(),
              initialProduct: product,
            ),
          ),
        );
      },
      onQuantityChanged: (qty) => _updateCart(
        id,
        qty - quantity,
        product.title,
        sellPrice: product.sellPrice,
        mrpPrice: product.mrpPrice,
        imgPath: product.imgPath,
        weight: product.variationName,
        category: product.subcategory,
        productId: product.id.toString(),
        variationId: product.variationId?.toString(),
      ),
    );
  }

  /// 2-Column Grocery Product Card (Fallback converted to unified ProductCard)
  Widget _buildGroceryGridCard(Map<String, dynamic> item) {
    final id = item['id'] as String;
    final quantity = context.watch<CartProvider>().getQuantity(id);
    final prod = HomeProductModel(
      id: int.tryParse(id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1,
      title: item['name'] as String? ?? '',
      brand: item['category'] as String?,
      sellPrice: (item['price'] as num?)?.toDouble() ?? 0.0,
      mrpPrice: (item['mrp'] as num?)?.toDouble() ?? 0.0,
      variationName: item['weight'] as String? ?? '250 Grams',
      stockQuantity: (item['isSoldOut'] == true) ? 0 : 20,
    );

    return ProductCard(
      product: prod,
      quantity: quantity,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              productIdOrSlug: prod.id.toString(),
              initialProduct: prod,
            ),
          ),
        );
      },
      onQuantityChanged: (qty) => _updateCart(
        id,
        qty - quantity,
        prod.title,
        sellPrice: prod.sellPrice,
        mrpPrice: prod.mrpPrice,
        weight: prod.variationName,
        category: prod.brand,
        productId: prod.id.toString(),
        variationId: prod.variationId?.toString(),
      ),
    );
  }

  // /// 10. Footer Policy Links
  // Widget _buildFooterPolicyLinks() {
  //   return Padding(
  //     padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
  //     child: Column(
  //       children: [
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             GestureDetector(
  //               onTap: () => _showPolicySheet(
  //                 'Privacy Policy',
  //                 'At GrahMitra, your privacy is strictly protected. We do not sell your personal data. '
  //                     'Your location and contact details are used exclusively to process and deliver your orders efficiently.',
  //               ),
  //               child: Text(
  //                 'Privacy Policy',
  //                 style: AppTextStyles.plusJakartaSans(
  //                   fontSize: 11.5.sp,
  //                   fontWeight: FontWeight.w600,
  //                   color: AppColors.textSecondary,
  //                 ),
  //               ),
  //             ),
  //             Padding(
  //               padding: EdgeInsets.symmetric(horizontal: 8.w),
  //               child: const Text('•', style: TextStyle(color: Color(0xFFCBD5E1))),
  //             ),
  //             GestureDetector(
  //               onTap: () => _showPolicySheet(
  //                 'Terms & Conditions',
  //                 'By accessing or using GrahMitra, you agree to all user policies. '
  //                     'Orders once placed are fulfilled by verified local partner shops in your area.',
  //               ),
  //               child: Text(
  //                 'Terms',
  //                 style: AppTextStyles.plusJakartaSans(
  //                   fontSize: 11.5.sp,
  //                   fontWeight: FontWeight.w600,
  //                   color: AppColors.textSecondary,
  //                 ),
  //               ),
  //             ),
  //             Padding(
  //               padding: EdgeInsets.symmetric(horizontal: 8.w),
  //               child: const Text('•', style: TextStyle(color: Color(0xFFCBD5E1))),
  //             ),
  //             GestureDetector(
  //               onTap: () => _showPolicySheet(
  //                 'Refund Policy',
  //                 'If you receive an incorrect or damaged item, instant doorstep replacements or refunds are provided.',
  //               ),
  //               child: Text(
  //                 'Refund Policy',
  //                 style: AppTextStyles.plusJakartaSans(
  //                   fontSize: 11.5.sp,
  //                   fontWeight: FontWeight.w600,
  //                   color: AppColors.textSecondary,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         8.height,
  //         Text(
  //           '© 2026 Grahmitra. Handcrafted for your daily convenience.',
  //           style: AppTextStyles.plusJakartaSans(
  //             fontSize: 10.sp,
  //             color: AppColors.textLight,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  /// Modern Category Card: Quick-Commerce style squircle card with pastel image bubble + bold label
  Widget _buildModernCategoryCard({
    required String title,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required Color borderColor,
    String? imgUrl,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.all(5.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Pastel Image / Icon Bubble
                Expanded(
                  child: Center(
                    child: (imgUrl != null && imgUrl.isNotEmpty)
                        ? Padding(
                            padding: EdgeInsets.all(5.r),
                            child: Image.network(
                              imgUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  icon,
                                  size: 24.sp,
                                  color: iconColor,
                                );
                              },
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Center(
                                  child: SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: iconColor,
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : Icon(icon, size: 24.sp, color: iconColor),
                  ),
                ),
                4.height,
                // Category Title (up to 2 lines, centered)
                SizedBox(
                  height: 24.h,
                  child: Center(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                        height: 1.15,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
