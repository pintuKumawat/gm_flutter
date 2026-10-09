import 'package:flutter/material.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/models/profile/referral_model.dart';
import 'package:grahmitracus/repositories/profile/referral_repo.dart';

class ReferralProvider extends ChangeNotifier {
  final ReferralRepo _repo;

  ReferralProvider({ReferralRepo? repo}) : _repo = repo ?? ReferralRepo();

  bool _isLoading = false;
  String? _errorMessage;
  ReferralModel? _referralData;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ReferralModel? get referralData => _referralData;
  List<ReferredFriendModel> get friends => _referralData?.friends ?? [];
  double get totalEarned => _referralData?.totalEarned ?? 0.0;

  Future<void> fetchReferralHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _referralData = await _repo.getReferralHistory();
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

  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _referralData = null;
    notifyListeners();
  }
}
