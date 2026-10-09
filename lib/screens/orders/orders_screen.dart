import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/core/responsive/responsive.dart';
import 'package:grahmitracus/models/cart/order_model.dart';
import 'package:grahmitracus/providers/cart/cart_provider.dart';
import 'package:grahmitracus/providers/cart/order_provider.dart';
import 'package:grahmitracus/screens/cart/cart_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      context.read<OrderProvider>().fetchOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showTrackingModal(BuildContext context, OrderModel initialOrder) {
    final targetId = initialOrder.rawId.isNotEmpty ? initialOrder.rawId : initialOrder.orderCode;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: context.read<OrderProvider>().trackOrder(targetId),
          builder: (context, snapshot) {
            final data = snapshot.data;
            final isLoading = snapshot.connectionState == ConnectionState.waiting;
            final order = initialOrder;
            
            final displayStatus = data != null ? (data['order_status']?.toString() ?? order.status) : order.status;
            final deliveryOtp = data?['delivery_otp']?.toString();
            final riders = data?['riders'] as List? ?? [];
            
            Color getStatusColor(String s) {
              final ls = s.toLowerCase();
              if (ls.contains('delivered') || ls.contains('completed')) return const Color(0xFF16A34A);
              if (ls.contains('cancelled') || ls.contains('failed') || ls.contains('returned')) return const Color(0xFFDC2626);
              return const Color(0xFF6B21A8);
            }
            Color getStatusBg(String s) {
              final ls = s.toLowerCase();
              if (ls.contains('delivered') || ls.contains('completed')) return const Color(0xFFDCFCE7);
              if (ls.contains('cancelled') || ls.contains('failed') || ls.contains('returned')) return const Color(0xFFFEE2E2);
              return const Color(0xFFF3E8FF);
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 28.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: AppColors.borderSubtle,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  16.height,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.id,
                            style: AppTextStyles.plusJakartaSans(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            order.date,
                            style: AppTextStyles.plusJakartaSans(
                              fontSize: 11.5.sp,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: getStatusBg(displayStatus),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          displayStatus,
                          style: AppTextStyles.plusJakartaSans(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: getStatusColor(displayStatus),
                          ),
                        ),
                      ),
                    ],
                  ),
                  16.height,
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  16.height,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Delivery Tracking',
                        style: AppTextStyles.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      if (isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  12.height,
                  if (!isLoading && data == null)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Text(
                        'Tracking information is currently unavailable.',
                        style: AppTextStyles.plusJakartaSans(
                          fontSize: 12.sp,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  if (data != null) ...[
                    _buildTrackingStep(
                      title: 'Current Status',
                      subtitle: displayStatus.toUpperCase(),
                      isCompleted: true,
                      isLast: true,
                    ),
                    if (deliveryOtp != null && deliveryOtp.isNotEmpty) ...[
                      16.height,
                      Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFF26BDB5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: const Color(0xFF26BDB5).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.vpn_key_rounded, color: Color(0xFF26BDB5), size: 20),
                            12.width,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Delivery OTP',
                                  style: AppTextStyles.plusJakartaSans(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1E9A94),
                                  ),
                                ),
                                Text(
                                  deliveryOtp,
                                  style: AppTextStyles.plusJakartaSans(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF1E9A94),
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (riders.isNotEmpty) ...[
                      16.height,
                      Text(
                        'Rider Information',
                        style: AppTextStyles.plusJakartaSans(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      8.height,
                      ...riders.map((r) {
                        final riderName = r['name']?.toString() ?? 'Unknown Rider';
                        final riderPhone = r['phone']?.toString() ?? 'N/A';
                        final vehicle = [r['vehicle_type'], r['vehicle_number']]
                            .where((e) => e != null && e.toString().trim().isNotEmpty)
                            .join(' - ');
                        final lat = r['current_latitude'];
                        final lng = r['current_longitude'];
                        
                        return Container(
                          margin: EdgeInsets.only(bottom: 8.h),
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(8.r),
                            color: Colors.white,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person_pin_circle_rounded, color: AppColors.brandPurple, size: 20),
                                  8.width,
                                  Expanded(
                                    child: Text(
                                      riderName,
                                      style: AppTextStyles.plusJakartaSans(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (riderPhone != 'N/A') ...[
                                6.height,
                                Row(
                                  children: [
                                    const Icon(Icons.phone_rounded, color: Color(0xFF64748B), size: 14),
                                    6.width,
                                    Text(
                                      riderPhone,
                                      style: AppTextStyles.plusJakartaSans(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (vehicle.isNotEmpty) ...[
                                6.height,
                                Row(
                                  children: [
                                    const Icon(Icons.directions_bike_rounded, color: Color(0xFF64748B), size: 14),
                                    6.width,
                                    Text(
                                      vehicle,
                                      style: AppTextStyles.plusJakartaSans(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (lat != null && lng != null) ...[
                                6.height,
                                Row(
                                  children: [
                                    const Icon(Icons.my_location_rounded, color: Color(0xFF64748B), size: 14),
                                    6.width,
                                    Text(
                                      '$lat, $lng',
                                      style: AppTextStyles.plusJakartaSans(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                  16.height,
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: AppColors.brandPurple, size: 18),
                        8.width,
                        Expanded(
                    child: Text(
                      order.deliveryAddress,
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            16.height,
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
                child: Text(
                  'Close',
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
          },
        );
      },
    );
  }

  Widget _buildTrackingStep({
    required String title,
    required String subtitle,
    required bool isCompleted,
    bool isCurrent = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18.r,
              height: 18.r,
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFF16A34A)
                    : (isCurrent
                        ? AppColors.brandPurple
                        : const Color(0xFFCBD5E1)),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  isCompleted ? Icons.check : Icons.circle,
                  color: Colors.white,
                  size: isCompleted ? 12 : 6,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2.w,
                height: 28.h,
                color: isCompleted
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFE2E8F0),
              ),
          ],
        ),
        12.width,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w700,
                  color: isCompleted || isCurrent
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF94A3B8),
                ),
              ),
              Text(
                subtitle,
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 11.sp,
                  color: const Color(0xFF64748B),
                ),
              ),
              if (!isLast) 12.height,
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = context.watch<OrderProvider>();
    final activeOrders = orderProv.activeOrders;
    final pastOrders = orderProv.pastOrders;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'My Orders',
          style: AppTextStyles.screenTitle,
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.h),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: AppColors.subtleBackground,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppColors.brandPurple,
                borderRadius: BorderRadius.circular(10.r),
              ),
              labelColor: AppColors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppTextStyles.plusJakartaSans(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: AppTextStyles.plusJakartaSans(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(text: 'Active Orders (${activeOrders.length})'),
                const Tab(text: 'Past Orders'),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: orderProv.isLoadingOrders
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.brandPurple),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  // Active Orders Tab
                  RefreshIndicator(
                    onRefresh: () => context.read<OrderProvider>().fetchOrders(),
                    color: AppColors.brandPurple,
                    child: activeOrders.isEmpty
                        ? SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: 400.h,
                              child: _buildEmptyState('No active orders right now'),
                            ),
                          )
                        : _buildOrderList(activeOrders, isActive: true),
                  ),

                  // Past Orders Tab
                  RefreshIndicator(
                    onRefresh: () => context.read<OrderProvider>().fetchOrders(),
                    color: AppColors.brandPurple,
                    child: pastOrders.isEmpty
                        ? SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: 400.h,
                              child: _buildEmptyState('No previous orders found'),
                            ),
                          )
                        : _buildOrderList(pastOrders, isActive: false),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72.r,
            height: 72.r,
            decoration: const BoxDecoration(
              color: AppColors.subtleBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 36.sp,
              color: AppColors.iconSubtle,
            ),
          ),
          16.height,
          Text(
            message,
            style: AppTextStyles.plusJakartaSans(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<OrderModel> orders, {required bool isActive}) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: orders.length,
      separatorBuilder: (_, _) => 14.height,
      itemBuilder: (context, index) {
        final order = orders[index];
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            _showTrackingModal(context, order);
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.borderSubtle.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44.r,
                      height: 44.r,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.inventory_2_outlined, color: Colors.white, size: 22.r),
                    ),
                    12.width,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Order #${order.id.replaceAll('#', '')}',
                                  style: AppTextStyles.plusJakartaSans(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              4.width,
                              Icon(Icons.copy_rounded, size: 14.sp, color: const Color(0xFF94A3B8)),
                              8.width,
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: order.statusBg,
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  order.status.toUpperCase(),
                                  style: AppTextStyles.plusJakartaSans(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w800,
                                    color: order.statusColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          4.height,
                          Text(
                            'Ordered on ${order.date.replaceAll('Today, ', '')}',
                            style: AppTextStyles.plusJakartaSans(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          10.height,
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(6.r),
                                  border: Border.all(color: const Color(0xFFF1F5F9)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.shopping_bag_outlined, size: 12.sp, color: const Color(0xFF64748B)),
                                    4.width,
                                    Text(
                                      '${order.orderedItems.isNotEmpty ? order.orderedItems.length : order.items.split(',').length} Item${(order.orderedItems.isNotEmpty ? order.orderedItems.length : order.items.split(',').length) > 1 ? 's' : ''}',
                                      style: AppTextStyles.plusJakartaSans(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              8.width,
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(6.r),
                                    border: Border.all(color: const Color(0xFFFEF3C7)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.payments_outlined, size: 12.sp, color: const Color(0xFFD97706)),
                                      4.width,
                                      Expanded(
                                        child: Text(
                                          order.paymentMethod,
                                          style: AppTextStyles.plusJakartaSans(
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFFD97706),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                16.height,
                const Divider(color: Color(0xFFF1F5F9), height: 1),
                16.height,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL AMOUNT',
                          style: AppTextStyles.plusJakartaSans(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF94A3B8),
                            letterSpacing: 0.5,
                          ),
                        ),
                        2.height,
                        Text(
                          order.total,
                          style: AppTextStyles.plusJakartaSans(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'View Details',
                          style: AppTextStyles.plusJakartaSans(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandPurple,
                          ),
                        ),
                        2.width,
                        Icon(Icons.chevron_right_rounded, size: 16.sp, color: AppColors.brandPurple),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
