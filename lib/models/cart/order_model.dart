import 'package:flutter/material.dart';
import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/models/cart/cart_item_model.dart';

/// Order Model representing a placed order
class OrderModel {
  final String rawId;
  final String orderCode;
  final String id;
  final String date;
  final String status;
  final String rawStatus;
  final bool isPastOrder;
  final Color statusColor;
  final Color statusBg;
  final String items;
  final String total;
  final int itemCount;
  final String deliveryAddress;
  final String paymentMethod;
  final List<CartItem> orderedItems;
  final DateTime createdAt;

  const OrderModel({
    required this.rawId,
    required this.orderCode,
    required this.id,
    required this.date,
    required this.status,
    required this.rawStatus,
    required this.isPastOrder,
    required this.statusColor,
    required this.statusBg,
    required this.items,
    required this.total,
    required this.itemCount,
    this.deliveryAddress = 'Home - Main Address',
    this.paymentMethod = 'Cash on Delivery',
    this.orderedItems = const [],
    required this.createdAt,
  });

  /// Factory to construct a new OrderModel from Cart checkout
  factory OrderModel.fromCart({
    required String orderId,
    required List<CartItem> items,
    required double grandTotal,
    required String deliveryAddress,
    required String paymentMethod,
  }) {
    final now = DateTime.now();
    final timeStr =
        '${now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour)}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
    final dateStr = 'Today, $timeStr';

    final itemsSummary = items
        .map((i) => '${i.title}${i.weight != null ? ' (${i.weight})' : ''}')
        .take(3)
        .join(', ');

    final formattedSummary = items.length > 3
        ? '$itemsSummary + ${items.length - 3} more'
        : itemsSummary;

    final code = orderId.replaceAll('#', '');

    return OrderModel(
      rawId: code,
      orderCode: code,
      id: orderId.startsWith('#') ? orderId : '#$orderId',
      date: dateStr,
      status: 'Order Placed',
      rawStatus: 'placed',
      isPastOrder: false,
      statusColor: AppColors.brandPurple,
      statusBg: AppColors.brandPurpleLight,
      items: formattedSummary,
      total: '₹ ${grandTotal.toStringAsFixed(2)}',
      itemCount: items.fold(0, (sum, item) => sum + item.quantity),
      deliveryAddress: deliveryAddress,
      paymentMethod: paymentMethod,
      orderedItems: List.from(items),
      createdAt: now,
    );
  }

  /// Factory to construct from backend API JSON
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString() ?? '';
    final code = json['order_code']?.toString() ?? rawId;
    final rawStatus = (json['order_status'] ?? json['status'] ?? 'pending').toString().toLowerCase().trim();

    final pastStatuses = ['delivered', 'completed', 'cancelled', 'rejected', 'returned', 'rto', 'refunded'];
    final isPast = pastStatuses.contains(rawStatus);

    Color sColor = AppColors.brandPurple;
    Color sBg = AppColors.brandPurpleLight;
    String displayStatus = 'Order Placed';

    if (rawStatus == 'delivered' || rawStatus == 'completed') {
      sColor = AppColors.discountGreen;
      sBg = AppColors.discountGreenBg;
      displayStatus = 'Delivered';
    } else if (rawStatus == 'cancelled' || rawStatus == 'rejected' || rawStatus == 'returned' || rawStatus == 'rto' || rawStatus == 'refunded') {
      sColor = AppColors.error;
      sBg = AppColors.errorLight;
      displayStatus = 'Cancelled';
    } else if (rawStatus == 'out_for_delivery' || rawStatus == 'dispatched' || rawStatus == 'in_transit' || rawStatus == 'shipped' || rawStatus == 'handed_over' || rawStatus == 'picked_up') {
      sColor = AppColors.brandOrange;
      sBg = AppColors.brandOrangeLight;
      displayStatus = 'Out for Delivery';
    } else if (rawStatus == 'packing' || rawStatus == 'packed' || rawStatus == 'processing' || rawStatus == 'ready_for_rider') {
      sColor = AppColors.brandPurple;
      sBg = AppColors.brandPurpleLight;
      displayStatus = 'Packing';
    } else {
      sColor = AppColors.brandPurple;
      sBg = AppColors.brandPurpleLight;
      displayStatus = 'Order Placed';
    }

    final createdAtStr = json['order_date'] ?? DateTime.now().toIso8601String();
    final parsedDate = DateTime.tryParse(createdAtStr) ?? DateTime.now();
    final timeStr =
        '${parsedDate.hour > 12 ? parsedDate.hour - 12 : (parsedDate.hour == 0 ? 12 : parsedDate.hour)}:${parsedDate.minute.toString().padLeft(2, '0')} ${parsedDate.hour >= 12 ? 'PM' : 'AM'}';
    final dateStr = '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}, $timeStr';

    final totalVal = double.tryParse(json['total']?.toString() ?? '0') ?? 0.0;
    final totalStr = '₹ ${totalVal.toStringAsFixed(2)}';
    final itemCount = json['items_count'] ?? (json['products'] is List ? (json['products'] as List).length : 1);

    List<CartItem> parsedItems = [];
    String itemsText = 'Order items ($itemCount items)';

    if (json['products'] != null && json['products'] is List) {
      final productsList = json['products'] as List;
      parsedItems = productsList.map((item) {
        final sellP = double.tryParse(item['price']?.toString() ?? '0') ?? 0;
        return CartItem(
          id: item['variation_id']?.toString() ?? item['product_id']?.toString() ?? '',
          title: item['product_name'] ?? item['name'] ?? 'Product',
          sellPrice: sellP,
          mrpPrice: sellP,
          imageUrl: item['product_image'] ?? '',
          quantity: item['quantity'] ?? 1,
          weight: item['variation_name'],
          productId: item['product_id']?.toString(),
          variationId: item['variation_id']?.toString(),
        );
      }).toList();

      if (parsedItems.isNotEmpty) {
        final summary = parsedItems
            .map((i) => '${i.title}${i.weight != null && i.weight!.isNotEmpty ? ' (${i.weight})' : ''}')
            .take(3)
            .join(', ');

        itemsText = parsedItems.length > 3
            ? '$summary + ${parsedItems.length - 3} more'
            : summary;
      }
    }

    String address = 'Home - Main Address';
    if (json['shipping_details'] != null || json['shipping_to'] != null) {
      final ship = json['shipping_details'] ?? json['shipping_to'];
      if (ship is Map<String, dynamic>) {
        final parts = [
          ship['street_address'] ?? ship['address_line1'],
          ship['city'],
          ship['pincode'] ?? ship['postcode']
        ].where((p) => p != null && p.toString().trim().isNotEmpty).join(', ');
        if (parts.isNotEmpty) address = parts;
      } else if (ship is String && ship.trim().isNotEmpty) {
        address = ship;
      }
    }

    return OrderModel(
      rawId: rawId,
      orderCode: code,
      id: code.startsWith('#') ? code : '#$code',
      date: dateStr,
      status: displayStatus,
      rawStatus: rawStatus,
      isPastOrder: isPast,
      statusColor: sColor,
      statusBg: sBg,
      items: itemsText,
      total: totalStr,
      itemCount: itemCount,
      deliveryAddress: address,
      paymentMethod: (json['payment_method'] ?? json['shipping_method'] ?? 'Online').toString().toUpperCase(),
      orderedItems: parsedItems,
      createdAt: parsedDate,
    );
  }
}
