import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grahmitracus/core/config/env_config.dart';
import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/screens/main_nav/main_navigation_screen.dart';

import 'package:provider/provider.dart';
import 'package:grahmitracus/providers/auth/register_provider.dart';
import 'package:grahmitracus/providers/auth/send_otp_provider.dart';
import 'package:grahmitracus/providers/auth/verify_otp_provider.dart';
import 'package:grahmitracus/providers/location/location_provider.dart';
import 'package:grahmitracus/providers/product/category_group_provider.dart';
import 'package:grahmitracus/providers/product/category_provider.dart';
import 'package:grahmitracus/providers/product/home_group_products_provider.dart';
import 'package:grahmitracus/providers/product/product_detail_provider.dart';
import 'package:grahmitracus/providers/product/search_provider.dart';
import 'package:grahmitracus/providers/product/spotlight_banner_provider.dart';
import 'package:grahmitracus/providers/product/trending_product_provider.dart';

import 'package:grahmitracus/providers/cart/cart_provider.dart';
import 'package:grahmitracus/core/services/api_service.dart';
import 'package:grahmitracus/core/services/auth_storage_service.dart';
import 'package:grahmitracus/providers/cart/order_provider.dart';
import 'package:grahmitracus/providers/payment/payment_provider.dart';

import 'package:grahmitracus/providers/profile/profile_provider.dart';
import 'package:grahmitracus/providers/profile/wallet_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:grahmitracus/core/services/firebase_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }
  await EnvConfig.init();
  try {
    await FirebaseNotificationService.initialize();
  } catch (e) {
    debugPrint('FirebaseNotificationService initialization warning: $e');
  }

  // Initialize stored access token if available
  final token = await AuthStorageService.getAccessToken();
  if (token != null && token.isNotEmpty) {
    ApiService.instance.setAuthToken(token);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SendOtpProvider()),
        ChangeNotifierProvider(create: (_) => VerifyOtpProvider()),
        ChangeNotifierProvider(create: (_) => RegisterProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final profileProvider = ProfileProvider();
            if (token != null && token.isNotEmpty) {
              profileProvider.fetchProfile();
            }
            return profileProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => WalletProvider()..fetchWallet()),
        ChangeNotifierProvider(create: (_) => LocationProvider()..init()),
        ChangeNotifierProvider(create: (_) => CategoryGroupProvider()..fetchGroups()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()..fetchCategories()),
        ChangeNotifierProvider(create: (_) => TrendingProductProvider()),
        ChangeNotifierProvider(create: (_) => HomeGroupProductsProvider()),
        ChangeNotifierProvider(create: (_) => SpotlightBannerProvider()..fetchBanners(displayLocation: 'home')),
        ChangeNotifierProvider(create: (_) => ProductDetailProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Grahmitra',
          theme: ThemeData(
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.brandPurple,
              surface: AppColors.background,
            ),
            textTheme: Typography.material2021().black.apply(
                  fontFamily: 'Plus Jakarta Sans',
                ),
            useMaterial3: true,
          ),
          home: child,
        );
      },
      child: const MainNavigationScreen(),
    );
  }
}
