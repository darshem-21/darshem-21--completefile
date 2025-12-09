import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import 'widgets/earnings_summary_card.dart';
import 'widgets/farmer_header_widget.dart';
import 'widgets/product_performance_widget.dart';
import 'widgets/quick_action_card.dart';
import 'widgets/recent_orders_section.dart';

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({super.key});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard>
    with TickerProviderStateMixin {
  int _currentTabIndex = 0;
  bool _isConnected = true;
  late TabController _tabController;

  // Mock data for farmer dashboard
  final Map<String, dynamic> _farmerData = {
    "id": 1,
    "name": "Rajesh Kumar",
    "profileImage":
        "https://images.pexels.com/photos/1222271/pexels-photo-1222271.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
    "farmName": "Green Valley Organic Farm",
    "isVerified": true,
    "location": "Punjab, India",
    "joinedDate": "2023-01-15",
  };

  final Map<String, dynamic> _earningsData = {
    "todaySales": 2450.0,
    "pendingPayments": 1200.0,
    "monthlyRevenue": 45000.0,
    "totalEarnings": 125000.0,
    "completedOrders": 156,
    "pendingOrders": 8,
  };

  final List<Map<String, dynamic>> _recentOrders = [
    {
      "id": 1,
      "buyerName": "Priya Sharma",
      "productName": "Organic Tomatoes",
      "productImage":
          "https://images.pexels.com/photos/1327838/pexels-photo-1327838.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "quantity": 5,
      "totalAmount": 450.0,
      "status": "completed",
      "orderDate": DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      "id": 2,
      "buyerName": "Amit Patel",
      "productName": "Fresh Spinach",
      "productImage":
          "https://images.pexels.com/photos/2325843/pexels-photo-2325843.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "quantity": 3,
      "totalAmount": 180.0,
      "status": "processing",
      "orderDate": DateTime.now().subtract(const Duration(hours: 5)),
    },
    {
      "id": 3,
      "buyerName": "Sunita Devi",
      "productName": "Organic Carrots",
      "productImage":
          "https://images.pexels.com/photos/143133/pexels-photo-143133.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "quantity": 2,
      "totalAmount": 120.0,
      "status": "pending",
      "orderDate": DateTime.now().subtract(const Duration(days: 1)),
    },
  ];

  final List<Map<String, dynamic>> _topProducts = [
    {
      "id": 1,
      "name": "Organic Tomatoes",
      "image":
          "https://images.pexels.com/photos/1327838/pexels-photo-1327838.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "salesCount": 45,
      "revenue": 6750.0,
      "growthPercentage": 12.5,
    },
    {
      "id": 2,
      "name": "Fresh Spinach",
      "image":
          "https://images.pexels.com/photos/2325843/pexels-photo-2325843.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "salesCount": 32,
      "revenue": 4800.0,
      "growthPercentage": 8.3,
    },
    {
      "id": 3,
      "name": "Organic Carrots",
      "image":
          "https://images.pexels.com/photos/143133/pexels-photo-143133.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "salesCount": 28,
      "revenue": 3360.0,
      "growthPercentage": -2.1,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
    _simulateNetworkStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _simulateNetworkStatus() {
    // Simulate network connectivity changes
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _isConnected = !_isConnected;
        });
        _simulateNetworkStatus();
      }
    });
  }

  Future<void> _handleRefresh() async {
    setState(() {
    });

    // Provide haptic feedback
    HapticFeedback.lightImpact();

    // Simulate data refresh
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        // Update earnings data to simulate refresh
        _earningsData['todaySales'] =
            (_earningsData['todaySales'] as double) + 150.0;
      });
    }
  }

  void _onQuickActionTap(String action) {
    switch (action) {
      case 'add_product':
        _showAddProductDialog();
        break;
      case 'manage_inventory':
        // Navigate to inventory management
        break;
      case 'view_orders':
        // Navigate to orders screen
        break;
      case 'check_messages':
        // Navigate to messages screen
        break;
    }
  }

  void _showAddProductDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 40.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            children: [
              Container(
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                'Add New Product',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 3.h),
              Row(
                children: [
                  Expanded(
                    child: _buildAddProductOption(
                      'Take Photo',
                      'camera_alt',
                      () {
                        Navigator.pop(context);
                        // Handle camera action
                      },
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: _buildAddProductOption(
                      'Choose from Gallery',
                      'photo_library',
                      () {
                        Navigator.pop(context);
                        // Handle gallery action
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              _buildAddProductOption(
                'Add Product Details',
                'edit',
                () {
                  Navigator.pop(context);
                  // Navigate to product form
                },
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddProductOption(
      String title, String iconName, VoidCallback onTap,
      {bool isFullWidth = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 32,
            ),
            SizedBox(height: 1.h),
            Text(
              title,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _onOrderTap(Map<String, dynamic> order) {
    Navigator.pushNamed(context, '/product-detail', arguments: order);
  }

  void _onProfileTap() {
    // Navigate to profile screen or show profile options
  }

  void _onEarningsToggle() {
    // Handle earnings detail toggle
  }

  void _onViewAllProducts() {
    // Navigate to all products screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppTheme.lightTheme.colorScheme.primary,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: FarmerHeaderWidget(
                farmerData: _farmerData,
                isConnected: _isConnected,
                onProfileTap: _onProfileTap,
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: 2.h),
            ),
            SliverToBoxAdapter(
              child: EarningsSummaryCard(
                earningsData: _earningsData,
                onToggleDetails: _onEarningsToggle,
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: 2.h),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  QuickActionCard(
                    title: 'Add New Product',
                    iconName: 'add_a_photo',
                    onTap: () => _onQuickActionTap('add_product'),
                  ),
                  QuickActionCard(
                    title: 'Manage Inventory',
                    iconName: 'inventory_2',
                    onTap: () => _onQuickActionTap('manage_inventory'),
                  ),
                  QuickActionCard(
                    title: 'View Orders',
                    iconName: 'shopping_bag',
                    notificationCount:
                        _earningsData['pendingOrders'] as int? ?? 0,
                    onTap: () => _onQuickActionTap('view_orders'),
                  ),
                  QuickActionCard(
                    title: 'Check Messages',
                    iconName: 'chat',
                    notificationCount: 3,
                    onTap: () => _onQuickActionTap('check_messages'),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: 2.h),
            ),
            SliverToBoxAdapter(
              child: RecentOrdersSection(
                recentOrders: _recentOrders,
                onOrderTap: _onOrderTap,
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: 2.h),
            ),
            SliverToBoxAdapter(
              child: ProductPerformanceWidget(
                topProducts: _topProducts,
                onViewAll: _onViewAllProducts,
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: 10.h),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color:
                  AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (index) {
            setState(() {
              _currentTabIndex = index;
            });
            _tabController.animateTo(index);

            // Handle navigation based on tab
            switch (index) {
              case 0:
                // Already on dashboard
                break;
              case 1:
                // Navigate to products
                break;
              case 2:
                // Navigate to orders
                break;
              case 3:
                // Navigate to chat
                break;
              case 4:
                // Navigate to profile
                break;
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.lightTheme.colorScheme.surface,
          selectedItemColor: AppTheme.lightTheme.colorScheme.primary,
          unselectedItemColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          selectedLabelStyle:
              AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTheme.lightTheme.textTheme.labelSmall,
          items: [
            BottomNavigationBarItem(
              icon: CustomIconWidget(
                iconName:
                    _currentTabIndex == 0 ? 'dashboard' : 'dashboard_outlined',
                color: _currentTabIndex == 0
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: CustomIconWidget(
                iconName: _currentTabIndex == 1
                    ? 'inventory'
                    : 'inventory_2_outlined',
                color: _currentTabIndex == 1
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
              label: 'Products',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  CustomIconWidget(
                    iconName: _currentTabIndex == 2
                        ? 'shopping_bag'
                        : 'shopping_bag_outlined',
                    color: _currentTabIndex == 2
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  if ((_earningsData['pendingOrders'] as int? ?? 0) > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(0.5.w),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 3.w,
                          minHeight: 3.w,
                        ),
                        child: Text(
                          (_earningsData['pendingOrders'] as int).toString(),
                          style: AppTheme.lightTheme.textTheme.labelSmall
                              ?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onError,
                            fontWeight: FontWeight.w600,
                            fontSize: 8.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  CustomIconWidget(
                    iconName: _currentTabIndex == 3 ? 'chat' : 'chat_outlined',
                    color: _currentTabIndex == 3
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(0.5.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 3.w,
                        minHeight: 3.w,
                      ),
                      child: Text(
                        '3',
                        style:
                            AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onError,
                          fontWeight: FontWeight.w600,
                          fontSize: 8.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: CustomIconWidget(
                iconName: _currentTabIndex == 4 ? 'person' : 'person_outline',
                color: _currentTabIndex == 4
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onQuickActionTap('add_product'),
        backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
        foregroundColor: AppTheme.lightTheme.colorScheme.onSecondary,
        child: CustomIconWidget(
          iconName: 'add',
          color: AppTheme.lightTheme.colorScheme.onSecondary,
          size: 28,
        ),
      ),
    );
  }
}
