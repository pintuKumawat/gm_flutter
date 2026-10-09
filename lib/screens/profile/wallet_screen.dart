import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/core/responsive/responsive.dart';
import 'package:grahmitracus/models/profile/wallet_model.dart';
import 'package:grahmitracus/providers/profile/wallet_provider.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWallet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Wallet',
          style: AppTextStyles.plusJakartaSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<WalletProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.wallet == null) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.brandPurple,
              ),
            );
          }

          if (provider.hasError && provider.wallet == null) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48.sp,
                      color: AppColors.error,
                    ),
                    16.height,
                    Text(
                      provider.errorMessage ?? 'Failed to load wallet details',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    20.height,
                    ElevatedButton(
                      onPressed: () => provider.fetchWallet(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Retry',
                        style: AppTextStyles.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final wallet = provider.wallet;
          final balance = wallet?.walletBalance ?? 0.0;
          final locked = wallet?.lockedWalletBalance ?? 0.0;
          final transactions = wallet?.transactions ?? [];

          return RefreshIndicator(
            onRefresh: () => provider.fetchWallet(),
            color: AppColors.brandPurple,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wallet Balance Hero Card
                  _buildBalanceCard(balance, locked, wallet?.referralCode),

                  24.height,

                  // Transactions Header
                  Text(
                    'Transaction History',
                    style: AppTextStyles.plusJakartaSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  14.height,

                  // Transactions List / Empty State
                  if (transactions.isEmpty)
                    _buildEmptyState()
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      separatorBuilder: (context, index) => Divider(
                        color: AppColors.borderSubtle,
                        height: 20.h,
                      ),
                      itemBuilder: (context, index) {
                        return _buildTransactionItem(transactions[index]);
                      },
                    ),
                  24.height,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(double balance, double locked, String? referralCode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.brandPurple,
            AppColors.buttonGradientEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPurple.withValues(alpha: 0.3),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Balance',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            ],
          ),
          8.height,
          Text(
            '₹ ${balance.toStringAsFixed(2)}',
            style: AppTextStyles.plusJakartaSans(
              fontSize: 28.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          if (locked > 0) ...[
            12.height,
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'Locked Bonus: ₹ ${locked.toStringAsFixed(2)}',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: AppColors.subtleBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 44.sp,
            color: AppColors.iconSubtle,
          ),
          12.height,
          Text(
            'No transactions yet',
            style: AppTextStyles.plusJakartaSans(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          6.height,
          Text(
            'Your wallet credits and debits will appear here.',
            textAlign: TextAlign.center,
            style: AppTextStyles.plusJakartaSans(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(WalletTransactionModel item) {
    final isCredit = item.type.toLowerCase() == 'credit';

    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: isCredit
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: isCredit ? AppColors.success : AppColors.error,
              size: 18.sp,
            ),
          ),
          14.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description.isNotEmpty
                      ? item.description
                      : (isCredit ? 'Wallet Credit' : 'Wallet Debit'),
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (item.createdAt != null && item.createdAt!.isNotEmpty) ...[
                  4.height,
                  Text(
                    _formatDate(item.createdAt!),
                    style: AppTextStyles.plusJakartaSans(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          10.width,
          Text(
            '${isCredit ? "+" : "-"} ₹ ${item.amount.toStringAsFixed(2)}',
            style: AppTextStyles.plusJakartaSans(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: isCredit ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String rawDate) {
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return rawDate;
    }
  }
}
