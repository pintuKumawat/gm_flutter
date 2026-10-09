import 'package:flutter/material.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/models/product/category_model.dart';
import 'package:grahmitracus/repositories/product/category_repo.dart';

/// Provider for managing subcategories associated with category groups.
class CategoryProvider extends ChangeNotifier {
  final CategoryRepo _repo;

  CategoryProvider({CategoryRepo? repo}) : _repo = repo ?? CategoryRepo();

  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;
  int? _selectedCatGroupId;
  int? _selectedCategoryId;

  // Getters
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null && _errorMessage!.isNotEmpty;
  int? get selectedCatGroupId => _selectedCatGroupId;
  int? get selectedCategoryId => _selectedCategoryId;

  /// Returns active subcategories filtered by category group id.
  /// If [groupId] is null, returns all active categories.
  List<CategoryModel> categoriesForGroup(int? groupId) {
    if (groupId == null) {
      return _categories.where((c) => c.active).toList();
    }
    return _categories
        .where((c) => c.active && c.catGroupId == groupId)
        .toList();
  }

  /// Currently selected category model
  CategoryModel? get selectedCategory {
    if (_selectedCategoryId == null) return null;
    try {
      return _categories.firstWhere((c) => c.id == _selectedCategoryId);
    } catch (_) {
      return null;
    }
  }

  /// Fetch subcategories from API
  Future<void> fetchCategories({
    int? catGroupId,
    bool forceRefresh = false,
  }) async {
    if (_isLoading) return;
    if (_categories.isNotEmpty && !forceRefresh && catGroupId == null) return;

    _isLoading = true;
    _errorMessage = null;
    _selectedCatGroupId = catGroupId;
    notifyListeners();

    try {
      final fetched = await _repo.getCategories(catGroupId: catGroupId);
      fetched.sort((a, b) {
        final orderA = a.sortOrder ?? 999;
        final orderB = b.sortOrder ?? 999;
        return orderA.compareTo(orderB);
      });

      _categories = fetched;
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load categories: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select a category group to filter subcategories
  void filterByGroup(int? catGroupId) {
    if (_selectedCatGroupId != catGroupId) {
      _selectedCatGroupId = catGroupId;
      _selectedCategoryId = null;
      notifyListeners();
    }
  }

  /// Select a specific subcategory
  void selectCategory(int? categoryId) {
    if (_selectedCategoryId != categoryId) {
      _selectedCategoryId = categoryId;
      notifyListeners();
    }
  }

  /// Reset provider state
  void reset() {
    _categories = [];
    _isLoading = false;
    _errorMessage = null;
    _selectedCatGroupId = null;
    _selectedCategoryId = null;
    notifyListeners();
  }
}
