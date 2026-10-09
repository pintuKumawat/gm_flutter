import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/core/responsive/responsive.dart';
import 'package:grahmitracus/providers/profile/profile_provider.dart';
import 'package:grahmitracus/providers/profile/wallet_provider.dart';
import 'package:grahmitracus/providers/location/location_provider.dart';
import 'package:grahmitracus/screens/auth/login_page.dart';
import 'package:grahmitracus/screens/profile/saved_addresses_screen.dart';
import 'package:grahmitracus/screens/profile/notifications_screen.dart';
import 'package:grahmitracus/screens/profile/language_screen.dart';
import 'package:grahmitracus/screens/profile/customer_support_screen.dart';
import 'package:grahmitracus/screens/profile/privacy_policy_screen.dart';
import 'package:grahmitracus/screens/profile/faq_screen.dart';
import 'package:grahmitracus/core/services/api_endpoints.dart';
import 'package:grahmitracus/core/services/api_service.dart';
import 'package:grahmitracus/core/services/auth_storage_service.dart';
import 'package:grahmitracus/screens/profile/refer_earn_screen.dart';
import 'package:grahmitracus/screens/profile/edit_profile_screen.dart';
import 'package:grahmitracus/screens/profile/wallet_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProfileProvider>().fetchProfile();
      }
    });
  }

  void _showLogoutDialog(BuildContext context) {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Log Out',
          style: AppTextStyles.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18.sp,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to log out of Grahmitra?',
          style: AppTextStyles.plusJakartaSans(
            fontSize: 13.sp,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final refreshToken = await AuthStorageService.getRefreshToken();
                if (refreshToken != null && refreshToken.isNotEmpty) {
                  await ApiService.instance.post(
                    ApiEndpoints.logout,
                    data: {'refreshToken': refreshToken},
                  );
                }
              } catch (_) {}

              await AuthStorageService.clearTokens();
              ApiService.instance.clearAuthToken();

              if (!context.mounted) return;
              context.read<ProfileProvider>().reset();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  settings: const RouteSettings(name: 'LoginPage'),
                  builder: (context) => const LoginPage(),
                ),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'Log Out',
              style: AppTextStyles.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('My Profile', style: AppTextStyles.screenTitle),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: AppColors.brandPurple,
              size: 20.sp,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              context.read<ProfileProvider>().fetchProfile();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await context.read<ProfileProvider>().fetchProfile();
          },
          color: AppColors.brandPurple,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Consumer<ProfileProvider>(
              builder: (context, provider, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error notification banner if API fetch failed
                    if (provider.hasError) ...[
                      _buildErrorBanner(context, provider),
                      12.height,
                    ],

                    // User Profile Info Card
                    _buildProfileCard(provider),

                    20.height,

                    // Quick Stats Row
                    Row(
                      children: [
                        Consumer<WalletProvider>(
                          builder: (context, walletProvider, _) {
                            final balanceStr =
                                '₹ ${walletProvider.balance.toStringAsFixed(2)}';
                            return Expanded(
                              child: _buildStatCard(
                                balanceStr,
                                'Wallet Balance',
                                Icons.account_balance_wallet_outlined,
                                AppColors.brandPurple,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const WalletScreen(),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        12.width,
                        Consumer<LocationProvider>(
                          builder: (context, locationProv, _) {
                            final addressCount = locationProv.savedAddresses.length.toString();
                            return Expanded(
                              child: _buildStatCard(
                                addressCount,
                                'Saved Addresses',
                                Icons.location_on_outlined,
                                AppColors.brandOrange,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SavedAddressesScreen(),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    16.height,

                    // Refer & Earn Card
                    _buildReferCard(
                      icon: Icons.card_giftcard_rounded,
                      title: 'Refer & Earn',
                      subtitle: 'Invite your friends and earn rewards',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReferEarnScreen(),
                          ),
                        );
                      },
                    ),

                    24.height,
                    Text(
                      'Account Settings',
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    12.height,

                    // Settings Options
                    _buildMenuItem(
                      icon: Icons.location_city_rounded,
                      title: 'Saved Addresses',
                      subtitle: 'Manage your delivery locations',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SavedAddressesScreen(),
                          ),
                        );
                      },
                    ),

                    _buildMenuItem(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      subtitle: 'Manage order updates & alerts',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.translate_rounded,
                      title: 'Language',
                      subtitle: 'English / हिन्दी',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LanguageScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.headset_mic_outlined,
                      title: 'Customer Support',
                      subtitle: '24/7 Chat and helpline support',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CustomerSupportScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.question_answer_outlined,
                      title: 'FAQ',
                      subtitle: 'Frequently Asked Questions',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FaqScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy & Terms',
                      subtitle: 'Read terms of service & data policies',
                      onTap: () async {
                        try {
                          final Uri url = Uri.parse('https://grahmitra.com/privacy-policy');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          } else {
                            // Fallback to launching without checking if canLaunchUrl fails on some Android 11+ devices
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not open Privacy Policy. Please restart the app.')),
                            );
                          }
                        }
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.person_remove_outlined,
                      title: 'Delete Account',
                      subtitle: 'Permanently remove your account & data',
                      iconColor: AppColors.error,
                      onTap: () async {
                        try {
                          final Uri url = Uri.parse('https://grahmitra.com/delete-account');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          } else {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not open Delete Account page.')),
                            );
                          }
                        }
                      },
                    ),

                    14.height,
                    // Logout button
                    InkWell(
                      onTap: () => _showLogoutDialog(context),
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 14.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: AppColors.error,
                              size: 20.sp,
                            ),
                            12.width,
                            Expanded(
                              child: Text(
                                'Log Out',
                                style: AppTextStyles.plusJakartaSans(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.error,
                              size: 18.sp,
                            ),
                          ],
                        ),
                      ),
                    ),
                    30.height,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Build Error Banner Widget
  Widget _buildErrorBanner(BuildContext context, ProfileProvider provider) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 20.sp,
          ),
          10.width,
          Expanded(
            child: Text(
              provider.errorMessage ?? 'Failed to load profile details',
              style: AppTextStyles.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<ProfileProvider>().fetchProfile();
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Retry',
              style: AppTextStyles.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build Profile Info Card Widget (handling loading, success, and empty state)
  Widget _buildProfileCard(ProfileProvider provider) {
    if (provider.isLoading) {
      return Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: AppColors.subtleBackground,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28.r,
              backgroundColor: AppColors.brandPurple.withValues(alpha: 0.12),
              child: SizedBox(
                width: 24.r,
                height: 24.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.brandPurple,
                ),
              ),
            ),
            14.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Loading profile...',
                    style: AppTextStyles.plusJakartaSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  3.height,
                  Text(
                    'Please wait',
                    style: AppTextStyles.plusJakartaSans(
                      fontSize: 12.5.sp,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final user = provider.user;
    final String displayName = user != null ? user.fullName : 'GrahMitra User';
    final String displayPhone = user?.phone != null && user!.phone!.isNotEmpty
        ? user.phone!
        : 'No phone number';

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.subtleBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28.r,
            backgroundColor: AppColors.brandPurple.withValues(alpha: 0.12),
            child: Icon(
              Icons.person_rounded,
              size: 32.sp,
              color: AppColors.brandPurple,
            ),
          ),
          14.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                3.height,
                Text(
                  displayPhone,
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 12.5.sp,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: AppColors.brandPurple,
              size: 20.sp,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    final content = Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22.sp),
          10.height,
          Text(
            value,
            style: AppTextStyles.plusJakartaSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          2.height,
          Text(
            label,
            style: AppTextStyles.plusJakartaSans(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(14.r),
        child: content,
      );
    }

    return content;
  }

  Widget _buildReferCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.subtleBackground,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: AppColors.brandPurple.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.brandPurple, size: 18.sp),
              ),
              12.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    2.height,
                    Text(
                      subtitle,
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 11.5.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.iconSubtle,
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final activeColor = iconColor ?? AppColors.brandPurple;
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.subtleBackground,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: activeColor, size: 18.sp),
              ),
              12.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                        color: iconColor ?? AppColors.textPrimary,
                      ),
                    ),
                    2.height,
                    Text(
                      subtitle,
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 11.5.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.iconSubtle,
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
