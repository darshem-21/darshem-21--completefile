import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:farmmarket/services/geo_service.dart';

class DeliveryMapWidget extends StatelessWidget {
  final LatLng buyerPosition;
  final LatLng? sellerPosition;
  final VoidCallback? onTrackLive;

  const DeliveryMapWidget({
    super.key,
    required this.buyerPosition,
    this.sellerPosition,
    this.onTrackLive,
  });

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      Marker(
        point: buyerPosition,
        width: 36,
        height: 36,
        child: _pin(Colors.red),
      ),
      if (sellerPosition != null)
        Marker(
          point: sellerPosition!,
          width: 36,
          height: 36,
          child: _pin(Colors.green),
        ),
    ];

    final center = sellerPosition ?? buyerPosition;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 220,
        child: FutureBuilder<List<LatLng>>(
          future: (sellerPosition != null)
              ? GeoService.osrmRoutePolyline(start: buyerPosition, end: sellerPosition!)
              : Future.value(<LatLng>[]),
          builder: (context, snap) {
            final poly = snap.data ?? const <LatLng>[];
            double? distanceKm;
            if (sellerPosition != null) {
              final d = Distance();
              distanceKm = d.as(LengthUnit.Kilometer, buyerPosition, sellerPosition!);
            }
            return Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 11,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.farmmarket',
                    ),
                    if (poly.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(points: poly, color: Colors.blue, strokeWidth: 4),
                        ],
                      ),
                    MarkerLayer(markers: markers),
                  ],
                ),
                if (distanceKm != null)
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                        ],
                      ),
                      child: Text(
                        'Distance: ${distanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: InkWell(
                    onTap: onTrackLive,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          const Text('Live', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _pin(Color color) => Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      );
}
