/// Model representing a Category Group from `/api/groups`.
class CategoryGroupModel {
  final int id;
  final String name;
  final String? shortDesc;
  final String? slag;
  final String? imgPath;
  final int? sortOrder;
  final int? isActive;

  const CategoryGroupModel({
    required this.id,
    required this.name,
    this.shortDesc,
    this.slag,
    this.imgPath,
    this.sortOrder,
    this.isActive,
  });

  /// Check if the group is currently active
  bool get active => isActive == 1 || isActive == null;

  factory CategoryGroupModel.fromJson(Map<String, dynamic> json) {
    return CategoryGroupModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] as String? ?? '',
      shortDesc: json['short_desc'] as String?,
      slag: (json['slag'] ?? json['slug']) as String?,
      imgPath: (json['img_path'] ?? json['imgPath'] ?? json['image']) as String?,
      sortOrder: json['sort_order'] is int
          ? json['sort_order'] as int
          : int.tryParse(json['sort_order']?.toString() ?? ''),
      isActive: json['is_active'] is int
          ? json['is_active'] as int
          : int.tryParse(json['is_active']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'short_desc': shortDesc,
        'slag': slag,
        'img_path': imgPath,
        'sort_order': sortOrder,
        'is_active': isActive,
      };
}
