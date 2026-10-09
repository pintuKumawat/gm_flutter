/// Model representing customer wallet balance and transactions response.
class WalletModel {
  final bool success;
  final double walletBalance;
  final double lockedWalletBalance;
  final String? referralCode;
  final List<WalletTransactionModel> transactions;

  const WalletModel({
    required this.success,
    required this.walletBalance,
    this.lockedWalletBalance = 0.0,
    this.referralCode,
    this.transactions = const [],
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    final rawBalance = json['wallet_balance'] ?? json['balance'] ?? 0;
    final balanceVal = rawBalance is num
        ? rawBalance.toDouble()
        : double.tryParse(rawBalance.toString()) ?? 0.0;

    final rawLocked = json['locked_wallet_balance'] ?? json['locked_balance'] ?? 0;
    final lockedVal = rawLocked is num
        ? rawLocked.toDouble()
        : double.tryParse(rawLocked.toString()) ?? 0.0;

    final rawList = json['transactions'] as List? ?? json['history'] as List? ?? [];
    final parsedTx = rawList
        .map((e) => WalletTransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return WalletModel(
      success: json['success'] as bool? ?? true,
      walletBalance: balanceVal,
      lockedWalletBalance: lockedVal,
      referralCode: json['referral_code'] as String?,
      transactions: parsedTx,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'wallet_balance': walletBalance,
        'locked_wallet_balance': lockedWalletBalance,
        'referral_code': referralCode,
        'transactions': transactions.map((t) => t.toJson()).toList(),
      };
}

/// Model representing an individual wallet transaction history item.
class WalletTransactionModel {
  final int id;
  final double amount;
  final String type; // 'credit' or 'debit'
  final String description;
  final String? kind;
  final String? status;
  final String? createdAt;

  const WalletTransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    this.kind,
    this.status,
    this.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'] ?? 0;
    final amountVal = rawAmount is num
        ? rawAmount.toDouble()
        : double.tryParse(rawAmount.toString()) ?? 0.0;

    return WalletTransactionModel(
      id: json['id'] as int? ?? 0,
      amount: amountVal,
      type: json['type'] as String? ?? 'credit',
      description: json['description'] as String? ?? json['remarks'] as String? ?? '',
      kind: json['kind'] as String?,
      status: json['status'] as String? ?? 'completed',
      createdAt: json['created_at'] as String? ?? json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'type': type,
        'description': description,
        'kind': kind,
        'status': status,
        'created_at': createdAt,
      };
}
