
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/bulk_actions_widget.dart';
import './widgets/camera_capture_widget.dart';
import './widgets/inventory_alert_widget.dart';
import './widgets/product_card_widget.dart';
import './widgets/product_filters_widget.dart';
import './widgets/product_form_modal.dart';

class FarmerProductManagement extends StatefulWidget {
  const FarmerProductManagement({super.key});

  @override
  State<FarmerProductManagement> createState() =>
      _FarmerProductManagementState();
}

class _FarmerProductManagementState extends State<FarmerProductManagement>
    with TickerProviderStateMixin {
  int _currentTabIndex = 1; // Products tab is active
  bool _isGridView = true;
  bool _isSearching = false;
  String _searchQuery = '';
  String _selectedFilter = 'all';
  String _selectedSort = 'recent';
  List<String> _selectedProductIds = [];
  bool _isBulkMode = false;

  late TextEditingController _searchController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  // Mock product data
  final List<Map<String, dynamic>> _products = [
    {
      'id': '1',
      'name': 'Organic Tomatoes',
      'category': 'Vegetables',
      'price': 150.0,
      'unit': 'kg',
      'stock': 45,
      'status': 'active',
      'image':
          'https://images.pexels.com/photos/1327838/pexels-photo-1327838.jpeg?auto=compress&cs=tinysrgb&w=600',
      'views': 234,
      'orders': 12,
      'revenue': 1800.0,
      'isVisible': true,
      'harvestDate': DateTime.now().subtract(const Duration(days: 2)),
      'farmingMethod': 'Organic',
      'description': 'Fresh organic tomatoes grown without pesticides',
      'minOrderQty': 1,
      'deliveryOptions': ['pickup', 'delivery'],
    },
    {
      'id': '2',
      'name': 'Fresh Spinach',
      'category': 'Leafy Greens',
      'price': 80.0,
      'unit': 'bunch',
      'stock': 0,
      'status': 'out_of_stock',
      'image':
          'https://images.pexels.com/photos/2325843/pexels-photo-2325843.jpeg?auto=compress&cs=tinysrgb&w=600',
      'views': 156,
      'orders': 8,
      'revenue': 640.0,
      'isVisible': true,
      'harvestDate': DateTime.now().subtract(const Duration(days: 1)),
      'farmingMethod': 'Organic',
      'description': 'Fresh spinach leaves, rich in iron and vitamins',
      'minOrderQty': 2,
      'deliveryOptions': ['pickup'],
    },
    {
      'id': '3',
      'name': 'Carrots',
      'category': 'Root Vegetables',
      'price': 120.0,
      'unit': 'kg',
      'stock': 15,
      'status': 'low_stock',
      'image':
          'https://images.pexels.com/photos/143133/pexels-photo-143133.jpeg?auto=compress&cs=tinysrgb&w=600',
      'views': 189,
      'orders': 15,
      'revenue': 1800.0,
      'isVisible': false,
      'harvestDate': DateTime.now().subtract(const Duration(days: 3)),
      'farmingMethod': 'Conventional',
      'description': 'Sweet and crunchy carrots, perfect for cooking',
      'minOrderQty': 1,
      'deliveryOptions': ['pickup', 'delivery'],
    },
    {
      'id': '4',
      'name': 'Bell Peppers',
      'category': 'Vegetables',
      'price': 200.0,
      'unit': 'kg',
      'stock': 25,
      'status': 'pending_approval',
      'image':
          'https://images.pexels.com/photos/1268101/pexels-photo-1268101.jpeg?auto=compress&cs=tinysrgb&w=600',
      'views': 67,
      'orders': 3,
      'revenue': 600.0,
      'isVisible': true,
      'harvestDate': DateTime.now().subtract(const Duration(days: 1)),
      'farmingMethod': 'Organic',
      'description': 'Colorful bell peppers, rich in vitamin C',
      'minOrderQty': 1,
      'deliveryOptions': ['pickup', 'delivery'],
    },
  ];

  List<Map<String, dynamic>> get _filteredProducts {
    var filtered = _products.where((product) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final matchesSearch = product['name']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            product['category']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
        if (!matchesSearch) return false;
      }

      // Status filter
      if (_selectedFilter != 'all') {
        if (_selectedFilter != product['status']) return false;
      }

      return true;
    }).toList();

    // Sorting
    switch (_selectedSort) {
      case 'name':
        filtered.sort((a, b) => a['name'].compareTo(b['name']));
        break;
      case 'price_low':
        filtered.sort((a, b) => a['price'].compareTo(b['price']));
        break;
      case 'price_high':
        filtered.sort((a, b) => b['price'].compareTo(a['price']));
        break;
      case 'stock':
        filtered.sort((a, b) => b['stock'].compareTo(a['stock']));
        break;
      case 'recent':
      default:
        filtered.sort((a, b) => b['harvestDate'].compareTo(a['harvestDate']));
        break;
    }

    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductFiltersWidget(
        currentFilter: _selectedFilter,
        currentSort: _selectedSort,
        onFilterChanged: (filter) {
          setState(() {
            _selectedFilter = filter;
          });
        },
        onSortChanged: (sort) {
          setState(() {
            _selectedSort = sort;
          });
        },
      ),
    );
  }

  Future<void> _addProduct() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProductFormModal(),
    );

    if (result != null) {
      setState(() {
        _products.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          ...result,
          'views': 0,
          'orders': 0,
          'revenue': 0.0,
          'status': 'active',
        });
      });

      Fluttertoast.showToast(
        msg: "Product added successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        textColor: AppTheme.lightTheme.colorScheme.onPrimary,
      );
    }
  }

  Future<void> _captureProductPhoto() async {
    final result = await showModalBottomSheet<List<XFile>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CameraCaptureWidget(),
    );

    if (result != null && result.isNotEmpty) {
      // Process captured images and show product form
      _showProductFormWithImages(result);
    }
  }

  void _showProductFormWithImages(List<XFile> images) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductFormModal(initialImages: images),
    );
  }

  void _toggleProductVisibility(String productId) {
    setState(() {
      final index = _products.indexWhere((p) => p['id'] == productId);
      if (index != -1) {
        _products[index]['isVisible'] = !_products[index]['isVisible'];
      }
    });
  }

  void _editProduct(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductFormModal(product: product),
    );
  }

  void _duplicateProduct(Map<String, dynamic> product) {
    setState(() {
      final duplicated = Map<String, dynamic>.from(product);
      duplicated['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      duplicated['name'] = '${product['name']} (Copy)';
      duplicated['views'] = 0;
      duplicated['orders'] = 0;
      duplicated['revenue'] = 0.0;
      duplicated['status'] = 'active';
      _products.add(duplicated);
    });

    Fluttertoast.showToast(
      msg: "Product duplicated successfully!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _archiveProduct(String productId) {
    setState(() {
      final index = _products.indexWhere((p) => p['id'] == productId);
      if (index != -1) {
        _products[index]['status'] = 'archived';
      }
    });

    Fluttertoast.showToast(
      msg: "Product archived",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _promoteProduct(String productId) {
    // Mock promotion logic
    Fluttertoast.showToast(
      msg: "Product promoted!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
      textColor: AppTheme.lightTheme.colorScheme.onSecondary,
    );
  }

  void _toggleBulkMode() {
    setState(() {
      _isBulkMode = !_isBulkMode;
      if (!_isBulkMode) {
        _selectedProductIds.clear();
      }
    });
  }

  void _toggleProductSelection(String productId) {
    setState(() {
      if (_selectedProductIds.contains(productId)) {
        _selectedProductIds.remove(productId);
      } else {
        _selectedProductIds.add(productId);
      }
    });
  }

  void _selectAllProducts() {
    setState(() {
      _selectedProductIds =
          _filteredProducts.map((p) => p['id'] as String).toList();
    });
  }

  void _bulkArchive() {
    setState(() {
      for (final productId in _selectedProductIds) {
        final index = _products.indexWhere((p) => p['id'] == productId);
        if (index != -1) {
          _products[index]['status'] = 'archived';
        }
      }
      _selectedProductIds.clear();
      _isBulkMode = false;
    });

    Fluttertoast.showToast(
      msg: "Selected products archived",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _bulkPromote() {
    // Mock bulk promotion
    setState(() {
      _selectedProductIds.clear();
      _isBulkMode = false;
    });

    Fluttertoast.showToast(
      msg: "Selected products promoted!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
      textColor: AppTheme.lightTheme.colorScheme.onSecondary,
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      snap: false,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: AppTheme.lightTheme.colorScheme.surfaceTint,
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search products...',
                border: InputBorder.none,
                hintStyle: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
              style: AppTheme.lightTheme.textTheme.bodyMedium,
              onChanged: _onSearchChanged,
            )
          : Text(
              'My Products',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
      actions: [
        if (_isBulkMode) ...[
          TextButton(
            onPressed: _selectAllProducts,
            child: Text(
              'Select All',
              style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _toggleBulkMode,
            child: Text(
              'Cancel',
              style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ] else ...[
          IconButton(
            onPressed: _toggleSearch,
            icon: CustomIconWidget(
              iconName: _isSearching ? 'close' : 'search',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
          ),
          IconButton(
            onPressed: _showFilterSheet,
            icon: CustomIconWidget(
              iconName: 'filter_list',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'toggle_view':
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                  break;
                case 'bulk_actions':
                  _toggleBulkMode();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_view',
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: _isGridView ? 'view_list' : 'grid_view',
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Text(_isGridView ? 'List View' : 'Grid View'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'bulk_actions',
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'checklist',
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    const Text('Bulk Actions'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildProductGrid() {
    final products = _filteredProducts;

    if (products.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'inventory_2',
                size: 64,
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              SizedBox(height: 2.h),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No products found'
                    : 'No products yet',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Try adjusting your search or filters'
                    : 'Add your first product to get started',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (_searchQuery.isEmpty) ...[
                SizedBox(height: 3.h),
                ElevatedButton.icon(
                  onPressed: _addProduct,
                  icon: CustomIconWidget(
                    iconName: 'add',
                    size: 20,
                    color: AppTheme.lightTheme.colorScheme.onPrimary,
                  ),
                  label: const Text('Add Product'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.all(4.w),
      sliver: _isGridView
          ? SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 3.w,
                mainAxisSpacing: 3.w,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = products[index];
                  return ProductCardWidget(
                    product: product,
                    isGridView: true,
                    isBulkMode: _isBulkMode,
                    isSelected: _selectedProductIds.contains(product['id']),
                    onTap: () => _isBulkMode
                        ? _toggleProductSelection(product['id'])
                        : _editProduct(product),
                    onLongPress: () => _toggleBulkMode(),
                    onVisibilityToggle: () =>
                        _toggleProductVisibility(product['id']),
                    onEdit: () => _editProduct(product),
                    onDuplicate: () => _duplicateProduct(product),
                    onArchive: () => _archiveProduct(product['id']),
                    onPromote: () => _promoteProduct(product['id']),
                  );
                },
                childCount: products.length,
              ),
            )
          : SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = products[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: 2.h),
                    child: ProductCardWidget(
                      product: product,
                      isGridView: false,
                      isBulkMode: _isBulkMode,
                      isSelected: _selectedProductIds.contains(product['id']),
                      onTap: () => _isBulkMode
                          ? _toggleProductSelection(product['id'])
                          : _editProduct(product),
                      onLongPress: () => _toggleBulkMode(),
                      onVisibilityToggle: () =>
                          _toggleProductVisibility(product['id']),
                      onEdit: () => _editProduct(product),
                      onDuplicate: () => _duplicateProduct(product),
                      onArchive: () => _archiveProduct(product['id']),
                      onPromote: () => _promoteProduct(product['id']),
                    ),
                  );
                },
                childCount: products.length,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),

          // Inventory alerts
          SliverToBoxAdapter(
            child: InventoryAlertWidget(
              products: _products,
              onProductTap: _editProduct,
            ),
          ),

          // Product grid/list
          _buildProductGrid(),

          // Bottom spacing for FAB
          SliverToBoxAdapter(
            child: SizedBox(height: 10.h),
          ),
        ],
      ),

      // Bulk actions bottom bar
      bottomSheet: _isBulkMode && _selectedProductIds.isNotEmpty
          ? BulkActionsWidget(
              selectedCount: _selectedProductIds.length,
              onArchive: _bulkArchive,
              onPromote: _bulkPromote,
              onCancel: _toggleBulkMode,
            )
          : null,

      // Bottom navigation
      bottomNavigationBar: !_isBulkMode
          ? Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.lightTheme.colorScheme.shadow
                        .withValues(alpha: 0.1),
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

                  // Handle navigation
                  switch (index) {
                    case 0:
                      Navigator.pushReplacementNamed(
                          context, AppRoutes.farmerDashboard);
                      break;
                    case 1:
                      // Already on products
                      break;
                    case 2:
                      Navigator.pushNamed(context, AppRoutes.ordersOverview);
                      break;
                    case 3:
                      Navigator.pushNamed(context, AppRoutes.chat);
                      break;
                    case 4:
                      Navigator.pushNamed(context, AppRoutes.profilePage);
                      break;
                  }
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: AppTheme.lightTheme.colorScheme.surface,
                selectedItemColor: AppTheme.lightTheme.colorScheme.primary,
                unselectedItemColor:
                    AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                selectedLabelStyle:
                    AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: AppTheme.lightTheme.textTheme.labelSmall,
                items: [
                  BottomNavigationBarItem(
                    icon: CustomIconWidget(
                      iconName: _currentTabIndex == 0
                          ? 'dashboard'
                          : 'dashboard_outlined',
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
                    icon: CustomIconWidget(
                      iconName: _currentTabIndex == 2
                          ? 'shopping_bag'
                          : 'shopping_bag_outlined',
                      color: _currentTabIndex == 2
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                    label: 'Orders',
                  ),
                  BottomNavigationBarItem(
                    icon: CustomIconWidget(
                      iconName:
                          _currentTabIndex == 3 ? 'chat' : 'chat_outlined',
                      color: _currentTabIndex == 3
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                    label: 'Chat',
                  ),
                  BottomNavigationBarItem(
                    icon: CustomIconWidget(
                      iconName:
                          _currentTabIndex == 4 ? 'person' : 'person_outline',
                      color: _currentTabIndex == 4
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                    label: 'Profile',
                  ),
                ],
              ),
            )
          : null,

      // Floating action buttons
      floatingActionButton: !_isBulkMode
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Camera capture FAB
                ScaleTransition(
                  scale: _fabAnimation,
                  child: FloatingActionButton(
                    heroTag: 'camera',
                    onPressed: _captureProductPhoto,
                    backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
                    foregroundColor:
                        AppTheme.lightTheme.colorScheme.onSecondary,
                    mini: true,
                    child: CustomIconWidget(
                      iconName: 'camera_alt',
                      color: AppTheme.lightTheme.colorScheme.onSecondary,
                      size: 20,
                    ),
                  ),
                ),
                SizedBox(height: 1.h),
                // Main add product FAB
                ScaleTransition(
                  scale: _fabAnimation,
                  child: FloatingActionButton(
                    heroTag: 'add',
                    onPressed: _addProduct,
                    backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                    foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
                    child: CustomIconWidget(
                      iconName: 'add',
                      color: AppTheme.lightTheme.colorScheme.onPrimary,
                      size: 28,
                    ),
                  ),
                ),
              ],
            )
          : null,
    );
  }
}
