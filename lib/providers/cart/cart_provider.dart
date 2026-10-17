import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:grahmitracus/models/cart/cart_item_model.dart';
import 'package:grahmitracus/models/cart/coupon_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:grahmitracus/providers/location/location_provider.dart';
import 'package:grahmitracus/repositories/cart/cart_repo.dart';

/// Centralized Provider managing Shopping Cart state, pricing, and discounts
class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};
  String? _appliedCoupon;

  CartProvider() {
    loadCartFromPrefs();
  }
  double _couponDiscount = 0.0;
  String? _couponMessage;
  bool _isRevalidating = false;

  // Active Coupons State
  List<CouponModel> _activeCoupons = [];
  bool _isLoadingCoupons = false;
  String? _couponsError;
  bool _isApplyingCoupon = false;

  // Getters
  bool get isRevalidating => _isRevalidating;
  Map<String, CartItem> get items => {..._items};
  List<CartItem> get itemList => _items.values.toList();
  int get itemCount => _items.length;
  bool get isEmpty => _items.isEmpty;

  List<CouponModel> get activeCoupons => _activeCoupons;
  bool get isLoadingCoupons => _isLoadingCoupons;
  String? get couponsError => _couponsError;
  bool get isApplyingCoupon => _isApplyingCoupon;


  // Checkout Validation State
  bool _isCheckoutValid = false;
  bool _isValidatingCheckout = false;
  String? _checkoutValidationError;
  
  double _apiShippingCost = 25.0;
  bool _apiShippingQuoted = false;
  double _apiPlatformFee = 2.0;
  double _apiRushHourSurcharge = 0.0;
  double _apiCodConvenienceFee = 0.0;
  bool _apiIsCodEnabled = true;

  bool get isCheckoutValid => _isCheckoutValid;
  bool get isValidatingCheckout => _isValidatingCheckout;
  String? get checkoutValidationError => _checkoutValidationError;
  bool get apiShippingQuoted => _apiShippingQuoted;
  double get apiRushHourSurcharge => _apiRushHourSurcharge;
  double get apiCodConvenienceFee => _apiCodConvenienceFee;
  bool get apiIsCodEnabled => _apiIsCodEnabled;

  /// Canonical cart key generator for consistent referencing across all screens
  static String buildCartKey(String productId, {String? variationId}) {
    final cleanPid = productId.trim();
    final cleanVid = variationId?.trim();
    if (cleanVid != null &&
        cleanVid.isNotEmpty &&
        cleanVid != 'default' &&
        cleanVid != '0' &&
        cleanVid != 'null') {
      return '${cleanPid}_$cleanVid';
    }
    return cleanPid;
  }

  /// Resolves the existing cart key in _items matching a given key, productId, or variationId
  String? findCartKey({String? id, String? productId, String? variationId}) {
    final cleanPid = (productId ?? (id != null && id.contains('_') ? id.split('_').first : id))?.trim();
    final cleanVid = (variationId ?? (id != null && id.contains('_') ? id.split('_').last : null))?.trim();

    final hasSpecificVid = cleanVid != null &&
        cleanVid.isNotEmpty &&
        cleanVid != 'default' &&
        cleanVid != '0' &&
        cleanVid != 'null';

    // 1. If variationId is specific, ONLY match exact variation
    if (hasSpecificVid) {
      final canonicalKey = (cleanPid != null && cleanPid.isNotEmpty)
          ? '${cleanPid}_$cleanVid'
          : null;
      if (canonicalKey != null && _items.containsKey(canonicalKey)) {
        return canonicalKey;
      }
      if (id != null && _items.containsKey(id)) {
        final item = _items[id]!;
        final itemVid = item.variationId ?? (id.contains('_') ? id.split('_').last : null);
        if (itemVid == cleanVid) {
          return id;
        }
      }
      for (final entry in _items.entries) {
        final itemPid = entry.value.productId ?? entry.key.split('_').first;
        final itemVid = entry.value.variationId ?? (entry.key.contains('_') ? entry.key.split('_').last : null);
        if (cleanPid != null && cleanPid.isNotEmpty) {
          if (itemPid == cleanPid && itemVid == cleanVid) {
            return entry.key;
          }
        } else if (itemVid == cleanVid) {
          return entry.key;
        }
      }
      // Critical: If a specific variation was requested and not found, NEVER fall back to another variant or base product!
      return null;
    }

    // 2. No specific variation requested:
    // Direct key match in _items
    if (id != null && _items.containsKey(id)) {
      return id;
    }

    if (cleanPid == null || cleanPid.isEmpty) return null;

    // Direct base productId in _items
    if (_items.containsKey(cleanPid)) {
      return cleanPid;
    }

    // Fallback: Check if there's any item belonging to this productId
    for (final entry in _items.entries) {
      final itemPid = entry.value.productId ?? entry.key.split('_').first;
      if (itemPid == cleanPid) {
        return entry.key;
      }
    }

    return null;
  }

  /// Total units count across all cart items (for badge count)
  int get totalQuantity =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  /// Get specific product quantity by cart key or resolved key
  int getQuantity(String id) {
    if (_items.containsKey(id)) {
      return _items[id]!.quantity;
    }
    final resolvedKey = findCartKey(id: id);
    if (resolvedKey != null && _items.containsKey(resolvedKey)) {
      return _items[resolvedKey]!.quantity;
    }
    return 0;
  }

  /// Get product quantity with optional variation matching.
  /// If variationId is provided, returns that variation's quantity.
  /// If variationId is null or not in cart, returns the total quantity of this product in cart.
  int getProductQuantity(String productId, {String? variationId}) {
    final cleanPid = productId.trim();
    if (cleanPid.isEmpty) return 0;

    final cleanVid = variationId?.trim();
    final hasSpecificVid = cleanVid != null &&
        cleanVid.isNotEmpty &&
        cleanVid != 'default' &&
        cleanVid != '0' &&
        cleanVid != 'null';

    // 1. If specific variation, match exact variation ONLY
    if (hasSpecificVid) {
      final canonicalKey = '${cleanPid}_$cleanVid';
      if (_items.containsKey(canonicalKey)) {
        return _items[canonicalKey]!.quantity;
      }
      for (final item in _items.values) {
        final itemPid = item.productId ?? item.id.split('_').first;
        final itemVid = item.variationId ?? (item.id.contains('_') ? item.id.split('_').last : null);
        if (itemPid == cleanPid && itemVid == cleanVid) {
          return item.quantity;
        }
      }
      // Critical: If specific variation was requested and not found, its quantity is 0!
      return 0;
    }

    // 2. Direct match with productId key
    if (_items.containsKey(cleanPid)) {
      return _items[cleanPid]!.quantity;
    }

    // 3. Fallback: Sum quantities of all variations for this product (only when no specific variation requested)
    int total = 0;
    for (final item in _items.values) {
      final itemPid = item.productId ?? item.id.split('_').first;
      if (itemPid == cleanPid) {
        total += item.quantity;
      }
    }
    return total;
  }

  /// Check if product is in cart
  bool contains(String id) {
    if (_items.containsKey(id)) return true;
    return findCartKey(id: id) != null;
  }

  /// Total Selling Price
  double get subtotal =>
      _items.values.fold(0.0, (sum, item) => sum + item.totalSellPrice);

  /// Total MRP Price
  double get totalMrp =>
      _items.values.fold(0.0, (sum, item) => sum + item.totalMrpPrice);

  /// Total product discount savings
  double get productSavings {
    final diff = totalMrp - subtotal;
    return diff > 0 ? diff : 0.0;
  }

  /// Total overall savings (product discount + coupon discount)
  double get totalSavings => productSavings + _couponDiscount;

  /// Delivery Fee: Free on orders >= ₹199, else ₹25
  double get deliveryFee {
    if (_items.isEmpty) return 0.0;
    if (_apiShippingQuoted) return _apiShippingCost;
    if (subtotal >= 199.0) return 0.0;
    return 25.0;
  }

  /// Minimal handling charge
  double get handlingFee => _items.isEmpty ? 0.0 : (_apiShippingQuoted ? _apiPlatformFee : 2.0);

  /// Final Grand Total to Pay
  double get grandTotal {
    if (_items.isEmpty) return 0.0;
    final total = subtotal - _couponDiscount + deliveryFee + handlingFee + _apiRushHourSurcharge;
    return total < 0 ? 0.0 : total;
  }

  /// Convenience fee based on payment method ('cod' vs online)
  double convenienceFeeFor(String paymentMethod) {
    final isCod = paymentMethod.toLowerCase().contains('cash') || paymentMethod.toLowerCase() == 'cod';
    return isCod ? _apiCodConvenienceFee : 0.0;
  }

  /// Grand total based on selected payment method
  double grandTotalFor(String paymentMethod) {
    if (_items.isEmpty) return 0.0;
    final fee = convenienceFeeFor(paymentMethod);
    final total = grandTotal + fee;
    return total < 0 ? 0.0 : total;
  }

  String? get appliedCoupon => _appliedCoupon;
  double get couponDiscount => _couponDiscount;
  String? get couponMessage => _couponMessage;

  /// Add item to cart or increment quantity
  void addToCart({
    required String id,
    required String title,
    required double sellPrice,
    required double mrpPrice,
    String? imageUrl,
    String? weight,
    String? category,
    String? storeName,
    String? productId,
    String? variationId,
    int quantity = 1,
  }) {
    final effectiveProductId = productId ?? (id.contains('_') ? id.split('_').first : id);
    final effectiveVariationId = variationId ?? (id.contains('_') ? id.split('_').last : null);

    final existingKey = findCartKey(
      id: id,
      productId: effectiveProductId,
      variationId: effectiveVariationId,
    );
    final targetKey = existingKey ?? buildCartKey(effectiveProductId, variationId: effectiveVariationId);

    if (existingKey != null && _items.containsKey(existingKey)) {
      final existing = _items[existingKey]!;
      _items[existingKey] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
    } else if (_items.containsKey(targetKey)) {
      final existing = _items[targetKey]!;
      _items[targetKey] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
    } else {
      _items[targetKey] = CartItem(
        id: targetKey,
        title: title,
        imageUrl: imageUrl,
        sellPrice: sellPrice,
        mrpPrice: mrpPrice,
        quantity: quantity,
        weight: weight,
        category: category,
        productId: effectiveProductId,
        variationId: effectiveVariationId,
        storeName: storeName,
      );
    }
    _recalculateCoupon();
    _saveCartToPrefs();
    notifyListeners();
  }

  /// Update item quantity directly (if 0 or less, remove item)
  void updateQuantity(
    String id,
    int quantity, {
    String? title,
    double? sellPrice,
    double? mrpPrice,
    String? imageUrl,
    String? weight,
    String? category,
    String? storeName,
    String? productId,
    String? variationId,
  }) {
    final effectiveProductId = productId ?? (id.contains('_') ? id.split('_').first : id);
    final effectiveVariationId = variationId ?? (id.contains('_') ? id.split('_').last : null);

    final existingKey = findCartKey(
      id: id,
      productId: effectiveProductId,
      variationId: effectiveVariationId,
    );
    final targetKey = existingKey ?? buildCartKey(effectiveProductId, variationId: effectiveVariationId);

    if (quantity <= 0) {
      _items.remove(targetKey);
      if (existingKey != null && existingKey != targetKey) {
        _items.remove(existingKey);
      }
      _items.remove(id);
    } else if (existingKey != null && _items.containsKey(existingKey)) {
      _items[existingKey] = _items[existingKey]!.copyWith(quantity: quantity);
    } else if (_items.containsKey(targetKey)) {
      _items[targetKey] = _items[targetKey]!.copyWith(quantity: quantity);
    } else if (title != null && sellPrice != null) {
      _items[targetKey] = CartItem(
        id: targetKey,
        title: title,
        imageUrl: imageUrl,
        sellPrice: sellPrice,
        mrpPrice: mrpPrice ?? sellPrice,
        quantity: quantity,
        weight: weight,
        category: category,
        storeName: storeName,
        productId: effectiveProductId,
        variationId: effectiveVariationId,
      );
    }
    _recalculateCoupon();
    _saveCartToPrefs();
    notifyListeners();
  }

  /// Increment item quantity by 1
  void increment(String id) {
    final existingKey = findCartKey(id: id) ?? id;
    if (_items.containsKey(existingKey)) {
      _items[existingKey] = _items[existingKey]!.copyWith(quantity: _items[existingKey]!.quantity + 1);
      _recalculateCoupon();
      _saveCartToPrefs();
      notifyListeners();
    }
  }

  /// Decrement item quantity by 1 (removes if reaches 0)
  void decrement(String id) {
    final existingKey = findCartKey(id: id) ?? id;
    if (_items.containsKey(existingKey)) {
      final current = _items[existingKey]!.quantity;
      if (current <= 1) {
        _items.remove(existingKey);
      } else {
        _items[existingKey] = _items[existingKey]!.copyWith(quantity: current - 1);
      }
      _recalculateCoupon();
      _saveCartToPrefs();
      notifyListeners();
    }
  }

  /// Remove item completely from cart
  void removeItem(String id) {
    final existingKey = findCartKey(id: id) ?? id;
    bool removed = _items.remove(existingKey) != null;
    if (_items.remove(id) != null) {
      removed = true;
    }
    if (removed) {
      _recalculateCoupon();
      _saveCartToPrefs();
      notifyListeners();
    }
  }

  /// Fetches active coupons list from backend GET /api/coupons/active
  Future<void> fetchActiveCoupons() async {
    _isLoadingCoupons = true;
    _couponsError = null;
    notifyListeners();

    try {
      final repo = CartRepo();
      final response = await repo.getActiveCoupons();
      if (response['success'] == true && response['coupons'] != null) {
        final List<dynamic> list = response['coupons'];
        _activeCoupons = list
            .map((item) => CouponModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _couponsError =
            response['message']?.toString() ?? 'Failed to load coupons';
      }
    } catch (e) {
      _couponsError = 'Unable to fetch active coupons.';
    } finally {
      _isLoadingCoupons = false;
      notifyListeners();
    }
  }

  /// Apply promo code / coupon via backend API POST /api/coupons/apply
  Future<bool> applyCoupon(String code) async {
    final cleanCode = code.trim();
    if (cleanCode.isEmpty) {
      _couponMessage = 'Please enter a coupon code';
      notifyListeners();
      return false;
    }

    if (_items.isEmpty) {
      _couponMessage = 'Cart is empty';
      notifyListeners();
      return false;
    }

    _isApplyingCoupon = true;
    _couponMessage = null;
    notifyListeners();

    try {
      final payload = {
        "coupon_code": cleanCode,
        "order_amount": subtotal,
        "cart_items": _items.values
            .map((item) => {
                  "product_id": int.tryParse(item.productId ?? item.id.split('_').first) ?? 0,
                  "variation_id": int.tryParse(item.variationId ?? (item.id.contains('_') ? item.id.split('_').last : '')) ?? int.tryParse(item.productId ?? item.id) ?? 0,
                  "price": item.sellPrice,
                  "quantity": item.quantity,
                })
            .toList(),
      };

      final repo = CartRepo();
      final response = await repo.applyCoupon(payload);
      final result = ApplyCouponResult.fromJson(response);

      if (result.success) {
        _appliedCoupon = result.code ?? cleanCode;
        _couponDiscount = result.discountAmount;
        _couponMessage = result.message;
        notifyListeners();
        return true;
      } else {
        _couponMessage = result.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      final String msg = e.toString();
      _couponMessage = msg.contains('ApiException')
          ? msg.replaceAll('ApiException: ', '')
          : 'Invalid or ineligible coupon code';
      notifyListeners();
      return false;
    } finally {
      _isApplyingCoupon = false;
      notifyListeners();
    }
  }

  /// Remove applied coupon
  void removeCoupon() {
    _appliedCoupon = null;
    _couponDiscount = 0.0;
    _couponMessage = null;
    notifyListeners();
  }

  void _recalculateCoupon() {
    if (_appliedCoupon != null && _items.isEmpty) {
      removeCoupon();
    }
  }

  /// Clear all items and coupons from cart
  void clearCart() {
    _items.clear();
    _appliedCoupon = null;
    _couponDiscount = 0.0;
    _couponMessage = null;
    _resetCheckoutValidation();
    _saveCartToPrefs();
    notifyListeners();
  }

  void _resetCheckoutValidation() {
    _isCheckoutValid = false;
    _checkoutValidationError = null;
    _apiShippingQuoted = false;
    _apiShippingCost = 25.0;
    _apiPlatformFee = 2.0;
    _apiRushHourSurcharge = 0.0;
    _apiCodConvenienceFee = 0.0;
    _apiIsCodEnabled = true;
  }

  /// Revalidates cart items' prices and stock with the backend API
  Future<void> revalidate(LocationProvider locationProv) async {
    if (_items.isEmpty) return;
    
    _isRevalidating = true;
    notifyListeners();

    try {
      final currentLoc = locationProv.currentLocation;
      final pincode = currentLoc.address?.pincode ?? currentLoc.pincode;
      final hasPincode = pincode != null && pincode.trim().isNotEmpty;
      final areaId = hasPincode ? null : currentLoc.areaId;
      final lat = currentLoc.address?.latitude ?? currentLoc.lat;
      final lng = currentLoc.address?.longitude ?? currentLoc.lng;

      final payload = {
        "items": _items.values.map((item) => {
          "variation_id": int.tryParse(item.variationId ?? '') ?? int.tryParse(item.id.split('_').last) ?? int.tryParse(item.id.split('_').first) ?? 0,
          "offer_id": null,
          "vendor_id": null
        }).toList(),
        "shipping_to": {
          "area_id": areaId,
          if (hasPincode) "pincode": pincode.trim(),
          if (lat != null) "latitude": lat,
          if (lng != null) "longitude": lng,
        }
      };

      final repo = CartRepo();
      final response = await repo.revalidateCart(payload);
      
      if (response['success'] == true && response['items'] != null) {
        final updatedItems = response['items'] as List;
        for (var apiItem in updatedItems) {
          final String varId = apiItem['variation_id'].toString();
          final matchingKey = findCartKey(id: varId, variationId: varId);
          if (matchingKey != null && _items.containsKey(matchingKey)) {
            final double newPrice = (apiItem['sell_price'] as num?)?.toDouble() ?? _items[matchingKey]!.sellPrice;
            
            // Note: The API returns deliverable and available boolean flags.
            // Keeping minimum changes to UI: we only update the authoritative price here.
            _items[matchingKey] = _items[matchingKey]!.copyWith(sellPrice: newPrice);
          }
        }
        _recalculateCoupon();
        _saveCartToPrefs();
      }
    } catch (e) {
      // Intentionally silent failure for revalidation to keep existing local cart usable 
      // if network goes down, preserving current architecture pattern.
    } finally {
      _isRevalidating = false;
      notifyListeners();
    }
  }

  /// Validates checkout, computes surcharges, and checks deliverability
  Future<bool> validateCheckout(LocationProvider locationProv) async {
    if (_items.isEmpty) return false;

    _isValidatingCheckout = true;
    _isCheckoutValid = false;
    _checkoutValidationError = null;
    notifyListeners();

    try {
      final currentLoc = locationProv.currentLocation;
      final pincode = currentLoc.address?.pincode ?? currentLoc.pincode;
      final hasPincode = pincode != null && pincode.trim().isNotEmpty;
      final areaId = hasPincode ? null : currentLoc.areaId;
      final lat = currentLoc.address?.latitude ?? currentLoc.lat;
      final lng = currentLoc.address?.longitude ?? currentLoc.lng;

      final payload = {
        "items": _items.values.map((item) => {
          "product_id": int.tryParse(item.productId ?? '') ?? int.tryParse(item.id.split('_').first) ?? 0,
          "variation_id": int.tryParse(item.variationId ?? (item.id.contains('_') ? item.id.split('_').last : '')),
          "quantity": item.quantity,
          "price": item.sellPrice
        }).toList(),
        "shipping_to": {
          "area_id": areaId,
          if (hasPincode) "pincode": pincode.trim(),
          if (lat != null) "latitude": lat,
          if (lng != null) "longitude": lng,
        }
      };

      final repo = CartRepo();
      final response = await repo.validateCheckout(payload);

      if (response['success'] == true) {
        _isCheckoutValid = true;
        _apiShippingQuoted = response['shipping_quoted'] ?? false;
        _apiShippingCost = (response['shipping_cost'] as num?)?.toDouble() ?? 0.0;
        _apiPlatformFee = (response['platform_fee'] as num?)?.toDouble() ?? 2.0;
        _apiRushHourSurcharge = (response['rush_hour_surcharge'] as num?)?.toDouble() ?? 0.0;
        _apiCodConvenienceFee = (response['cod_convenience_fee'] as num?)?.toDouble() ?? 0.0;
        _apiIsCodEnabled = response['is_cod_enabled'] ?? true;
        
        final invalidItems = response['invalid_items'] as List?;
        if (invalidItems != null && invalidItems.isNotEmpty) {
          _isCheckoutValid = false;
          _checkoutValidationError = 'Some items are unavailable for delivery to this address.';
        }
      } else {
        _isCheckoutValid = false;
        _checkoutValidationError = response['message'] ?? 'Checkout validation failed.';
      }
    } catch (e) {
      _isCheckoutValid = false;
      _checkoutValidationError = 'Network error while validating checkout. Please try again.';
    } finally {
      _isValidatingCheckout = false;
      notifyListeners();
    }
    return _isCheckoutValid;
  }

  /// Saves the current cart items to SharedPreferences
  Future<void> _saveCartToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final cartList = _items.values.map((item) => item.toJson()).toList();
    prefs.setString('cart_items', json.encode(cartList));
  }

  /// Loads the cart items from SharedPreferences
  Future<void> loadCartFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final cartString = prefs.getString('cart_items');
    
    if (cartString != null) {
      final List<dynamic> decodedData = json.decode(cartString);
      
      _items = {};
      for (var itemJson in decodedData) {
        final item = CartItem.fromJson(itemJson);
        // Load any valid cart item with quantity > 0 and valid id/productId
        final pid = item.productId ?? item.id.split('_').first;
        if (pid.isNotEmpty && item.quantity > 0) {
          _items[item.id] = item;
        }
      }
      
      _recalculateCoupon();
      notifyListeners();
    }
  }
}
