/// Strongly-typed Model representing customer transaction record from GET /api/transactions
class TransactionModel {
  final int id;
  final String? orderCode;
  final int? orderId;
  final String? paymentMethod;
  final double amount;
  final String currency;
  final String status;
  final String? razorpayPaymentId;
  final String? razorpayOrderId;
  final double creditUsed;
  final int? codVerified;
  final DateTime? codVerifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TransactionModel({
    required this.id,
    this.orderCode,
    this.orderId,
    this.paymentMethod,
    required this.amount,
    this.currency = 'INR',
    this.status = 'pending',
    this.razorpayPaymentId,
    this.razorpayOrderId,
    this.creditUsed = 0.0,
    this.codVerified,
    this.codVerifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  static double _parseDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: _parseInt(json['id']) ?? 0,
      orderCode: json['order_code']?.toString() ?? json['orderCode']?.toString(),
      orderId: _parseInt(json['order_id']),
      paymentMethod: json['payment_method']?.toString() ?? json['paymentMethod']?.toString(),
      amount: _parseDouble(json['amount']),
      currency: json['currency']?.toString() ?? 'INR',
      status: (json['status']?.toString() ?? 'pending').toLowerCase(),
      razorpayPaymentId: json['razorpay_payment_id']?.toString(),
      razorpayOrderId: json['razorpay_order_id']?.toString(),
      creditUsed: _parseDouble(json['credit_used']),
      codVerified: _parseInt(json['cod_verified']),
      codVerifiedAt: json['cod_verified_at'] != null
          ? DateTime.tryParse(json['cod_verified_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_code': orderCode,
        'order_id': orderId,
        'payment_method': paymentMethod,
        'amount': amount,
        'currency': currency,
        'status': status,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_order_id': razorpayOrderId,
        'credit_used': creditUsed,
        'cod_verified': codVerified,
        'cod_verified_at': codVerifiedAt?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  /// UI helpers matching the reference design and frontend logic
  String get description {
    final method = (paymentMethod?.toLowerCase() == 'cod')
        ? 'Cash on Delivery'
        : (paymentMethod?.toLowerCase() == 'razorpay'
            ? 'Razorpay Payment'
            : 'Payment');
    if (orderCode != null && orderCode!.isNotEmpty) {
      return '$method - Order $orderCode';
    }
    return '$method - refunded, no order created';
  }

  bool get isCredit => status == 'refunded';

  String get instrumentName =>
      (paymentMethod?.toLowerCase() == 'cod') ? 'CASH SETTLEMENT' : 'DIGITAL GATEWAY';

  String get displayAmount {
    final symbol = (currency == 'INR' || currency.isEmpty) ? '₹' : (currency == 'USD' ? '\$' : '$currency ');
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  String get signedDisplayAmount => isCredit ? '+$displayAmount' : '-$displayAmount';

  /// Formatted date matching screenshot: e.g. "OCT 9, 2026, 10:24 AM"
  String get formattedDate {
    if (createdAt == null) return 'DATE NOT AVAILABLE';
    final dt = createdAt!.toLocal();
    final months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    final month = months[dt.month - 1];
    final day = dt.day;
    final year = dt.year;

    final hour24 = dt.hour;
    final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';

    return '$month $day, $year, $hour12:$minute $period';
  }
}

/// Computed metrics statistics model matching the 2x2 grid in reference design
class TransactionStats {
  final double completedTotal;
  final double pendingTotal;
  final double refundedTotal;
  final int totalCount;
  final String currency;

  const TransactionStats({
    this.completedTotal = 0.0,
    this.pendingTotal = 0.0,
    this.refundedTotal = 0.0,
    this.totalCount = 0,
    this.currency = 'INR',
  });

  String get symbol => (currency == 'INR' || currency.isEmpty) ? '₹' : (currency == 'USD' ? '\$' : '$currency ');

  String get completedDisplay => '$symbol${completedTotal.toStringAsFixed(2)}';
  String get pendingDisplay => '$symbol${pendingTotal.toStringAsFixed(2)}';
  String get refundedDisplay => '$symbol${refundedTotal.toStringAsFixed(2)}';
  String get transactionsCountDisplay => '$totalCount';

  factory TransactionStats.fromList(List<TransactionModel> items) {
    if (items.isEmpty) {
      return const TransactionStats();
    }
    double completed = 0;
    double pending = 0;
    double refunded = 0;

    for (final tx in items) {
      switch (tx.status.toLowerCase()) {
        case 'completed':
          completed += tx.amount;
          break;
        case 'pending':
          pending += tx.amount;
          break;
        case 'refunded':
          refunded += tx.amount;
          break;
      }
    }

    final curr = items.first.currency;
    return TransactionStats(
      completedTotal: completed,
      pendingTotal: pending,
      refundedTotal: refunded,
      totalCount: items.length,
      currency: curr,
    );
  }
}
