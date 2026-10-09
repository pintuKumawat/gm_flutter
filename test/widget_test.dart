import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grahmitracus/main.dart';
import 'package:grahmitracus/screens/auth/otp_screen.dart';
import 'package:grahmitracus/screens/home/home_screen.dart';

void main() {
  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome to GrahMitra'), findsOneWidget);
    expect(find.text('+91'), findsOneWidget);
    expect(find.text('REFERRAL CODE?'), findsOneWidget);
  });

  testWidgets('OTP screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (context, child) {
          return const MaterialApp(
            home: OtpScreen(phoneNumber: '8740929857'),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verify OTP'), findsOneWidget);
    expect(find.text('Change number'), findsOneWidget);
    expect(find.text('Verify & Login'), findsOneWidget);
  });

  testWidgets('Home screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (context, child) {
          return const MaterialApp(
            home: HomeScreen(),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Set your delivery location'), findsOneWidget);
    expect(find.text('Grocery'), findsWidgets);
    expect(find.text('Daily Needs'), findsWidgets);
  });
}
