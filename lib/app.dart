import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/auth/splash_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/auth/email_verify_screen.dart';
import 'presentation/screens/auth/phone_verify_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/marketplace/marketplace_screen.dart';
import 'presentation/screens/supplier/add_listing_screen.dart';
import 'presentation/screens/order/my_orders_screen.dart';
import 'presentation/screens/notification/notification_screen.dart';
import 'presentation/screens/ai/ai_chatbot_screen.dart'; // নতুন ইমপোর্ট

class SeaLinkApp extends StatelessWidget {
  const SeaLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SeaLink BD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/verify-email': (_) => const EmailVerifyScreen(),
        '/verify-phone': (_) => const PhoneVerifyScreen(),
        '/home': (_) => const HomeScreen(),
        '/marketplace': (_) => const MarketplaceScreen(),
        '/add-listing': (_) => const AddListingScreen(),
        '/my-orders': (_) => const MyOrdersScreen(),
        '/notifications': (_) => const NotificationScreen(),
        '/ai-chat': (_) => const AIChatbotScreen(), // নতুন রুট
      },
    );
  }
}