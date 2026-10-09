import 'package:grahmitracus/core/services/api_endpoints.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/core/services/api_service.dart';
import 'package:grahmitracus/models/product/category_model.dart';

/// Repository handling category & subcategory network calls.
class CategoryRepo {
  final ApiService _apiService;

  CategoryRepo({ApiService? apiService})
      : _apiService = apiService ?? ApiService.instance;

  /// Fetches subcategories from `/api/categories`, optionally filtered by `cat_group_id`.
  ///
  /// Method & Route: GET `/api/categories` (Auth Required: No)
  Future<List<CategoryModel>> getCategories({int? catGroupId}) async {
    try {
      final Map<String, dynamic> queryParameters = {};
      if (catGroupId != null) {
        queryParameters['cat_group_id'] = catGroupId;
      }

      final response = await _apiService.get(
        ApiEndpoints.categories,
        queryParameters:
            queryParameters.isNotEmpty ? queryParameters : null,
      );

      if (response.data is List) {
        return (response.data as List)
            .map((item) =>
                CategoryModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        final dynamic rawList =
            map['data'] ?? map['categories'] ?? map['result'];
        if (rawList is List) {
          return rawList
              .map((item) =>
                  CategoryModel.fromJson(item as Map<String, dynamic>))
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
