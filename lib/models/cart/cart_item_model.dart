/// Cart Item Model representing an item stored in the shopping cart
class CartItem {
  final String id;
  final String title;
  final String? imageUrl;
  final double sellPrice;
  final double mrpPrice;
  final int quantity;
  final String? weight;
  final String? category;
  final String? productId;
  final String? variationId;
  final String? storeName;

  const CartItem({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.sellPrice,
    required this.mrpPrice,
    this.quantity = 1,
    this.weight,
    this.category,
    this.productId,
    this.variationId,
    this.storeName,
  });

  /// Total selling price for current quantity
  double get totalSellPrice => sellPrice * quantity;

  /// Total MRP price for current quantity
  double get totalMrpPrice => (mrpPrice > 0 ? mrpPrice : sellPrice) * quantity;

  /// Total money saved on this item
  double get totalSavings => totalMrpPrice - totalSellPrice > 0
      ? totalMrpPrice - totalSellPrice
      : 0.0;

  /// Discount percentage
  int get discountPercent {
    if (mrpPrice <= sellPrice || mrpPrice <= 0) return 0;
    return (((mrpPrice - sellPrice) / mrpPrice) * 100).round();
  }

  CartItem copyWith({
    String? id,
    String? title,
    String? imageUrl,
    double? sellPrice,
    double? mrpPrice,
    int? quantity,
    String? weight,
    String? category,
    String? productId,
    String? variationId,
    String? storeName,
  }) {
    return CartItem(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      sellPrice: sellPrice ?? this.sellPrice,
      mrpPrice: mrpPrice ?? this.mrpPrice,
      quantity: quantity ?? this.quantity,
      weight: weight ?? this.weight,
      category: category ?? this.category,
      productId: productId ?? this.productId,
      variationId: variationId ?? this.variationId,
      storeName: storeName ?? this.storeName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'sellPrice': sellPrice,
      'mrpPrice': mrpPrice,
      'quantity': quantity,
      'weight': weight,
      'category': category,
      'productId': productId,
      'variationId': variationId,
      'storeName': storeName,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      imageUrl: json['imageUrl'],
      sellPrice: (json['sellPrice'] as num?)?.toDouble() ?? 0.0,
      mrpPrice: (json['mrpPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] ?? 1,
      weight: json['weight'],
      category: json['category'],
      productId: json['productId']?.toString(),
      variationId: json['variationId']?.toString(),
      storeName: json['storeName'],
    );
  }
}
