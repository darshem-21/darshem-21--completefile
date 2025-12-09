import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:farmmarket/services/supabase_service.dart';
import 'package:farmmarket/presentation/consumer_marketplace/widgets/users_map_page.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  static const _allowedEmails = {
    'jjsmithun@gmail.com',
    'darshanks343@gmail.com',
  };

  bool _isAllowed() {
    final email = SupabaseService.currentUserEmail;
    return email != null && _allowedEmails.contains(email);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAllowed()) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: const SizedBox.shrink(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on, color: Colors.white),
            tooltip: 'User locations',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UsersMapPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Top metrics: registered users, buyers, sellers, sold, in-stock
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: SupabaseService.streamProducts(),
              builder: (context, prodSnap) {
                final products = prodSnap.data ?? const [];
                // Compute visibility aligned with Home feed
                final now = DateTime.now();
                bool isExpired(Map<String, dynamic> row) {
                  final stockVal = row['stock'];
                  final stock = (stockVal is num) ? stockVal.toInt() : int.tryParse('${stockVal ?? 0}') ?? 0;
                  final updatedAtStr = (row['updated_at'] ?? row['created_at'])?.toString();
                  final updatedAt = DateTime.tryParse(updatedAtStr ?? '');
                  return stock <= 0 && updatedAt != null && now.difference(updatedAt).inMinutes >= 1;
                }
                final visibleProducts = products.where((p) => (p['status']?.toString() ?? 'active') == 'active' && !isExpired(Map<String, dynamic>.from(p))).toList();
                // Apply Home page default price window (₹0..₹1000)
                double _priceOf(Map p) {
                  final v = p['price'];
                  return (v is num) ? v.toDouble() : double.tryParse('${v ?? 0}') ?? 0.0;
                }
                final priceFiltered = visibleProducts.where((p) {
                  final pr = _priceOf(p);
                  return pr >= 0 && pr <= 1000.0;
                }).toList();
                final sellers = priceFiltered.map((e) => e['seller_id']?.toString()).whereNotNull().toSet();
                final inStockCount = priceFiltered.where((p) {
                  final stock = p['stock'];
                  final s = (stock is num) ? stock.toInt() : int.tryParse('${stock ?? 0}') ?? 0;
                  return s > 0;
                }).length;

                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: SupabaseService.streamSales(),
                  builder: (context, saleSnap) {
                    final sales = saleSnap.data ?? const [];
                    final buyers = sales.map((e) => e['buyer_id']?.toString()).whereNotNull().toSet();
                    final soldProductsFromSales = sales
                        .map((e) => e['product_id']?.toString() ?? '')
                        .where((id) => id.isNotEmpty)
                        .toSet()
                        .length;
                    final totalRevenue = sales.fold<double>(0.0, (sum, s) {
                      final v = s['line_total'];
                      return sum + ((v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0);
                    });

                    return StreamBuilder<List<Map<String, dynamic>>> (
                      stream: SupabaseService.streamProfiles(),
                      builder: (context, profSnap) {
                        final profiles = profSnap.data ?? const [];
                        final registeredUsers = profiles.length;
                        // Participants (buyers & sellers) combined tile
                        final participants = <String>{...buyers, ...sellers}
                            .where((e) => e.isNotEmpty)
                            .toSet();
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _metric('Total Users', registeredUsers.toString(), icon: Icons.group, color: Colors.indigo),
                            _metric('Buyers & Sellers', participants.length.toString(), icon: Icons.people_alt_outlined, color: Colors.teal),
                            _metric('Products Sold', soldProductsFromSales.toString(), icon: Icons.check_circle, color: Colors.green),
                            _metric('In Stock', inStockCount.toString(), icon: Icons.inventory_2, color: Colors.orange),
                            _metric('Total Revenue', totalRevenue.toStringAsFixed(2), icon: Icons.payments, color: Colors.pink),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            // Category wise counts
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: SupabaseService.streamProducts(),
                builder: (context, snapshot) {
                  final products = snapshot.data ?? const [];
                  // Compute visibility aligned with Home feed
                  final now2 = DateTime.now();
                  bool isExpired2(Map<String, dynamic> row) {
                    final stockVal = row['stock'];
                    final stock = (stockVal is num) ? stockVal.toInt() : int.tryParse('${stockVal ?? 0}') ?? 0;
                    final updatedAtStr = (row['updated_at'] ?? row['created_at'])?.toString();
                    final updatedAt = DateTime.tryParse(updatedAtStr ?? '');
                    return stock <= 0 && updatedAt != null && now2.difference(updatedAt).inMinutes >= 1;
                  }
                  final visible = products.where((p) => (p['status']?.toString() ?? 'active') == 'active' && !isExpired2(Map<String, dynamic>.from(p))).toList();
                  final byCategory = groupBy<Map<String, dynamic>, String>(
                    visible,
                    (p) => (p['category']?.toString() ?? 'Others'),
                  );
                  final entries = byCategory.entries.toList()
                    ..sort((a, b) => a.key.compareTo(b.key));

                  return ListView(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Category Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                      ...entries.map((e) {
                        final sold = e.value.where((p) {
                          final stock = p['stock'];
                          final s = (stock is num) ? stock.toInt() : int.tryParse('${stock ?? 0}') ?? 0;
                          return s <= 0;
                        }).length;
                        final total = e.value.length;
                        final instock = total - sold;
                        return ListTile(
                          title: Text(e.key),
                          subtitle: Text('Total: $total  •  Sold: $sold  •  In stock: $instock'),
                        );
                      }),
                      const Divider(height: 24),
                      const Text('Monthly Sales', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: SupabaseService.streamSales(),
                        builder: (context, saleSnap) {
                          final sales = saleSnap.data ?? const [];
                          // group by YYYY-MM
                          final months = <String, double>{};
                          for (final s in sales) {
                            final createdAt = DateTime.tryParse('${s['created_at'] ?? ''}');
                            final total = (s['line_total'] is num)
                                ? (s['line_total'] as num).toDouble()
                                : double.tryParse('${s['line_total'] ?? 0}') ?? 0.0;
                            if (createdAt == null) continue;
                            final key = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';
                            months[key] = (months[key] ?? 0) + total;
                          }
                          final monthEntries = months.entries.toList()
                            ..sort((a, b) => a.key.compareTo(b.key));
                          if (monthEntries.isEmpty) {
                            return const Text('No sales yet');
                          }
                          // Revenue by seller
                          final bySeller = <String, double>{};
                          // Best-selling products (by quantity)
                          final byProductQty = <String, int>{};
                          // Weekly trend (last 8 weeks): YYYY-WW
                          final byWeek = <String, double>{};

                          for (final s in sales) {
                            final seller = (s['seller_id'] ?? '').toString();
                            final productName = (s['product_name'] ?? '').toString();
                            final qty = (s['quantity'] is num)
                                ? (s['quantity'] as num).toInt()
                                : int.tryParse('${s['quantity'] ?? 0}') ?? 0;
                            final line = (s['line_total'] is num)
                                ? (s['line_total'] as num).toDouble()
                                : double.tryParse('${s['line_total'] ?? 0}') ?? 0.0;
                            final createdAt = DateTime.tryParse('${s['created_at'] ?? ''}');

                            if (seller.isNotEmpty) {
                              bySeller[seller] = (bySeller[seller] ?? 0) + line;
                            }
                            if (productName.isNotEmpty) {
                              byProductQty[productName] = (byProductQty[productName] ?? 0) + qty;
                            }
                            if (createdAt != null) {
                              // ISO week key
                              final weekOfYear = ((DateTime(createdAt.year, 1, 1).weekday <= 4)
                                  ? 1
                                  : 0) + ((createdAt.difference(DateTime(createdAt.year, 1, 1)).inDays + DateTime(createdAt.year, 1, 1).weekday) / 7).floor();
                              final weekKey = '${createdAt.year}-W${weekOfYear.toString().padLeft(2, '0')}';
                              byWeek[weekKey] = (byWeek[weekKey] ?? 0) + line;
                            }
                          }

                          final topSellers = bySeller.entries.toList()
                            ..sort((a, b) => b.value.compareTo(a.value));
                          final bestProducts = byProductQty.entries.toList()
                            ..sort((a, b) => b.value.compareTo(a.value));
                          final weekEntries = byWeek.entries.toList()
                            ..sort((a, b) => a.key.compareTo(b.key));

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Monthly totals list
                              ...monthEntries.map((e) => ListTile(
                                dense: true,
                                title: Text(e.key),
                                trailing: Text(e.value.toStringAsFixed(2)),
                              )),
                              const SizedBox(height: 16),
                              const Text('Revenue by Seller', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              ...topSellers.take(10).map((e) => ListTile(
                                dense: true,
                                title: Text(e.key),
                                trailing: Text(e.value.toStringAsFixed(2)),
                              )),
                              const SizedBox(height: 16),
                              const Text('Best-selling Products (Qty)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              ...bestProducts.take(10).map((e) => ListTile(
                                dense: true,
                                title: Text(e.key),
                                trailing: Text(e.value.toString()),
                              )),
                              const SizedBox(height: 16),
                              const Text('Weekly Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              ...weekEntries.take(8).map((e) => ListTile(
                                dense: true,
                                title: Text(e.key),
                                trailing: Text(e.value.toStringAsFixed(2)),
                              )),
                              const SizedBox(height: 16),
                              const Text('Fast Moving Products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              // Aggregate sales by product_id to compute qty and revenue
                              Builder(builder: (context) {
                                final byProd = <String, Map<String, dynamic>>{}; // id -> {name, qty, revenue}
                                for (final s in sales) {
                                  final pid = (s['product_id'] ?? '').toString();
                                  final pname = (s['product_name'] ?? '').toString();
                                  final qty = (s['quantity'] is num) ? (s['quantity'] as num).toInt() : int.tryParse('${s['quantity'] ?? 0}') ?? 0;
                                  final line = (s['line_total'] is num) ? (s['line_total'] as num).toDouble() : double.tryParse('${s['line_total'] ?? 0}') ?? 0.0;
                                  if (pid.isEmpty) continue;
                                  final acc = byProd.putIfAbsent(pid, () => {'name': pname, 'qty': 0, 'revenue': 0.0});
                                  acc['qty'] = (acc['qty'] as int) + qty;
                                  acc['revenue'] = (acc['revenue'] as double) + line;
                                }
                                final items = byProd.entries.toList()
                                  ..sort((a, b) => (b.value['qty'] as int).compareTo(a.value['qty'] as int));
                                if (items.isEmpty) return const Text('No sales yet');
                                // Join with products and profiles to show current stock and seller name
                                return StreamBuilder<List<Map<String, dynamic>>>(
                                  stream: SupabaseService.streamProfiles(),
                                  builder: (context, profSnap2) {
                                    final profiles = profSnap2.data ?? const [];
                                    final nameById = { for (final p in profiles) (p['id']?.toString() ?? ''): (p['name']?.toString() ?? '') };
                                    return StreamBuilder<List<Map<String, dynamic>>>(
                                      stream: SupabaseService.streamProducts(),
                                      builder: (context, prodSnap3) {
                                        final prodsAll = prodSnap3.data ?? const [];
                                        // Show only visible products, aligned with Home feed
                                        final now3 = DateTime.now();
                                        bool isExpired3(Map<String, dynamic> row) {
                                          final stockVal = row['stock'];
                                          final stock = (stockVal is num) ? stockVal.toInt() : int.tryParse('${stockVal ?? 0}') ?? 0;
                                          final updatedAtStr = (row['updated_at'] ?? row['created_at'])?.toString();
                                          final updatedAt = DateTime.tryParse(updatedAtStr ?? '');
                                          return stock <= 0 && updatedAt != null && now3.difference(updatedAt).inMinutes >= 1;
                                        }
                                        final prods = prodsAll.where((p) => (p['status']?.toString() ?? 'active') == 'active' && !isExpired3(Map<String, dynamic>.from(p))).toList();
                                        final prodById = { for (final p in prods) (p['id']?.toString() ?? ''): p };
                                        return Column(
                                          children: items.take(10).map((e) {
                                            final id = e.key;
                                            final data = e.value;
                                            final prod = prodById[id];
                                            final sellerId = (prod?['seller_id']?.toString() ?? '');
                                            final sellerName = nameById[sellerId] ?? sellerId;
                                            final stockVal = prod?['stock'];
                                            final stock = (stockVal is num) ? stockVal.toInt() : int.tryParse('${stockVal ?? 0}') ?? 0;
                                            return ListTile(
                                              dense: true,
                                              title: Text('${data['name']}'),
                                              subtitle: Text('Seller: $sellerName'),
                                              trailing: Text('Sold: ${data['qty']}  •  Rev: ${(data['revenue'] as double).toStringAsFixed(2)}  •  Stock: $stock'),
                                            );
                                          }).toList(),
                                        );
                                      },
                                    );
                                  },
                                );
                              }),
                              const SizedBox(height: 16),
                              const Text('All Products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              StreamBuilder<List<Map<String, dynamic>>>(
                                stream: SupabaseService.streamProfiles(),
                                builder: (context, profSnap) {
                                  final profiles = profSnap.data ?? const [];
                                  final nameById = { for (final p in profiles) (p['id']?.toString() ?? ''): (p['name']?.toString() ?? '') };
                                  return StreamBuilder<List<Map<String, dynamic>>>(
                                    stream: SupabaseService.streamProducts(),
                                    builder: (context, prodSnap2) {
                                      final prodsAll = prodSnap2.data ?? const [];
                                      // Apply same home visibility
                                      final now4 = DateTime.now();
                                      bool isExpired4(Map<String, dynamic> row) {
                                        final stockVal = row['stock'];
                                        final stock = (stockVal is num) ? stockVal.toInt() : int.tryParse('${stockVal ?? 0}') ?? 0;
                                        final updatedAtStr = (row['updated_at'] ?? row['created_at'])?.toString();
                                        final updatedAt = DateTime.tryParse(updatedAtStr ?? '');
                                        return stock <= 0 && updatedAt != null && now4.difference(updatedAt).inMinutes >= 1;
                                      }
                                      final prods = prodsAll.where((p) => (p['status']?.toString() ?? 'active') == 'active' && !isExpired4(Map<String, dynamic>.from(p))).toList();
                                      if (prods.isEmpty) return const Text('No products');
                                      return Column(
                                        children: prods.map((p) {
                                          final sellerId = (p['seller_id']?.toString() ?? '');
                                          final sellerName = (nameById[sellerId] ?? sellerId);
                                          final name = (p['name']?.toString() ?? 'Product');
                                          final cat = (p['category']?.toString() ?? 'Others');
                                          final stock = (p['stock'] is num)
                                              ? (p['stock'] as num).toInt()
                                              : int.tryParse('${p['stock'] ?? 0}') ?? 0;
                                          final status = stock <= 0 ? 'Sold' : 'In stock: $stock';
                                          return ListTile(
                                            dense: true,
                                            title: Text(name),
                                            subtitle: Text('Seller: $sellerName  •  Category: $cat'),
                                            trailing: Text(status),
                                          );
                                        }).toList(),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String title, String value, {IconData icon = Icons.analytics, Color? color}) {
    final Color base = color ?? Colors.blueGrey;
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: base.withOpacity(0.08),
        border: Border.all(color: base.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: base.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: base, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: base.withOpacity(0.9))),
                const SizedBox(height: 6),
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: base)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
