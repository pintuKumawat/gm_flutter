import 'package:grahmitracus/core/services/api_endpoints.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/core/services/api_service.dart';
import 'package:grahmitracus/models/product/category_group_model.dart';

/// Repository handling category group network calls.
class CategoryGroupRepo {
  final ApiService _apiService;

  CategoryGroupRepo({ApiService? apiService})
      : _apiService = apiService ?? ApiService.instance;

  /// Fetches all active groups from `/api/groups`.
  ///
  /// Method & Route: GET `/api/groups` (Auth Required: No)
  Future<List<CategoryGroupModel>> getGroups() async {
    try {
      final response = await _apiService.get(ApiEndpoints.groups);

      if (response.data is List) {
        return (response.data as List)
            .map((item) =>
                CategoryGroupModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        final dynamic rawList = map['data'] ?? map['groups'] ?? map['result'];
        if (rawList is List) {
          return rawList
              .map((item) =>
                  CategoryGroupModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }

      return [];
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
