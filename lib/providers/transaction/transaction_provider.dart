import 'package:flutter/material.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/models/transaction/transaction_model.dart';
import 'package:grahmitracus/repositories/transaction/transaction_repo.dart';

/// Provider managing customer transactions state, filtering, search, and summary stats.
class TransactionProvider extends ChangeNotifier {
  final TransactionRepo _repo;

  TransactionProvider({TransactionRepo? repo})
      : _repo = repo ?? TransactionRepo();

  List<TransactionModel> _transactions = const [];
  bool _isLoading = false;
  String? _errorMessage;
  String _activeFilter = 'all'; // 'all', 'cod', 'razorpay'
  String _searchQuery = '';
  int _fetchSequence = 0;

  // Getters
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get activeFilter => _activeFilter;
  String get searchQuery => _searchQuery;

  TransactionStats get stats => TransactionStats.fromList(_transactions);

  List<TransactionModel> get filteredTransactions {
    final query = _searchQuery.trim().toLowerCase();
    if (_transactions.isEmpty) return const [];

    return _transactions.where((t) {
      // 1. Filter tab
      final method = t.paymentMethod?.toLowerCase() ?? '';
      final matchesFilter = _activeFilter == 'all' || method == _activeFilter;
      if (!matchesFilter) return false;

      // 2. Search query
      if (query.isEmpty) return true;
      final desc = t.description.toLowerCase();
      final code = (t.orderCode ?? '').toLowerCase();
      final orderIdStr = t.orderId?.toString().toLowerCase() ?? '';
      final txIdStr = t.id.toString();
      final rzpOrderId = (t.razorpayOrderId ?? '').toLowerCase();
      final rzpPaymentId = (t.razorpayPaymentId ?? '').toLowerCase();
      final instrument = t.instrumentName.toLowerCase();

      return desc.contains(query) ||
          code.contains(query) ||
          orderIdStr.contains(query) ||
          txIdStr.contains(query) ||
          rzpOrderId.contains(query) ||
          rzpPaymentId.contains(query) ||
          instrument.contains(query);
    }).toList(growable: false);
  }

  /// Sets filter tab: 'all' (Global View), 'cod' (Cash Settlement), 'razorpay' (Digital Gateway)
  void setFilter(String filter) {
    if (_activeFilter != filter) {
      _activeFilter = filter;
      notifyListeners();
    }
  }

  /// Sets search term
  void setSearchQuery(String query) {
    final trimmed = query.trim();
    if (_searchQuery != trimmed) {
      _searchQuery = trimmed;
      notifyListeners();
    }
  }

  /// Resets search term back to empty
  void resetSearch() {
    if (_searchQuery.isNotEmpty) {
      _searchQuery = '';
      notifyListeners();
    }
  }

  /// Fetches transactions from the centralized API endpoint
  Future<void> fetchTransactions({
    bool forceRefresh = false,
    bool resetSearch = false,
  }) async {
    if (resetSearch && _searchQuery.isNotEmpty) {
      _searchQuery = '';
    }

    if (_isLoading && !forceRefresh) return;
    if (!forceRefresh && _transactions.isNotEmpty) return;

    final currentSeq = ++_fetchSequence;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final items = await _repo.getTransactions();
      if (currentSeq != _fetchSequence) return;
      _transactions = List.unmodifiable(items);
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      if (currentSeq != _fetchSequence) return;
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (currentSeq != _fetchSequence) return;
      _errorMessage = 'Failed to load transactions. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears in-memory transactions on user logout
  void reset() {
    _transactions = const [];
    _isLoading = false;
    _errorMessage = null;
    _activeFilter = 'all';
    _searchQuery = '';
    _fetchSequence++;
    notifyListeners();
  }
}
