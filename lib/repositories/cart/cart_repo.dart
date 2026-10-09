import 'package:grahmitracus/core/services/api_endpoints.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/core/services/api_service.dart';

/// Repository handling cart network calls.
class CartRepo {
  final ApiService _apiService;

  CartRepo({ApiService? apiService})
      : _apiService = apiService ?? ApiService.instance;

  /// Revalidates the cart prices and stock from backend
  ///
  /// Method & Route: POST `/api/cart/revalidate` (Auth Required: No)
  Future<Map<String, dynamic>> revalidateCart(Map<String, dynamic> payload) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.cartRevalidate,
        data: payload,
      );

      return response.data as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Validates checkout and computes surcharges
  ///
  /// Method & Route: POST `/api/checkout/validate` (Auth Required: No)
  Future<Map<String, dynamic>> validateCheckout(Map<String, dynamic> payload) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.checkoutValidate,
        data: payload,
      );
      return response.data as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Gets list of currently active coupons
  ///
  /// Method & Route: GET `/api/coupons/active` (Auth Required: Yes)
  Future<Map<String, dynamic>> getActiveCoupons() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.activeCoupons,
      );
      return response.data as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Validates and applies a coupon to the order
  ///
  /// Method & Route: POST `/api/coupons/apply` (Auth Required: Yes)
  Future<Map<String, dynamic>> applyCoupon(Map<String, dynamic> payload) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.applyCoupon,
        data: payload,
      );
      return response.data as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}

