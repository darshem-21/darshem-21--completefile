import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../config/secrets.dart';

class GeoService {
  GeoService._();

  static Future<Position> getCurrentPosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      throw Exception('Location permission denied');
    }
    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
  }

  static Future<LatLng?> geocodeAddress(String address) async {
    if (address.trim().isEmpty) return null;
    final encoded = Uri.encodeComponent(address);
    final url =
        'https://api.geoapify.com/v1/geocode/search?text=$encoded&format=json&apiKey=${Secrets.geoapifyApiKey}';
    final dio = Dio();
    final resp = await dio.get(url);
    if (resp.statusCode == 200) {
      final data = resp.data is Map ? resp.data as Map : json.decode(resp.data);
      // Geoapify returns either { results: [ { lat, lon } ] } when format=json
      // or GeoJSON { features: [ { geometry: { coordinates: [lon, lat] } } ] }
      if (data['results'] is List && (data['results'] as List).isNotEmpty) {
        final first = (data['results'] as List).first as Map;
        final lat = (first['lat'] as num?)?.toDouble();
        final lon = (first['lon'] as num?)?.toDouble();
        if (lat != null && lon != null) return LatLng(lat, lon);
      }
      if (data['features'] is List && (data['features'] as List).isNotEmpty) {
        final first = (data['features'] as List).first as Map;
        final geom = first['geometry'] as Map?;
        final coords = (geom?['coordinates'] as List?)?.cast<num>();
        if (coords != null && coords.length >= 2) {
          final lon = coords[0].toDouble();
          final lat = coords[1].toDouble();
          return LatLng(lat, lon);
        }
      }
    }
    return null;
  }

  static Future<String?> reverseGeocodeCity({required double lat, required double lon}) async {
    final url =
        'https://api.geoapify.com/v1/geocode/reverse?lat=$lat&lon=$lon&format=json&apiKey=${Secrets.geoapifyApiKey}';
    final dio = Dio();
    final resp = await dio.get(url);
    if (resp.statusCode == 200) {
      final data = resp.data is Map ? resp.data as Map : json.decode(resp.data);
      if (data['results'] is List && (data['results'] as List).isNotEmpty) {
        final first = (data['results'] as List).first as Map;
        final city = (first['city'] ?? first['town'] ?? first['village'] ?? first['county'] ?? first['state'] ?? first['name'])?.toString();
        return city;
      }
    }
    return null;
  }

  /// Nominatim: forward geocoding (address -> coordinates), free + keyless.
  /// Returns first match as LatLng, or null if not found.
  static Future<LatLng?> nominatimGeocode(String query) async {
    if (query.trim().isEmpty) return null;
    final dio = Dio();
    try {
      final res = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': 1,
          'limit': 1,
        },
        options: Options(headers: {
          'User-Agent': 'farmmarket-app/1.0',
        }),
      );
      if (res.statusCode == 200 && res.data is List && (res.data as List).isNotEmpty) {
        final first = (res.data as List).first as Map;
        final lat = (first['lat'] as String?);
        final lon = (first['lon'] as String?);
        if (lat != null && lon != null) {
          final latD = double.tryParse(lat);
          final lonD = double.tryParse(lon);
          if (latD != null && lonD != null) {
            return LatLng(latD, lonD);
          }
        }
      }
    } catch (_) {
      // fall through to null
    }
    return null;
  }

  /// Nominatim: reverse geocoding (lat/lon -> human readable address).
  /// Returns display_name or null.
  static Future<String?> nominatimReverseGeocode({
    required double lat,
    required double lon,
  }) async {
    final dio = Dio();
    try {
      final res = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'format': 'jsonv2',
        },
        options: Options(headers: {
          'User-Agent': 'farmmarket-app/1.0',
        }),
      );
      if (res.statusCode == 200 && res.data is Map) {
        final data = res.data as Map;
        final displayName = data['display_name'] as String?;
        return displayName;
      }
    } catch (_) {
      // ignore and return null
    }
    return null;
  }

  static Future<List<LatLng>> getRoutePolyline({
    required LatLng start,
    required LatLng end,
    String mode = 'drive',
  }) async {
    // mode: walk | bike | drive
    final url =
        'https://api.geoapify.com/v1/routing?waypoints=${start.latitude},${start.longitude}|${end.latitude},${end.longitude}&mode=$mode&apiKey=${Secrets.geoapifyApiKey}';
    final dio = Dio();
    final resp = await dio.get(url);
    if (resp.statusCode == 200) {
      final data = resp.data is Map ? resp.data as Map : json.decode(resp.data);
      // GeoJSON FeatureCollection with LineString in features[0].geometry
      if (data['features'] is List && (data['features'] as List).isNotEmpty) {
        final first = (data['features'] as List).first as Map;
        final geom = first['geometry'] as Map?;
        if (geom != null && geom['type'] == 'LineString') {
          final coords = (geom['coordinates'] as List?)?.cast<List>();
          if (coords != null) {
            return coords
                .map((pair) => LatLng(
                      (pair[1] as num).toDouble(),
                      (pair[0] as num).toDouble(),
                    ))
                .toList();
          }
        }
      }
    }
    return <LatLng>[];
  }

  /// OSRM public server routing: returns a polyline as list of LatLng between
  /// start and end. Uses free, keyless OSRM instance.
  static Future<List<LatLng>> osrmRoutePolyline({
    required LatLng start,
    required LatLng end,
  }) async {
    final dio = Dio();
    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/'
          '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
          '?overview=full&geometries=geojson';
      final resp = await dio.get(url);
      if (resp.statusCode == 200 && resp.data is Map) {
        final data = resp.data as Map;
        if (data['routes'] is List && (data['routes'] as List).isNotEmpty) {
          final first = (data['routes'] as List).first as Map;
          final geom = first['geometry'] as Map?;
          if (geom != null && geom['type'] == 'LineString') {
            final coords = (geom['coordinates'] as List?)?.cast<List>();
            if (coords != null) {
              return coords
                  .map((pair) => LatLng(
                        (pair[1] as num).toDouble(),
                        (pair[0] as num).toDouble(),
                      ))
                  .toList();
            }
          }
        }
      }
    } catch (_) {
      // ignore and fall through to empty list
    }
    return <LatLng>[];
  }

}
