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

  /// Total units count across all cart items (for badge count)
  int get totalQuantity =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  /// Get specific product quantity
  int getQuantity(String id) => _items[id]?.quantity ?? 0;

  /// Check if product is in cart
  bool contains(String id) => _items.containsKey(id);

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
    if (_items.containsKey(id)) {
      final existing = _items[id]!;
      _items[id] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
    } else {
      _items[id] = CartItem(
        id: id,
        title: title,
        imageUrl: imageUrl,
        sellPrice: sellPrice,
        mrpPrice: mrpPrice,
        quantity: quantity,
        weight: weight,
        category: category,
        productId: productId,
        variationId: variationId,
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
    if (quantity <= 0) {
      _items.remove(id);
    } else if (_items.containsKey(id)) {
      _items[id] = _items[id]!.copyWith(quantity: quantity);
    } else if (title != null && sellPrice != null) {
      _items[id] = CartItem(
        id: id,
        title: title,
        imageUrl: imageUrl,
        sellPrice: sellPrice,
        mrpPrice: mrpPrice ?? sellPrice,
        quantity: quantity,
        weight: weight,
        category: category,
        storeName: storeName,
        productId: productId ?? id,
        variationId: variationId,
      );
    }
    _recalculateCoupon();
    _saveCartToPrefs();
    notifyListeners();
  }

  /// Increment item quantity by 1
  void increment(String id) {
    if (_items.containsKey(id)) {
      _items[id] = _items[id]!.copyWith(quantity: _items[id]!.quantity + 1);
      _recalculateCoupon();
      _saveCartToPrefs();
      notifyListeners();
    }
  }

  /// Decrement item quantity by 1 (removes if reaches 0)
  void decrement(String id) {
    if (_items.containsKey(id)) {
      final current = _items[id]!.quantity;
      if (current <= 1) {
        _items.remove(id);
      } else {
        _items[id] = _items[id]!.copyWith(quantity: current - 1);
      }
      _recalculateCoupon();
      _saveCartToPrefs();
      notifyListeners();
    }
  }

  /// Remove item completely from cart
  void removeItem(String id) {
    if (_items.remove(id) != null) {
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
                  "product_id": int.tryParse(item.id) ?? 0,
                  "variation_id": int.tryParse(item.id) ?? 0,
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
          "variation_id": int.tryParse(item.variationId ?? '') ?? int.tryParse(item.id.split('_').first) ?? 0,
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
          final String id = apiItem['variation_id'].toString();
          if (_items.containsKey(id)) {
            final double newPrice = (apiItem['sell_price'] as num?)?.toDouble() ?? _items[id]!.sellPrice;
            
            // Note: The API returns deliverable and available boolean flags.
            // Keeping minimum changes to UI: we only update the authoritative price here.
            _items[id] = _items[id]!.copyWith(sellPrice: newPrice);
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
          "product_id": int.tryParse(item.productId ?? '') ?? int.tryParse(item.id) ?? 0,
          "variation_id": int.tryParse(item.variationId ?? ''),
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
        // Only load valid items with product and variation ID
        if (item.productId != null && item.variationId != null && item.variationId != "null") {
          _items[item.id] = item;
        }
      }
      
      _recalculateCoupon();
      notifyListeners();
    }
  }
}
