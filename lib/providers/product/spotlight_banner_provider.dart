import 'package:flutter/material.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/models/product/spotlight_banner_model.dart';
import 'package:grahmitracus/repositories/product/spotlight_banner_repo.dart';

/// Provider for managing Spotlight Promotional Banners from `/api/spotlight`.
class SpotlightBannerProvider extends ChangeNotifier {
  final SpotlightBannerRepo _repo;

  SpotlightBannerProvider({SpotlightBannerRepo? repo})
      : _repo = repo ?? SpotlightBannerRepo();

  List<SpotlightBannerModel> _banners = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<SpotlightBannerModel> get banners => _banners;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null && _errorMessage!.isNotEmpty;

  /// Fetch spotlight banners from `/api/spotlight`
  Future<void> fetchBanners({
    String displayLocation = 'home',
    int? categoryGroupId,
    int? locationId,
    bool forceRefresh = false,
  }) async {
    if (_isLoading) return;
    if (_banners.isNotEmpty && !forceRefresh && categoryGroupId == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _repo.getSpotlightBanners(
        displayLocation: displayLocation,
        categoryGroupId: categoryGroupId,
        locationId: locationId,
      );
      _banners = fetched;
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load banners: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
}
