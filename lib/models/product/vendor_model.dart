import 'package:grahmitracus/core/config/env_config.dart';
import 'package:grahmitracus/models/product/home_product_model.dart';

/// Model representing a vendor shop returned by `/api/vendors` or `/api/store/:slug`
class VendorModel {
  final int vendorId;
  final String storeName;
  final String? storeLogo;
  final String? slug;
  final String? storeDescription;

  const VendorModel({
    required this.vendorId,
    required this.storeName,
    this.storeLogo,
    this.slug,
    this.storeDescription,
  });

  /// Resolves full image URL whether it's absolute (R2/S3) or relative (backend server)
  String? get fullLogoUrl {
    if (storeLogo == null || storeLogo!.trim().isEmpty) return null;
    final trimmed = storeLogo!.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final base = EnvConfig.baseUrl.endsWith('/')
        ? EnvConfig.baseUrl.substring(0, EnvConfig.baseUrl.length - 1)
        : EnvConfig.baseUrl;
    final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$base$cleanPath';
  }

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['vendor_id'] ?? json['user_id'] ?? json['id'];
    return VendorModel(
      vendorId: rawId is int
          ? rawId
          : int.tryParse(rawId?.toString() ?? '0') ?? 0,
      storeName: json['store_name'] as String? ?? 'Store',
      storeLogo:
          (json['store_logo'] ?? json['logo'] ?? json['image']) as String?,
      slug: (json['slug'] ?? json['vendor_slug']) as String?,
      storeDescription:
          (json['store_description'] ?? json['description']) as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'vendor_id': vendorId,
        'store_name': storeName,
        'store_logo': storeLogo,
        'slug': slug,
        'store_description': storeDescription,
      };
}

/// Response payload from `GET /api/store/:slug`
class StoreDetailResponse {
  final bool success;
  final VendorModel store;
  final List<HomeProductModel> products;
  final int totalProducts;
  final int page;
  final int totalPages;
  final List<String> storeCategories;

  const StoreDetailResponse({
    required this.success,
    required this.store,
    required this.products,
    this.totalProducts = 0,
    this.page = 1,
    this.totalPages = 1,
    this.storeCategories = const [],
  });

  factory StoreDetailResponse.fromJson(Map<String, dynamic> json) {
    final rawStore = json['store'];
    final storeModel = rawStore is Map<String, dynamic>
        ? VendorModel.fromJson(rawStore)
        : rawStore is Map
            ? VendorModel.fromJson(Map<String, dynamic>.from(rawStore))
            : const VendorModel(vendorId: 0, storeName: 'Store');

    final rawProducts = json['products'];
    final List<HomeProductModel> productList = [];
    if (rawProducts is List) {
      for (final item in rawProducts) {
        if (item is Map) {
          productList.add(
              HomeProductModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final rawPagination = json['pagination'];
    int total = productList.length;
    int page = 1;
    int totalPages = 1;
    if (rawPagination is Map) {
      total = int.tryParse(rawPagination['total']?.toString() ?? '') ?? total;
      page = int.tryParse(rawPagination['page']?.toString() ?? '') ?? 1;
      totalPages = int.tryParse(rawPagination['totalPages']?.toString() ??
              rawPagination['pages']?.toString() ??
              '') ??
          1;
    }

    final rawCategories = json['storeCategories'] ?? json['categories'];
    final List<String> categories = [];
    if (rawCategories is List) {
      for (final cat in rawCategories) {
        if (cat != null && cat.toString().isNotEmpty) {
          categories.add(cat.toString());
        }
      }
    }

    return StoreDetailResponse(
      success: json['success'] == true,
      store: storeModel,
      products: productList,
      totalProducts: total,
      page: page,
      totalPages: totalPages,
      storeCategories: categories,
    );
  }
}
