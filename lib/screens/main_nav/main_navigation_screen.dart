import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/core/responsive/responsive.dart';
import 'package:grahmitracus/core/services/auth_guard.dart';
import 'package:grahmitracus/screens/auth/login_page.dart';
import 'package:grahmitracus/screens/categories/categories_screen.dart';
import 'package:grahmitracus/screens/home/home_screen.dart';
import 'package:grahmitracus/screens/offers/offers_screen.dart';
import 'package:grahmitracus/screens/orders/orders_screen.dart';
import 'package:grahmitracus/screens/profile/profile_screen.dart';

class _NavItemData {
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String? badgeText;
  final Color? badgeColor;

  const _NavItemData({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
    this.badgeText,
    this.badgeColor,
  });
}

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  static const List<_NavItemData> _navItems = [
    _NavItemData(
      label: 'Home',
      activeIcon: Icons.home_rounded,
      inactiveIcon: Icons.home_outlined,
    ),
    _NavItemData(
      label: 'Categories',
      activeIcon: Icons.grid_view_rounded,
      inactiveIcon: Icons.grid_view_outlined,
    ),
    _NavItemData(
      label: 'Offers',
      activeIcon: Icons.local_offer_rounded,
      inactiveIcon: Icons.local_offer_outlined,
      badgeText: 'SALE',
      badgeColor: Color(0xFFEF4444),
    ),
    _NavItemData(
      label: 'Orders',
      activeIcon: Icons.receipt_long_rounded,
      inactiveIcon: Icons.receipt_long_outlined,
    ),
    _NavItemData(
      label: 'Profile',
      activeIcon: Icons.person_rounded,
      inactiveIcon: Icons.person_outline_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _checkInitialTabAuth();
  }

  void _checkInitialTabAuth() async {
    if (_currentIndex == 4) {
      final isAuth = await AuthGuard.isAuthenticated();
      if (!isAuth && mounted) {
        setState(() {
          _currentIndex = 0;
        });
        _navigateToLoginForProfile();
      }
    }
  }

  void _onTabTapped(int index) async {
    if (_currentIndex == index) return;
    HapticFeedback.lightImpact();

    if (index == 4) {
      final isAuth = await AuthGuard.isAuthenticated();
      if (!isAuth) {
        if (!mounted) return;
        _navigateToLoginForProfile();
        return;
      }
    }

    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateToLoginForProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'LoginPage'),
        builder: (context) => LoginPage(
          onLoginSuccess: (loginContext) {
            AuthGuard.popAuthFlow(loginContext);
            if (mounted) {
              setState(() {
                _currentIndex = 4;
              });
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        onTabChange: _onTabTapped,
      ),
      const CategoriesScreen(),
      const OffersScreen(),
      const OrdersScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: _buildModernBottomNavigationBar(),
    );
  }

  /// Modern Grocery App Bottom Navigation Bar
  Widget _buildModernBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(
            color: Color(0xFFF1F5F9),
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 62.h,
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isSelected = _currentIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _onTabTapped(index),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Active indicator line at top
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        width: isSelected ? 22.w : 0,
                        height: 3.h,
                        margin: EdgeInsets.only(bottom: 4.h),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.brandPurple
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),

                      // Icon Container with Pill Glow & Badge
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            padding: EdgeInsets.symmetric(
                              horizontal: isSelected ? 14.w : 8.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.brandPurple
                                      .withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: AnimatedScale(
                              scale: isSelected ? 1.12 : 1.0,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutBack,
                              child: Icon(
                                isSelected ? item.activeIcon : item.inactiveIcon,
                                size: 21.sp,
                                color: isSelected
                                    ? AppColors.brandPurple
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),

                          // Micro Badge (e.g., 'SALE' on Offers tab)
                          if (item.badgeText != null)
                            Positioned(
                              top: -4.h,
                              right: -4.w,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4.w,
                                  vertical: 1.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: item.badgeColor ?? const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(6.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (item.badgeColor ??
                                              const Color(0xFFEF4444))
                                          .withValues(alpha: 0.4),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  item.badgeText!,
                                  style: AppTextStyles.plusJakartaSans(
                                    fontSize: 7.5.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      3.height,

                      // Label
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        style: AppTextStyles.plusJakartaSans(
                          fontSize: isSelected ? 10.5.sp : 10.sp,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? AppColors.brandPurple
                              : const Color(0xFF64748B),
                        ),
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
