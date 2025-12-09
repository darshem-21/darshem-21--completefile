import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../services/supabase_service.dart';

class OrdersOverviewPage extends StatefulWidget {
  const OrdersOverviewPage({super.key});

  @override
  State<OrdersOverviewPage> createState() => _OrdersOverviewPageState();
}

class _OrdersOverviewPageState extends State<OrdersOverviewPage> {
  bool _soldExpanded = true;
  bool _boughtExpanded = true;

  @override
  Widget build(BuildContext context) {
    final me = SupabaseService.currentUserId;
    if (me == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Order Tracking',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: Text(
            'Please log in to view your orders.',
            style: GoogleFonts.inter(),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order Tracking',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: SupabaseService.streamSales(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final rows = snapshot.data ?? const [];
          if (rows.isEmpty) {
            return Center(
              child: Text(
                'No orders yet',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            );
          }

          final soldOrders = _groupOrders(rows.where((r) => r['seller_id'] == me));
          final boughtOrders = _groupOrders(rows.where((r) => r['buyer_id'] == me));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader('SOLD', Icons.shopping_bag, _soldExpanded, () {
                setState(() {
                  _soldExpanded = !_soldExpanded;
                });
              }),
              if (_soldExpanded)
                _buildOrderList(context, soldOrders, isSellerView: true),
              const SizedBox(height: 24),
              _buildSectionHeader('BOUGHT', Icons.receipt_long, _boughtExpanded, () {
                setState(() {
                  _boughtExpanded = !_boughtExpanded;
                });
              }),
              if (_boughtExpanded)
                _buildOrderList(context, boughtOrders, isSellerView: false),
            ],
          );
        },
      ),
    );
  }

  List<_OrderSummary> _groupOrders(Iterable<Map<String, dynamic>> rows) {
    final byOrderId = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      final orderId = (row['order_id'] ?? '').toString();
      if (orderId.isEmpty) continue;
      byOrderId.putIfAbsent(orderId, () => []).add(row);
    }
    final result = <_OrderSummary>[];
    byOrderId.forEach((orderId, items) {
      final first = items.first;
      final buyerId = (first['buyer_id'] ?? '').toString();
      final sellerId = (first['seller_id'] ?? '').toString();
      final totalAmount = items.fold<double>(0.0, (sum, it) {
        final val = it['line_total'];
        if (val is num) return sum + val.toDouble();
        return sum + (double.tryParse(val?.toString() ?? '0') ?? 0.0);
      });
      final productName = (first['product_name'] ?? 'Items').toString();
      final itemCount = items.length;
      result.add(
        _OrderSummary(
          orderId: orderId,
          buyerId: buyerId,
          sellerId: sellerId,
          productName: productName,
          itemCount: itemCount,
          totalAmount: totalAmount,
          items: items,
        ),
      );
    });
    result.sort((a, b) => b.orderId.compareTo(a.orderId));
    return result;
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    bool expanded,
    VoidCallback onToggle,
  ) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
          onPressed: onToggle,
        ),
      ],
    );
  }

  Widget _buildOrderList(
    BuildContext context,
    List<_OrderSummary> orders, {
    required bool isSellerView,
  }) {
    if (orders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          isSellerView ? 'No sold orders yet' : 'No purchased orders yet',
          style: GoogleFonts.inter(color: Colors.grey),
        ),
      );
    }
    return Column(
      children: orders.map((o) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            onTap: () => _openOrderDetail(context, o, isSellerView: isSellerView),
            title: Text(
              o.productName,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Order ${o.orderId} • ${o.itemCount} item${o.itemCount > 1 ? 's' : ''} • ₹${o.totalAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                const SizedBox(height: 4),
                FutureBuilder<String?>(
                  future: SupabaseService.getOrderTrackingStatus(o.orderId),
                  builder: (context, snapshot) {
                    final status = snapshot.data;
                    return Text(
                      _formatStatusText(status),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),
                isSellerView
                    ? _VerticalTimeline()
                    : _HorizontalTimeline(),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  tooltip: 'Delete order',
                  onPressed: () async {
                    final shouldDelete = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete this order?'),
                        content: const Text('This will remove the order from your list.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Keep'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (shouldDelete == true) {
                      await SupabaseService.deleteOrderAndSales(orderId: o.orderId);
                    }
                  },
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _openOrderDetail(BuildContext context, _OrderSummary summary, {required bool isSellerView}) async {
    final itemsForTracking = <Map<String, dynamic>>[];
    for (int i = 0; i < summary.items.length; i++) {
      final row = summary.items[i];
      final productId = (row['product_id'] ?? '').toString();
      String? imageUrl;
      if (productId.isNotEmpty) {
        imageUrl = await SupabaseService.getFirstProductImageUrl(productId);
      }
      double? sellerLat;
      double? sellerLon;
      if (i == 0 && productId.isNotEmpty) {
        final coords = await SupabaseService.getProductCoords(productId);
        if (coords != null) {
          sellerLat = coords['lat'];
          sellerLon = coords['lon'];
        }
      }

      itemsForTracking.add({
        'id': productId,
        'name': (row['product_name'] ?? 'Item').toString(),
        'imageUrl': imageUrl ?? '',
        'quantity': (row['quantity'] is num)
            ? (row['quantity'] as num).toInt()
            : int.tryParse(row['quantity']?.toString() ?? '1') ?? 1,
        'price': (row['line_total'] is num)
            ? (row['line_total'] as num).toDouble()
            : double.tryParse(row['line_total']?.toString() ?? '0') ?? 0.0,
        'farmerName': '',
        if ((summary.sellerId).isNotEmpty) 'ownerId': summary.sellerId,
        if (i == 0 && sellerLat != null && sellerLon != null) 'latitude': sellerLat,
        if (i == 0 && sellerLat != null && sellerLon != null) 'longitude': sellerLon,
      });
    }

    if (!mounted) return;
    Navigator.pushNamed(
      context,
      AppRoutes.orderTracking,
      arguments: {
        'orderId': summary.orderId,
        'buyerEmail': '',
        'buyerId': summary.buyerId,
        'items': itemsForTracking,
        'viewAsSeller': isSellerView,
      },
    );
  }

  String _formatStatusText(String? status) {
    switch (status) {
      case 'packed':
        return 'Packed';
      case 'payment_confirmation':
        return 'Payment Confirmation';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'ready_for_pickup':
        return 'Ready for Pickup';
      case 'preparing':
        return 'Preparing';
      case 'rejected':
        return 'Rejected';
      case 'confirmed':
        return 'Confirmed';
      default:
        return 'Status: Pending';
    }
  }
}

class _OrderSummary {
  final String orderId;
  final String buyerId;
  final String sellerId;
  final String productName;
  final int itemCount;
  final double totalAmount;
  final List<Map<String, dynamic>> items;

  _OrderSummary({
    required this.orderId,
    required this.buyerId,
    required this.sellerId,
    required this.productName,
    required this.itemCount,
    required this.totalAmount,
    required this.items,
  });
}

class _HorizontalTimeline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _TimelineDot(completed: true),
        _TimelineLine(),
        _TimelineDot(completed: true),
        _TimelineLine(),
        _TimelineDot(completed: true),
        _TimelineLine(),
        _TimelineDot(completed: true),
      ],
    );
  }
}

class _VerticalTimeline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Column(
              children: [
                _TimelineDot(completed: true),
                _TimelineLine(vertical: true),
                _TimelineDot(completed: true),
                _TimelineLine(vertical: true),
                _TimelineDot(completed: true),
                _TimelineLine(vertical: true),
                _TimelineDot(completed: true),
              ],
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Confirmed', style: GoogleFonts.inter(fontSize: 11)),
                const SizedBox(height: 6),
                Text('Packed', style: GoogleFonts.inter(fontSize: 11)),
                const SizedBox(height: 6),
                Text('Out for delivery', style: GoogleFonts.inter(fontSize: 11)),
                const SizedBox(height: 6),
                Text('Delivered', style: GoogleFonts.inter(fontSize: 11)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _TimelineDot extends StatelessWidget {
  final bool completed;

  const _TimelineDot({required this.completed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: completed ? Colors.green : Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _TimelineLine extends StatelessWidget {
  final bool vertical;

  const _TimelineLine({this.vertical = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: vertical ? 2 : 16,
      height: vertical ? 12 : 2,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}
