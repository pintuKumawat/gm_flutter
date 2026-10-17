import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/models/location/location_state_model.dart';
import 'package:grahmitracus/models/location/serviceable_location_model.dart';
import 'package:grahmitracus/models/location/user_address_model.dart';
import 'package:grahmitracus/repositories/location/location_repo.dart';

/// Provider managing active delivery location, serviceable areas list,
/// and saved customer addresses with user-isolated persistence.
class LocationProvider extends ChangeNotifier {
  static String _userAddressesKey(int userId) => 'user_saved_addresses_$userId';
  static String _userLocationKey(int userId) => 'user_selected_location_$userId';
  static const String _guestLocationKey = 'guest_selected_location';

  final LocationRepo _repo;

  LocationProvider({LocationRepo? repo}) : _repo = repo ?? LocationRepo();

  int? _currentUserId;
  UserLocationState _currentLocation = UserLocationState.defaultLocation();
  List<CityLocationsModel> _serviceableLocations = [];
  List<UserAddressModel> _savedAddresses = [];

  bool _isLoadingLocations = false;
  bool _isLoadingAddresses = false;
  bool _isSavingAddress = false;
  bool _isDetecting = false;
  String? _errorMessage;

  // Getters
  int? get currentUserId => _currentUserId;
  UserLocationState get currentLocation => _currentLocation;
  List<CityLocationsModel> get serviceableLocations => _serviceableLocations;
  List<UserAddressModel> get savedAddresses => _savedAddresses;
  bool get isLoadingLocations => _isLoadingLocations;
  bool get isLoadingAddresses => _isLoadingAddresses;
  bool get isSavingAddress => _isSavingAddress;
  bool get isDetecting => _isDetecting;
  String? get errorMessage => _errorMessage;
  /// Whether the user has an explicitly selected or saved delivery location
  bool get hasSelectedLocation =>
      _currentLocation.type != 'default' &&
      _currentLocation.displayString.trim().isNotEmpty;

  /// Active Area ID for filtering products
  int get activeAreaId => _currentLocation.areaId ?? 101;

  /// Loads both serviceable areas and restores user location data if a user session exists
  Future<void> init({int? initialUserId}) async {
    _currentUserId = initialUserId;
    await fetchServiceableLocations();
    if (_currentUserId != null) {
      await _restoreUserLocationData(_currentUserId!);
      await fetchSavedAddresses();
    } else {
      await _restoreGuestLocation();
    }
  }

  /// Initializes or switches the location session to a specific authenticated user
  Future<void> initUserSession(int? userId) async {
    if (_currentUserId != userId) {
      // Clear memory from prior session before binding new user data
      _savedAddresses = [];
      _currentLocation = UserLocationState.defaultLocation();
    }
    _currentUserId = userId;
    if (userId != null) {
      await _restoreUserLocationData(userId);
      await fetchSavedAddresses();
    } else {
      clearUserData();
    }
  }

  Future<void> _persistCurrentLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_currentLocation.toJson());
      if (_currentUserId != null) {
        await prefs.setString(_userLocationKey(_currentUserId!), jsonStr);
      } else {
        await prefs.setString(_guestLocationKey, jsonStr);
      }
    } catch (e) {
      debugPrint('Failed to persist location: $e');
    }
  }

  Future<void> _persistSavedAddresses() async {
    try {
      if (_currentUserId == null) return;
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _savedAddresses.map((a) => a.toJson()).toList();
      await prefs.setString(_userAddressesKey(_currentUserId!), jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Failed to persist addresses: $e');
    }
  }

  Future<void> _restoreUserLocationData(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 1. Restore cached addresses
      final rawAddrs = prefs.getString(_userAddressesKey(userId));
      if (rawAddrs != null && rawAddrs.isNotEmpty) {
        final decoded = jsonDecode(rawAddrs);
        if (decoded is List) {
          _savedAddresses = decoded
              .map((item) => UserAddressModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
        }
      }

      // 2. Restore selected location
      final rawLoc = prefs.getString(_userLocationKey(userId));
      if (rawLoc != null && rawLoc.isNotEmpty) {
        final decoded = jsonDecode(rawLoc);
        if (decoded is Map<String, dynamic>) {
          _currentLocation = UserLocationState.fromJson(decoded);
        } else if (decoded is Map) {
          _currentLocation = UserLocationState.fromJson(Map<String, dynamic>.from(decoded));
        }
      } else if (_savedAddresses.isNotEmpty) {
        final primary = _savedAddresses.firstWhere(
          (a) => a.isPrimary,
          orElse: () => _savedAddresses.first,
        );
        _currentLocation = UserLocationState.fromAddress(primary);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to restore user location data: $e');
    }
  }

  Future<void> _restoreGuestLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawLoc = prefs.getString(_guestLocationKey);
      if (rawLoc != null && rawLoc.isNotEmpty) {
        final decoded = jsonDecode(rawLoc);
        if (decoded is Map<String, dynamic>) {
          _currentLocation = UserLocationState.fromJson(decoded);
        } else if (decoded is Map) {
          _currentLocation = UserLocationState.fromJson(Map<String, dynamic>.from(decoded));
        }
        notifyListeners();
      }
    } catch (_) {}
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
      _persistSavedAddresses();

      // If user has a primary address and current location is default, preselect primary
      if (_savedAddresses.isNotEmpty && _currentLocation.type == 'default') {
        try {
          final primary = _savedAddresses.firstWhere(
            (a) => a.isPrimary,
            orElse: () => _savedAddresses.first,
          );
          _currentLocation = UserLocationState.fromAddress(primary);
          _persistCurrentLocation();
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
    _persistCurrentLocation();
    notifyListeners();
  }

  /// Sets location to a saved customer address
  void selectAddress(UserAddressModel address) {
    _currentLocation = UserLocationState.fromAddress(address);
    _persistCurrentLocation();
    notifyListeners();
  }

  /// Sets custom location state
  void selectLocationState(UserLocationState state) {
    _currentLocation = state;
    _persistCurrentLocation();
    notifyListeners();
  }

  /// Clears location back to default
  void clearLocation() {
    _currentLocation = UserLocationState.defaultLocation();
    _persistCurrentLocation();
    notifyListeners();
  }


  /// Detects real device location using GPS and resolves to a serviceable area via backend API
  Future<bool> detectLocation() async {
    _isDetecting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Check if location services are enabled on the device
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = 'Location services are disabled on your device. Please enable GPS.';
        _isDetecting = false;
        notifyListeners();
        return false;
      }

      // 2. Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = 'Location permission was denied. Please allow location access.';
          _isDetecting = false;
          notifyListeners();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage = 'Location permissions are permanently denied. Please enable them in app settings.';
        _isDetecting = false;
        notifyListeners();
        return false;
      }

      // 3. Acquire current device coordinates (with 10-second timeout fallback)
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (_) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          position = lastKnown;
        } else {
          _errorMessage = 'Could not acquire GPS position. Please check your signal or select an area.';
          _isDetecting = false;
          notifyListeners();
          return false;
        }
      }

      final lat = position.latitude;
      final lng = position.longitude;

      // 4. Resolve coordinates with backend /api/master/resolve-location
      final resolveData = await _repo.resolveLocationByCoordinates(
        latitude: lat,
        longitude: lng,
      );

      if (resolveData != null && resolveData['success'] == true) {
        final isServiceable = resolveData['serviceable'] == true;
        if (!isServiceable) {
          _errorMessage = 'We do not currently deliver to your detected location.';
          _isDetecting = false;
          notifyListeners();
          return false;
        }

        final areaId = resolveData['area_id'] is int
            ? resolveData['area_id'] as int
            : int.tryParse(resolveData['area_id']?.toString() ?? '');

        final label = resolveData['label'] as String? ??
            resolveData['area_name'] as String? ??
            resolveData['city'] as String?;

        String? candidatePincode;
        String? candidateAreaName;
        String? candidateCity = resolveData['city'] as String?;

        final candidateAreas = resolveData['candidate_areas'];
        if (candidateAreas is List && candidateAreas.isNotEmpty) {
          final firstCandidate = candidateAreas.first;
          if (firstCandidate is Map<String, dynamic>) {
            candidatePincode = firstCandidate['pincode']?.toString();
            candidateAreaName = firstCandidate['area_name'] as String?;
            candidateCity = firstCandidate['city_name'] as String? ?? candidateCity;
          }
        }

        _currentLocation = UserLocationState(
          type: 'detected',
          displayString: label ?? '${candidateAreaName ?? "Detected Location"}, ${candidateCity ?? ""}',
          areaId: areaId,
          areaName: candidateAreaName,
          city: candidateCity,
          pincode: candidatePincode,
          lat: lat,
          lng: lng,
        );
        _persistCurrentLocation();

        _isDetecting = false;
        notifyListeners();
        return true;
      }

      _errorMessage = 'Could not find a deliverable area for your location. Please select an area manually.';
      _isDetecting = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to detect location: ${e.toString()}';
      _isDetecting = false;
      notifyListeners();
      return false;
    }
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
      _persistSavedAddresses();
      _persistCurrentLocation();
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
        _persistCurrentLocation();
      }
      _persistSavedAddresses();
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

  /// Clears user-specific saved addresses on logout and resets delivery location to default.
  /// NOTE: User-isolated data persisted on disk and backend is NOT deleted, ensuring
  /// it is safely preserved and restored when the same user logs in again.
  void clearUserData() {
    _savedAddresses = [];
    _currentLocation = UserLocationState.defaultLocation();
    _currentUserId = null;
    _errorMessage = null;
    notifyListeners();
  }
}

