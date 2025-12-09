import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import 'widgets/address_selection_widget.dart';
import 'widgets/cart_item_widget.dart';
import 'widgets/cart_summary_widget.dart';
import 'widgets/empty_cart_widget.dart';
import '../../services/local_storage.dart';
import '../common/map_picker.dart';
import 'package:farmmarket/services/supabase_service.dart';

class ShoppingCart extends StatefulWidget {
  const ShoppingCart({super.key});

  @override
  State<ShoppingCart> createState() => _ShoppingCartState();
}

class _ShoppingCartState extends State<ShoppingCart> {
  List<CartItem> _cartItems = [];
  String _selectedAddress = 'Select delivery address';
  double? _addressLat;
  double? _addressLng;
  String? _appliedPromoCode;
  double _promoDiscount = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Delay to access context arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['items'] is List) {
        final incoming = (args['items'] as List)
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _mergeAndSaveIncomingItems(incoming);
      }
      _loadCartData();
    });
  }

  CartItem _cartItemFromMap(Map data) {
    return CartItem(
      id: (data['id'] ?? UniqueKey().toString()).toString(),
      productName: (data['productName'] ?? data['name'] ?? 'Product').toString(),
      farmerName: (data['farmerName'] ?? 'Farmer').toString(),
      imageUrl: (data['imageUrl'] ?? data['image'] ?? '').toString(),
      ownerId: (data['ownerId'] as String?),
      latitude: (data['latitude'] is num)
          ? (data['latitude'] as num).toDouble()
          : (data['latitude'] != null
              ? double.tryParse(data['latitude'].toString())
              : null),
      longitude: (data['longitude'] is num)
          ? (data['longitude'] as num).toDouble()
          : (data['longitude'] != null
              ? double.tryParse(data['longitude'].toString())
              : null),
      unitPrice: (data['unitPrice'] is num)
          ? (data['unitPrice'] as num).toDouble()
          : double.tryParse(data['unitPrice']?.toString() ?? '0') ?? 0.0,
      quantity: (data['quantity'] is num)
          ? (data['quantity'] as num).toInt()
          : int.tryParse(data['quantity']?.toString() ?? '1') ?? 1,
      isInStock: (data['isInStock'] as bool?) ?? true,
      freshnessIndicator: (data['freshnessIndicator'] ?? 'Fresh').toString(),
      availableQuantity: (data['availableQuantity'] is num)
          ? (data['availableQuantity'] as num).toInt()
          : int.tryParse(data['availableQuantity']?.toString() ?? '0') ?? 0,
      unit: (data['unit'] ?? data['unitLabel'] ?? '').toString(),
    );
  }

  Future<void> _loadCartData() async {
    setState(() => _isLoading = true);
    final stored = await LocalStorage.loadCartItems();
    final address = await LocalStorage.loadAddress();
    // Map and clamp quantities to available stock
    final items = stored.map(_cartItemFromMap).toList();
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.availableQuantity > 0 && item.quantity > item.availableQuantity) {
        items[i] = item.copyWith(quantity: item.availableQuantity);
      }
    }
    setState(() {
      _cartItems = items;
      if (address != null) {
        _selectedAddress = (address['label'] as String?) ?? _selectedAddress;
        final lat = address['lat'];
        final lng = address['lng'];
        _addressLat = (lat is num) ? lat.toDouble() : null;
        _addressLng = (lng is num) ? lng.toDouble() : null;
      }
      _isLoading = false;
    });
    await _persistCart();
  }

  Future<void> _persistCart() async {
    final list = _cartItems
        .map((e) => {
              'id': e.id,
              'productName': e.productName,
              'farmerName': e.farmerName,
              'imageUrl': e.imageUrl,
              'ownerId': e.ownerId,
              'latitude': e.latitude,
              'longitude': e.longitude,
              'unitPrice': e.unitPrice,
              'quantity': e.quantity,
              'isInStock': e.isInStock,
              'freshnessIndicator': e.freshnessIndicator,
              'availableQuantity': e.availableQuantity,
              'unit': e.unit,
            })
        .toList();
    await LocalStorage.saveCartItems(list);
  }

  Future<void> _mergeAndSaveIncomingItems(List<Map<String, dynamic>> incoming) async {
    final existing = await LocalStorage.loadCartItems();
    existing.addAll(incoming);
    await LocalStorage.saveCartItems(existing);
  }

  Future<void> _confirmRemoveItem(String itemId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove item?'),
        content: const Text('Do you want to delete this item from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      _removeItem(itemId);
    }
  }

  void _removeItem(String itemId) {
    setState(() {
      _cartItems.removeWhere((item) => item.id == itemId);
    });
    _persistCart();
    _showSnackBar('Item removed from cart');
  }

  void _updateQuantity(String itemId, int newQuantity) {
    setState(() {
      final index = _cartItems.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        final maxQ = _cartItems[index].availableQuantity;
        final clamped = (maxQ > 0) ? newQuantity.clamp(1, maxQ) : newQuantity;
        _cartItems[index] = _cartItems[index].copyWith(quantity: clamped);
      }
    });
    _persistCart();

    // Haptic feedback for iOS
    HapticFeedback.lightImpact();
  }

  void _moveToWishlist(String itemId) {
    _removeItem(itemId);
    _showSnackBar('Item moved to wishlist');
  }

  void _shareItem(String itemId) {
    final item = _cartItems.firstWhere((item) => item.id == itemId);
    _showSnackBar('Sharing ${item.productName}...');
  }

  void _applyPromoCode(String promoCode) {
    setState(() {
      _appliedPromoCode = promoCode;
      // Simulate promo code validation and discount calculation
      if (promoCode.toUpperCase() == 'FRESH10') {
        _promoDiscount = _calculateSubtotal() * 0.1; // 10% discount
      } else {
        _promoDiscount = 5.0; // Fixed discount
      }
    });
    _showSnackBar('Promo code applied successfully!');
  }

  void _removePromoCode() {
    setState(() {
      _appliedPromoCode = null;
      _promoDiscount = 0.0;
    });
  }

  double _calculateSubtotal() {
    return _cartItems.fold(
        0, (sum, item) => sum + (item.unitPrice * item.quantity));
  }

  double _getDeliveryFee() {
    return 0.0;
  }

  double _calculateTax() {
    return 0.0;
  }

  bool _canProceedToCheckout() {
    return _cartItems.isNotEmpty && _cartItems.every((item) => item.isInStock);
  }

  Future<void> _confirmOrder() async {
    if (_canProceedToCheckout()) {
      // Show order confirmation message before navigating
      _showSnackBar('Order confirmed');
      // Prepare order id and buyer details
      final orderId = const Uuid().v4();
      String buyerEmail = SupabaseService.currentUserEmail ?? '';
      final buyerId = SupabaseService.currentUserId;
      // Fallback to profile email if session email is empty
      if ((buyerEmail.isEmpty) && buyerId != null) {
        final fromProfile = await SupabaseService.getUserEmailFromProfile(buyerId);
        if (fromProfile != null && fromProfile.isNotEmpty) {
          buyerEmail = fromProfile;
        }
      }
      // Push to buyer: Order Confirmed
      if (buyerId != null) {
        // ignore: unawaited_futures
        SupabaseService.sendPushToUser(
          userId: buyerId,
          title: 'Order Confirmed',
          body: 'Your order $orderId has been confirmed.',
          data: {
            'type': 'order_confirmed',
            'order_id': orderId,
          },
        );
      }
      // Email to buyer: Order Confirmed (registered email)
      if (buyerEmail.isNotEmpty) {
        final itemsForEmail = _cartItems
            .map((e) => {
                  'name': e.productName,
                  'quantity': e.quantity,
                  'price': (e.unitPrice * e.quantity),
                })
            .toList();
        final totalAmount = _cartItems.fold<double>(0.0, (sum, e) => sum + (e.unitPrice * e.quantity));
        await SupabaseService.sendBuyerOrderConfirmedEmail(
          buyerEmail: buyerEmail,
          orderId: orderId,
          items: List<Map<String, dynamic>>.from(itemsForEmail),
          totalAmount: totalAmount,
        );
      }
      // Notify owners and insert sales; decrement stock now (no zeroing)
      String? firstSellerId;
      for (final item in _cartItems) {
        try {
          if (item.ownerId != null && item.ownerId!.isNotEmpty) {
            firstSellerId ??= item.ownerId;
            await SupabaseService.sendOwnerEmail(
              ownerId: item.ownerId!,
              productName: item.productName,
              buyerEmail: buyerEmail,
            );
            // Push to owner: New Order confirmed
            // ignore: unawaited_futures
            SupabaseService.sendPushToUser(
              userId: item.ownerId!,
              title: 'New Order',
              body: 'Order $orderId confirmed for ${item.productName}',
              data: {
                'type': 'order_confirmed_owner',
                'order_id': orderId,
                'product_id': item.id,
              },
            );
          }

          // Insert a sale row
          await SupabaseService.insertSale(data: {
            'order_id': orderId,
            if (buyerId != null) 'buyer_id': buyerId,
            if (item.ownerId != null) 'seller_id': item.ownerId!,
            'product_id': item.id,
            'product_name': item.productName,
            'quantity': item.quantity,
            'line_total': item.unitPrice * item.quantity,
          });

          // Decrement stock immediately so remaining quantity reflects globally
          // ignore: unawaited_futures
          SupabaseService.decrementProductStock(
            productId: item.id,
            quantity: item.quantity,
          );
        } catch (_) {
          // ignore and continue for other items
        }
      }
      // Create/update order tracking record (new table, one seller per order; use first seller id)
      if (buyerId != null && firstSellerId != null) {
        try {
          await SupabaseService.upsertOrderTracking(
            orderId: orderId,
            buyerId: buyerId,
            sellerId: firstSellerId!,
            status: 'confirmed',
          );
        } catch (_) {
          // ignore order record failures; tracking screen will handle missing data gracefully
        }
      }
      if (!mounted) return;
      Navigator.pushNamed(context, AppRoutes.orderTracking, arguments: {
        'orderId': orderId,
        'buyerEmail': SupabaseService.currentUserEmail,
        'buyerId': SupabaseService.currentUserId,
        'items': _cartItems.map((e) => {
              'id': e.id,
              'name': e.productName,
              'imageUrl': e.imageUrl,
              'quantity': e.quantity,
              'price': (e.unitPrice * e.quantity),
              'farmerName': e.farmerName,
              if (e.ownerId != null) 'ownerId': e.ownerId,
              if (e.latitude != null) 'latitude': e.latitude,
              if (e.longitude != null) 'longitude': e.longitude,
            }).toList(),
      });
    }
  }

  void _continueShopping() {
    Navigator.pushNamed(context, AppRoutes.consumerMarketplace);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Shopping Cart',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_cartItems.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: Stack(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.shopping_cart),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        _cartItems.length.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
              ? EmptyCartWidget(onBrowseProducts: _continueShopping)
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          setState(() {
                            _isLoading = true;
                          });
                          _loadCartData();
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              // Address Selection
                              AddressSelectionWidget(
                                selectedAddress: _selectedAddress,
                                onAddressSelected: (address) {
                                  setState(() {
                                    _selectedAddress = address;
                                  });
                                },
                                onEditAddress: () async {
                                  final result = await Navigator.of(context).push<Map<String, dynamic>?>(
                                    MaterialPageRoute(
                                      builder: (_) => const MapPicker(),
                                    ),
                                  );
                                  if (result != null && mounted) {
                                    final lat = (result['lat'] as num?)?.toDouble();
                                    final lng = (result['lng'] as num?)?.toDouble();
                                    final address = (result['address'] as String?) ?? 'Selected location';
                                    setState(() {
                                      _addressLat = lat;
                                      _addressLng = lng;
                                      _selectedAddress = address;
                                    });
                                    await LocalStorage.saveAddress({
                                      'label': address,
                                      'lat': lat,
                                      'lng': lng,
                                    });
                                    final userId = SupabaseService.currentUserId;
                                    if (userId != null && lat != null && lng != null) {
                                      // ignore: unawaited_futures
                                      SupabaseService.upsertUserLocation(
                                        userId: userId,
                                        lat: lat,
                                        lng: lng,
                                        label: address,
                                      );
                                    }
                                  }
                                },
                              ),

                              // Delivery options removed

                              // Cart Items
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _cartItems.length,
                                itemBuilder: (context, index) {
                                  final item = _cartItems[index];
                                  return CartItemWidget(
                                    productId: item.id,
                                    productName: item.productName,
                                    farmerName: item.farmerName,
                                    imageUrl: item.imageUrl,
                                    unitPrice: item.unitPrice,
                                    quantity: item.quantity,
                                    isInStock: item.isInStock,
                                    freshnessIndicator: item.freshnessIndicator,
                                    maxQuantity: item.availableQuantity,
                                    unit: item.unit,
                                    onRemove: () => _confirmRemoveItem(item.id),
                                    onQuantityChanged: (quantity) =>
                                        _updateQuantity(item.id, quantity),
                                    onMoveToWishlist: () =>
                                        _moveToWishlist(item.id),
                                    onShare: () => _shareItem(item.id),
                                  );
                                },
                              ),

                              const SizedBox(
                                  height: 100), // Space for bottom bar
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
      bottomSheet: _cartItems.isNotEmpty
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CartSummaryWidget(
                  subtotal: _calculateSubtotal(),
                  deliveryFee: _getDeliveryFee(),
                  taxAmount: _calculateTax(),
                  discount: _promoDiscount,
                  promoCode: _appliedPromoCode,
                  onPromoCodeApplied: _applyPromoCode,
                  onPromoCodeRemoved: _removePromoCode,
                  showPromoSection: false,
                ),

                // Sticky Bottom Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: _continueShopping,
                        child: Text(
                          'Continue Shopping',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              _canProceedToCheckout() ? _confirmOrder : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Confirm Order',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : null,
    );
  }
}

class CartItem {
  final String id;
  final String productName;
  final String farmerName;
  final String imageUrl;
  final String? ownerId;
  final double? latitude;
  final double? longitude;
  final double unitPrice;
  final int quantity;
  final bool isInStock;
  final String freshnessIndicator;
  final int availableQuantity;
  final String unit;

  CartItem({
    required this.id,
    required this.productName,
    required this.farmerName,
    required this.imageUrl,
    this.ownerId,
    this.latitude,
    this.longitude,
    required this.unitPrice,
    required this.quantity,
    this.isInStock = true,
    this.freshnessIndicator = 'Fresh',
    this.availableQuantity = 0,
    this.unit = '',
  });

  CartItem copyWith({
    String? id,
    String? productName,
    String? farmerName,
    String? imageUrl,
    String? ownerId,
    double? latitude,
    double? longitude,
    double? unitPrice,
    int? quantity,
    bool? isInStock,
    String? freshnessIndicator,
    int? availableQuantity,
    String? unit,
  }) {
    return CartItem(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      farmerName: farmerName ?? this.farmerName,
      imageUrl: imageUrl ?? this.imageUrl,
      ownerId: ownerId ?? this.ownerId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      isInStock: isInStock ?? this.isInStock,
      freshnessIndicator: freshnessIndicator ?? this.freshnessIndicator,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      unit: unit ?? this.unit,
    );
  }
}
