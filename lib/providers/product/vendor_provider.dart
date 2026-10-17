import 'package:flutter/material.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/models/product/home_product_model.dart';
import 'package:grahmitracus/models/product/vendor_model.dart';
import 'package:grahmitracus/repositories/product/vendor_repo.dart';

/// Provider managing nearby vendor shops and individual store storefront state
class VendorProvider extends ChangeNotifier {
  final VendorRepo _repo;

  VendorProvider({VendorRepo? repo}) : _repo = repo ?? VendorRepo();

  // ── Vendors List State ──
  List<VendorModel> _vendors = [];
  bool _isLoading = false;
  String? _errorMessage;
  int? _lastFetchedAreaId;

  List<VendorModel> get vendors => List.unmodifiable(_vendors);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null && _errorMessage!.isNotEmpty;
  bool get hasVendors => _vendors.isNotEmpty;

  // ── Store Front / Detail State ──
  StoreDetailResponse? _storeDetailResponse;
  List<HomeProductModel> _storeProducts = [];
  bool _isStoreLoading = false;
  bool _isLoadingMore = false;
  String? _storeError;
  String _currentSlug = '';
  int _currentPage = 1;
  bool _hasMore = false;
  String _selectedCategory = '';
  String _searchQuery = '';

  StoreDetailResponse? get storeDetail => _storeDetailResponse;
  VendorModel? get currentStore => _storeDetailResponse?.store;
  List<HomeProductModel> get storeProducts =>
      List.unmodifiable(_storeProducts);
  bool get isStoreLoading => _isStoreLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get storeError => _storeError;
  bool get hasStoreError => _storeError != null && _storeError!.isNotEmpty;
  bool get hasMore => _hasMore;
  List<String> get storeCategories =>
      _storeDetailResponse?.storeCategories ?? const [];
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  /// Fetch nearby vendors list from `/api/vendors`
  Future<void> fetchVendors({int? areaId, bool forceRefresh = false}) async {
    if (!forceRefresh && _vendors.isNotEmpty && _lastFetchedAreaId == areaId) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _lastFetchedAreaId = areaId;
    notifyListeners();

    try {
      _vendors = await _repo.getVendors(areaId: areaId);
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load vendors: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch store details and products for a specific vendor via `/api/store/:slug`
  Future<void> fetchStoreDetails(
    String slug, {
    int? areaId,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _currentSlug == slug &&
        _storeProducts.isNotEmpty &&
        _storeDetailResponse != null) {
      return;
    }

    _currentSlug = slug;
    _currentPage = 1;
    _isStoreLoading = true;
    _storeError = null;
    notifyListeners();

    try {
      final res = await _repo.getStoreDetails(
        slug: slug,
        page: 1,
        category: _selectedCategory,
        search: _searchQuery,
        areaId: areaId,
      );

      _storeDetailResponse = res;
      _storeProducts = List<HomeProductModel>.from(res.products);
      _hasMore = res.page < res.totalPages && res.products.isNotEmpty;
      _isStoreLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _storeError = e.message;
      _isStoreLoading = false;
      notifyListeners();
    } catch (e) {
      _storeError = 'Failed to load store: $e';
      _isStoreLoading = false;
      notifyListeners();
    }
  }

  /// Load next page of store products
  Future<void> loadMoreStoreProducts({int? areaId}) async {
    if (_isLoadingMore || !_hasMore || _isStoreLoading || _currentSlug.isEmpty) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final res = await _repo.getStoreDetails(
        slug: _currentSlug,
        page: nextPage,
        category: _selectedCategory,
        search: _searchQuery,
        areaId: areaId,
      );

      if (res.products.isNotEmpty) {
        _currentPage = nextPage;
        _storeProducts.addAll(res.products);
        _hasMore = res.page < res.totalPages;
      } else {
        _hasMore = false;
      }
      _isLoadingMore = false;
      notifyListeners();
    } catch (_) {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Filter store products by category
  void setStoreCategory(String category, {int? areaId}) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    fetchStoreDetails(_currentSlug, areaId: areaId, forceRefresh: true);
  }

  /// Search inside current store
  void searchStoreProducts(String query, {int? areaId}) {
    _searchQuery = query;
    fetchStoreDetails(_currentSlug, areaId: areaId, forceRefresh: true);
  }

  /// Clear filter and search parameters
  void clearStoreFilters({int? areaId}) {
    _selectedCategory = '';
    _searchQuery = '';
    fetchStoreDetails(_currentSlug, areaId: areaId, forceRefresh: true);
  }

  /// Clear current store details (e.g. when exiting screen)
  void clearStoreDetails() {
    _storeDetailResponse = null;
    _storeProducts = [];
    _currentSlug = '';
    _currentPage = 1;
    _hasMore = false;
    _selectedCategory = '';
    _searchQuery = '';
    _storeError = null;
  }
}
