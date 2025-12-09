import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import 'package:farmmarket/services/supabase_service.dart';
import 'package:farmmarket/presentation/common/map_picker.dart';
import 'package:farmmarket/services/geo_service.dart';
import 'package:farmmarket/services/local_storage.dart';
import 'package:farmmarket/presentation/consumer_marketplace/widgets/users_map_page.dart';

import 'package:farmmarket/presentation/consumer_marketplace/widgets/category_chip_widget.dart';
import 'package:farmmarket/presentation/consumer_marketplace/widgets/filter_bottom_sheet_widget.dart';
import 'package:farmmarket/presentation/consumer_marketplace/widgets/product_card_widget.dart';
import 'package:farmmarket/presentation/consumer_marketplace/widgets/quick_actions_widget.dart';
import 'package:farmmarket/presentation/consumer_marketplace/widgets/sort_bottom_sheet_widget.dart';
import '../farmer_product_management/widgets/product_form_modal.dart';

class ConsumerMarketplace extends StatefulWidget {
  const ConsumerMarketplace({super.key});

  @override
  State<ConsumerMarketplace> createState() => _ConsumerMarketplaceState();
}

class _ConsumerMarketplaceState extends State<ConsumerMarketplace>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int _currentTabIndex = 0;
  String _selectedCategory = "All";
  String _currentSort = "nearest";
  Map<String, dynamic> _currentFilters = {};
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _selectedLocationLabel = 'Location: Mumbai';
  double? _selectedLat;
  double? _selectedLng;

  // Cache the products stream to avoid resubscribing on rebuilds
  late final Stream<List<Map<String, dynamic>>> _productsStream;

  @override
  bool get wantKeepAlive => true;

  final List<String> _categories = [
    "All",
    "Vegetables",
    "Fruits",
    "Grains",
    "Dairy"
  ];

  final List<Map<String, dynamic>> _allProducts = [
    // Your sample products here...
  ];

  List<Map<String, dynamic>> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _filteredProducts = List.from(_allProducts);
    _scrollController.addListener(_onScroll);
    _loadInitialLocation();
    _productsStream = SupabaseService.streamProducts(
      orderByUpdatedAtDesc: true,
    );
  }

  Widget _buildHeaderBackground(String displayName, String? email) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green,
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 4.w, right: 4.w, top: 0.5.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (email != null)
                          Text(
                            email,
                            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              color: Colors.black,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.black87, size: 20),
                    tooltip: 'About this app',
                    onPressed: _showPlatformInfo,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 0.5.h),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => _applyFiltersAndSort(),
                      decoration: InputDecoration(
                        hintText: 'Search fresh produce…',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  SizedBox(
                    height: 44,
                    width: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _showFilterBottomSheet,
                      child: const Icon(Icons.tune),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 0.6.h),
              child: Row(
                children: [
                  InkWell(
                    onTap: _showLocationOptions,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _selectedLocationLabel,
                              style: AppTheme.lightTheme.textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _showSortBottomSheet,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.sort, color: Colors.white),
                    label: const Text(
                      'Sort',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlatformInfo() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('About FarmMarket'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Contact:\n'
                  'dharshanks98@gmail.com\n'
                  'jjsmithun@gmail.com\n'
                  'preethamcghero@gmail.com\n'
                  'paramveerudbale@gmail.com'),
              SizedBox(height: 12),
              Text(
                'It is a user-friendly platform for farmers to reduce loss. '
                'There is no delivery built-in here – delivery is arranged by '
                'negotiation and chat between both sides.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
    });
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoadingMore = false;
    });
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
      _filteredProducts = List.from(_allProducts);
    });
    _applyFiltersAndSort();
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _applyFiltersAndSort();
  }

  void _onFiltersApplied(Map<String, dynamic> filters) {
    setState(() {
      _currentFilters = filters;
    });
    _applyFiltersAndSort();
  }

  void _onSortSelected(String sortType) {
    setState(() {
      _currentSort = sortType;
    });
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    List<Map<String, dynamic>> filtered = List.from(_allProducts);

    if (_selectedCategory != "All") {
      filtered = filtered
          .where((product) => product["category"] == _selectedCategory)
          .toList();
    }

    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered
          .where((product) =>
              (product["name"] as String).toLowerCase().contains(searchTerm) ||
              (product["farmerName"] as String)
                  .toLowerCase()
                  .contains(searchTerm))
          .toList();
    }

    setState(() {
      _filteredProducts = filtered;
    });
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>?>(
      MaterialPageRoute(
        builder: (_) => MapPicker(
          initialLat: _selectedLat ?? 19.0760,
          initialLng: _selectedLng ?? 72.8777,
        ),
      ),
    );
    if (result != null && mounted) {
      final lat = (result['lat'] as num?)?.toDouble();
      final lng = (result['lng'] as num?)?.toDouble();
      final address = (result['address'] as String?) ?? 'Selected location';
      String city = address;
      final parts = address.split(',');
      if (parts.isNotEmpty) {
        city = parts.first.trim();
      }
      setState(() {
        _selectedLat = lat;
        _selectedLng = lng;
        _selectedLocationLabel = 'Location: $city';
      });
      await LocalStorage.saveBrowseLocation({
        'label': _selectedLocationLabel,
        'lat': lat,
        'lng': lng,
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      final pos = await GeoService.getCurrentPosition();
      if (!mounted) return;

      // On web, Geolocator often uses approximate IP/Wi-Fi based location.
      // Let the user know they can fine-tune using the map.
      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location on web may be approximate. Drag the map pin to adjust.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }

      // Open full-screen map centered on current location so user can fine-tune
      final result = await Navigator.of(context).push<Map<String, dynamic>?>(
        MaterialPageRoute(
          builder: (_) => MapPicker(
            initialLat: pos.latitude,
            initialLng: pos.longitude,
          ),
        ),
      );

      if (result != null && mounted) {
        final lat = (result['lat'] as num?)?.toDouble();
        final lng = (result['lng'] as num?)?.toDouble();
        final address = (result['address'] as String?) ?? 'Selected location';
        String cityLabel = address;
        final parts = address.split(',');
        if (parts.isNotEmpty) {
          cityLabel = parts.first.trim();
        }
        final label = 'Location: $cityLabel';

        setState(() {
          _selectedLat = lat;
          _selectedLng = lng;
          _selectedLocationLabel = label;
        });

        await LocalStorage.saveBrowseLocation({
          'label': label,
          'lat': lat,
          'lng': lng,
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white,
          content: const Text(
            'Location unavailable. Please enable location services in settings.',
            style: TextStyle(color: Colors.black),
          ),
        ),
      );
    }
  }

  Future<void> _loadInitialLocation() async {
    final saved = await LocalStorage.loadBrowseLocation();
    if (!mounted) return;
    if (saved != null) {
      final lat = (saved['lat'] as num?)?.toDouble();
      final lng = (saved['lng'] as num?)?.toDouble();
      final label = (saved['label'] as String?) ?? _selectedLocationLabel;
      setState(() {
        _selectedLat = lat;
        _selectedLng = lng;
        _selectedLocationLabel = label;
      });
    }
  }

  void _openUsersMap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const UsersMapPage(),
      ),
    );
  }

  void _showLocationOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.my_location),
                title: const Text('Use Current Location'),
                onTap: () async {
                  Navigator.pop(context);
                  await _useCurrentLocation();
                },
              ),
              ListTile(
                leading: const Icon(Icons.map),
                title: const Text('Choose on Map'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickLocation();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheetWidget(
        currentFilters: _currentFilters,
        onFiltersApplied: _onFiltersApplied,
      ),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SortBottomSheetWidget(
        currentSort: _currentSort,
        onSortSelected: _onSortSelected,
      ),
    );
  }

  void _showQuickActions(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickActionsWidget(
        product: product,
        onAddToWishlist: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${product["name"]} added to wishlist")),
          );
        },
        onShare: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Product shared successfully")),
          );
        },
        onViewFarmerProfile: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Viewing ${product["farmerName"]}'s profile")),
          );
        },
      ),
    );
  }

  void _onProductTap(Map<String, dynamic> product) {
    Navigator.pushNamed(context, AppRoutes.productDetail, arguments: product);
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentTabIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushNamed(context, AppRoutes.shoppingCart);
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.ordersOverview);
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.profilePage);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // keep-alive
    final email = SupabaseService.currentUserEmail;
    final displayName = (email != null && email.contains('@'))
        ? email.split('@').first
        : 'User';

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerScrolled) {
          return [
            SliverAppBar(
              automaticallyImplyLeading: false,
              pinned: false,
              floating: false,
              expandedHeight: 190,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: _buildHeaderBackground(displayName, email),
              ),
            ),
          ];
        },
        body: RefreshIndicator(
          onRefresh: _refreshProducts,
          child: Column(
            children: [
              // Categories (with consistent start/end padding)
              SizedBox(
                height: 48,
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => SizedBox(width: 2.4.w),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return CategoryChipWidget(
                      category: category,
                      isSelected: category == _selectedCategory,
                      onTap: () => _onCategorySelected(category),
                    );
                  },
                ),
              ),
              
              // Product Grid (live from Supabase)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.6.h),
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _productsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      final rows = snapshot.data ?? [];
                      // Apply search and category filters client-side
                      final search = _searchController.text.trim().toLowerCase();
                      final currentUid = SupabaseService.currentUserId;
                      List<Map<String, dynamic>> filteredRows = rows.where((row) {
                        final name = (row['name'] ?? '').toString().toLowerCase();
                        final farmer = (row['farmer_name'] ?? 'farmer').toString().toLowerCase();
                        final category = (row['category'] ?? 'All').toString();
                        final matchesSearch = search.isEmpty || name.contains(search) || farmer.contains(search);
                        final matchesCategory = _selectedCategory == 'All' || category == _selectedCategory;
                        // Numeric price
                        final priceNum = (row['price'] is num)
                            ? (row['price'] as num).toDouble()
                            : double.tryParse((row['price'] ?? '0').toString()) ?? 0.0;
                        final minPrice = (_currentFilters['minPrice'] as double?) ?? 0.0;
                        final maxPrice = (_currentFilters['maxPrice'] as double?) ?? 1000.0;
                        final matchesPrice = priceNum >= minPrice && priceNum <= maxPrice;
                        // Organic filter via farming_method text
                        final organicOnly = (_currentFilters['organicOnly'] as bool?) ?? false;
                        final method = (row['farming_method'] ?? '').toString().toLowerCase();
                        final matchesOrganic = !organicOnly || method.contains('organic');
                        // Only show active products on home feed
                        final status = (row['status'] ?? 'active').toString();
                        final matchesStatus = status == 'active';

                        // Keep products visible even when stock is 0; card will show "Out of stock".
                        return matchesSearch && matchesCategory && matchesPrice && matchesOrganic && matchesStatus;
                      }).toList();

                      if (filteredRows.isEmpty) {
                        return const Center(child: Text('No products yet'));
                      }
                      return GridView.builder(
                        controller: _scrollController,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          // Slightly taller items so the card can fit without overflow
                          childAspectRatio: 0.7,
                        ),
                        itemCount: filteredRows.length,
                        itemBuilder: (context, index) {
                          final row = filteredRows[index];
                          final isOwner = SupabaseService.currentUserId != null && (row['seller_id']?.toString() ?? '') == SupabaseService.currentUserId;
                          final List imageUrls = (row['image_urls'] as List?) ?? const [];
                          final productMap = <String, dynamic>{
                            'id': row['id'],
                            'ownerId': row['seller_id'],
                            'name': row['name'] ?? 'Product',
                            'image': imageUrls.isNotEmpty
                                ? imageUrls.first as String
                                : 'https://via.placeholder.com/600x400?text=No+Image',
                            'images': imageUrls.cast<String>(),
                            'freshness': 'Fresh',
                            'farmerName': 'Farmer',
                            'isVerified': true,
                            'price': '₹${row['price'] ?? 0} ',
                            'priceValue': (row['price'] ?? 0).toDouble(),
                            'unit': ' /${row['unit'] ?? 'kg'}',
                            'availableQuantity': row['stock'] ?? 0,
                            'description': row['description'],
                            'harvestDate': row['harvest_date']?.toString(),
                            'farmingMethod': row['farming_method'],
                            'category': row['category'],
                            'pickup_address': row['pickup_address'],
                            'latitude': row['latitude'],
                            'longitude': row['longitude'],
                          };
                          return ProductCardWidget(
                            product: productMap,
                            onTap: () => _onProductTap(productMap),
                            onLongPress: () => _showQuickActions(productMap),
                            isUserProduct: isOwner,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              if (_isLoadingMore)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: SupabaseService.currentUserId != null
          ? FloatingActionButton(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              onPressed: () async {
                final result = await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const ProductFormModal(),
                );
                if (result != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Product saved')),
                  );
                }
              },
              child: const Icon(Icons.add),
            )
          : const SizedBox.shrink(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        selectedItemColor: AppTheme.lightTheme.colorScheme.primary,
        unselectedItemColor:
            AppTheme.lightTheme.colorScheme.onSurfaceVariant,
        items: [
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'home',
              color: _currentTabIndex == 0
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'shopping_cart',
              color: _currentTabIndex == 1
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'receipt_long',
              color: _currentTabIndex == 2
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'person',
              color: _currentTabIndex == 3
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
