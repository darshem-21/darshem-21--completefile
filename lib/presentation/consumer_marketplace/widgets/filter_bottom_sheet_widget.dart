import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class FilterBottomSheetWidget extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onFiltersApplied;

  const FilterBottomSheetWidget({
    super.key,
    required this.currentFilters,
    required this.onFiltersApplied,
  });

  @override
  State<FilterBottomSheetWidget> createState() =>
      _FilterBottomSheetWidgetState();
}

class _FilterBottomSheetWidgetState extends State<FilterBottomSheetWidget> {
  late Map<String, dynamic> _filters;
  late RangeValues _priceRange;
  late double _distance;
  late bool _organicOnly;
  late bool _availableToday;

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.currentFilters);
    _priceRange = RangeValues(
      (_filters["minPrice"] as double?) ?? 0.0,
      (_filters["maxPrice"] as double?) ?? 1000.0,
    );
    _distance = (_filters["maxDistance"] as double?) ?? 50.0;
    _organicOnly = (_filters["organicOnly"] as bool?) ?? false;
    _availableToday = (_filters["availableToday"] as bool?) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 12.w,
            height: 0.5.h,
            margin: EdgeInsets.symmetric(vertical: 2.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Filters",
                  style: AppTheme.lightTheme.textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: _resetFilters,
                  child: Text(
                    "Reset",
                    style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(color: AppTheme.lightTheme.colorScheme.outline),

          // Filter Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price Range
                  _buildFilterSection(
                    "Price Range",
                    Column(
                      children: [
                        RangeSlider(
                          values: _priceRange,
                          min: 0,
                          max: 1000,
                          divisions: 20,
                          labels: RangeLabels(
                            "₹${_priceRange.start.round()}",
                            "₹${_priceRange.end.round()}",
                          ),
                          onChanged: (values) {
                            setState(() {
                              _priceRange = values;
                            });
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "₹${_priceRange.start.round()}",
                              style: AppTheme.lightTheme.textTheme.bodySmall,
                            ),
                            Text(
                              "₹${_priceRange.end.round()}",
                              style: AppTheme.lightTheme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Distance
                  _buildFilterSection(
                    "Distance from Farmer",
                    Column(
                      children: [
                        Slider(
                          value: _distance,
                          min: 1,
                          max: 100,
                          divisions: 99,
                          label: "${_distance.round()} km",
                          onChanged: (value) {
                            setState(() {
                              _distance = value;
                            });
                          },
                        ),
                        Text(
                          "Within ${_distance.round()} km",
                          style: AppTheme.lightTheme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),

                  // Organic Certification
                  _buildFilterSection(
                    "Certification",
                    SwitchListTile(
                      title: Text(
                        "Organic Certified Only",
                        style: AppTheme.lightTheme.textTheme.bodyMedium,
                      ),
                      value: _organicOnly,
                      onChanged: (value) {
                        setState(() {
                          _organicOnly = value;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),

                  // Availability
                  _buildFilterSection(
                    "Availability",
                    SwitchListTile(
                      title: Text(
                        "Available Today",
                        style: AppTheme.lightTheme.textTheme.bodyMedium,
                      ),
                      value: _availableToday,
                      onChanged: (value) {
                        setState(() {
                          _availableToday = value;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Apply Button
          Container(
            padding: EdgeInsets.all(4.w),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                child: Text("Apply Filters"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 2.h),
        Text(
          title,
          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        content,
        SizedBox(height: 1.h),
      ],
    );
  }

  void _resetFilters() {
    setState(() {
      _priceRange = const RangeValues(0, 1000);
      _distance = 50.0;
      _organicOnly = false;
      _availableToday = false;
    });
  }

  void _applyFilters() {
    final filters = {
      "minPrice": _priceRange.start,
      "maxPrice": _priceRange.end,
      "maxDistance": _distance,
      "organicOnly": _organicOnly,
      "availableToday": _availableToday,
    };
    widget.onFiltersApplied(filters);
    Navigator.pop(context);
  }
}
