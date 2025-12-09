import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SortBottomSheetWidget extends StatelessWidget {
  final String currentSort;
  final Function(String) onSortSelected;

  const SortBottomSheetWidget({
    super.key,
    required this.currentSort,
    required this.onSortSelected,
  });

  @override
  Widget build(BuildContext context) {
    final sortOptions = [
      {"key": "nearest", "title": "Nearest First", "icon": "location_on"},
      {
        "key": "price_low",
        "title": "Price: Low to High",
        "icon": "trending_up"
      },
      {
        "key": "price_high",
        "title": "Price: High to Low",
        "icon": "trending_down"
      },
      {"key": "freshest", "title": "Freshest", "icon": "eco"},
      {"key": "rating", "title": "Highest Rated", "icon": "star"},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Text(
              "Sort By",
              style: AppTheme.lightTheme.textTheme.titleLarge,
            ),
          ),

          Divider(color: AppTheme.lightTheme.colorScheme.outline),

          // Sort Options
          ...sortOptions.map((option) => ListTile(
                leading: CustomIconWidget(
                  iconName: option["icon"] as String,
                  color: currentSort == option["key"]
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                title: Text(
                  option["title"] as String,
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    color: currentSort == option["key"]
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.onSurface,
                    fontWeight: currentSort == option["key"]
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                trailing: currentSort == option["key"]
                    ? CustomIconWidget(
                        iconName: 'check',
                        color: AppTheme.lightTheme.colorScheme.primary,
                        size: 20,
                      )
                    : null,
                onTap: () {
                  onSortSelected(option["key"] as String);
                  Navigator.pop(context);
                },
              )),

          SizedBox(height: 2.h),
        ],
      ),
    );
  }
}
