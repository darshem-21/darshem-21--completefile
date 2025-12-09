import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';

class MapPicker extends StatefulWidget {
  const MapPicker({super.key, this.initialLat, this.initialLng});

  final double? initialLat;
  final double? initialLng;

  @override
  State<MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  late final MapController _mapController;
  late LatLng _center;
  String? _address;
  bool _isReverseGeocoding = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _center = LatLng(widget.initialLat ?? 19.0760, widget.initialLng ?? 72.8777); // Default: Mumbai
    _reverseGeocode(_center);
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() => _isReverseGeocoding = true);
    try {
      final dio = Dio();
      final res = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': point.latitude,
          'lon': point.longitude,
          'format': 'jsonv2',
        },
        options: Options(headers: {
          'User-Agent': 'farmmarket-app/1.0'
        }),
      );
      final displayName = res.data['display_name'] as String?;
      if (!mounted) return;
      setState(() {
        _address = displayName ?? 'Selected location';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _address = 'Selected location';
      });
    } finally {
      if (mounted) setState(() => _isReverseGeocoding = false);
    }
  }

  void _onMapMove(MapPosition pos, bool _) {
    if (pos.center != null) {
      _center = pos.center!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick location'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13,
              onPositionChanged: _onMapMove,
              interactionOptions: const InteractionOptions(enableMultiFingerGestureRace: true),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.farmmarket.app',
              ),
            ],
          ),
          // Center marker
          const IgnorePointer(
            ignoring: true,
            child: Center(
              child: Icon(Icons.location_on, size: 36, color: Colors.redAccent),
            ),
          ),
          // Address banner
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: Material(
              color: Colors.white,
              elevation: 2,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.place, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isReverseGeocoding ? 'Loading address…' : (_address ?? 'Move map to select'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18),
                      tooltip: 'Refresh address',
                      onPressed: () => _reverseGeocode(_center),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop({
                  'lat': _center.latitude,
                  'lng': _center.longitude,
                  'address': _address,
                });
              },
              child: const Text('Use this location'),
            ),
          ),
        ),
      ),
    );
  }
}
