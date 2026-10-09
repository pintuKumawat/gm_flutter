import 'package:grahmitracus/models/product/home_product_model.dart';

/// Model representing a Category Group containing its associated products from `/api/category-groups-products`.
class CategoryGroupProductsModel {
  final int groupId;
  final String groupName;
  final String? groupSlag;
  final String? shortDesc;
  final List<HomeProductModel> products;

  const CategoryGroupProductsModel({
    required this.groupId,
    required this.groupName,
    this.groupSlag,
    this.shortDesc,
    this.products = const [],
  });

  factory CategoryGroupProductsModel.fromJson(Map<String, dynamic> json) {
    final rawProducts = json['products'];
    List<HomeProductModel> productList = [];

    if (rawProducts is List) {
      productList = rawProducts
          .whereType<Map<String, dynamic>>()
          .map((item) => HomeProductModel.fromJson(item))
          .toList();
    }

    return CategoryGroupProductsModel(
      groupId: json['group_id'] is int
          ? json['group_id'] as int
          : int.tryParse(json['group_id']?.toString() ?? json['id']?.toString() ?? '0') ?? 0,
      groupName: json['group_name'] as String? ?? json['name'] as String? ?? '',
      groupSlag: (json['group_slag'] ?? json['group_slug'] ?? json['slag'] ?? json['slug']) as String?,
      shortDesc: (json['short_desc'] ?? json['shortDesc']) as String?,
      products: productList,
    );
  }

  Map<String, dynamic> toJson() => {
        'group_id': groupId,
        'group_name': groupName,
        'group_slag': groupSlag,
        'short_desc': shortDesc,
        'products': products.map((p) => p.toJson()).toList(),
      };
}
