import 'package:grahmitracus/core/config/env_config.dart';

/// Product Model for Home Screen Rails, Category Groups, and Super Saver Deals
class HomeProductModel {
  final int id;
  final String title;
  final String? shortDesc;
  final String? brand;
  final String? subcategory;
  final int? categoryId;
  final int? subcategoryId;
  final String? productImg;
  final String? productThumbNail;
  final double sellPrice;
  final double mrpPrice;
  final String? variationName;
  final int? variationId;
  final int stockQuantity;
  final int? isPublish;
  final int? isActive;
  final int? isFeatured;
  final int? isTrending;
  final int? isPremium;
  final String? slag;
  final String? tags;
  final String? storeName;
  final String? vendorSlug;
  final int? vendorId;

  const HomeProductModel({
    required this.id,
    required this.title,
    this.shortDesc,
    this.brand,
    this.subcategory,
    this.categoryId,
    this.subcategoryId,
    this.productImg,
    this.productThumbNail,
    required this.sellPrice,
    required this.mrpPrice,
    this.variationName,
    this.variationId,
    this.stockQuantity = 0,
    this.isPublish,
    this.isActive,
    this.isFeatured,
    this.isTrending,
    this.isPremium,
    this.slag,
    this.tags,
    this.storeName,
    this.vendorSlug,
    this.vendorId,
  });

  /// Formatted image path with fallback
  String? get imgPath {
    final raw = productThumbNail ?? productImg;
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    final base = EnvConfig.baseUrl.endsWith('/')
        ? EnvConfig.baseUrl.substring(0, EnvConfig.baseUrl.length - 1)
        : EnvConfig.baseUrl;
    final cleanPath = raw.startsWith('/') ? raw : '/$raw';
    return '$base$cleanPath';
  }

  /// Discount percentage (e.g. 15%)
  int get discountPercent {
    if (mrpPrice <= 0 || sellPrice >= mrpPrice) return 0;
    return (((mrpPrice - sellPrice) / mrpPrice) * 100).round();
  }

  /// Discount text (e.g. '15% OFF')
  String get discountText {
    final pct = discountPercent;
    if (pct <= 0) return '';
    return '$pct% OFF';
  }

  /// Extracted badge from tags (e.g. 'BESTSELLER', 'DEAL', 'PREMIUM')
  String? get badge {
    if (tags != null && tags!.trim().isNotEmpty) {
      return tags!.split(',').first.trim().toUpperCase();
    }
    if (isTrending == 1) return 'HOT DEAL';
    if (isFeatured == 1) return 'FEATURED';
    if (isPremium == 1) return 'PREMIUM';
    if (discountPercent >= 15) return '$discountPercent% OFF';
    return null;
  }

  /// Weight / Variation subtitle (e.g. '1 Kg', '500 ml', '1 Pack')
  String get weightText => variationName ?? '1 Pack';

  /// Whether product is sold out
  bool get isSoldOut => stockQuantity <= 0;

  factory HomeProductModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['product_id'];
    return HomeProductModel(
      id: rawId is int
          ? rawId
          : int.tryParse(rawId?.toString() ?? '0') ?? 0,
      title: json['title'] as String? ?? json['name'] as String? ?? '',
      shortDesc: json['short_desc'] as String? ?? json['shortDesc'] as String? ?? json['description'] as String?,
      brand: json['brand'] as String?,
      subcategory: (json['subcategory'] ?? json['sub_category'] ?? json['subcategory_name']) as String?,
      categoryId: json['category_id'] is int
          ? json['category_id'] as int
          : int.tryParse(json['category_id']?.toString() ?? ''),
      subcategoryId: json['subcategory_id'] is int
          ? json['subcategory_id'] as int
          : int.tryParse(json['subcategory_id']?.toString() ?? ''),
      productImg: (json['product_img'] ?? json['productImg'] ?? json['image']) as String?,
      productThumbNail: (json['product_thumb_nail'] ?? json['productThumbnail']) as String?,
      sellPrice: (json['sell_price'] ?? json['sellPrice'] ?? json['price'] ?? json['selling_price'] ?? 0) is num
          ? ((json['sell_price'] ?? json['sellPrice'] ?? json['price'] ?? json['selling_price'] ?? 0) as num).toDouble()
          : double.tryParse(json['sell_price']?.toString() ?? json['selling_price']?.toString() ?? '0') ?? 0.0,
      mrpPrice: (json['mrp_price'] ?? json['mrpPrice'] ?? json['mrp'] ?? 0) is num
          ? ((json['mrp_price'] ?? json['mrpPrice'] ?? json['mrp'] ?? 0) as num).toDouble()
          : double.tryParse(json['mrp_price']?.toString() ?? json['mrp']?.toString() ?? '0') ?? 0.0,
      variationName: (json['variation_name'] ?? json['variationName'] ?? json['variation']) as String?,
      variationId: json['variation_id'] is int
          ? json['variation_id'] as int
          : int.tryParse(json['variation_id']?.toString() ?? ''),
      stockQuantity: json['stock_quantity'] is int
          ? json['stock_quantity'] as int
          : int.tryParse(json['stock_quantity']?.toString() ?? '0') ?? 0,
      isPublish: json['is_publish'] is int
          ? json['is_publish'] as int
          : int.tryParse(json['is_publish']?.toString() ?? ''),
      isActive: json['is_active'] is int
          ? json['is_active'] as int
          : int.tryParse(json['is_active']?.toString() ?? ''),
      isFeatured: json['is_featured'] is int
          ? json['is_featured'] as int
          : int.tryParse(json['is_featured']?.toString() ?? ''),
      isTrending: json['is_trending'] is int
          ? json['is_trending'] as int
          : int.tryParse(json['is_trending']?.toString() ?? ''),
      isPremium: json['is_premium'] is int
          ? json['is_premium'] as int
          : int.tryParse(json['is_premium']?.toString() ?? ''),
      slag: (json['slag'] ?? json['slug']) as String?,
      tags: json['tags'] as String?,
      storeName: (json['store_name'] ?? json['vendor_name'] ?? json['vendorName']) as String?,
      vendorSlug: (json['vendor_slug'] ?? json['vendorSlug']) as String?,
      vendorId: json['vendor_id'] is int
          ? json['vendor_id'] as int
          : int.tryParse(json['vendor_id']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'short_desc': shortDesc,
        'brand': brand,
        'subcategory': subcategory,
        'category_id': categoryId,
        'subcategory_id': subcategoryId,
        'product_img': productImg,
        'product_thumb_nail': productThumbNail,
        'sell_price': sellPrice,
        'mrp_price': mrpPrice,
        'variation_name': variationName,
        'variation_id': variationId,
        'stock_quantity': stockQuantity,
        'is_publish': isPublish,
        'is_active': isActive,
        'is_featured': isFeatured,
        'is_trending': isTrending,
        'is_premium': isPremium,
        'slag': slag,
        'tags': tags,
        'store_name': storeName,
        'vendor_slug': vendorSlug,
        'vendor_id': vendorId,
      };
}
