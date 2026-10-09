import 'package:grahmitracus/core/config/env_config.dart';

/// Full Product Detail Model matching backend response from `/api/products/:id`
class ProductDetailModel {
  final int id;
  final String title;
  final String? brand;
  final String? description;
  final String? shortDesc;
  final String? category;
  final String? subcategory;
  final int? categoryId;
  final int? subcategoryId;
  final String? keywords;
  final String? tags;
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
  final double gstPercent;
  final String? slag;
  final String? storeName;
  final String? vendorSlug;
  final int? vendorId;
  final List<String> galleryImages;
  final List<ProductVariationModel> variations;
  final List<ProductOfferModel> offers;
  final List<ProductSellerModel> sellers;

  const ProductDetailModel({
    required this.id,
    required this.title,
    this.brand,
    this.description,
    this.shortDesc,
    this.category,
    this.subcategory,
    this.categoryId,
    this.subcategoryId,
    this.keywords,
    this.tags,
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
    this.gstPercent = 0.0,
    this.slag,
    this.storeName,
    this.vendorSlug,
    this.vendorId,
    this.galleryImages = const [],
    this.variations = const [],
    this.offers = const [],
    this.sellers = const [],
  });

  /// Main hero image with base url prefix
  String? get heroImageUrl {
    final raw = productImg ?? productThumbNail;
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    final base = EnvConfig.baseUrl.endsWith('/')
        ? EnvConfig.baseUrl.substring(0, EnvConfig.baseUrl.length - 1)
        : EnvConfig.baseUrl;
    final cleanPath = raw.startsWith('/') ? raw : '/$raw';
    return '$base$cleanPath';
  }

  /// All unique images for gallery carousel
  List<String> get allImages {
    final List<String> list = [];
    final hero = heroImageUrl;
    if (hero != null && hero.isNotEmpty) list.add(hero);

    final base = EnvConfig.baseUrl.endsWith('/')
        ? EnvConfig.baseUrl.substring(0, EnvConfig.baseUrl.length - 1)
        : EnvConfig.baseUrl;

    for (final img in galleryImages) {
      if (img.isEmpty) continue;
      final full = (img.startsWith('http://') || img.startsWith('https://'))
          ? img
          : '$base${img.startsWith('/') ? img : '/$img'}';
      if (!list.contains(full)) {
        list.add(full);
      }
    }
    return list;
  }

  /// Discount percentage (e.g. 20%)
  int get discountPercent {
    if (mrpPrice <= 0 || sellPrice >= mrpPrice) return 0;
    return (((mrpPrice - sellPrice) / mrpPrice) * 100).round();
  }

  /// Amount saved in INR
  double get savings => (mrpPrice > sellPrice) ? (mrpPrice - sellPrice) : 0.0;

  /// Sold out flag
  bool get isSoldOut => stockQuantity <= 0;

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) {
        return double.tryParse(val.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
      }
      return 0.0;
    }

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    // Parse gallery images
    List<String> imageList = [];
    final rawImgs = json['images'];
    if (rawImgs is List) {
      for (final item in rawImgs) {
        if (item is String && item.isNotEmpty) {
          imageList.add(item);
        } else if (item is Map<String, dynamic> && item['image'] != null) {
          imageList.add(item['image'].toString());
        }
      }
    }

    // Parse variations
    List<ProductVariationModel> variationList = [];
    final rawVars = json['variations'];
    if (rawVars is List) {
      variationList = rawVars
          .whereType<Map<String, dynamic>>()
          .map((v) => ProductVariationModel.fromJson(v))
          .toList();
    }

    // Parse offers
    List<ProductOfferModel> offerList = [];
    final rawOffers = json['offers'];
    if (rawOffers is List) {
      offerList = rawOffers
          .whereType<Map<String, dynamic>>()
          .map((o) => ProductOfferModel.fromJson(o))
          .toList();
    }

    // Parse sellers
    List<ProductSellerModel> sellerList = [];
    final rawSellers = json['sellers'];
    if (rawSellers is List) {
      sellerList = rawSellers
          .whereType<Map<String, dynamic>>()
          .map((s) => ProductSellerModel.fromJson(s))
          .toList();
    }

    return ProductDetailModel(
      id: parseInt(json['id']),
      title: json['title'] as String? ?? json['name'] as String? ?? '',
      brand: json['brand'] as String?,
      description: json['description'] as String?,
      shortDesc: json['short_desc'] as String? ?? json['shortDesc'] as String?,
      category: json['category'] as String?,
      subcategory: (json['subcategory'] ?? json['sub_category']) as String?,
      categoryId: json['category_id'] is int
          ? json['category_id'] as int
          : int.tryParse(json['category_id']?.toString() ?? ''),
      subcategoryId: json['subcategory_id'] is int
          ? json['subcategory_id'] as int
          : int.tryParse(json['subcategory_id']?.toString() ?? ''),
      keywords: json['keywords'] as String?,
      tags: json['tags'] as String?,
      productImg: (json['product_img'] ?? json['productImg'] ?? json['image']) as String?,
      productThumbNail: (json['product_thumb_nail'] ?? json['productThumbnail']) as String?,
      sellPrice: parseDouble(json['sell_price'] ?? json['sellPrice'] ?? json['price']),
      mrpPrice: parseDouble(json['mrp_price'] ?? json['mrpPrice'] ?? json['mrp']),
      variationName: (json['variation_name'] ?? json['variationName']) as String?,
      variationId: json['variation_id'] is int
          ? json['variation_id'] as int
          : int.tryParse(json['variation_id']?.toString() ?? ''),
      stockQuantity: parseInt(json['stock_quantity'] ?? json['stockQuantity']),
      isPublish: parseInt(json['is_publish']),
      isActive: parseInt(json['is_active']),
      isFeatured: parseInt(json['is_featured']),
      isTrending: parseInt(json['is_trending']),
      isPremium: parseInt(json['is_premium']),
      gstPercent: parseDouble(json['gst_percent']),
      slag: (json['slag'] ?? json['slug']) as String?,
      storeName: (json['store_name'] ?? json['vendor_name'] ?? json['vendorName']) as String?,
      vendorSlug: (json['vendor_slug'] ?? json['vendorSlug']) as String?,
      vendorId: json['vendor_id'] is int
          ? json['vendor_id'] as int
          : int.tryParse(json['vendor_id']?.toString() ?? ''),
      galleryImages: imageList,
      variations: variationList,
      offers: offerList,
      sellers: sellerList,
    );
  }
}

/// Variation model for Pack / Weight options (e.g. "250g", "1 Kg")
class ProductVariationModel {
  final int id;
  final int? productId;
  final String name;
  final int? offerId;
  final int? vendorId;
  final String? sku;
  final double sellPrice;
  final double mrpPrice;
  final int stockQuantity;
  final int? isActive;
  final String? storeName;
  final String? vendorSlug;
  final double gstPercent;

  const ProductVariationModel({
    required this.id,
    this.productId,
    required this.name,
    this.offerId,
    this.vendorId,
    this.sku,
    required this.sellPrice,
    required this.mrpPrice,
    this.stockQuantity = 0,
    this.isActive = 1,
    this.storeName,
    this.vendorSlug,
    this.gstPercent = 0.0,
  });

  int get discountPercent {
    if (mrpPrice <= 0 || sellPrice >= mrpPrice) return 0;
    return (((mrpPrice - sellPrice) / mrpPrice) * 100).round();
  }

  bool get isOutOfStock => stockQuantity <= 0;

  factory ProductVariationModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) {
        return double.tryParse(val.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
      }
      return 0.0;
    }

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return ProductVariationModel(
      id: parseInt(json['id'] ?? json['variation_id']),
      productId: parseInt(json['product_id']),
      name: json['name'] as String? ?? json['variation_name'] as String? ?? 'Standard',
      offerId: parseInt(json['offer_id']),
      vendorId: parseInt(json['vendor_id']),
      sku: json['sku'] as String?,
      sellPrice: parseDouble(json['sell_price'] ?? json['sellPrice'] ?? json['price']),
      mrpPrice: parseDouble(json['mrp_price'] ?? json['mrpPrice'] ?? json['mrp']),
      stockQuantity: parseInt(json['stock_quantity'] ?? json['stockQuantity']),
      isActive: parseInt(json['is_active'] ?? 1),
      storeName: json['store_name'] as String?,
      vendorSlug: json['vendor_slug'] as String?,
      gstPercent: parseDouble(json['gst_percent']),
    );
  }
}

/// Vendor offer model representing a seller's specific offer
class ProductOfferModel {
  final int offerId;
  final int vendorId;
  final int variationId;
  final String variationName;
  final double sellPrice;
  final double mrpPrice;
  final int stockQuantity;
  final String? sku;
  final String? storeName;
  final String? vendorSlug;
  final double gstPercent;

  const ProductOfferModel({
    required this.offerId,
    required this.vendorId,
    required this.variationId,
    required this.variationName,
    required this.sellPrice,
    required this.mrpPrice,
    this.stockQuantity = 0,
    this.sku,
    this.storeName,
    this.vendorSlug,
    this.gstPercent = 0.0,
  });

  factory ProductOfferModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) {
        return double.tryParse(val.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
      }
      return 0.0;
    }

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return ProductOfferModel(
      offerId: parseInt(json['offer_id'] ?? json['id']),
      vendorId: parseInt(json['vendor_id']),
      variationId: parseInt(json['variation_id']),
      variationName: json['variation_name'] as String? ?? json['name'] as String? ?? '',
      sellPrice: parseDouble(json['sell_price'] ?? json['price']),
      mrpPrice: parseDouble(json['mrp_price'] ?? json['mrp']),
      stockQuantity: parseInt(json['stock_quantity']),
      sku: json['sku'] as String?,
      storeName: json['store_name'] as String?,
      vendorSlug: json['vendor_slug'] as String?,
      gstPercent: parseDouble(json['gst_percent']),
    );
  }
}

/// Seller listing card model
class ProductSellerModel {
  final int vendorId;
  final String storeName;
  final String? vendorSlug;
  final String? storeLogo;
  final double fromPrice;
  final int totalStock;
  final int packCount;
  final bool deliverable;

  const ProductSellerModel({
    required this.vendorId,
    required this.storeName,
    this.vendorSlug,
    this.storeLogo,
    required this.fromPrice,
    this.totalStock = 0,
    this.packCount = 1,
    this.deliverable = true,
  });

  factory ProductSellerModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) {
        return double.tryParse(val.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
      }
      return 0.0;
    }

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return ProductSellerModel(
      vendorId: parseInt(json['vendor_id'] ?? json['id']),
      storeName: json['store_name'] as String? ?? 'Verified Store',
      vendorSlug: json['vendor_slug'] as String?,
      storeLogo: json['store_logo'] as String?,
      fromPrice: parseDouble(json['from_price'] ?? json['sell_price']),
      totalStock: parseInt(json['total_stock'] ?? json['stock_quantity']),
      packCount: parseInt(json['pack_count'] ?? 1),
      deliverable: json['deliverable'] != false,
    );
  }
}
