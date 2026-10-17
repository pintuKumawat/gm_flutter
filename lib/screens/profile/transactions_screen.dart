import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/core/responsive/responsive.dart';
import 'package:grahmitracus/models/transaction/transaction_model.dart';
import 'package:grahmitracus/providers/transaction/transaction_provider.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<TransactionProvider>();
        provider.resetSearch();
        provider.fetchTransactions(forceRefresh: true);
      }
    });
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch(TransactionProvider provider) {
    _searchController.clear();
    provider.resetSearch();
  }

  Future<void> _handleRefresh(TransactionProvider provider) async {
    HapticFeedback.selectionClick();
    _searchController.clear();
    await provider.fetchTransactions(forceRefresh: true, resetSearch: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left_rounded,
            size: 28.sp,
            color: const Color(0xFF0F172A),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        actions: [
          Consumer<TransactionProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  child: Center(
                    child: SizedBox(
                      width: 18.sp,
                      height: 18.sp,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.brandPurple,
                        ),
                      ),
                    ),
                  ),
                );
              }
              return IconButton(
                icon: Icon(
                  Icons.refresh_rounded,
                  color: AppColors.brandPurple,
                  size: 22.sp,
                ),
                tooltip: 'Refresh Transactions',
                onPressed: () => _handleRefresh(provider),
              );
            },
          ),
          6.width,
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            color: AppColors.brandPurple,
            onRefresh: () => _handleRefresh(provider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header
                  _buildHeader(),
                  16.height,

                  // Error notification if any
                  if (provider.errorMessage != null) ...[
                    _buildErrorBanner(provider),
                    16.height,
                  ],

                  // 2x2 Summary Metric Cards
                  _buildSummaryGrid(provider.stats),
                  16.height,

                  // Search Bar
                  _buildSearchBar(provider),
                  12.height,

                  // Filter Tabs (Global View, Cash Settlement, Digital Gateway)
                  _buildFilterTabs(provider),
                  16.height,

                  // Transactions List / States
                  if (provider.isLoading && provider.transactions.isEmpty)
                    _buildLoadingList()
                  else if (provider.filteredTransactions.isEmpty)
                    _buildEmptyState(
                      isSearching: provider.searchQuery.isNotEmpty,
                      onClearSearch: () => _clearSearch(provider),
                    )
                  else
                    _buildTransactionsList(provider.filteredTransactions),

                  24.height,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Title and Subtitle matching the reference design
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction',
          style: AppTextStyles.plusJakartaSans(
            fontSize: 22.sp,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        4.height,
        Text(
          'Comprehensive audit trail of all electronic and physical settlements.',
          style: AppTextStyles.plusJakartaSans(
            fontSize: 12.5.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
            height: 1.3,
          ),
        ),
      ],
    );
  }

  /// Error banner with retry action
  Widget _buildErrorBanner(TransactionProvider provider) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: const Color(0xFFDC2626),
            size: 20.sp,
          ),
          10.width,
          Expanded(
            child: Text(
              provider.errorMessage ?? 'Failed to load transactions',
              style: AppTextStyles.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF991B1B),
              ),
            ),
          ),
          TextButton(
            onPressed: () => _handleRefresh(provider),
            child: Text(
              'Retry',
              style: AppTextStyles.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 2x2 Metric Statistics Cards matching the reference design exactly
  Widget _buildSummaryGrid(TransactionStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12.w) / 2;
        return Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          children: [
            _buildStatCard(
              width: cardWidth,
              label: 'COMPLETED',
              value: stats.completedDisplay,
              valueColor: const Color(0xFF9333EA), // Purple
            ),
            _buildStatCard(
              width: cardWidth,
              label: 'PENDING',
              value: stats.pendingDisplay,
              valueColor: const Color(0xFFD97706), // Amber / Gold
            ),
            _buildStatCard(
              width: cardWidth,
              label: 'REFUNDED',
              value: stats.refundedDisplay,
              valueColor: const Color(0xFF2563EB), // Blue
            ),
            _buildStatCard(
              width: cardWidth,
              label: 'TRANSACTIONS',
              value: stats.transactionsCountDisplay,
              valueColor: const Color(0xFF0F172A), // Dark
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required double width,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.plusJakartaSans(
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF64748B),
              letterSpacing: 0.8,
            ),
          ),
          8.height,
          Text(
            value,
            style: AppTextStyles.plusJakartaSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: valueColor,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Search Input Field with magnifier icon
  Widget _buildSearchBar(TransactionProvider provider) {
    return Container(
      height: 42.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: const Color(0xFF94A3B8),
            size: 19.sp,
          ),
          8.width,
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) => provider.setSearchQuery(val),
              style: AppTextStyles.plusJakartaSans(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'SEARCH BY ORDER ID OR DESCRIPTION...',
                hintStyle: AppTextStyles.plusJakartaSans(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () => _clearSearch(provider),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Icon(
                  Icons.close_rounded,
                  size: 16.sp,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Filter Tabs (Global View, Cash Settlement, Digital Gateway)
  Widget _buildFilterTabs(TransactionProvider provider) {
    final tabs = [
      {'id': 'all', 'label': 'Global View'},
      {'id': 'cod', 'label': 'Cash Settlement'},
      {'id': 'razorpay', 'label': 'Digital Gateway'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = provider.activeFilter == tab['id'];
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                provider.setFilter(tab['id']!);
              },
              borderRadius: BorderRadius.circular(6.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: Text(
                  tab['label']!,
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF334155),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// List of Transactions
  Widget _buildTransactionsList(List<TransactionModel> items) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => 10.height,
      itemBuilder: (context, index) {
        return _buildTransactionCard(items[index]);
      },
    );
  }

  /// Individual Transaction Card matching the reference design exactly
  Widget _buildTransactionCard(TransactionModel tx) {
    final statusBadge = _buildStatusBadge(tx.status);
    final isCash = (tx.paymentMethod?.toLowerCase() == 'cod');

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Purple Icon + Title & Date + Status Badge & Amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Purple Square Icon
              Container(
                width: 38.r,
                height: 38.r,
                decoration: BoxDecoration(
                  color: const Color(0xFF9333EA),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: Icon(
                    isCash ? Icons.payments_outlined : Icons.credit_card_outlined,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
              ),
              10.width,

              // Title and Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.description,
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    5.height,
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 11.5.sp,
                          color: const Color(0xFF64748B),
                        ),
                        4.width,
                        Text(
                          tx.formattedDate,
                          style: AppTextStyles.plusJakartaSans(
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              8.width,

              // Status and Signed Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  statusBadge,
                  4.height,
                  Text(
                    tx.signedDisplayAmount,
                    style: AppTextStyles.plusJakartaSans(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w900,
                      color: tx.isCredit ? const Color(0xFF9333EA) : const Color(0xFFDC2626),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ],
          ),

          8.height,
          // Divider
          Container(
            height: 1,
            color: const Color(0xFFF1F5F9),
          ),
          8.height,

          // Bottom Instrument Row
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'INSTRUMENT',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.6,
                ),
              ),
              2.height,
              Text(
                tx.instrumentName,
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Status badge matching colors in reference design
  Widget _buildStatusBadge(String status) {
    Color bg;
    Color border;
    Color text;

    switch (status.toLowerCase()) {
      case 'completed':
        bg = const Color(0xFFF3E8FF);
        border = const Color(0xFFD8B4FE);
        text = const Color(0xFF7E22CE);
        break;
      case 'refunded':
        bg = const Color(0xFFEFF6FF);
        border = const Color(0xFFBFDBFE);
        text = const Color(0xFF1D4ED8);
        break;
      case 'failed':
        bg = const Color(0xFFFEE2E2);
        border = const Color(0xFFFECACA);
        text = const Color(0xFFB91C1C);
        break;
      case 'pending':
      default:
        bg = const Color(0xFFFEF9C3);
        border = const Color(0xFFFDE047);
        text = const Color(0xFFA16207);
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: border, width: 1.0),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.plusJakartaSans(
          fontSize: 8.5.sp,
          fontWeight: FontWeight.w800,
          color: text,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  /// Empty state matching the reference web design
  Widget _buildEmptyState({
    bool isSearching = false,
    VoidCallback? onClearSearch,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 48.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52.r,
            height: 52.r,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isSearching ? Icons.search_off_rounded : Icons.receipt_long_outlined,
              size: 26.sp,
              color: const Color(0xFF94A3B8),
            ),
          ),
          14.height,
          Text(
            isSearching ? 'NO MATCHING TRANSACTIONS' : 'NO RECONCILIATION RECORDS',
            style: AppTextStyles.plusJakartaSans(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
          if (isSearching && onClearSearch != null) ...[
            12.height,
            TextButton(
              onPressed: onClearSearch,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                backgroundColor: AppColors.brandPurple.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Clear Search',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandPurple,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Shimmer loading skeleton
  Widget _buildLoadingList() {
    return Column(
      children: List.generate(4, (index) {
        return Container(
          margin: EdgeInsets.only(bottom: 10.h),
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38.r,
                    height: 38.r,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  10.width,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 12.h,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                        6.height,
                        Container(
                          width: 120.w,
                          height: 10.h,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ],
                    ),
                  ),
                  12.width,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 50.w,
                        height: 14.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      6.height,
                      Container(
                        width: 65.w,
                        height: 16.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              10.height,
              Container(
                height: 1,
                color: const Color(0xFFF1F5F9),
              ),
              8.height,
              Container(
                width: 70.w,
                height: 8.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              4.height,
              Container(
                width: 110.w,
                height: 12.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
