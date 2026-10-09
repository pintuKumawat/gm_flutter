import 'package:flutter/material.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/models/product/trending_product_model.dart';
import 'package:grahmitracus/repositories/product/trending_product_repo.dart';

/// Provider for managing Trending Products state fetched from `/api/products/trendings`.
class TrendingProductProvider extends ChangeNotifier {
  final TrendingProductRepo _repo;

  TrendingProductProvider({TrendingProductRepo? repo})
      : _repo = repo ?? TrendingProductRepo();

  List<TrendingProductModel> _products = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentAreaId = 101;

  // Getters
  List<TrendingProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null && _errorMessage!.isNotEmpty;
  int get currentAreaId => _currentAreaId;

  /// Fetch trending products from API
  Future<void> fetchTrendingProducts({
    int areaId = 101,
    bool forceRefresh = false,
  }) async {
    if (_isLoading && !forceRefresh) return;
    if (_products.isNotEmpty && !forceRefresh && _currentAreaId == areaId) return;

    _isLoading = true;
    _errorMessage = null;
    _currentAreaId = areaId;
    notifyListeners();

    try {
      final fetched = await _repo.getTrendingProducts(areaId: areaId);
      final activeList = fetched.where((p) => p.isActive).toList();
      _products = activeList.isNotEmpty ? activeList : fetched;
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load trending products: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Change area ID and re-fetch trending products
  void changeArea(int areaId) {
    if (_currentAreaId != areaId) {
      _currentAreaId = areaId;
      fetchTrendingProducts(areaId: areaId, forceRefresh: true);
    }
  }

  /// Reset provider state
  void reset() {
    _products = [];
    _isLoading = false;
    _errorMessage = null;
    _currentAreaId = 101;
    notifyListeners();
  }
}
