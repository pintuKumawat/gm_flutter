/// Model representing an active coupon returned by GET /api/coupons/active
class CouponModel {
  final int id;
  final String code;
  final String? type;
  final double? flatAmount;
  final double? minOrderAmount;
  final String? startDate;
  final String? endDate;

  const CouponModel({
    required this.id,
    required this.code,
    this.type,
    this.flatAmount,
    this.minOrderAmount,
    this.startDate,
    this.endDate,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      code: json['code']?.toString() ?? '',
      type: json['type']?.toString(),
      flatAmount: (json['flat_amount'] as num?)?.toDouble(),
      minOrderAmount: (json['min_order_amount'] as num?)?.toDouble(),
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'type': type,
      'flat_amount': flatAmount,
      'min_order_amount': minOrderAmount,
      'start_date': startDate,
      'end_date': endDate,
    };
  }
}

/// Model representing the response of POST /api/coupons/apply
class ApplyCouponResult {
  final bool success;
  final String message;
  final String? code;
  final double discountAmount;
  final double? finalAmount;
  final String? savingsPercentage;

  const ApplyCouponResult({
    required this.success,
    required this.message,
    this.code,
    this.discountAmount = 0.0,
    this.finalAmount,
    this.savingsPercentage,
  });

  factory ApplyCouponResult.fromJson(Map<String, dynamic> json) {
    final couponObj = json['coupon'] as Map<String, dynamic>?;
    final calcObj = json['calculation'] as Map<String, dynamic>?;

    final String code = couponObj?['code']?.toString() ?? '';
    final double discount = (couponObj?['discount_amount'] as num?)?.toDouble() ??
        (calcObj?['discount_amount'] as num?)?.toDouble() ??
        0.0;
    final double? finalAmt = (couponObj?['final_amount'] as num?)?.toDouble() ??
        (calcObj?['final_amount'] as num?)?.toDouble();
    final String? savingsPct = calcObj?['savings_percentage']?.toString();

    return ApplyCouponResult(
      success: json['success'] == true,
      message: json['message']?.toString() ?? (json['success'] == true ? 'Coupon applied successfully' : 'Failed to apply coupon'),
      code: code.isNotEmpty ? code : null,
      discountAmount: discount,
      finalAmount: finalAmt,
      savingsPercentage: savingsPct,
    );
  }
}
