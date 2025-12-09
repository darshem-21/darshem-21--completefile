import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const _cartKey = 'cart_items_v1';
  static const _addressKey = 'delivery_address_v1';
  static const _browseLocationKey = 'browse_location_v1';

  // Cart
  static Future<void> saveCartItems(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(items);
    await prefs.setString(_cartKey, jsonStr);
  }

  static Future<List<Map<String, dynamic>>> loadCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_cartKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    final decoded = jsonDecode(jsonStr);
    if (decoded is List) {
      return decoded.cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  // Address
  static Future<void> saveAddress(Map<String, dynamic> address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_addressKey, jsonEncode(address));
  }

  static Future<Map<String, dynamic>?> loadAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_addressKey);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    return Map<String, dynamic>.from(jsonDecode(jsonStr));
  }

  static Future<void> saveBrowseLocation(Map<String, dynamic> location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_browseLocationKey, jsonEncode(location));
  }

  static Future<Map<String, dynamic>?> loadBrowseLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_browseLocationKey);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    return Map<String, dynamic>.from(jsonDecode(jsonStr));
  }
}
