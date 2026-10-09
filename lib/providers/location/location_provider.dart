import 'package:flutter/material.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/models/location/location_state_model.dart';
import 'package:grahmitracus/models/location/serviceable_location_model.dart';
import 'package:grahmitracus/models/location/user_address_model.dart';
import 'package:grahmitracus/repositories/location/location_repo.dart';

/// Provider managing active delivery location, serviceable areas list,
/// and saved customer addresses.
class LocationProvider extends ChangeNotifier {
  final LocationRepo _repo;

  LocationProvider({LocationRepo? repo}) : _repo = repo ?? LocationRepo();

  UserLocationState _currentLocation = UserLocationState.defaultLocation();
  List<CityLocationsModel> _serviceableLocations = [];
  List<UserAddressModel> _savedAddresses = [];

  bool _isLoadingLocations = false;
  bool _isLoadingAddresses = false;
  bool _isSavingAddress = false;
  bool _isDetecting = false;
  String? _errorMessage;

  // Getters
  UserLocationState get currentLocation => _currentLocation;
  List<CityLocationsModel> get serviceableLocations => _serviceableLocations;
  List<UserAddressModel> get savedAddresses => _savedAddresses;
  bool get isLoadingLocations => _isLoadingLocations;
  bool get isLoadingAddresses => _isLoadingAddresses;
  bool get isSavingAddress => _isSavingAddress;
  bool get isDetecting => _isDetecting;
  String? get errorMessage => _errorMessage;

  /// Active Area ID for filtering products
  int get activeAreaId => _currentLocation.areaId ?? 101;

  /// Loads both serviceable areas and saved addresses
  Future<void> init() async {
    await Future.wait([fetchServiceableLocations(), fetchSavedAddresses()]);
  }

  /// Fetches deliverable areas from `/api/master/serviceable-locations`
  Future<void> fetchServiceableLocations() async {
    _isLoadingLocations = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _serviceableLocations = await _repo.getServiceableLocations();
      _isLoadingLocations = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoadingLocations = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoadingLocations = false;
      notifyListeners();
    }
  }

  /// Fetches user's saved addresses from `/api/customer/address`
  Future<void> fetchSavedAddresses() async {
    _isLoadingAddresses = true;
    notifyListeners();

    try {
      _savedAddresses = await _repo.getSavedAddresses();

      // If user has a primary address and current location is default, preselect primary
      if (_savedAddresses.isNotEmpty && _currentLocation.type == 'default') {
        try {
          final primary = _savedAddresses.firstWhere(
            (a) => a.isPrimary,
            orElse: () => _savedAddresses.first,
          );
          _currentLocation = UserLocationState.fromAddress(primary);
        } catch (_) {}
      }

      _isLoadingAddresses = false;
      notifyListeners();
    } catch (_) {
      _isLoadingAddresses = false;
      notifyListeners();
    }
  }

  /// Sets location to a specific deliverable area chip
  void selectArea(AreaLocationModel area) {
    _currentLocation = UserLocationState.fromArea(area);
    notifyListeners();
  }

  /// Sets location to a saved customer address
  void selectAddress(UserAddressModel address) {
    _currentLocation = UserLocationState.fromAddress(address);
    notifyListeners();
  }

  /// Sets custom location state
  void selectLocationState(UserLocationState state) {
    _currentLocation = state;
    notifyListeners();
  }

  /// Clears location back to default
  void clearLocation() {
    _currentLocation = UserLocationState.defaultLocation();
    notifyListeners();
  }

  /// Detects location using pincode validation or fallback
  Future<bool> detectLocation({String pincode = '201309'}) async {
    _isDetecting = true;
    notifyListeners();

    try {
      final area = await _repo.validatePincode(pincode);
      if (area != null) {
        _currentLocation = UserLocationState.fromArea(area);
        _isDetecting = false;
        notifyListeners();
        return true;
      }
    } catch (_) {}

    _isDetecting = false;
    notifyListeners();
    return false;
  }

  /// Adds a new delivery address
  Future<UserAddressModel?> addNewAddress(Map<String, dynamic> data) async {
    _isSavingAddress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await _repo.addAddress(data);
      _savedAddresses.insert(0, created);
      _currentLocation = UserLocationState.fromAddress(created);
      _isSavingAddress = false;
      notifyListeners();
      return created;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isSavingAddress = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Failed to add address. Please try again.';
      _isSavingAddress = false;
      notifyListeners();
      return null;
    }
  }

  /// Updates an existing address
  Future<bool> updateAddress(int id, Map<String, dynamic> data) async {
    _isSavingAddress = true;
    notifyListeners();

    try {
      await _repo.updateAddress(id, data);
      await fetchSavedAddresses();
      _isSavingAddress = false;
      notifyListeners();
      return true;
    } catch (_) {
      _isSavingAddress = false;
      notifyListeners();
      return false;
    }
  }

  /// Deletes a saved address
  Future<bool> deleteAddress(int id) async {
    try {
      await _repo.deleteAddress(id);
      _savedAddresses.removeWhere((a) => a.id == id);
      if (_currentLocation.address?.id == id) {
        if (_savedAddresses.isNotEmpty) {
          _currentLocation = UserLocationState.fromAddress(
            _savedAddresses.first,
          );
        } else {
          _currentLocation = UserLocationState.defaultLocation();
        }
      }
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Sets an address as primary
  Future<void> setPrimaryAddress(int id) async {
    try {
      await _repo.setPrimaryAddress(id);
      await fetchSavedAddresses();
    } catch (_) {}
  }
}
