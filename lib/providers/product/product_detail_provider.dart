import 'package:flutter/foundation.dart';
import 'package:grahmitracus/models/product/home_product_model.dart';
import 'package:grahmitracus/models/product/product_detail_model.dart';
import 'package:grahmitracus/repositories/product/product_detail_repo.dart';

/// Provider managing Product Details, Variations, Gallery Images, Quantity, and Related Products
class ProductDetailProvider with ChangeNotifier {
  final ProductDetailRepo _repo = ProductDetailRepo();

  ProductDetailModel? _product;
  ProductVariationModel? _selectedVariation;
  int _quantity = 1;
  String _activeImage = '';
  List<HomeProductModel> _relatedProducts = [];
  bool _isLoadingProduct = false;
  bool _isLoadingRelated = false;
  String? _errorMessage;

  // Getters
  ProductDetailModel? get product => _product;
  ProductVariationModel? get selectedVariation => _selectedVariation;
  int get quantity => _quantity;
  String get activeImage => _activeImage;
  List<HomeProductModel> get relatedProducts => _relatedProducts;
  bool get isLoadingProduct => _isLoadingProduct;
  bool get isLoadingRelated => _isLoadingRelated;
  String? get errorMessage => _errorMessage;

  /// Effective price for selected variation or base product
  double get effectivePrice =>
      _selectedVariation?.sellPrice ?? _product?.sellPrice ?? 0.0;

  /// Effective MRP for selected variation or base product
  double get effectiveMrp =>
      _selectedVariation?.mrpPrice ?? _product?.mrpPrice ?? 0.0;

  /// Effective savings in INR
  double get effectiveSavings =>
      (effectiveMrp > effectivePrice) ? (effectiveMrp - effectivePrice) : 0.0;

  /// Effective discount percentage
  int get effectiveDiscountPercent {
    if (effectiveMrp <= 0 || effectivePrice >= effectiveMrp) return 0;
    return (((effectiveMrp - effectivePrice) / effectiveMrp) * 100).round();
  }

  /// Check whether currently selected variation or product is in stock
  bool get isInStock {
    if (_selectedVariation != null) {
      return _selectedVariation!.stockQuantity > 0;
    }
    return (_product?.stockQuantity ?? 0) > 0;
  }

  /// Available stock quantity
  int get availableStock =>
      _selectedVariation?.stockQuantity ?? _product?.stockQuantity ?? 0;

  /// Fetch full product details and trigger related products
  Future<void> loadProduct(
    String idOrSlug, {
    int? areaId = 101,
    String? pincode,
    double? lat,
    double? lng,
  }) async {
    _isLoadingProduct = true;
    _errorMessage = null;
    _product = null;
    _selectedVariation = null;
    _quantity = 1;
    _activeImage = '';
    _relatedProducts = [];
    notifyListeners();

    try {
      final detail = await _repo.getProductDetail(
        idOrSlug,
        areaId: areaId,
        pincode: pincode,
        lat: lat,
        lng: lng,
      );

      if (detail != null) {
        _product = detail;
        _activeImage = detail.heroImageUrl ?? '';

        // Select first variation if available
        if (detail.variations.isNotEmpty) {
          _selectedVariation = detail.variations.first;
        }

        _isLoadingProduct = false;
        notifyListeners();

        // Trigger related products fetch
        if (detail.categoryId != null && detail.categoryId! > 0) {
          loadRelatedProducts(
            detail.categoryId!,
            detail.id,
            areaId: areaId,
            pincode: pincode,
            lat: lat,
            lng: lng,
          );
        }
      } else {
        _isLoadingProduct = false;
        _errorMessage = 'Product not found';
        notifyListeners();
      }
    } catch (e) {
      _isLoadingProduct = false;
      _errorMessage = 'Failed to load product details';
      notifyListeners();
    }
  }

  /// Fetch related products for the current category
  Future<void> loadRelatedProducts(
    int categoryId,
    int productId, {
    int limit = 12,
    int offset = 0,
    int? areaId = 101,
    String? pincode,
    double? lat,
    double? lng,
  }) async {
    _isLoadingRelated = true;
    notifyListeners();

    try {
      final items = await _repo.getRelatedProducts(
        categoryId: categoryId,
        productId: productId,
        limit: limit,
        offset: offset,
        areaId: areaId,
        pincode: pincode,
        lat: lat,
        lng: lng,
      );

      _relatedProducts = items;
      _isLoadingRelated = false;
      notifyListeners();
    } catch (e) {
      _isLoadingRelated = false;
      notifyListeners();
    }
  }

  /// Change selected variation (pack size / weight)
  void selectVariation(ProductVariationModel variation) {
    _selectedVariation = variation;
    _quantity = 1;
    notifyListeners();
  }

  /// Change active gallery image
  void setActiveImage(String imageUrl) {
    _activeImage = imageUrl;
    notifyListeners();
  }

  /// Set quantity
  void setQuantity(int q) {
    final maxStock = availableStock;
    if (maxStock > 0 && q > maxStock) {
      _quantity = maxStock;
    } else if (q < 1) {
      _quantity = 1;
    } else {
      _quantity = q;
    }
    notifyListeners();
  }

  /// Increment quantity
  void incrementQuantity() {
    final maxStock = availableStock;
    if (maxStock > 0 && _quantity >= maxStock) return;
    _quantity += 1;
    notifyListeners();
  }

  /// Decrement quantity
  void decrementQuantity() {
    if (_quantity > 1) {
      _quantity -= 1;
      notifyListeners();
    }
  }
}
