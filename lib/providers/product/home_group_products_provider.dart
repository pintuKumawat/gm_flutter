import 'package:flutter/material.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/models/product/category_group_products_model.dart';
import 'package:grahmitracus/models/product/home_product_model.dart';
import 'package:grahmitracus/repositories/product/home_group_products_repo.dart';

/// Provider for managing Home Screen Category Groups & Products from `/api/category-groups-products`
/// and `/api/products?categoryGroupSlug=...`.
class HomeGroupProductsProvider extends ChangeNotifier {
  final HomeGroupProductsRepo _repo;

  HomeGroupProductsProvider({HomeGroupProductsRepo? repo})
      : _repo = repo ?? HomeGroupProductsRepo();

  List<CategoryGroupProductsModel> _groupProducts = [];
  List<HomeProductModel> _selectedGroupProducts = [];
  bool _isLoading = false;
  bool _isLoadingGroupProducts = false;
  String? _errorMessage;
  String? _selectedGroupSlug;

  // Getters
  List<CategoryGroupProductsModel> get groupProducts => _groupProducts;
  List<HomeProductModel> get selectedGroupProducts => _selectedGroupProducts;
  bool get isLoading => _isLoading;
  bool get isLoadingGroupProducts => _isLoadingGroupProducts;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null && _errorMessage!.isNotEmpty;
  String? get selectedGroupSlug => _selectedGroupSlug;

  /// Fetch all category groups with products from `/api/category-groups-products`
  Future<void> fetchCategoryGroupsProducts({
    int? areaId,
    String? pincode,
    double? lat,
    double? lng,
    bool forceRefresh = false,
  }) async {
    if (_isLoading) return;
    if (_groupProducts.isNotEmpty && !forceRefresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _repo.getCategoryGroupsProducts(
        areaId: areaId,
        pincode: pincode,
        lat: lat,
        lng: lng,
      );
      _groupProducts = fetched;
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load group products: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch products for a specific selected category group slug
  Future<void> fetchProductsForGroupSlug({
    required String slug,
    int? areaId,
    bool forceRefresh = false,
  }) async {
    if (_selectedGroupSlug == slug && _selectedGroupProducts.isNotEmpty && !forceRefresh) {
      return;
    }

    _selectedGroupSlug = slug;
    _isLoadingGroupProducts = true;
    notifyListeners();

    try {
      // First check if products are already present in loaded groupProducts
      final localMatch = _groupProducts.firstWhere(
        (g) => (g.groupSlag ?? '').toLowerCase() == slug.toLowerCase(),
        orElse: () => const CategoryGroupProductsModel(groupId: 0, groupName: ''),
      );

      if (localMatch.products.isNotEmpty && !forceRefresh) {
        _selectedGroupProducts = localMatch.products;
        _isLoadingGroupProducts = false;
        notifyListeners();
        return;
      }

      final fetched = await _repo.getProductsByGroupSlug(
        slug: slug,
        areaId: areaId,
      );
      _selectedGroupProducts = fetched;
      _isLoadingGroupProducts = false;
      notifyListeners();
    } catch (e) {
      // Fallback to local match if available
      final localMatch = _groupProducts.firstWhere(
        (g) => (g.groupSlag ?? '').toLowerCase() == slug.toLowerCase(),
        orElse: () => const CategoryGroupProductsModel(groupId: 0, groupName: ''),
      );
      _selectedGroupProducts = localMatch.products;
      _isLoadingGroupProducts = false;
      notifyListeners();
    }
  }

  /// Find products for a given category group name or slug from existing cache
  List<HomeProductModel> getProductsForGroup(String? name, String? slug) {
    if (name == null && slug == null) return [];
    final targetName = (name ?? '').toLowerCase();
    final targetSlug = (slug ?? '').toLowerCase();

    for (final group in _groupProducts) {
      final gName = group.groupName.toLowerCase();
      final gSlug = (group.groupSlag ?? '').toLowerCase();

      if (gSlug == targetSlug ||
          gName == targetName ||
          gName.contains(targetName) ||
          targetName.contains(gName)) {
        return group.products;
      }
    }
    return [];
  }

  /// Clear selected group filter
  void clearSelectedGroup() {
    _selectedGroupSlug = null;
    _selectedGroupProducts = [];
    notifyListeners();
  }
}
