import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:grahmitracus/models/cart/order_model.dart';
import 'package:grahmitracus/providers/cart/cart_provider.dart';
import 'package:grahmitracus/providers/location/location_provider.dart';
import 'package:grahmitracus/repositories/cart/order_repo.dart';

/// Provider to handle Order placement, tracking, and order history with user-isolated persistence
class OrderProvider with ChangeNotifier {
  static String _userOrdersKey(int userId) => 'user_orders_$userId';

  final OrderRepo _repo = OrderRepo();

  int? _currentUserId;
  bool _isPlacingOrder = false;
  bool _isLoadingOrders = false;
  OrderModel? _lastPlacedOrder;

  List<OrderModel> _activeOrders = [];
  List<OrderModel> _pastOrders = [];

  int? get currentUserId => _currentUserId;
  List<OrderModel> get activeOrders => List.unmodifiable(_activeOrders);
  List<OrderModel> get pastOrders => List.unmodifiable(_pastOrders);
  OrderModel? get lastPlacedOrder => _lastPlacedOrder;
  bool get isPlacingOrder => _isPlacingOrder;
  bool get isLoadingOrders => _isLoadingOrders;

  /// Initializes or switches the order history session to a specific authenticated user
  Future<void> initUserSession(int? userId) async {
    if (_currentUserId != userId) {
      // Clear memory from prior session before binding new user data
      _activeOrders = [];
      _pastOrders = [];
      _lastPlacedOrder = null;
    }
    _currentUserId = userId;
    if (userId != null) {
      await _restoreUserOrders(userId);
      await fetchOrders();
    } else {
      reset();
    }
  }

  Future<void> _persistUserOrders() async {
    try {
      if (_currentUserId == null) return;
      final prefs = await SharedPreferences.getInstance();
      final allOrders = [..._activeOrders, ..._pastOrders];
      final jsonList = allOrders.map((o) => o.toJson()).toList();
      await prefs.setString(_userOrdersKey(_currentUserId!), jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Failed to persist user orders: $e');
    }
  }

  Future<void> _restoreUserOrders(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_userOrdersKey(userId));
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final parsed = decoded
              .map((item) => OrderModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
          _activeOrders = [];
          _pastOrders = [];
          for (var order in parsed) {
            if (order.isPastOrder) {
              _pastOrders.add(order);
            } else {
              _activeOrders.add(order);
            }
          }
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Failed to restore user orders: $e');
    }
  }

  /// Fetch all customer orders and split into active/past based on status
  Future<void> fetchOrders() async {
    _isLoadingOrders = true;
    notifyListeners();

    try {
      final response = await _repo.getCustomerOrders(page: 1, limit: 50);
      
      List<dynamic> ordersList = [];
      if (response is List) {
        ordersList = response;
      } else if (response is Map<String, dynamic>) {
        ordersList = response['orders'] as List? ?? response['data'] as List? ?? [];
      } else if (response != null && response is Map) {
        ordersList = response['orders'] as List? ?? response['data'] as List? ?? [];
      }
      
      final parsedOrders = ordersList.map((json) {
        if (json is Map<String, dynamic>) {
          return OrderModel.fromJson(json);
        } else if (json is Map) {
          return OrderModel.fromJson(Map<String, dynamic>.from(json));
        }
        return null;
      }).whereType<OrderModel>().toList();
      
      _activeOrders = [];
      _pastOrders = [];
      
      for (var order in parsedOrders) {
        if (order.isPastOrder) {
          _pastOrders.add(order);
        } else {
          _activeOrders.add(order);
        }
      }
      _persistUserOrders();
    } catch (e) {
      debugPrint("Failed to fetch orders: $e");
    } finally {
      _isLoadingOrders = false;
      notifyListeners();
    }
  }


  /// Get detailed info for a specific order
  Future<OrderModel?> getOrderDetails(String orderId) async {
    try {
      final response = await _repo.getOrderDetails(orderId);
      return OrderModel.fromJson(response);
    } catch (e) {
      debugPrint("Failed to fetch order details: $e");
      return null;
    }
  }

  /// Get live tracking data for an order
  Future<Map<String, dynamic>?> trackOrder(String orderId) async {
    try {
      final response = await _repo.trackOrder(orderId);
      if (response['success'] == true) {
        return response;
      }
      return null;
    } catch (e) {
      debugPrint("Failed to track order: $e");
      return null;
    }
  }

  /// Place order from cart and add to active orders
  Future<OrderModel> placeOrder({
    required CartProvider cart,
    required LocationProvider locationProv,
    required String deliveryAddress,
    required String paymentMethod,
    Map<String, dynamic>? userProfile,
    Map<String, dynamic>? razorpayData,
  }) async {
    _isPlacingOrder = true;
    notifyListeners();

    try {
      final isCod = paymentMethod.toLowerCase().contains('cash') || paymentMethod.toLowerCase() == 'cod';
      final effectiveMethod = isCod ? 'cod' : 'razorpay';

      final currentLoc = locationProv.currentLocation;
      final address = currentLoc.address;
      final pincode = address?.pincode ?? currentLoc.pincode ?? '201309';
      final areaId = (pincode.isNotEmpty) ? null : currentLoc.areaId;
      final lat = address?.latitude ?? currentLoc.lat;
      final lng = address?.longitude ?? currentLoc.lng;

      final shippingDetails = {
        "address_line1": deliveryAddress,
        "street_address": address?.streetAddress ?? deliveryAddress,
        "city": address?.city ?? currentLoc.city ?? 'Noida',
        "state": address?.state ?? 'Uttar Pradesh',
        "pincode": pincode,
        "postcode": pincode,
        "area_id": areaId,
        "latitude": ?lat,
        "longitude": ?lng,
        if (address != null) "address_id": address.id,
      };

      final customerDetails = {
        "fullName": userProfile != null
            ? '${userProfile['first_name'] ?? userProfile['firstName'] ?? ''} ${userProfile['last_name'] ?? userProfile['lastName'] ?? ''}'.trim()
            : 'Customer',
        "email": userProfile?['email'] ?? '',
        "phone": userProfile?['phone'] ?? '',
      };

      final payload = {
        "idempotency_key": 'ck-${DateTime.now().millisecondsSinceEpoch}',
        "customer_details": customerDetails,
        "shipping_details": shippingDetails,
        "payment_method": effectiveMethod,
        "cod_verified": isCod ? false : null,
        "items": cart.itemList.map((item) {
          final pId = int.tryParse(item.productId ?? '') ?? int.tryParse(item.id.split('_').first) ?? 0;
          final vId = int.tryParse(item.variationId ?? '');
          return {
            "product_id": pId,
            "variation_id": vId ?? pId,
            "quantity": item.quantity,
            "price": item.sellPrice,
            "product_name": item.title,
            "variation_name": item.weight ?? 'Standard',
            "sku": '',
            "offer_id": null,
            "vendor_id": null,
          };
        }).toList(),
        "subtotal": cart.subtotal,
        "shipping_charge": cart.deliveryFee,
        "convenience_fee": cart.convenienceFeeFor(paymentMethod),
        "total": cart.grandTotalFor(paymentMethod),
        "coupon_code": cart.appliedCoupon,
        "total_discount": cart.couponDiscount,
        if (razorpayData != null) "razorpay_order_id": razorpayData['razorpay_order_id'],
        if (razorpayData != null) "razorpay_payment_id": razorpayData['razorpay_payment_id'],
        if (razorpayData != null) "razorpay_signature": razorpayData['razorpay_signature'],
      };

      final response = await _repo.placeOrder(payload);

      if (response['success'] == true) {
        final orderCodeStr = response['order_code'] ?? response['order_id']?.toString() ?? 'unknown';

        await fetchOrders();

        final newOrder = _activeOrders.firstWhere(
          (o) => o.orderCode == orderCodeStr || o.rawId == orderCodeStr || o.id == orderCodeStr || o.id == '#$orderCodeStr',
          orElse: () {
            final cartOrder = OrderModel.fromCart(
              orderId: orderCodeStr,
              items: cart.itemList,
              grandTotal: cart.grandTotal,
              deliveryAddress: deliveryAddress,
              paymentMethod: paymentMethod,
            );
            _activeOrders.insert(0, cartOrder);
            return cartOrder;
          },
        );

        _lastPlacedOrder = newOrder;

        cart.clearCart();
        return newOrder;
      } else {
        throw Exception(response['error'] ?? response['message'] ?? "Failed to place order.");
      }
    } catch (e) {
      debugPrint("Order placement error: $e");
      rethrow;
    } finally {
      _isPlacingOrder = false;
      notifyListeners();
    }
  }

  /// Clears in-memory cached orders on logout or account switching.
  /// User order data in backend and local user-keyed cache is safely preserved.
  void reset() {
    _activeOrders = [];
    _pastOrders = [];
    _lastPlacedOrder = null;
    _isPlacingOrder = false;
    _isLoadingOrders = false;
    _currentUserId = null;
    notifyListeners();
  }
}

