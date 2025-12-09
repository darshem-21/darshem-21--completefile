import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import 'package:farmmarket/services/supabase_service.dart';
import 'package:farmmarket/services/whatsapp_service.dart';
import 'package:latlong2/latlong.dart';
import '../../services/geo_service.dart';
import 'widgets/expandable_section.dart';
import 'widgets/farmer_info_card.dart';
import 'widgets/product_image_carousel.dart';
import 'widgets/product_info_section.dart';
import 'widgets/quantity_selector.dart';
import 'widgets/sticky_bottom_bar.dart';
import 'widgets/location_map_sheet.dart';
import '../../services/local_storage.dart';

class ProductDetail extends StatefulWidget {
  const ProductDetail({super.key});

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  int _selectedQuantity = 1;
  int _inCartQuantityForThisProduct = 0;
  bool _isLoading = false;
  String? _sellerId;

  @override
  void initState() {
    super.initState();
    // Defer reading context until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _ingestArgs(args);
      }
    });
  }

  void _ingestArgs(Map<String, dynamic> p) {
    setState(() {
      _productData = {
        "id": p['id'] ?? _productData['id'],
        "name": p['name'] ?? _productData['name'],
        "images": (p['images'] as List?)?.cast<String>() ??
            (p['image'] != null ? [p['image'] as String] : _productData['images']),
        "price": (p['priceValue'] is num)
            ? (p['priceValue'] as num).toDouble()
            : _productData['price'],
        "unit": p['unit'] ?? _productData['unit'],
        "availableQuantity": p['availableQuantity'] ?? _productData['availableQuantity'],
        "isFresh": true,
        "isOrganic": true,
        "description": p['description'] ?? _productData['description'],
        "harvestDate": p['harvestDate'] ?? _productData['harvestDate'],
        "farmingMethod": p['farmingMethod'] ?? _productData['farmingMethod'],
        "storageInstructions": _productData['storageInstructions'],
        "bulkPricing": _productData['bulkPricing'],
        "nutritionalInfo": _productData['nutritionalInfo'],
        // optional location on the product payload as fallback reference
        if (p['pickup_address'] != null) 'pickup_address': p['pickup_address'],
        if (p['latitude'] != null) 'latitude': p['latitude'],
        if (p['longitude'] != null) 'longitude': p['longitude'],
      };

      _farmerData = {
        ..._farmerData,
        "name": p['farmerName'] ?? _farmerData['name'],
        // align farmer location fields; prefer explicit lat/lng when provided
        if (p['pickup_address'] != null) 'location': p['pickup_address'],
        if (p['latitude'] != null) 'latitude': p['latitude'],
        if (p['longitude'] != null) 'longitude': p['longitude'],
      };
      // If farmer location still empty but product has pickup_address, use it
      if (((_farmerData['location'] as String?) ?? '').isEmpty &&
          (_productData['pickup_address'] is String)) {
        _farmerData = {
          ..._farmerData,
          'location': (_productData['pickup_address'] as String),
        };
      }
      // Keep seller id handy for chat
      _sellerId = p['ownerId'] as String?;
    });
    // Try to backfill address from seller profile if missing
    _ensureFarmerAddressFromProfile();
    // After ingesting, compute distance asynchronously
    _updateFarmerDistance();
    // Load how many of this product are already in cart to cap available
    _loadInCartQuantity();
  }

  Future<void> _ensureFarmerAddressFromProfile() async {
    try {
      final sellerId = _sellerId;
      if (sellerId == null || sellerId.isEmpty) return;
      final prof = await SupabaseService.getProfile(sellerId);
      if (prof == null) return;
      // Build a readable address from detailed fields if available
      final parts = <String?>[
        prof['house_no']?.toString(),
        prof['street']?.toString(),
        prof['area']?.toString(),
        prof['village']?.toString(),
        prof['taluk']?.toString(),
        prof['district']?.toString(),
        prof['state']?.toString(),
        prof['country']?.toString(),
        prof['pincode']?.toString(),
      ].where((e) => e != null && e!.trim().isNotEmpty).map((e) => e!.trim()).toList();
      String address = parts.join(', ');
      if (address.isEmpty) {
        address = (prof['address'] as String?)?.trim() ?? '';
      }
      if (!mounted) return;
      setState(() {
        _farmerData = {
          ..._farmerData,
          'name': (prof['name'] ?? _farmerData['name'])?.toString() ?? _farmerData['name'],
          if (address.isNotEmpty) 'location': address,
          'phone': (prof['phone'] ?? '').toString(),
          'account_number': (prof['account_number'] ?? '').toString(),
          'ifsc': (prof['ifsc'] ?? '').toString(),
        };
        // Also mirror into product pickup for consistency when we have an address
        if (address.isNotEmpty) {
          _productData = {
            ..._productData,
            'pickup_address': address,
          };
        }
      });
    } catch (_) {
      // ignore profile lookup failures
    }
  }

  Future<void> _onEditPrice() async {
    final controller = TextEditingController(
      text: (_productData['price'] as double).toStringAsFixed(2),
    );

    final newPrice = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Price'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: '₹ '),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final v = double.tryParse(controller.text.trim());
              if (v != null && v > 0) {
                Navigator.pop(context, v);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newPrice == null) return;

    final id = (_productData['id'] ?? '').toString();
    if (id.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await SupabaseService.updateProduct(
        productId: id,
        data: {'price': newPrice},
      );
      if (!mounted) return;
      setState(() {
        _productData = {
          ..._productData,
          'price': newPrice,
        };
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Price updated')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update price: $e')),
      );
    }
  }

  Future<void> _onDeleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: const Text(
            'This will permanently remove the product. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final id = (_productData['id'] ?? '').toString();
    if (id.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await SupabaseService.deleteProduct(productId: id);
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pop(context); // Leave detail page after delete
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  // Product data defaults are neutral placeholders; real data should come from route args
  Map<String, dynamic> _productData = {
    "id": null,
    "name": "Product",
    "images": <String>[],
    "price": 0.0,
    "unit": "unit",
    "availableQuantity": 0,
    "isFresh": false,
    "isOrganic": false,
    "description": "",
    "harvestDate": "",
    "farmingMethod": "",
    "storageInstructions": "",
    "bulkPricing": <Map<String, dynamic>>[],
    "nutritionalInfo": <String, String>{},
  };

  Map<String, dynamic> _farmerData = {
    "id": null,
    "name": "Farmer",
    "profilePhoto": null,
    "isVerified": false,
    "distance": null,
    "rating": null,
    "reviewCount": null,
    "location": "",
    "farmSize": "",
    "experience": "",
    "phone": "",
    "account_number": "",
    "ifsc": "",
  };

  Future<void> _updateFarmerDistance() async {
    try {
      // Get user position: prefer saved address; fallback to GPS
      LatLng? userPos;
      final saved = await LocalStorage.loadAddress();
      if (saved != null) {
        final lat = (saved['lat'] as num?)?.toDouble();
        final lng = (saved['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          userPos = LatLng(lat, lng);
        }
      }
      if (userPos == null) {
        final pos = await GeoService.getCurrentPosition();
        userPos = LatLng(pos.latitude, pos.longitude);
      }

      // Resolve farmer coordinates
      LatLng? farmerPos;
      String farmerAddress = (_farmerData['location'] as String?) ?? '';
      final fLatNum = _farmerData['latitude'];
      final fLonNum = _farmerData['longitude'];
      final fLat = (fLatNum is num) ? fLatNum.toDouble() : null;
      final fLon = (fLonNum is num) ? fLonNum.toDouble() : null;
      if (fLat != null && fLon != null) {
        farmerPos = LatLng(fLat, fLon);
      } else {
        final pLatNum = _productData['latitude'];
        final pLonNum = _productData['longitude'];
        final pLat = (pLatNum is num) ? pLatNum.toDouble() : null;
        final pLon = (pLonNum is num) ? pLonNum.toDouble() : null;
        if (pLat != null && pLon != null) {
          farmerPos = LatLng(pLat, pLon);
        } else {
          if (farmerAddress.isEmpty) {
            farmerAddress = (_productData['pickup_address'] as String?) ?? '';
          }
          if (farmerAddress.isNotEmpty) {
            farmerPos = await GeoService.geocodeAddress(farmerAddress);
          }
        }
      }

      if (userPos != null && farmerPos != null && mounted) {
        final d = Distance();
        final meters = d.distance(userPos, farmerPos);
        final km = meters / 1000.0;
        setState(() {
          _farmerData = {
            ..._farmerData,
            'distance': km.toStringAsFixed(1),
            'latitude': farmerPos!.latitude,
            'longitude': farmerPos.longitude,
            if (farmerAddress.isNotEmpty) 'location': farmerAddress,
          };
        });
      }
    } catch (_) {
      // ignore errors; leave distance null
    }
  }

  void _onQuantityChanged(int quantity) {
    setState(() {
      _selectedQuantity = quantity;
    });
  }

  Future<void> _loadInCartQuantity() async {
    try {
      final items = await LocalStorage.loadCartItems();
      final String pid = (_productData['id'] ?? '').toString();
      int sum = 0;
      for (final m in items) {
        final id = (m['id'] ?? '').toString();
        if (id == pid) {
          final q = m['quantity'];
          if (q is num) sum += q.toInt();
        }
      }
      if (mounted) {
        setState(() {
          _inCartQuantityForThisProduct = sum;
          // also ensure current selection does not exceed remaining
          final maxQty = _effectiveAvailableQuantity;
          if (maxQty > 0 && _selectedQuantity > maxQty) {
            _selectedQuantity = maxQty;
          }
        });
      }
    } catch (_) {}
  }

  void _onAddToCart() {
    if (_selectedQuantity <= 0 || !_isInStock) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    Future.delayed(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      // Build cart item and persist
      final firstImage = ((_productData["images"] as List?)?.cast<String>() ?? const []).isNotEmpty
          ? ((_productData["images"] as List).first as String)
          : '';
      final addedItem = {
        'id': (_productData['id'] ?? '').toString(),
        'productName': _productData['name'],
        'farmerName': _farmerData['name'],
        'ownerId': _sellerId,
        'imageUrl': firstImage,
        'unitPrice': _productData['price'],
        'quantity': _selectedQuantity,
        'isInStock': true,
        'freshnessIndicator': 'Fresh',
        'availableQuantity': _productData['availableQuantity'] ?? 0,
        'unit': _productData['unit'],
        // Always use seller profile address when available
        'pickup_address': (_farmerData['location'] as String?).toString().isNotEmpty
            ? _farmerData['location']
            : _productData['pickup_address'],
        'latitude': _productData['latitude'] ?? _farmerData['latitude'],
        'longitude': _productData['longitude'] ?? _farmerData['longitude'],
      };

      final existing = await LocalStorage.loadCartItems();
      existing.add(addedItem);
      await LocalStorage.saveCartItems(existing);

      Navigator.pushNamed(context, AppRoutes.shoppingCart);
    });
  }

  Future<void> _onBuyNow() async {
    // Repurpose as Location: show user + farmer on map
    try {
      final pos = await GeoService.getCurrentPosition();
      final userLatLng = LatLng(pos.latitude, pos.longitude);
      LatLng? farmerLatLng;
      String farmerAddress = (_farmerData['location'] as String?) ?? '';

      // Prefer coordinates if available
      final latNum = _farmerData['latitude'];
      final lonNum = _farmerData['longitude'];
      final lat = (latNum is num) ? latNum.toDouble() : null;
      final lon = (lonNum is num) ? lonNum.toDouble() : null;
      if (lat != null && lon != null) {
        farmerLatLng = LatLng(lat, lon);
      } else {
        // Fallback to any coordinates on product object
        final platNum = _productData['latitude'];
        final plonNum = _productData['longitude'];
        final plat = (platNum is num) ? platNum.toDouble() : null;
        final plon = (plonNum is num) ? plonNum.toDouble() : null;
        if (plat != null && plon != null) {
          farmerLatLng = LatLng(plat, plon);
        } else {
          // Last resort: geocode the address string
          if (farmerAddress.isEmpty) {
            farmerAddress = (_productData['pickup_address'] as String?) ?? farmerAddress;
          }
          if (farmerAddress.isNotEmpty) {
            farmerLatLng = await GeoService.geocodeAddress(farmerAddress);
          }
        }
      }

      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => LocationMapSheet(
          userPosition: userLatLng,
          farmerPosition: farmerLatLng,
          farmerAddress: farmerAddress,
        ),
      );
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

  void _onChatWithFarmer() {
    final phone = (_farmerData['phone'] as String?)?.trim();
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Farmer phone number not available')), 
      );
      return;
    }
    // WhatsApp expects country code without '+' (e.g. 919876543210)
    WhatsAppService.openWhatsApp(
      phone,
      message: 'Hi! I am interested in your product ${_productData['name']}.',
    );
  }

  void _onShareProduct() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Product link copied to clipboard'),
        backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
      ),
    );
  }

  void _onFarmerProfileTap() {
    Navigator.pushNamed(context, AppRoutes.profilePage);
  }

  int get _availableQuantityRaw => (_productData["availableQuantity"] as int);

  int get _effectiveAvailableQuantity {
    final remaining = _availableQuantityRaw - _inCartQuantityForThisProduct;
    // Reserve 1 unit if more than 1 remains, so user can't take all and make it 0 immediately
    final reserve = remaining > 1 ? 1 : 0;
    final cap = remaining - reserve;
    return cap > 0 ? cap : 0;
  }

  bool get _isInStock => _effectiveAvailableQuantity > 0;

  double get _totalPrice =>
      (_productData["price"] as double) * _selectedQuantity;

  double get _averageRating => 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProductImageCarousel(
                      images: (_productData["images"] as List).cast<String>(),
                      productName: _productData["name"] as String,
                    ),
                    ProductInfoSection(productData: _productData),
                    FarmerInfoCard(
                      farmerData: _farmerData,
                      onTap: _onFarmerProfileTap,
                      showActions: (SupabaseService.currentUserId != null &&
                          SupabaseService.currentUserId == _sellerId),
                      onEditPrice: _onEditPrice,
                      onDelete: _onDeleteProduct,
                    ),
                    QuantitySelector(
                      initialQuantity: _selectedQuantity,
                      minQuantity: 1,
                      maxQuantity: _effectiveAvailableQuantity,
                      unit: _productData["unit"] as String,
                      onQuantityChanged: _onQuantityChanged,
                    ),
                    ExpandableSection(
                      title: 'Product Description',
                      showToggle: false,
                      initiallyExpanded: true,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _productData["description"] as String,
                            style: AppTheme.lightTheme.textTheme.bodyMedium,
                          ),
                          SizedBox(height: 2.h),
                          _buildProductDetails(),
                        ],
                      ),
                    ),
                    ExpandableSection(
                      title: 'Nutritional Information',
                      content: _buildNutritionalInfo(),
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: StickyBottomBar(
              isInStock: _isInStock,
              selectedQuantity: _selectedQuantity,
              totalPrice: _totalPrice,
              onAddToCart: _onAddToCart,
              onBuyNow: _onBuyNow,
              isOwner: (SupabaseService.currentUserId != null &&
                  SupabaseService.currentUserId == _sellerId),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      elevation: 1,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: CustomIconWidget(
          iconName: 'arrow_back',
          color: AppTheme.lightTheme.colorScheme.onSurface,
          size: 20, // smaller back icon
        ),
      ),
      title: Text(
        _productData["name"] as String,
        style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        IconButton(
          onPressed: _onChatWithFarmer,
          icon: const Icon(Icons.chat),
          color: Colors.green,
        ),
        IconButton(
          onPressed: _onShareProduct,
          icon: CustomIconWidget(
            iconName: 'share',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 20, // smaller share icon
          ),
        ),
      ],
    );
  }

  Widget _buildProductDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Harvest Date', _productData["harvestDate"] as String),
        _buildDetailRow(
            'Farming Method', _productData["farmingMethod"] as String),
        _buildDetailRow('Storage Instructions',
            _productData["storageInstructions"] as String),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 35.w,
            child: Text(
              '$label:',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionalInfo() {
    final nutritionalInfo =
        _productData["nutritionalInfo"] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: nutritionalInfo.entries.map((entry) {
        return _buildDetailRow(
          entry.key.replaceAll('_', ' ').toUpperCase(),
          entry.value as String,
        );
      }).toList(),
    );
  }
}
