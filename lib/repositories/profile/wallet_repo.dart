import 'package:grahmitracus/core/services/api_endpoints.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/core/services/api_service.dart';
import 'package:grahmitracus/models/profile/wallet_model.dart';

/// Repository for Customer Wallet network calls.
class WalletRepo {
  final ApiService _apiService;

  WalletRepo({ApiService? apiService})
      : _apiService = apiService ?? ApiService.instance;

  /// Fetches customer wallet balance and transaction history.
  ///
  /// Endpoint: GET `/api/customer/wallet`
  Future<WalletModel> getWallet() async {
    try {
      final response = await _apiService.get(ApiEndpoints.customerWallet);

      if (response.data is Map<String, dynamic>) {
        return WalletModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ApiException(message: 'Invalid response format received from server');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
