/// Model representing a Subcategory / Category belonging to a Category Group (`cat_group_id`).
class CategoryModel {
  final int id;
  final String name;
  final int? catGroupId;
  final String? imgPath;
  final String? slag;
  final int? isActive;
  final int? sortOrder;

  const CategoryModel({
    required this.id,
    required this.name,
    this.catGroupId,
    this.imgPath,
    this.slag,
    this.isActive,
    this.sortOrder,
  });

  /// Checks if the category is currently active
  bool get active => isActive == 1 || isActive == null;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] as String? ?? '',
      catGroupId: json['cat_group_id'] is int
          ? json['cat_group_id'] as int
          : int.tryParse(json['cat_group_id']?.toString() ?? ''),
      imgPath:
          (json['img_path'] ?? json['imgPath'] ?? json['image']) as String?,
      slag: (json['slag'] ?? json['slug']) as String?,
      isActive: json['is_active'] is int
          ? json['is_active'] as int
          : int.tryParse(json['is_active']?.toString() ?? ''),
      sortOrder: json['sort_order'] is int
          ? json['sort_order'] as int
          : int.tryParse(json['sort_order']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'cat_group_id': catGroupId,
        'img_path': imgPath,
        'slag': slag,
        'is_active': isActive,
        'sort_order': sortOrder,
      };
}
