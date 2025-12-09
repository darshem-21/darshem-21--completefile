import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sizer/sizer.dart';
import 'package:farmmarket/services/geo_service.dart';


class LocationMapSheet extends StatelessWidget {
  final LatLng userPosition;
  final LatLng? farmerPosition;
  final String farmerAddress;

  const LocationMapSheet({
    super.key,
    required this.userPosition,
    required this.farmerPosition,
    required this.farmerAddress,
  });

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      Marker(
        point: userPosition,
        width: 36,
        height: 36,
        child: _pin(Colors.blue, 'You'),
      ),
      if (farmerPosition != null)
        Marker(
          point: farmerPosition!,
          width: 36,
          height: 36,
          child: _pin(Colors.green, 'Farmer'),
        ),
    ];

    final center = farmerPosition ?? userPosition;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: Column(
          children: [
            SizedBox(height: 1.h),
            Container(
              width: 12.w,
              height: 0.8.h,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(1.h),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Locations',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (farmerAddress.isNotEmpty) ...[
                    SizedBox(height: 0.5.h),
                    Text(
                      farmerAddress,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
                child: FutureBuilder<List<LatLng>>(
                  future: (farmerPosition != null)
                      ? GeoService.getRoutePolyline(start: userPosition, end: farmerPosition!)
                      : Future.value(<LatLng>[]),
                  builder: (context, snap) {
                    final poly = snap.data ?? const <LatLng>[];
                    return FlutterMap(
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
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pin(Color color, String semantics) {
    return Semantics(
      label: semantics,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }
}
