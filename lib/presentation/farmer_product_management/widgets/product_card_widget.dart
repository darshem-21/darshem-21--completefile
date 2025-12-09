import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ProductCardWidget extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool isGridView;
  final bool isBulkMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onVisibilityToggle;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onArchive;
  final VoidCallback onPromote;

  const ProductCardWidget({
    super.key,
    required this.product,
    required this.isGridView,
    required this.isBulkMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onVisibilityToggle,
    required this.onEdit,
    required this.onDuplicate,
    required this.onArchive,
    required this.onPromote,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return AppTheme.lightTheme.colorScheme.tertiary;
      case 'out_of_stock':
        return AppTheme.lightTheme.colorScheme.error;
      case 'low_stock':
        return Colors.orange;
      case 'pending_approval':
        return Colors.amber;
      case 'archived':
        return AppTheme.lightTheme.colorScheme.onSurfaceVariant;
      default:
        return AppTheme.lightTheme.colorScheme.onSurfaceVariant;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'out_of_stock':
        return 'Out of Stock';
      case 'low_stock':
        return 'Low Stock';
      case 'pending_approval':
        return 'Pending';
      case 'archived':
        return 'Archived';
      default:
        return status;
    }
  }

  Widget _buildStatusChip() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: _getStatusColor(product['status'] ?? 'active')
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(product['status'] ?? 'active')
              .withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        _getStatusText(product['status'] ?? 'active'),
        style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
          color: _getStatusColor(product['status'] ?? 'active'),
          fontWeight: FontWeight.w600,
          fontSize: 8.sp,
        ),
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMetric('views', product['views'] ?? 0, 'visibility'),
        _buildMetric('orders', product['orders'] ?? 0, 'shopping_cart'),
        _buildMetric(
            '₹${(product['revenue'] ?? 0.0).toInt()}', '', 'currency_rupee'),
      ],
    );
  }

  Widget _buildMetric(String value, dynamic count, String iconName) {
    return Row(
      children: [
        CustomIconWidget(
          iconName: iconName,
          size: 12,
          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: 1.w),
        Text(
          count is int && count > 0 ? count.toString() : value,
          style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            fontSize: 8.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildVisibilityToggle() {
    return GestureDetector(
      onTap: onVisibilityToggle,
      child: Container(
        padding: EdgeInsets.all(1.w),
        decoration: BoxDecoration(
          color: (product['isVisible'] ?? true)
              ? AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1)
              : AppTheme.lightTheme.colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: CustomIconWidget(
          iconName:
              (product['isVisible'] ?? true) ? 'visibility' : 'visibility_off',
          size: 16,
          color: (product['isVisible'] ?? true)
              ? AppTheme.lightTheme.colorScheme.primary
              : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              margin: EdgeInsets.only(top: 2.h, bottom: 3.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            ListTile(
              leading: CustomIconWidget(iconName: 'edit', size: 24),
              title: const Text('Edit Product'),
              onTap: () {
                Navigator.pop(context);
                onEdit();
              },
            ),
            ListTile(
              leading: CustomIconWidget(iconName: 'content_copy', size: 24),
              title: const Text('Duplicate'),
              onTap: () {
                Navigator.pop(context);
                onDuplicate();
              },
            ),
            ListTile(
              leading: CustomIconWidget(iconName: 'archive', size: 24),
              title: const Text('Archive'),
              onTap: () {
                Navigator.pop(context);
                onArchive();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'trending_up',
                size: 24,
                color: AppTheme.lightTheme.colorScheme.secondary,
              ),
              title: Text(
                'Promote',
                style: TextStyle(
                  color: AppTheme.lightTheme.colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onPromote();
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isGridView) {
      return GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isBulkMode && isSelected
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.2),
              width: isBulkMode && isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.lightTheme.colorScheme.shadow
                    .withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        color: AppTheme
                            .lightTheme.colorScheme.surfaceContainerHighest,
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: product['image'] ?? '',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppTheme
                                .lightTheme.colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: CustomIconWidget(
                                iconName: 'image',
                                size: 32,
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppTheme
                                .lightTheme.colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: CustomIconWidget(
                                iconName: 'broken_image',
                                size: 32,
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Product details
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.all(3.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name and status
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product['name'] ?? '',
                                  style: AppTheme
                                      .lightTheme.textTheme.titleSmall
                                      ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 1.w),
                              _buildStatusChip(),
                            ],
                          ),
                          SizedBox(height: 1.h),

                          // Price and stock
                          Row(
                            children: [
                              Text(
                                '₹${product['price'] ?? 0}',
                                style: AppTheme.lightTheme.textTheme.titleMedium
                                    ?.copyWith(
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '/${product['unit'] ?? 'unit'}',
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Stock: ${product['stock'] ?? 0}',
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          // Performance metrics
                          _buildPerformanceMetrics(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Selection checkbox (bulk mode)
              if (isBulkMode)
                Positioned(
                  top: 2.w,
                  left: 2.w,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.lightTheme.colorScheme.shadow
                              .withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (value) => onTap(),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),

              // Visibility toggle and menu
              if (!isBulkMode)
                Positioned(
                  top: 2.w,
                  right: 2.w,
                  child: Row(
                    children: [
                      _buildVisibilityToggle(),
                      SizedBox(width: 1.w),
                      GestureDetector(
                        onTap: () => _showActionMenu(context),
                        child: Container(
                          padding: EdgeInsets.all(1.w),
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.surface
                                .withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: CustomIconWidget(
                            iconName: 'more_vert',
                            size: 16,
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    } else {
      // List view layout
      return GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isBulkMode && isSelected
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.2),
              width: isBulkMode && isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.lightTheme.colorScheme.shadow
                    .withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Selection checkbox (bulk mode)
              if (isBulkMode)
                Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (value) => onTap(),
                  ),
                ),

              // Product image
              Container(
                width: 20.w,
                height: 20.w,
                margin: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color:
                      AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: product['image'] ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppTheme
                          .lightTheme.colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: CustomIconWidget(
                          iconName: 'image',
                          size: 24,
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppTheme
                          .lightTheme.colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: CustomIconWidget(
                          iconName: 'broken_image',
                          size: 24,
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Product details
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and status
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product['name'] ?? '',
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          _buildStatusChip(),
                        ],
                      ),
                      SizedBox(height: 0.5.h),

                      // Category
                      Text(
                        product['category'] ?? '',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 1.h),

                      // Price and stock
                      Row(
                        children: [
                          Text(
                            '₹${product['price'] ?? 0}',
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '/${product['unit'] ?? 'unit'}',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Stock: ${product['stock'] ?? 0}',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),

                      // Performance metrics
                      _buildPerformanceMetrics(),
                    ],
                  ),
                ),
              ),

              // Action buttons
              if (!isBulkMode)
                Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    children: [
                      _buildVisibilityToggle(),
                      SizedBox(height: 1.h),
                      GestureDetector(
                        onTap: () => _showActionMenu(context),
                        child: Container(
                          padding: EdgeInsets.all(1.w),
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.outline
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: CustomIconWidget(
                            iconName: 'more_vert',
                            size: 16,
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }
  }
}
