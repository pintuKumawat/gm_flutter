import 'package:flutter/material.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/models/profile/wallet_model.dart';
import 'package:grahmitracus/repositories/profile/wallet_repo.dart';

/// Provider managing customer wallet balance and transaction history states.
class WalletProvider extends ChangeNotifier {
  final WalletRepo _repo;

  WalletProvider({WalletRepo? repo}) : _repo = repo ?? WalletRepo();

  bool _isLoading = false;
  String? _errorMessage;
  WalletModel? _wallet;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  WalletModel? get wallet => _wallet;
  double get balance => _wallet?.walletBalance ?? 0.0;
  double get lockedBalance => _wallet?.lockedWalletBalance ?? 0.0;
  List<WalletTransactionModel> get transactions => _wallet?.transactions ?? [];
  bool get hasError => _errorMessage != null && _errorMessage!.isNotEmpty;
  bool get isEmpty => transactions.isEmpty;

  /// Fetches wallet details from backend
  Future<void> fetchWallet() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _wallet = await _repo.getWallet();
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Resets error and state
  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _wallet = null;
    notifyListeners();
  }
}
