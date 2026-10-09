import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/core/responsive/responsive.dart';
import 'package:grahmitracus/models/product/category_model.dart';
import 'package:grahmitracus/models/product/home_product_model.dart';
import 'package:grahmitracus/providers/cart/cart_provider.dart';
import 'package:grahmitracus/providers/location/location_provider.dart';
import 'package:grahmitracus/providers/product/category_provider.dart';
import 'package:grahmitracus/providers/product/search_provider.dart';
import 'package:grahmitracus/screens/cart/cart_screen.dart';
import 'package:grahmitracus/screens/location/location_picker_screen.dart';
import 'package:grahmitracus/screens/product/product_detail_screen.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Product Search Screen matching Next.js MobileSearch view with instant suggestion,
/// debounced API queries, recent search history, trending categories, and rich seller rows.
class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  final bool startVoice;

  const SearchScreen({super.key, this.initialQuery, this.startVoice = false});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _searchController;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;
  late AnimationController _micPulseController;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechInitialized = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: widget.initialQuery ?? '');
    _focusNode = FocusNode();
    _scrollController = ScrollController()..addListener(_onScroll);

    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final searchProvider = context.read<SearchProvider>();
      final catProvider = context.read<CategoryProvider>();

      // Link trending categories into search provider
      if (catProvider.categories.isNotEmpty) {
        searchProvider.setTrendingCategories(catProvider.categories);
      }

      if (widget.startVoice) {
        _toggleVoiceSearch();
      } else if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
        searchProvider.onQueryChanged(widget.initialQuery!);
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SearchProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    if (_isListening) {
      _speech.stop();
    }
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _micPulseController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    context.read<SearchProvider>().onQueryChanged(val);
  }

  void _handleSuggestionTap(SearchSuggestion suggestion) {
    HapticFeedback.selectionClick();
    if (suggestion.type == 'category' && suggestion.category != null) {
      _handleCategoryTap(suggestion.category!);
      return;
    }

    _searchController.text = suggestion.label;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.label.length),
    );
    context.read<SearchProvider>().searchImmediate(suggestion.label);
    _focusNode.unfocus();
  }

  void _handleCategoryTap(CategoryModel cat) {
    HapticFeedback.lightImpact();
    _searchController.text = cat.name;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: cat.name.length),
    );
    context.read<SearchProvider>().searchImmediate(cat.name);
    _focusNode.unfocus();
  }

  void _handleProductTap(HomeProductModel product) {
    HapticFeedback.lightImpact();
    context.read<SearchProvider>().saveRecentSearch(
          _searchController.text.isNotEmpty
              ? _searchController.text
              : product.title,
        );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          productIdOrSlug: product.slag ?? product.id.toString(),
          initialProduct: product,
        ),
      ),
    );
  }

  Future<void> _toggleVoiceSearch() async {
    HapticFeedback.mediumImpact();

    if (_isListening) {
      await _speech.stop();
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
      return;
    }

    if (!_speechInitialized) {
      try {
        _speechInitialized = await _speech.initialize(
          onStatus: (status) {
            if (!mounted) return;
            if (status == 'done' || status == 'notListening') {
              setState(() {
                _isListening = false;
              });
              final text = _searchController.text.trim();
              if (text.isNotEmpty) {
                context.read<SearchProvider>().searchImmediate(text);
              }
            }
          },
          onError: (errorNotification) {
            if (!mounted) return;
            setState(() {
              _isListening = false;
            });
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Voice error: ${errorNotification.errorMsg}',
                  style: AppTextStyles.plusJakartaSans(color: Colors.white),
                ),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            );
          },
        );
      } catch (e) {
        _speechInitialized = false;
      }
    }

    if (!_speechInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Speech recognition is unavailable or permission denied.',
              style: AppTextStyles.plusJakartaSans(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _isListening = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.mic_rounded, color: Colors.white, size: 20.sp),
              10.width,
              Expanded(
                child: Text(
                  'Listening... Speak now (e.g. "Milk", "Atta", "Rice")',
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 12.5.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.brandPurple,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );
    }

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        final recognized = result.recognizedWords;
        if (recognized.isNotEmpty) {
          _searchController.text = recognized;
          _searchController.selection = TextSelection.fromPosition(
            TextPosition(offset: recognized.length),
          );
          _onSearchChanged(recognized);
        }
        if (result.finalResult) {
          setState(() {
            _isListening = false;
          });
          if (recognized.trim().isNotEmpty) {
            context.read<SearchProvider>().searchImmediate(recognized.trim());
          }
        }
      },
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
      cancelOnError: true,
    );
  }

  void _updateQuantity(HomeProductModel product, int delta) {
    HapticFeedback.selectionClick();
    final cart = context.read<CartProvider>();
    final id = product.id.toString();
    final current = cart.getQuantity(id);
    final updated = (current + delta).clamp(0, 99);
    cart.updateQuantity(
      id,
      updated,
      title: product.title,
      sellPrice: product.sellPrice,
      mrpPrice: product.mrpPrice,
      imageUrl: product.imgPath,
      weight: product.variationName,
      category: product.subcategory ?? product.brand,
      storeName: product.storeName,
      productId: product.id.toString(),
      variationId: product.variationId?.toString(),
    );

    if (delta > 0) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Added "${product.title}" to cart',
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 12.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
                    color: Colors.amberAccent,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0C831F),
          duration: const Duration(milliseconds: 1600),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      );
    }
  }

  String _formatPrice(double price) {
    if (price % 1 == 0) {
      return '₹${price.toInt()}';
    }
    return '₹${price.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = context.watch<SearchProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Search Input Bar
          _buildSearchInput(searchProvider),

          // Divider Line
          Container(
            height: 6.h,
            color: const Color(0xFFF8FAFC),
          ),

          // Main Body
          Expanded(
            child: _searchController.text.trim().isEmpty
                ? _buildEmptyState(searchProvider)
                : _buildSearchResults(searchProvider),
          ),
        ],
      ),
    );
  }

  /// Top App Bar with back button, location pill, and action icons
  PreferredSizeWidget _buildAppBar() {
    final locationProv = context.watch<LocationProvider>();
    final displayLocation = locationProv.currentLocation.displayString;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.chevron_left_rounded,
          size: 28.sp,
          color: const Color(0xFF1F2937),
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
      ),
      titleSpacing: 0,
      title: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LocationPickerScreen(),
            ),
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on_rounded,
              size: 16.sp,
              color: AppColors.brandPurple,
            ),
            4.width,
            Flexible(
              child: Text(
                displayLocation,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18.sp,
              color: const Color(0xFF6B7280),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.notifications_none_rounded,
            size: 22.sp,
            color: const Color(0xFF374151),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
          },
        ),
        8.width,
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1.h),
        child: Container(
          color: const Color(0xFFF1F5F9),
          height: 1.h,
        ),
      ),
    );
  }

  /// Search Input Field with Clear & Voice Search Action
  Widget _buildSearchInput(SearchProvider searchProvider) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: _focusNode.hasFocus
                ? AppColors.brandPurple
                : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: AppColors.brandPurple,
              size: 20.sp,
            ),
            10.width,
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                autofocus: widget.initialQuery == null || widget.initialQuery!.isEmpty,
                textInputAction: TextInputAction.search,
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
                decoration: InputDecoration(
                  hintText: 'Search for atta, milk, chips, oil...',
                  hintStyle: AppTextStyles.plusJakartaSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF9CA3AF),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                ),
                onChanged: _onSearchChanged,
                onSubmitted: (query) {
                  if (query.trim().isNotEmpty) {
                    searchProvider.saveRecentSearch(query);
                    searchProvider.searchImmediate(query);
                  }
                },
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _searchController.clear();
                  searchProvider.clearSearch();
                },
                child: Padding(
                  padding: EdgeInsets.only(right: 6.w),
                  child: Container(
                    padding: EdgeInsets.all(3.r),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE2E8F0),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14.sp,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            GestureDetector(
              onTap: _toggleVoiceSearch,
              child: AnimatedBuilder(
                animation: _micPulseController,
                builder: (context, child) {
                  return Container(
                    padding: EdgeInsets.all(7.r),
                    decoration: BoxDecoration(
                      color: _isListening
                          ? Colors.red.withValues(
                              alpha: 0.15 + (_micPulseController.value * 0.15))
                          : AppColors.brandPurple.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _isListening ? Colors.red : AppColors.brandPurple,
                      size: 18.sp,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty Query View (Recent Searches + Trending Categories)
  Widget _buildEmptyState(SearchProvider searchProvider) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      children: [
        // 1. Recent Searches
        if (searchProvider.recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 16.sp,
                    color: const Color(0xFF64748B),
                  ),
                  6.width,
                  Text(
                    'RECENT SEARCHES',
                    style: AppTextStyles.plusJakartaSans(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  searchProvider.clearRecentSearches();
                },
                child: Text(
                  'Clear',
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandPurple,
                  ),
                ),
              ),
            ],
          ),
          10.height,
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: searchProvider.recentSearches.map((term) {
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _searchController.text = term;
                  _searchController.selection = TextSelection.fromPosition(
                    TextPosition(offset: term.length),
                  );
                  searchProvider.searchImmediate(term);
                  _focusNode.unfocus();
                },
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13.sp,
                        color: const Color(0xFF64748B),
                      ),
                      6.width,
                      Text(
                        term,
                        style: AppTextStyles.plusJakartaSans(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          20.height,
        ],

        // 2. Trending Categories Section
        Row(
          children: [
            Icon(
              Icons.trending_up_rounded,
              size: 16.sp,
              color: const Color(0xFF64748B),
            ),
            6.width,
            Text(
              'TRENDING CATEGORIES',
              style: AppTextStyles.plusJakartaSans(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        10.height,
        Consumer<CategoryProvider>(
          builder: (context, catProv, _) {
            final categories = catProv.categories;
            if (categories.isEmpty) {
              return const SizedBox.shrink();
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length > 10 ? 10 : categories.length,
              separatorBuilder: (context, _) => Divider(
                height: 1.h,
                thickness: 0.8.h,
                color: const Color(0xFFF1F5F9),
              ),
              itemBuilder: (context, index) {
                final cat = categories[index];
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 0.w,
                    vertical: 4.h,
                  ),
                  leading: Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 0.8,
                      ),
                    ),
                    child: cat.imgPath != null && cat.imgPath!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10.r),
                            child: Image.network(
                              cat.imgPath!,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Icon(
                                Icons.category_rounded,
                                color: AppColors.brandPurple,
                                size: 20.sp,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.trending_up_rounded,
                            color: AppColors.brandPurple,
                            size: 20.sp,
                          ),
                  ),
                  title: Text(
                    cat.name,
                    style: AppTextStyles.plusJakartaSans(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: Text(
                    'Grocery',
                    style: AppTextStyles.plusJakartaSans(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  onTap: () => _handleCategoryTap(cat),
                );
              },
            );
          },
        ),
      ],
    );
  }

  /// Active Query Results (Suggestions list + Product Cards/Rows)
  Widget _buildSearchResults(SearchProvider searchProvider) {
    if (searchProvider.isLoading && searchProvider.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 32.w,
              height: 32.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.brandPurple),
              ),
            ),
            12.height,
            Text(
              'Searching products for you...',
              style: AppTextStyles.plusJakartaSans(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    if (searchProvider.errorMessage != null &&
        searchProvider.results.isEmpty &&
        !searchProvider.isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(18.r),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 40.sp,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              14.height,
              Text(
                'No Products Found',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              6.height,
              Text(
                'We couldn\'t find any match for "${_searchController.text}". Try checking for spelling errors or searching another keyword.',
                textAlign: TextAlign.center,
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      children: [
        // In-memory Autocomplete Suggestions
        if (searchProvider.suggestions.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: searchProvider.suggestions.map((s) {
                return InkWell(
                  onTap: () => _handleSuggestionTap(s),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 9.h,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          s.type == 'recent'
                              ? Icons.history_rounded
                              : s.type == 'category'
                                  ? Icons.trending_up_rounded
                                  : Icons.search_rounded,
                          size: 16.sp,
                          color: const Color(0xFF94A3B8),
                        ),
                        10.width,
                        Expanded(
                          child: _buildHighlightedText(
                            s.label,
                            _searchController.text.trim(),
                          ),
                        ),
                        Icon(
                          Icons.north_west_rounded,
                          size: 14.sp,
                          color: const Color(0xFFCBD5E1),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          12.height,
        ],

        // Search Results Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SHOWING RESULTS (${searchProvider.results.length})',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Instant Delivery',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0C831F),
                ),
              ),
            ],
          ),
        ),
        8.height,

        // Results Product Rows
        ...searchProvider.results.map((product) {
          return _buildProductSearchRow(product);
        }),

        // Loading more indicator at bottom
        if (searchProvider.isLoadingMore)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Center(
              child: SizedBox(
                width: 24.w,
                height: 24.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.brandPurple),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Builds a RichText with the query portion highlighted in bold dark color
  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(
        text,
        style: AppTextStyles.plusJakartaSans(
          fontSize: 13.5.sp,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF475569),
        ),
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matchIndex = lowerText.indexOf(lowerQuery);

    if (matchIndex == -1) {
      return Text(
        text,
        style: AppTextStyles.plusJakartaSans(
          fontSize: 13.5.sp,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF475569),
        ),
      );
    }

    final before = text.substring(0, matchIndex);
    final match = text.substring(matchIndex, matchIndex + query.length);
    final after = text.substring(matchIndex + query.length);

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: before,
            style: AppTextStyles.plusJakartaSans(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          TextSpan(
            text: match,
            style: AppTextStyles.plusJakartaSans(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          TextSpan(
            text: after,
            style: AppTextStyles.plusJakartaSans(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  /// Product search result row matching Next.js MobileSearch.js seller & product row
  Widget _buildProductSearchRow(HomeProductModel product) {
    final qty =
        context.watch<CartProvider>().getQuantity(product.id.toString());
    final isOutOfStock = product.stockQuantity == 0;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: () => _handleProductTap(product),
          child: Padding(
            padding: EdgeInsets.all(10.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Product Thumbnail
                Stack(
                  children: [
                    Container(
                      width: 64.w,
                      height: 64.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: const Color(0xFFF1F5F9),
                          width: 1,
                        ),
                      ),
                      child: product.imgPath != null &&
                              product.imgPath!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10.r),
                              child: Image.network(
                                product.imgPath!,
                                fit: BoxFit.contain,
                                errorBuilder: (ctx, err, stack) => Icon(
                                  Icons.shopping_bag_outlined,
                                  color: AppColors.brandPurple,
                                  size: 24.sp,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.shopping_bag_outlined,
                              color: AppColors.brandPurple,
                              size: 24.sp,
                            ),
                    ),
                    if (product.discountPercent > 0)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C831F),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10.r),
                              bottomRight: Radius.circular(6.r),
                            ),
                          ),
                          child: Text(
                            '${product.discountPercent}% OFF',
                            style: AppTextStyles.plusJakartaSans(
                              fontSize: 8.5.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                12.width,

                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Product Title
                      Text(
                        product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.plusJakartaSans(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                          height: 1.25,
                        ),
                      ),
                      3.height,

                      // Seller / Store & Weight Badge
                      Row(
                        children: [
                          if (product.storeName != null &&
                              product.storeName!.isNotEmpty) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                product.storeName!,
                                style: AppTextStyles.plusJakartaSans(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ),
                            6.width,
                          ],
                          Text(
                            product.variationName ?? '1 unit',
                            style: AppTextStyles.plusJakartaSans(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      4.height,

                      // Price & MRP
                      Row(
                        children: [
                          Text(
                            _formatPrice(product.sellPrice),
                            style: AppTextStyles.plusJakartaSans(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          if (product.mrpPrice > product.sellPrice) ...[
                            6.width,
                            Text(
                              _formatPrice(product.mrpPrice),
                              style: AppTextStyles.plusJakartaSans(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF94A3B8),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                          if (isOutOfStock) ...[
                            8.width,
                            Text(
                              'Out of stock',
                              style: AppTextStyles.plusJakartaSans(
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFE11D48),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                8.width,

                // Add / Stepper Button
                if (isOutOfStock)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'UNAVAILABLE',
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  )
                else if (qty == 0)
                  GestureDetector(
                    onTap: () => _updateQuantity(product, 1),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: AppColors.brandPurple,
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        'ADD',
                        style: AppTextStyles.plusJakartaSans(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandPurple,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 32.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C831F),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => _updateQuantity(product, -1),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.w),
                            child: Icon(
                              Icons.remove_rounded,
                              size: 16.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          '$qty',
                          style: AppTextStyles.plusJakartaSans(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        InkWell(
                          onTap: () => _updateQuantity(product, 1),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.w),
                            child: Icon(
                              Icons.add_rounded,
                              size: 16.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
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
