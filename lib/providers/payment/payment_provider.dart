import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:grahmitracus/repositories/payment/payment_repo.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentRepo _repo = PaymentRepo();
  late Razorpay _razorpay;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  PaymentProvider() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Function(Map<String, dynamic>)? _onSuccess;
  Function(String)? _onError;
  
  String? _currentKvontechTxId;

  /// Initiate Kvontech payment and open Razorpay
  Future<void> initiatePayment({
    required double amount,
    required String contact,
    required String email,
    required Function(Map<String, dynamic>) onSuccess,
    required Function(String) onError,
  }) async {
    _onSuccess = onSuccess;
    _onError = onError;
    _isProcessing = true;
    notifyListeners();

    try {
      // 1. Create payment on backend (Kvontech)
      final response = await _repo.createPayment(amount: amount);
      if (response['success'] == true) {
        final txId = response['transaction_id'];
        final details = response['checkout_details'];

        _currentKvontechTxId = txId;

        // 2. Open Razorpay checkout
        var options = {
          'key': details['key'],
          'amount': details['amount'],
          'currency': details['currency'] ?? 'INR',
          'name': 'GrahMitra',
          'description': 'Order Payment',
          'order_id': details['order_id'],
          'prefill': {
            'contact': contact,
            'email': email,
          },
          'theme': {
            'color': '#00B2A9',
          }
        };

        _razorpay.open(options);
      } else {
        _isProcessing = false;
        notifyListeners();
        _onError?.call(response['error'] ?? 'Payment initialization failed');
      }
    } catch (e) {
      _isProcessing = false;
      notifyListeners();
      _onError?.call('Failed to initialize payment: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (_currentKvontechTxId == null) {
      _isProcessing = false;
      notifyListeners();
      _onError?.call('Payment succeeded but missing transaction ID');
      return;
    }

    final successData = {
      'razorpay_order_id': _currentKvontechTxId, // Pass Kvontech transaction ID!
      'razorpay_payment_id': response.paymentId,
      'razorpay_signature': response.signature,
    };
    
    _isProcessing = false;
    notifyListeners();
    _onSuccess?.call(successData);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _isProcessing = false;
    notifyListeners();
    _onError?.call(response.message ?? 'Payment failed or cancelled');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Usually not needed unless specifically handled
    _isProcessing = false;
    notifyListeners();
    _onError?.call('External wallets not supported');
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }
}
