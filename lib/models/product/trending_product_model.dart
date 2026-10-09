class TrendingProductModel {
  final int id;
  final String title;
  final double sellPrice;
  final double mrpPrice;
  final String storeName;
  final String? brand;
  final String? imgPath;
  final String? weight;
  final String? categoryName;
  final String? variationName;
  final int? variationId;
  final bool isActive;
  final bool isTrending;

  const TrendingProductModel({
    required this.id,
    required this.title,
    required this.sellPrice,
    required this.mrpPrice,
    required this.storeName,
    this.brand,
    this.imgPath,
    this.weight,
    this.categoryName,
    this.variationName,
    this.variationId,
    this.isActive = true,
    this.isTrending = true,
  });

  factory TrendingProductModel.fromJson(Map<String, dynamic> json) {
    // Robust double price parser
    double parsePrice(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) {
        return double.tryParse(val.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
      }
      return 0.0;
    }

    // Robust int ID parser
    int parseId(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    // Robust bool parser
    bool parseBool(dynamic val) {
      if (val == null) return true;
      if (val is bool) return val;
      if (val is num) return val == 1;
      if (val is String) return val == '1' || val.toLowerCase() == 'true';
      return true;
    }

    final parsedSellPrice = parsePrice(json['sell_price'] ?? json['sellPrice'] ?? json['price']);
    final parsedMrpPrice = parsePrice(json['mrp_price'] ?? json['mrpPrice'] ?? json['mrp']);

    final img = (json['product_thumb_nail'] ??
            json['product_img'] ??
            json['img_path'] ??
            json['imgPath'] ??
            json['image'] ??
            json['thumbnail'])
        ?.toString();

    final variation = (json['variation_name'] ?? json['variationName'])?.toString();
    final unitWeight = (variation != null && variation.isNotEmpty)
        ? variation
        : (json['weight'] ?? json['unit'] ?? json['qty'] ?? json['short_desc'])?.toString();

    return TrendingProductModel(
      id: parseId(json['id']),
      title: (json['title'] ?? json['name'] ?? 'Product').toString(),
      sellPrice: parsedSellPrice,
      mrpPrice: parsedMrpPrice > 0 ? parsedMrpPrice : parsedSellPrice,
      storeName: (json['store_name'] ?? json['storeName'] ?? json['seller'] ?? 'Verified Store').toString(),
      brand: json['brand']?.toString(),
      imgPath: img,
      weight: unitWeight,
      categoryName: (json['category'] ?? json['category_name'] ?? json['categoryName'])?.toString(),
      variationName: variation,
      variationId: parseId(json['variation_id']),
      isActive: parseBool(json['is_active']),
      isTrending: parseBool(json['is_trending']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'sell_price': sellPrice,
      'mrp_price': mrpPrice,
      'store_name': storeName,
      if (brand != null) 'brand': brand,
      if (imgPath != null) 'img_path': imgPath,
      if (weight != null) 'weight': weight,
      if (categoryName != null) 'category_name': categoryName,
      if (variationName != null) 'variation_name': variationName,
      if (variationId != null) 'variation_id': variationId,
      'is_active': isActive ? 1 : 0,
      'is_trending': isTrending ? 1 : 0,
    };
  }

  /// Calculates percentage discount
  String get discountText {
    if (mrpPrice > sellPrice && mrpPrice > 0) {
      final discount = (((mrpPrice - sellPrice) / mrpPrice) * 100).round();
      if (discount > 0) {
        return '$discount% OFF';
      }
    }
    return '';
  }

  TrendingProductModel copyWith({
    int? id,
    String? title,
    double? sellPrice,
    double? mrpPrice,
    String? storeName,
    String? brand,
    String? imgPath,
    String? weight,
    String? categoryName,
    String? variationName,
    int? variationId,
    bool? isActive,
    bool? isTrending,
  }) {
    return TrendingProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      sellPrice: sellPrice ?? this.sellPrice,
      mrpPrice: mrpPrice ?? this.mrpPrice,
      storeName: storeName ?? this.storeName,
      brand: brand ?? this.brand,
      imgPath: imgPath ?? this.imgPath,
      weight: weight ?? this.weight,
      categoryName: categoryName ?? this.categoryName,
      variationName: variationName ?? this.variationName,
      variationId: variationId ?? this.variationId,
      isActive: isActive ?? this.isActive,
      isTrending: isTrending ?? this.isTrending,
    );
  }
}
