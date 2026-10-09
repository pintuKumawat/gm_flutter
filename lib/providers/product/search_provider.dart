import 'dart:async';
import 'package:flutter/material.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/models/product/category_model.dart';
import 'package:grahmitracus/models/product/home_product_model.dart';
import 'package:grahmitracus/repositories/product/search_repo.dart';

/// Represents a suggestion row (recent search term, category, or brand match)
class SearchSuggestion {
  final String label;
  final String type; // 'recent' | 'category' | 'brand'
  final CategoryModel? category;

  const SearchSuggestion({
    required this.label,
    required this.type,
    this.category,
  });
}

/// Provider managing Product Search state, debounced live suggestions,
/// pagination, recent search history, and trending categories.
class SearchProvider extends ChangeNotifier {
  final SearchRepo _repo;

  SearchProvider({SearchRepo? repo}) : _repo = repo ?? SearchRepo();

  String _query = '';
  List<HomeProductModel> _results = [];
  List<SearchSuggestion> _suggestions = [];
  final List<String> _recentSearches = [
    'Milk',
    'Atta',
    'Sugar',
    'Oil',
    'Biscuits',
  ];
  List<CategoryModel> _trendingCategories = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  String? _errorMessage;
  int _page = 1;
  static const int _pageSize = 10;
  Timer? _debounceTimer;

  // Getters
  String get query => _query;
  List<HomeProductModel> get results => _results;
  List<SearchSuggestion> get suggestions => _suggestions;
  List<String> get recentSearches => _recentSearches;
  List<CategoryModel> get trendingCategories => _trendingCategories;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  int get page => _page;

  /// Set trending categories from category provider
  void setTrendingCategories(List<CategoryModel> categories) {
    _trendingCategories = categories;
    notifyListeners();
  }

  /// Debounced search triggered when user types in the search bar
  void onQueryChanged(String newQuery, {int areaId = 101}) {
    _query = newQuery;
    _debounceTimer?.cancel();

    if (newQuery.trim().isEmpty) {
      _results = [];
      _suggestions = [];
      _isLoading = false;
      _isLoadingMore = false;
      _hasMore = false;
      _errorMessage = null;
      _page = 1;
      notifyListeners();
      return;
    }

    _computeSuggestions();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(pageToFetch: 1, areaId: areaId);
    });
  }

  /// Trigger immediate search without debounce (e.g. when suggestion or recent chip is tapped)
  Future<void> searchImmediate(String term, {int areaId = 101}) async {
    _debounceTimer?.cancel();
    _query = term;
    _page = 1;
    saveRecentSearch(term);
    _computeSuggestions();
    await _performSearch(pageToFetch: 1, areaId: areaId);
  }

  /// Internal search request execution
  Future<void> _performSearch({required int pageToFetch, int areaId = 101}) async {
    if (_query.trim().isEmpty) return;

    if (pageToFetch == 1) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    } else {
      _isLoadingMore = true;
      notifyListeners();
    }

    try {
      final offset = (pageToFetch - 1) * _pageSize;
      final response = await _repo.searchSuggest(
        query: _query,
        limit: _pageSize,
        offset: offset,
        areaId: areaId,
      );

      if (pageToFetch == 1) {
        _results = response.products;
        _page = 1;
        _hasMore = response.hasMore;
        if (_results.isEmpty) {
          _errorMessage = 'No products found matching "$_query"';
        } else {
          _errorMessage = null;
        }
      } else {
        _results.addAll(response.products);
        _page = pageToFetch;
        _hasMore = response.hasMore;
      }

      _computeSuggestions();
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    } on ApiException catch (e) {
      if (pageToFetch == 1) {
        _results = [];
        _errorMessage = e.message;
      }
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      if (pageToFetch == 1) {
        _results = [];
        _errorMessage = 'Search failed. Please try again.';
      }
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Loads next page of search results when user reaches scroll boundary
  Future<void> loadMore({int areaId = 101}) async {
    if (_isLoading || _isLoadingMore || !_hasMore || _query.trim().isEmpty) return;
    await _performSearch(pageToFetch: _page + 1, areaId: areaId);
  }

  /// Computes autocomplete suggestions in-memory matching React MobileSearch.js logic
  void _computeSuggestions() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) {
      _suggestions = [];
      return;
    }

    final Set<String> seen = {q};
    final List<SearchSuggestion> prefixList = [];
    final List<SearchSuggestion> containsList = [];

    void add(String? label, String type, [CategoryModel? cat]) {
      if (label == null || label.trim().isEmpty) return;
      final key = label.trim().toLowerCase();
      if (seen.contains(key)) return;
      final at = key.indexOf(q);
      if (at == -1) return;

      seen.add(key);
      final item = SearchSuggestion(label: label.trim(), type: type, category: cat);
      if (at == 0) {
        prefixList.add(item);
      } else {
        containsList.add(item);
      }
    }

    // 1. Matches from recent searches
    for (final term in _recentSearches) {
      add(term, 'recent');
    }

    // 2. Matches from trending categories
    for (final cat in _trendingCategories) {
      add(cat.name, 'category', cat);
    }

    // 3. Matches from brands in results
    for (final prod in _results) {
      if (prod.brand != null) {
        add(prod.brand, 'brand');
      }
    }

    _suggestions = [...prefixList, ...containsList].take(6).toList();
  }

  /// Save recent search term to history
  void saveRecentSearch(String term) {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;

    _recentSearches.removeWhere((s) => s.toLowerCase() == trimmed.toLowerCase());
    _recentSearches.insert(0, trimmed);
    if (_recentSearches.length > 8) {
      _recentSearches.removeLast();
    }
    notifyListeners();
  }

  /// Remove single item from recent searches
  void removeRecentSearch(String term) {
    _recentSearches.removeWhere((s) => s.toLowerCase() == term.toLowerCase());
    notifyListeners();
  }

  /// Clear all recent searches
  void clearRecentSearches() {
    _recentSearches.clear();
    notifyListeners();
  }

  /// Reset search query and state
  void clearSearch() {
    _debounceTimer?.cancel();
    _query = '';
    _results = [];
    _suggestions = [];
    _isLoading = false;
    _isLoadingMore = false;
    _hasMore = false;
    _errorMessage = null;
    _page = 1;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
