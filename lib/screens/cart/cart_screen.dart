import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/core/responsive/responsive.dart';
import 'package:grahmitracus/models/cart/cart_item_model.dart';
import 'package:grahmitracus/models/cart/order_model.dart';
import 'package:grahmitracus/providers/cart/cart_provider.dart';
import 'package:grahmitracus/providers/cart/order_provider.dart';
import 'package:grahmitracus/providers/location/location_provider.dart';
import 'package:grahmitracus/providers/payment/payment_provider.dart';
import 'package:grahmitracus/providers/profile/profile_provider.dart';
import 'package:grahmitracus/core/services/auth_guard.dart';
import 'package:grahmitracus/screens/auth/login_page.dart';
import 'package:grahmitracus/screens/location/location_picker_screen.dart';

class CartScreen extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateTab;

  const CartScreen({super.key, this.onNavigateTab});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _couponController = TextEditingController();
  String _selectedPaymentMethod = 'Cash on Delivery';

  final List<Map<String, dynamic>> _paymentOptions = const [
    {
      'id': 'Cash on Delivery',
      'title': 'Cash on Delivery (COD)',
      'subtitle': 'Pay with cash or UPI upon delivery',
      'icon': Icons.payments_rounded,
      'color': Color(0xFF16A34A),
    },
    {
      'id': 'UPI',
      'title': 'UPI / QR',
      'subtitle': 'Google Pay, PhonePe, Paytm',
      'icon': Icons.qr_code_2_rounded,
      'color': Color(0xFF6366F1),
    },
    {
      'id': 'Card',
      'title': 'Credit / Debit Card',
      'subtitle': 'Visa, Mastercard, RuPay',
      'icon': Icons.credit_card_rounded,
      'color': Color(0xFF0284C7),
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final cart = context.read<CartProvider>();
        final locationProv = context.read<LocationProvider>();
        cart.revalidate(locationProv);
        cart.fetchActiveCoupons();
      }
    });
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon(CartProvider cart) async {
    if (cart.isApplyingCoupon) return;
    HapticFeedback.selectionClick();
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    final success = await cart.applyCoupon(code);
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          cart.couponMessage ?? (success ? 'Coupon applied!' : 'Failed'),
          style: AppTextStyles.plusJakartaSans(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: success
            ? const Color(0xFF168A35)
            : const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }

  void _handlePlaceOrder() async {
    final cart = context.read<CartProvider>();
    final orderProv = context.read<OrderProvider>();
    final locationProv = context.read<LocationProvider>();
    final paymentProv = context.read<PaymentProvider>();

    if (cart.isEmpty) return;

    // Check authentication first before validating / placing order
    final isAuth = await AuthGuard.isAuthenticated();
    if (!isAuth) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: 'LoginPage'),
          builder: (context) => LoginPage(
            onLoginSuccess: (loginContext) {
              AuthGuard.popAuthFlow(loginContext);
              if (mounted) {
                _handlePlaceOrder();
              }
            },
          ),
        ),
      );
      return;
    }

    // 1. Revalidate latest prices and stock with backend
    await cart.revalidate(locationProv);

    if (!mounted) return;

    // 2. Validate checkout details (shipping cost, serviceability, fees)
    final isValid = await cart.validateCheckout(locationProv);

    if (!mounted) return;

    if (!isValid || cart.checkoutValidationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cart.checkoutValidationError ?? 'Checkout validation failed',
            style: AppTextStyles.plusJakartaSans(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedPaymentMethod == 'Cash on Delivery' && !cart.apiIsCodEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cash on Delivery is not available for this location/order.',
            style: AppTextStyles.plusJakartaSans(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.heavyImpact();

    final deliveryAddress = locationProv.currentLocation.displayString;

    final isOnlinePayment = _selectedPaymentMethod != 'Cash on Delivery';

    final profileProv = context.read<ProfileProvider>();
    final userProfileMap = profileProv.user != null ? {
      'first_name': profileProv.user!.firstName,
      'last_name': profileProv.user!.lastName,
      'email': profileProv.user!.email,
      'phone': profileProv.user!.phone,
    } : null;

    if (isOnlinePayment) {
      // 2. Initiate Payment flow
      final contact = profileProv.user?.phone ?? '9999999999';
      final email = profileProv.user?.email ?? 'customer@grahmitra.com';

      await paymentProv.initiatePayment(
        amount: cart.grandTotal,
        contact: contact,
        email: email,
        onSuccess: (razorpayData) async {
          // 3. Place order after successful payment
          try {
            final newOrder = await orderProv.placeOrder(
              cart: cart,
              locationProv: locationProv,
              deliveryAddress: deliveryAddress,
              paymentMethod: _selectedPaymentMethod,
              userProfile: userProfileMap,
              razorpayData: razorpayData,
            );
            
            if (!mounted) return;
            _showOrderSuccessSheet(newOrder);
          } catch (e) {
            if (!mounted) return;
            _showErrorSnackBar(e.toString());
          }
        },
        onError: (error) {
          _showErrorSnackBar(error);
        },
      );
    } else {
      // COD Flow
      try {
        final newOrder = await orderProv.placeOrder(
          cart: cart,
          locationProv: locationProv,
          deliveryAddress: deliveryAddress,
          paymentMethod: _selectedPaymentMethod,
          userProfile: userProfileMap,
        );

        if (!mounted) return;
        _showOrderSuccessSheet(newOrder);
      } catch (e) {
        if (!mounted) return;
        _showErrorSnackBar(e.toString());
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.plusJakartaSans(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showOrderSuccessSheet(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 28.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull Bar
              Center(
                child: Container(
                  width: 44.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              20.height,

              // Animated Celebration Circle
              Container(
                width: 76.r,
                height: 76.r,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 44.sp,
                  ),
                ),
              ),
              16.height,

              // Header Text
              Text(
                'Order Done!',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              6.height,
              Text(
                'Your order has been placed successfully',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              18.height,

              // Order Summary Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order ID',
                          style: AppTextStyles.plusJakartaSans(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          order.id,
                          style: AppTextStyles.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandPurple,
                          ),
                        ),
                      ],
                    ),
                    10.height,
                    const Divider(color: Color(0xFFE2E8F0), height: 1),
                    10.height,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              color: Color(0xFFF59E0B),
                              size: 18,
                            ),
                            4.width,
                            Text(
                              'Estimated Delivery',
                              style: AppTextStyles.plusJakartaSans(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '10-12 Mins',
                          style: AppTextStyles.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                    10.height,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Paid / To Pay',
                          style: AppTextStyles.plusJakartaSans(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          order.total,
                          style: AppTextStyles.plusJakartaSans(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    10.height,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payment Mode',
                          style: AppTextStyles.plusJakartaSans(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          order.paymentMethod,
                          style: AppTextStyles.plusJakartaSans(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              20.height,

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop(); // dismiss sheet
                        Navigator.of(context).pop(); // return to home
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                      ),
                      child: Text(
                        'Continue Shopping',
                        style: AppTextStyles.plusJakartaSans(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ),
                  12.width,
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pop();
                        // Navigate to Orders Tab (index 3)
                        widget.onNavigateTab?.call(3);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPurple,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Track Order',
                            style: AppTextStyles.plusJakartaSans(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          4.width,
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final isEmpty = cart.isEmpty;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(context, cart),
          body: isEmpty
              ? _buildEmptyState(context)
              : SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(bottom: 110.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Fast Delivery Banner
                        _buildDeliveryBanner(context),

                        12.height,

                        // 2. Cart Items List Card
                        _buildCartItemsSection(cart),

                        16.height,

                        // 3. Coupons & Offers Card
                        _buildCouponsSection(cart),

                        16.height,

                        // 4. Payment Method Selector Card
                        _buildPaymentMethodSection(),

                        16.height,

                        // 5. Bill Details & Price Breakdown
                        _buildBillBreakdownSection(cart),

                        16.height,

                        // 6. Guarantee & Cancellation note
                        _buildSafetyGuaranteeBadge(),

                        16.height,
                      ],
                    ),
                  ),
                ),
          bottomSheet: isEmpty ? null : _buildStickyCheckoutBar(context, cart),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, CartProvider cart) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          width: 34.r,
          height: 34.r,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 15,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Cart',
            style: AppTextStyles.plusJakartaSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          if (!cart.isEmpty)
            Text(
              '${cart.totalQuantity} items • Ready for quick delivery',
              style: AppTextStyles.plusJakartaSans(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
        ],
      ),
      actions: [
        if (!cart.isEmpty)
          TextButton.icon(
            onPressed: () {
              HapticFeedback.selectionClick();
              _confirmClearCart(context, cart);
            },
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFEF4444),
              size: 18,
            ),
            label: Text(
              'Clear',
              style: AppTextStyles.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFEF4444),
              ),
            ),
          ),
        8.width,
      ],
    );
  }

  void _confirmClearCart(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Clear Cart?',
          style: AppTextStyles.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 16.sp,
          ),
        ),
        content: Text(
          'Are you sure you want to remove all items from your cart?',
          style: AppTextStyles.plusJakartaSans(
            fontSize: 13.sp,
            color: const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              cart.clearCart();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100.r,
              height: 100.r,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.brandPurple.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.cartShopping,
                  size: 42.sp,
                  color: AppColors.brandPurple,
                ),
              ),
            ),
            20.height,
            Text(
              'Your Cart is Empty',
              style: AppTextStyles.plusJakartaSans(
                fontSize: 19.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            8.height,
            Text(
              'Looks like you haven\'t added anything yet.\nExplore fresh groceries and daily essentials!',
              textAlign: TextAlign.center,
              style: AppTextStyles.plusJakartaSans(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            24.height,
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: Text(
                'Explore Groceries',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPurple,
                foregroundColor: Colors.white,
                elevation: 3,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 1. Delivery ETA & Current Location Banner
  Widget _buildDeliveryBanner(BuildContext context) {
    final locationProv = context.watch<LocationProvider>();
    final address = locationProv.currentLocation.displayString;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFEF08A), Color(0xFFFDE047)],
              ),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.bolt_rounded,
              color: const Color(0xFF854D0E),
              size: 20.sp,
            ),
          ),
          12.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Fast Delivery',
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    6.width,
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 5.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        'FAST',
                        style: AppTextStyles.plusJakartaSans(
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ],
                ),
                3.height,
                Text(
                  address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          8.width,
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
              );
            },
            child: Text(
              'Change',
              style: AppTextStyles.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.brandPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Cart Items List Card
  Widget _buildCartItemsSection(CartProvider cart) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 14.w),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                'Cart Items (${cart.totalQuantity})',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                'Subtotal: ₹${cart.subtotal.toStringAsFixed(0)}',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandPurple,
                ),
              ),
            ],
          ),
          12.height,
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cart.itemList.length,
            separatorBuilder: (_, index) =>
                const Divider(color: Color(0xFFF1F5F9), height: 18),
            itemBuilder: (context, index) {
              final item = cart.itemList[index];
              return _buildCartItemTile(cart, item);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemTile(CartProvider cart, CartItem item) {
    final hasDiscount = item.mrpPrice > item.sellPrice;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Product Thumbnail
        Container(
          width: 54.r,
          height: 54.r,
          padding: EdgeInsets.all(4.r),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: item.imageUrl != null && item.imageUrl!.isNotEmpty
              ? Image.network(
                  item.imageUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                )
              : const Center(
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: Color(0xFF94A3B8),
                  ),
                ),
        ),
        10.width,

        // Title, Weight, Price
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              3.height,
              if (item.weight != null && item.weight!.isNotEmpty)
                Text(
                  item.weight!,
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              4.height,
              Row(
                children: [
                  Text(
                    '₹${item.totalSellPrice.toStringAsFixed(0)}',
                    style: AppTextStyles.plusJakartaSans(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  if (hasDiscount) ...[
                    6.width,
                    Text(
                      '₹${item.totalMrpPrice.toStringAsFixed(0)}',
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Stepper: [-] [Qty] [+]
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF168A35),
            borderRadius: BorderRadius.circular(8.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF168A35).withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  cart.decrement(item.id);
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
                  child: Icon(
                    item.quantity == 1
                        ? Icons.delete_outline_rounded
                        : Icons.remove_rounded,
                    color: Colors.white,
                    size: 14.sp,
                  ),
                ),
              ),
              Container(
                constraints: BoxConstraints(minWidth: 18.w),
                child: Text(
                  '${item.quantity}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  cart.increment(item.id);
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
                  child: Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 14.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 3. Coupons & Offers Section
  Widget _buildCouponsSection(CartProvider cart) {
    final isApplied = cart.appliedCoupon != null;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 14.w),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_offer_rounded,
                color: AppColors.brandOrange,
                size: 18,
              ),
              8.width,
              Text(
                'Coupons & Offers',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          12.height,

          if (isApplied) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF16A34A),
                        size: 18,
                      ),
                      8.width,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cart.appliedCoupon!,
                            style: AppTextStyles.plusJakartaSans(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF166534),
                            ),
                          ),
                          if (cart.couponDiscount > 0)
                            Text(
                              'Saved ₹${cart.couponDiscount.toStringAsFixed(0)} on this order',
                              style: AppTextStyles.plusJakartaSans(
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      cart.removeCoupon();
                    },
                    child: Text(
                      'REMOVE',
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 42.h,
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _couponController,
                      textCapitalization: TextCapitalization.characters,
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter coupon code',
                        hintStyle: AppTextStyles.plusJakartaSans(
                          fontSize: 12.sp,
                          color: const Color(0xFF94A3B8),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                      ),
                    ),
                  ),
                ),
                8.width,
                ElevatedButton(
                  onPressed: cart.isApplyingCoupon
                      ? null
                      : () => _applyCoupon(cart),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPurple,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: cart.isApplyingCoupon
                      ? SizedBox(
                          width: 14.w,
                          height: 14.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Apply',
                          style: AppTextStyles.plusJakartaSans(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
            10.height,

            // Quick coupon suggestions from backend API
            if (cart.isLoadingCoupons) ...[
              SizedBox(
                height: 28.h,
                child: Row(
                  children: [
                    SizedBox(
                      width: 14.w,
                      height: 14.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.brandPurple,
                      ),
                    ),
                    8.width,
                    Text(
                      'Loading available coupons...',
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 11.sp,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (cart.activeCoupons.isNotEmpty) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: cart.activeCoupons.map((coupon) {
                    String benefit = '';
                    if (coupon.flatAmount != null && coupon.flatAmount! > 0) {
                      benefit = '₹${coupon.flatAmount!.toStringAsFixed(0)} OFF';
                    } else if (coupon.minOrderAmount != null &&
                        coupon.minOrderAmount! > 0) {
                      benefit =
                          'Min ₹${coupon.minOrderAmount!.toStringAsFixed(0)}';
                    } else {
                      benefit = 'Special Offer';
                    }

                    return Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: _buildQuickCouponTag(coupon.code, benefit, cart),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildQuickCouponTag(String code, String benefit, CartProvider cart) {
    return GestureDetector(
      onTap: () {
        _couponController.text = code;
        _applyCoupon(cart);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              code,
              style: AppTextStyles.plusJakartaSans(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.brandPurple,
              ),
            ),
            4.width,
            Text(
              '($benefit)',
              style: AppTextStyles.plusJakartaSans(
                fontSize: 9.5.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 4. Payment Method Selector Card
  Widget _buildPaymentMethodSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 14.w),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: Color(0xFF0284C7),
                size: 18,
              ),
              8.width,
              Text(
                'Payment Method',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          12.height,
          Column(
            children: _paymentOptions.map((opt) {
              final isSelected = _selectedPaymentMethod == opt['id'];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedPaymentMethod = opt['id'] as String);
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.brandPurple.withValues(alpha: 0.04)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.brandPurple
                          : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: (opt['color'] as Color).withValues(
                            alpha: 0.12,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          opt['icon'] as IconData,
                          size: 16.sp,
                          color: opt['color'] as Color,
                        ),
                      ),
                      10.width,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt['title'] as String,
                              style: AppTextStyles.plusJakartaSans(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              opt['subtitle'] as String,
                              style: AppTextStyles.plusJakartaSans(
                                fontSize: 10.5.sp,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: isSelected
                            ? AppColors.brandPurple
                            : const Color(0xFF94A3B8),
                        size: 18.sp,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 5. Bill Details Breakdown
  Widget _buildBillBreakdownSection(CartProvider cart) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 14.w),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFF64748B),
                size: 18,
              ),
              8.width,
              Text(
                'Bill Summary',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          12.height,

          _buildBillRow(
            'Item Total (MRP)',
            '₹${cart.totalMrp.toStringAsFixed(0)}',
          ),
          if (cart.productSavings > 0) ...[
            6.height,
            _buildBillRow(
              'Product Savings',
              '- ₹${cart.productSavings.toStringAsFixed(0)}',
              isDiscount: true,
            ),
          ],
          if (cart.couponDiscount > 0) ...[
            6.height,
            _buildBillRow(
              'Coupon Discount (${cart.appliedCoupon})',
              '- ₹${cart.couponDiscount.toStringAsFixed(0)}',
              isDiscount: true,
            ),
          ],
          6.height,
          _buildBillRow(
            'Delivery Partner Fee',
            cart.deliveryFee == 0
                ? 'FREE'
                : '₹${cart.deliveryFee.toStringAsFixed(0)}',
            isDiscount: cart.deliveryFee == 0,
          ),
          6.height,
          _buildBillRow(
            'Handling & Packaging Charge',
            '₹${cart.handlingFee.toStringAsFixed(0)}',
          ),
          if (cart.apiRushHourSurcharge > 0) ...[
            6.height,
            _buildBillRow(
              'Rush Hour Surcharge',
              '₹${cart.apiRushHourSurcharge.toStringAsFixed(0)}',
            ),
          ],
          if (_selectedPaymentMethod == 'Cash on Delivery' &&
              cart.apiCodConvenienceFee > 0) ...[
            6.height,
            _buildBillRow(
              'COD Convenience Fee',
              '₹${cart.apiCodConvenienceFee.toStringAsFixed(0)}',
            ),
          ],

          12.height,
          const Divider(color: Color(0xFFE2E8F0), height: 1),
          12.height,

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'To Pay',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                '₹${(cart.grandTotal + (_selectedPaymentMethod == 'Cash on Delivery' ? cart.apiCodConvenienceFee : 0)).toStringAsFixed(0)}',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.brandPurple,
                ),
              ),
            ],
          ),

          if (cart.totalSavings > 0) ...[
            12.height,
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.savings_rounded,
                    color: Color(0xFF16A34A),
                    size: 16,
                  ),
                  6.width,
                  Expanded(
                    child: Text(
                      'Yay! You saved ₹${cart.totalSavings.toStringAsFixed(0)} on this order',
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.plusJakartaSans(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.plusJakartaSans(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: isDiscount
                ? const Color(0xFF16A34A)
                : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  /// 6. Safety & Guarantee note
  Widget _buildSafetyGuaranteeBadge() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.verified_user_rounded,
            color: Color(0xFF10B981),
            size: 15,
          ),
          6.width,
          Text(
            '100% Genuine Products • Safe & Contactless Delivery',
            style: AppTextStyles.plusJakartaSans(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom Sticky Checkout Action Bar
  Widget _buildStickyCheckoutBar(BuildContext context, CartProvider cart) {
    final orderProv = context.watch<OrderProvider>();

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Price & Savings
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₹${(cart.grandTotal + (_selectedPaymentMethod == 'Cash on Delivery' ? cart.apiCodConvenienceFee : 0)).toStringAsFixed(0)}',
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    if (cart.totalSavings > 0) ...[
                      6.width,
                      Text(
                        'SAVED ₹${cart.totalSavings.toStringAsFixed(0)}',
                        style: AppTextStyles.plusJakartaSans(
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${cart.totalQuantity} items • TOTAL',
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const Spacer(),

            // Place Order Button
            ElevatedButton(
              onPressed: (orderProv.isPlacingOrder || cart.isValidatingCheckout || context.watch<PaymentProvider>().isProcessing)
                  ? null
                  : () => _handlePlaceOrder(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPurple,
                disabledBackgroundColor: AppColors.brandPurple.withValues(
                  alpha: 0.6,
                ),
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 13.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: (orderProv.isPlacingOrder || cart.isValidatingCheckout || context.watch<PaymentProvider>().isProcessing)
                  ? SizedBox(
                      width: 20.r,
                      height: 20.r,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Place Order',
                          style: AppTextStyles.plusJakartaSans(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                        6.width,
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
