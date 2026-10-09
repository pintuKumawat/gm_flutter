import 'package:grahmitracus/core/services/api_endpoints.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/core/services/api_service.dart';

/// Repository handling order network calls.
class OrderRepo {
  final ApiService _apiService;

  OrderRepo({ApiService? apiService})
      : _apiService = apiService ?? ApiService.instance;

  /// POST /api/place/orders
  Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> payload) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.createOrder,
        data: payload,
      );
      return response.data as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// GET /api/customer/orders
  Future<dynamic> getCustomerOrders({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.orders,
        queryParameters: {'page': page, 'limit': limit},
      );
      return response.data;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// GET /api/customer/orders/detail/:id
  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.orderDetail(orderId),
      );
      return response.data as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// GET /api/customer/orders/tracking/:id
  Future<Map<String, dynamic>> trackOrder(String orderId) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.orderTracking(orderId),
      );
      return response.data as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
