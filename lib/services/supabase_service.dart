import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseClient _client = Supabase.instance.client;
  // Toggle for emailing. Set to true only if you want to send emails via Edge Functions.
  static bool sendEmails = true;

  // Helpers
  static Map<String, dynamic> _stripNulls(Map<String, dynamic> data) {
    final out = <String, dynamic>{};
    data.forEach((key, value) {
      if (value != null) out[key] = value;
    });
    return out;
  }

  // Profile UPI helpers
  static Future<String?> getProfileUpiId(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select('upi_id')
          .eq('id', userId)
          .maybeSingle();
      final upi = (data?['upi_id'] as String?)?.trim();
      return (upi != null && upi.isNotEmpty) ? upi : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> updateProfileUpiId({required String userId, required String upiId}) async {
    await upsertProfile(userId: userId, data: {'upi_id': upiId.trim()});
  }

  // Payment proofs (table: payment_proofs with columns id (uuid), order_id (text), url (text), created_at (timestamptz))
  static Future<void> insertPaymentProof({required String orderId, required String url}) async {
    try {
      await _client.from('payment_proofs').insert({
        'order_id': orderId,
        'url': url,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }

  static Future<List<String>> listPaymentProofs(String orderId) async {
    try {
      final rows = await _client
          .from('payment_proofs')
          .select('url')
          .eq('order_id', orderId)
          .order('created_at') as List<dynamic>;
      return rows.map<String>((e) => (e['url'] ?? '').toString()).where((u) => u.isNotEmpty).toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<int?> _getProductStock(String productId) async {
    try {
      final data = await _client
          .from('products')
          .select('stock')
          .eq('id', productId)
          .maybeSingle();
      final raw = data?['stock'];
      if (raw is num) return raw.toInt();
      return int.tryParse(raw?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  static Future<void> decrementProductStock({
    required String productId,
    required int quantity,
  }) async {
    try {
      final current = await _getProductStock(productId);
      if (current == null) return;
      final newStock = (current - quantity);
      final safe = newStock < 0 ? 0 : newStock;
      await updateProduct(productId: productId, data: {'stock': safe});
    } catch (_) {
      // ignore; stock will sync later if operation is restricted
    }
  }

  static Future<Map<String, double>?> getProductCoords(String productId) async {
    try {
      final data = await _client
          .from('products')
          .select('latitude, longitude')
          .eq('id', productId)
          .maybeSingle();
      if (data == null) return null;
      final latRaw = data['latitude'];
      final lonRaw = data['longitude'];
      final lat = (latRaw is num) ? latRaw.toDouble() : double.tryParse(latRaw?.toString() ?? '');
      final lon = (lonRaw is num) ? lonRaw.toDouble() : double.tryParse(lonRaw?.toString() ?? '');
      if (lat == null || lon == null) return null;
      return {'lat': lat, 'lon': lon};
    } catch (_) {
      return null;
    }
  }

  // Build a single-line address string from profile fields
  static String composeAddressFromProfile(Map<String, dynamic> profile) {
    final parts = <String?>[
      profile['house_no']?.toString(),
      profile['street']?.toString(),
      profile['area']?.toString(),
      profile['village']?.toString(),
      profile['taluk']?.toString(),
      profile['district']?.toString(),
      profile['state']?.toString(),
      profile['country']?.toString(),
      profile['pincode']?.toString(),
    ].where((e) => e != null && e!.trim().isNotEmpty).map((e) => e!.trim()).toList();
    final detailed = parts.join(', ');
    if (detailed.isNotEmpty) return detailed;
    return (profile['address'] as String?)?.trim() ?? '';
  }

  // Update all products of an owner to reflect the latest profile address as pickup_address.
  // If overwrite=false, only fills when pickup_address is null or empty.
  static Future<void> syncOwnerPickupAddress(String ownerId, {bool overwrite = false}) async {
    try {
      final prof = await getProfile(ownerId);
      if (prof == null) return;
      final address = composeAddressFromProfile(prof);
      if (address.isEmpty) return;
      var builder = _client
          .from('products')
          .update({'pickup_address': address, 'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('seller_id', ownerId);
      if (!overwrite) {
        // Only update rows where pickup_address is null or empty string
        builder = builder.or('pickup_address.is.null,pickup_address.eq.');
      }
      await builder;
    } catch (_) {
      // ignore sync failures
    }
  }

  static Future<String?> getUserEmailFromProfile(String userId) async {
    try {
      final profile = await getProfile(userId);
      final email = (profile?['email'] as String?)?.trim();
      if (email != null && email.isNotEmpty) return email;
    } catch (_) {}
    return null;
  }

  // PUSH notifications via Edge Function
  static Future<void> updateDeviceToken({
    required String userId,
    required String deviceToken,
    required String platform,
  }) async {
    try {
      await upsertProfile(userId: userId, data: {
        'device_token': deviceToken,
        'device_platform': platform,
      });
    } catch (_) {}
  }

  static Future<void> sendPushToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (userId.isEmpty) return;
    int attempt = 0;
    const fnNames = ['send-push', 'send_push', 'push-send'];
    while (true) {
      try {
        final fn = fnNames[attempt % fnNames.length];
        await _client.functions.invoke(
          fn,
          body: {
            'target_user_id': userId,
            'title': title,
            'body': body,
            if (data != null) 'data': data,
          },
        );
        return;
      } catch (e) {
        attempt++;
        // ignore: avoid_print
        print('[sendPushToUser] attempt=$attempt error: $e');
        if (attempt >= 6) return;
        await Future.delayed(const Duration(milliseconds: 800));
      }
    }
  }

  // PROFILES stream (for admin: registered users count, seller names lookup)
  static Stream<List<Map<String, dynamic>>> streamProfiles() {
    try {
      final stream = _client.from('profiles').stream(primaryKey: ['id']);
      final typed = stream as Stream<List<dynamic>>;
      return typed.map((rows) => rows
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList());
    } catch (_) {
      return const Stream<List<Map<String, dynamic>>>.empty();
    }
  }

  static Future<void> markProductSold({
    required String productId,
  }) async {
    try {
      await updateProduct(productId: productId, data: {
        'stock': 0,
      });
    } catch (_) {
      // If client update blocked by RLS (buyer cannot update seller's product),
      // invoke Edge Function with service role to mark as sold.
      try {
        await _client.functions.invoke(
          'mark-product-sold',
          body: {'product_id': productId},
        );
      } catch (_) {
        // swallow; UI will still proceed, streams may catch up later if function not configured
      }
    }
  }

  // Auth helpers
  static String? get currentUserId => _client.auth.currentUser?.id;
  static String? get currentUserEmail => _client.auth.currentUser?.email;
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // STORAGE
  static Future<String> uploadImage({
    required String bucket,
    required String path, // e.g. 'profiles/{userId}/avatar.jpg' or 'products/{productId}/image.jpg'
    Uint8List? bytes,
    String? filePath,
    String contentType = 'image/jpeg',
    bool upsert = true,
  }) async {
    final storage = _client.storage.from(bucket);

    if (bytes != null) {
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(upsert: upsert, contentType: contentType),
      );
    } else {
      // Web-safe: we do not use dart:io here. Callers must pass bytes.
      // On mobile/desktop, read the file into bytes in the caller and pass here.
      throw ArgumentError('Image bytes are required');
    }

    // Return a signed URL so it works even if the bucket is private
    final signed = await storage.createSignedUrl(path, 60 * 60 * 24 * 365);
    return signed;
  }

  // PROFILES
  static Future<void> upsertProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await _client.from('profiles').upsert({
      'id': userId,
      ...data,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  // PRODUCTS
  static Future<String> createProduct({
    required String ownerId,
    required Map<String, dynamic> data,
  }) async {
    // Coerce and provide defaults for required columns to avoid NOT NULL violations
    final String name = (data['name'] as String?)?.trim() ?? 'Product';
    final String description = (data['description'] as String?)?.trim() ?? '';
    final double price = (data['price'] is num)
        ? (data['price'] as num).toDouble()
        : double.tryParse('${data['price'] ?? 0}') ?? 0.0;
    final String unit = (data['unit'] as String?)?.trim() ?? 'kg';
    final int stock = (data['stock'] is num)
        ? (data['stock'] as num).toInt()
        : int.tryParse('${data['stock'] ?? 0}') ?? 0;
    final String category = (data['category'] as String?)?.trim() ?? 'Others';
    final String status = (data['status'] as String?)?.trim() ?? 'active';
    final String farmingMethod = (data['farming_method'] as String?)?.trim() ?? '';
    final String harvestDate = (data['harvest_date'] as String?) ?? DateTime.now().toUtc().toIso8601String();
    final int minOrderQty = (data['min_order_qty'] is num)
        ? (data['min_order_qty'] as num).toInt()
        : int.tryParse('${data['min_order_qty'] ?? 1}') ?? 1;
    final List<String> deliveryOptions = ((data['delivery_options'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList();
    // Always start with empty images array to satisfy NOT NULL array columns
    final List<String> imageUrls = ((data['image_urls'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList();

    final String? pickupAddress = (data['pickup_address'] as String?)?.trim();
    final double? latitude = (data['latitude'] is num)
        ? (data['latitude'] as num).toDouble()
        : double.tryParse('${data['latitude'] ?? ''}');
    final double? longitude = (data['longitude'] is num)
        ? (data['longitude'] as num).toDouble()
        : double.tryParse('${data['longitude'] ?? ''}');

    final payload = _stripNulls({
      'seller_id': ownerId,
      'name': name,
      'description': description,
      'price': price,
      'unit': unit,
      'stock': stock,
      'category': category,
      'status': status,
      'farming_method': farmingMethod,
      'harvest_date': harvestDate,
      'min_order_qty': minOrderQty,
      'delivery_options': deliveryOptions,
      'image_urls': imageUrls, // ensure non-null array
      if (pickupAddress != null && pickupAddress.isNotEmpty) 'pickup_address': pickupAddress,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });

    final inserted = await _client
        .from('products')
        .insert(payload)
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  static Future<String?> getFirstProductImageUrl(String productId) async {
    try {
      final data = await _client
          .from('products')
          .select('image_urls')
          .eq('id', productId)
          .maybeSingle();
      if (data == null) return null;
      final dynamic raw = data['image_urls'];
      if (raw is List && raw.isNotEmpty) {
        final first = raw.first;
        if (first != null) {
          return first.toString();
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static Future<void> updateProduct({
    required String productId,
    required Map<String, dynamic> data,
  }) async {
    final payload = _stripNulls({...data, 'updated_at': DateTime.now().toUtc().toIso8601String()});
    final uid = currentUserId;
    if (uid == null) {
      throw StateError('Not authenticated');
    }
    await _client
        .from('products')
        .update(payload)
        .eq('id', productId)
        .eq('seller_id', uid);
  }

  static Future<void> deleteProduct({
    required String productId,
  }) async {
    final uid = currentUserId;
    if (uid == null) {
      throw StateError('Not authenticated');
    }
    await _client
        .from('products')
        .delete()
        .eq('id', productId)
        .eq('seller_id', uid);
  }

  static Stream<List<Map<String, dynamic>>> streamProducts({
    String? ownerId,
    String? category,
    bool orderByUpdatedAtDesc = true,
  }) {
    // Use dynamic to accommodate SupabaseStreamBuilder/SupabaseStreamFilterBuilder chain
    dynamic builder = _client.from('products').stream(primaryKey: ['id']);
    if (ownerId != null) {
      builder = builder.eq('seller_id', ownerId);
    }
    if (category != null) {
      builder = builder.eq('category', category);
    }
    // Sorting will be applied client-side to avoid SDK typing friction with order() on streams

    final Stream<List<dynamic>> stream = builder as Stream<List<dynamic>>;
    return stream.map(
      (rows) => rows
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList(),
    );
  }

  static Stream<Map<String, dynamic>?> streamProductById(String productId) {
    return _client
        .from('products')
        .stream(primaryKey: ['id'])
        .eq('id', productId)
        .map((rows) => rows.isNotEmpty
            ? Map<String, dynamic>.from(rows.first)
            : null);
  }

  // Emails/notifications via Edge Function
  static Future<void> sendOwnerEmail({
    required String ownerId,
    required String productName,
    required String buyerEmail,
  }) async {
    if (!sendEmails) return; // emails disabled, keep app push only
    int attempt = 0;
    // Try common function name variants
    const fnNames = ['send-owner-email', 'send_owner_email', 'owner-email'];
    while (true) {
      try {
        final fn = fnNames[attempt % fnNames.length];
        await _client.functions.invoke(
          fn,
          body: {
            'owner_id': ownerId,
            'product_name': productName,
            'buyer_email': buyerEmail,
          },
        );
        return;
      } catch (e) {
        attempt++;
        // ignore: avoid_print
        print('[sendOwnerEmail] attempt=$attempt error: $e');
        if (attempt >= 6) return;
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  static Future<void> sendBuyerDeliveredEmail({
    required String buyerEmail,
    required String orderId,
    required List<Map<String, dynamic>> items,
    double? totalAmount,
  }) async {
    if (!sendEmails) return; // emails disabled, keep app push only
    // Build a simple HTML summary for the delivery email
    final buffer = StringBuffer();
    buffer.writeln('<p>Your order <strong>$orderId</strong> has been delivered.</p>');
    if (items.isNotEmpty) {
      buffer.writeln('<ul>');
      for (final item in items) {
        final name = (item['name'] ?? '').toString();
        final qty = (item['quantity'] ?? '').toString();
        final price = (item['price'] ?? '').toString();
        buffer.writeln('<li>$name &times; $qty – $price</li>');
      }
      buffer.writeln('</ul>');
    }
    if (totalAmount != null) {
      buffer.writeln('<p><strong>Total:</strong> $totalAmount</p>');
    }

    final subject = 'Order $orderId delivered';
    final html = buffer.toString();

    try {
      await _client.functions.invoke(
        'send-brevo-email',
        body: {
          'to': buyerEmail,
          'subject': subject,
          'html': html,
        },
      );
    } catch (e) {
      // ignore: avoid_print
      print('[sendBuyerDeliveredEmail] error: $e');
    }
  }

  static Future<void> sendBuyerOrderConfirmedEmail({
    required String buyerEmail,
    required String orderId,
    required List<Map<String, dynamic>> items,
    double? totalAmount,
  }) async {
    if (!sendEmails) return; // emails disabled, keep app push only
    // Build a simple HTML summary for the order email
    final buffer = StringBuffer();
    buffer.writeln('<p>Your order <strong>$orderId</strong> has been confirmed.</p>');
    if (items.isNotEmpty) {
      buffer.writeln('<ul>');
      for (final item in items) {
        final name = (item['name'] ?? '').toString();
        final qty = (item['quantity'] ?? '').toString();
        final price = (item['price'] ?? '').toString();
        buffer.writeln('<li>$name &times; $qty – $price</li>');
      }
      buffer.writeln('</ul>');
    }
    if (totalAmount != null) {
      buffer.writeln('<p><strong>Total:</strong> $totalAmount</p>');
    }

    final subject = 'Order $orderId confirmed';
    final html = buffer.toString();

    try {
      await _client.functions.invoke(
        'send-brevo-email',
        body: {
          'to': buyerEmail,
          'subject': subject,
          'html': html,
        },
      );
    } catch (e) {
      // ignore: avoid_print
      print('[sendBuyerOrderConfirmedEmail] error: $e');
    }
  }

  // USER LOCATIONS (buyer delivery location persisted to Supabase)
  static Future<void> upsertUserLocation({
    required String userId,
    required double lat,
    required double lng,
    String? label,
  }) async {
    try {
      await _client.from('user_locations').upsert({
        'user_id': userId,
        'lat': lat,
        'lng': lng,
        if (label != null && label.isNotEmpty) 'label': label,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // Ignore failures; app will still use local storage fallback
    }
  }

  // SALES (for Admin dashboard & reporting)
  static Future<void> insertSale({
    required Map<String, dynamic> data,
  }) async {
    try {
      await _client.from('sales').insert({
        ...data,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // ignore if table or RLS not configured; dashboard will handle missing data
    }
  }

  static Future<bool> hasSalesForOrder(String orderId) async {
    try {
      final List rows = await _client
          .from('sales')
          .select('id')
          .eq('order_id', orderId)
          .limit(1);
      return rows.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Stream<List<Map<String, dynamic>>> streamSales() {
    try {
      final stream = _client.from('sales').stream(primaryKey: ['id']);
      final typed = stream as Stream<List<dynamic>>;
      return typed.map((rows) => rows
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList());
    } catch (_) {
      // Fallback empty stream if not available
      return const Stream<List<Map<String, dynamic>>>.empty();
    }
  }

  // ORDERS (shared order status between buyer and seller)

  static Future<void> upsertOrder({
    required String orderId,
    required String buyerId,
    required String sellerId,
    required String status,
  }) async {
    await _client.from('orders').upsert({
      'id': orderId,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'status': status,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  static Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await _client
        .from('orders')
        .update({
          'status': status,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', orderId);
  }

  static Stream<Map<String, dynamic>?> streamOrderById(String orderId) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .map((rows) => rows.isNotEmpty
            ? Map<String, dynamic>.from(rows.first)
            : null);
  }

  /// ORDER TRACKING (new table for buyer/seller shared status)

  static Future<void> upsertOrderTracking({
    required String orderId,
    required String buyerId,
    required String sellerId,
    required String status,
  }) async {
    await _client.from('order_tracking').upsert({
      'id': orderId,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'status': status,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  static Future<void> updateOrderTrackingStatus({
    required String orderId,
    required String status,
  }) async {
    await _client
        .from('order_tracking')
        .update({
          'status': status,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', orderId);
  }

  static Stream<Map<String, dynamic>?> streamOrderTrackingById(String orderId) {
    return _client
        .from('order_tracking')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .map((rows) => rows.isNotEmpty
            ? Map<String, dynamic>.from(rows.first)
            : null);
  }

  static Future<String?> getOrderTrackingStatus(String orderId) async {
    try {
      final data = await _client
          .from('order_tracking')
          .select('status')
          .eq('id', orderId)
          .maybeSingle();
      if (data == null) return null;
      final status = data['status'];
      return status?.toString();
    } catch (_) {
      return null;
    }
  }

  /// Delete an order and its related sales rows.
  static Future<void> deleteOrderAndSales({
    required String orderId,
  }) async {
    try {
      await _client.from('sales').delete().eq('order_id', orderId);
    } catch (_) {
      // ignore failures on sales delete
    }
    try {
      await _client.from('orders').delete().eq('id', orderId);
    } catch (_) {
      // ignore failures on order delete
    }
    try {
      await _client.from('order_tracking').delete().eq('id', orderId);
    } catch (_) {
      // ignore failures on order_tracking delete
    }
  }
}
