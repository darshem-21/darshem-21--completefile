import 'package:flutter/material.dart';
import '../presentation/product_detail/product_detail.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/farmer_dashboard/farmer_dashboard.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/user_registration/user_registration.dart';
import '../presentation/consumer_marketplace/consumer_marketplace.dart';
import '../presentation/shopping_cart/shopping_cart.dart';
import '../presentation/order_tracking/order_tracking.dart';
import '../presentation/order_tracking/orders_overview.dart';
import '../presentation/farmer_product_management/farmer_product_management.dart';
import '../presentation/ProfilePage/ProfilePage.dart';
import '../presentation/chat/chat_screen.dart';
import '../presentation/chat/ai_chat_screen.dart';
import '../widgets/auth_gate.dart';
import '../presentation/admin_dashboard/admin_dashboard.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String productDetail = '/product-detail';
  static const String splash = '/splash-screen';
  static const String farmerDashboard = '/farmer-dashboard';
  static const String login = '/login-screen';
  static const String userRegistration = '/user-registration';
  static const String consumerMarketplace = '/consumer-marketplace';
  static const String shoppingCart = '/shopping-cart';
  static const String orderTracking = '/order-tracking';
  static const String ordersOverview = '/orders-overview';
  static const String farmerProductManagement = '/farmer-product-management';
  static const String profilePage = '/profile-page';
  static const String chat = '/chat';
  static const String aiChat = '/ai-chat';
  static const String adminDashboard = '/admin-dashboard';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    productDetail: (context) => const ProductDetail(),
    splash: (context) => const SplashScreen(),
    farmerDashboard: (context) => AuthGate(builder: (_) => const FarmerDashboard()),
    login: (context) => const LoginScreen(),
    userRegistration: (context) => const UserRegistration(),
    consumerMarketplace: (context) => AuthGate(builder: (_) => const ConsumerMarketplace()),
    shoppingCart: (context) => AuthGate(builder: (_) => const ShoppingCart()),
    orderTracking: (context) => AuthGate(builder: (_) => const OrderTracking()),
    ordersOverview: (context) => AuthGate(builder: (_) => const OrdersOverviewPage()),
    farmerProductManagement: (context) => AuthGate(builder: (_) => const FarmerProductManagement()),
    profilePage: (context) => AuthGate(builder: (_) => const ProfilePage()),
    chat: (context) => AuthGate(builder: (_) => const ChatScreen()),
    aiChat: (context) => AuthGate(builder: (_) => const AiChatScreen()),
    adminDashboard: (context) => const AdminDashboard(),
    // TODO: Add your other routes here
  };
}
