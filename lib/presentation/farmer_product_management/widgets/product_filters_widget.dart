import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ProductFiltersWidget extends StatefulWidget {
  final String currentFilter;
  final String currentSort;
  final Function(String) onFilterChanged;
  final Function(String) onSortChanged;

  const ProductFiltersWidget({
    super.key,
    required this.currentFilter,
    required this.currentSort,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  @override
  State<ProductFiltersWidget> createState() => _ProductFiltersWidgetState();
}

class _ProductFiltersWidgetState extends State<ProductFiltersWidget> {
  late String _selectedFilter;
  late String _selectedSort;

  final List<Map<String, String>> _filters = [
    {'id': 'all', 'name': 'All Products', 'icon': 'inventory'},
    {'id': 'active', 'name': 'Active', 'icon': 'check_circle'},
    {'id': 'out_of_stock', 'name': 'Out of Stock', 'icon': 'cancel'},
    {'id': 'low_stock', 'name': 'Low Stock', 'icon': 'warning'},
    {'id': 'pending_approval', 'name': 'Pending', 'icon': 'schedule'},
    {'id': 'archived', 'name': 'Archived', 'icon': 'archive'},
  ];

  final List<Map<String, String>> _sortOptions = [
    {'id': 'recent', 'name': 'Recently Added', 'icon': 'schedule'},
    {'id': 'name', 'name': 'Name (A-Z)', 'icon': 'sort_by_alpha'},
    {'id': 'price_low', 'name': 'Price (Low to High)', 'icon': 'trending_up'},
    {
      'id': 'price_high',
      'name': 'Price (High to Low)',
      'icon': 'trending_down'
    },
    {'id': 'stock', 'name': 'Stock Level', 'icon': 'inventory_2'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.currentFilter;
    _selectedSort = widget.currentSort;
  }

  void _applyFilters() {
    widget.onFilterChanged(_selectedFilter);
    widget.onSortChanged(_selectedSort);
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _selectedFilter = 'all';
      _selectedSort = 'recent';
    });
  }

  Widget _buildFilterOption(Map<String, String> filter) {
    final isSelected = _selectedFilter == filter['id'];

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter['id']!;
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 2.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1)
              : AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: filter['icon']!,
              size: 24,
              color: isSelected
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurface,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                filter['name']!,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              CustomIconWidget(
                iconName: 'check',
                size: 20,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(Map<String, String> sort) {
    final isSelected = _selectedSort == sort['id'];

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSort = sort['id']!;
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 2.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.lightTheme.colorScheme.secondary.withValues(alpha: 0.1)
              : AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.lightTheme.colorScheme.secondary
                : AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: sort['icon']!,
              size: 24,
              color: isSelected
                  ? AppTheme.lightTheme.colorScheme.secondary
                  : AppTheme.lightTheme.colorScheme.onSurface,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                sort['name']!,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? AppTheme.lightTheme.colorScheme.secondary
                      : AppTheme.lightTheme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              CustomIconWidget(
                iconName: 'check',
                size: 20,
                color: AppTheme.lightTheme.colorScheme.secondary,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 12.w,
            height: 0.5.h,
            margin: EdgeInsets.only(top: 2.h, bottom: 2.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: Row(
              children: [
                Text(
                  'Filter & Sort',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _resetFilters,
                  child: Text(
                    'Reset',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
            height: 1,
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(6.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter section
                  Text(
                    'Filter by Status',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 2.h),

                  Column(
                    children: _filters.map(_buildFilterOption).toList(),
                  ),

                  SizedBox(height: 4.h),

                  // Sort section
                  Text(
                    'Sort by',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightTheme.colorScheme.secondary,
                    ),
                  ),
                  SizedBox(height: 2.h),

                  Column(
                    children: _sortOptions.map(_buildSortOption).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Bottom buttons
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
