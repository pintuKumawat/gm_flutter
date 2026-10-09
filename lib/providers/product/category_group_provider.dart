import 'package:flutter/material.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/models/product/category_group_model.dart';
import 'package:grahmitracus/repositories/product/category_group_repo.dart';

/// Provider for managing Category Groups state on the Dashboard.
class CategoryGroupProvider extends ChangeNotifier {
  final CategoryGroupRepo _repo;

  CategoryGroupProvider({CategoryGroupRepo? repo})
      : _repo = repo ?? CategoryGroupRepo();

  List<CategoryGroupModel> _groups = [];
  bool _isLoading = false;
  String? _errorMessage;
  int? _selectedGroupId; // null means 'All'

  // Getters
  List<CategoryGroupModel> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null && _errorMessage!.isNotEmpty;
  int? get selectedGroupId => _selectedGroupId;

  CategoryGroupModel? get selectedGroup {
    if (_selectedGroupId == null) return null;
    try {
      return _groups.firstWhere((g) => g.id == _selectedGroupId);
    } catch (_) {
      return null;
    }
  }

  /// Fetch category groups from API
  Future<void> fetchGroups({bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (_groups.isNotEmpty && !forceRefresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedGroups = await _repo.getGroups();
      // Sort by sort_order if available
      fetchedGroups.sort((a, b) {
        final orderA = a.sortOrder ?? 999;
        final orderB = b.sortOrder ?? 999;
        return orderA.compareTo(orderB);
      });

      _groups = fetchedGroups;
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load groups: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select a specific group (pass null for 'All')
  void selectGroup(int? groupId) {
    if (_selectedGroupId != groupId) {
      _selectedGroupId = groupId;
      notifyListeners();
    }
  }

  /// Reset provider state
  void reset() {
    _groups = [];
    _isLoading = false;
    _errorMessage = null;
    _selectedGroupId = null;
    notifyListeners();
  }
}
