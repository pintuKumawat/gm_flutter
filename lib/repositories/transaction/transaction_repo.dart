import 'package:grahmitracus/core/services/api_endpoints.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/core/services/api_service.dart';
import 'package:grahmitracus/models/transaction/transaction_model.dart';

/// Repository handling API communications for customer transactions
class TransactionRepo {
  final ApiService _apiService;

  TransactionRepo({ApiService? apiService})
      : _apiService = apiService ?? ApiService.instance;

  /// GET /api/transactions
  Future<List<TransactionModel>> getTransactions() async {
    try {
      final response = await _apiService.get(ApiEndpoints.transactions);
      final dynamic raw = response.data;

      final List items;
      if (raw is List) {
        items = raw;
      } else if (raw is Map<String, dynamic> && raw['transactions'] is List) {
        items = raw['transactions'] as List;
      } else if (raw is Map<String, dynamic> && raw['data'] is List) {
        items = raw['data'] as List;
      } else {
        items = [];
      }

      return items
          .whereType<Map>()
          .map((e) => TransactionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
