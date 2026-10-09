import 'package:grahmitracus/core/services/api_endpoints.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/core/services/api_service.dart';

class PaymentRepo {
  final ApiService _apiService;

  PaymentRepo({ApiService? apiService})
      : _apiService = apiService ?? ApiService.instance;

  /// POST /api/create-kvontech-payment
  Future<Map<String, dynamic>> createPayment({
    required double amount,
    String currency = 'INR',
  }) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.createKvontechPayment,
        data: {
          'amount': (amount * 100).round(),
          'currency': currency,
        },
      );
      return response.data as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// POST /api/verify-razorpay-payment
  Future<Map<String, dynamic>> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.verifyRazorpayPayment,
        data: {
          'razorpay_order_id': razorpayOrderId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_signature': razorpaySignature,
        },
      );
      return response.data as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
