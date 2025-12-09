import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ProductCardWidget extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isUserProduct;
  final VoidCallback? onEdit;

  const ProductCardWidget({
    super.key,
    required this.product,
    required this.onTap,
    required this.onLongPress,
    this.isUserProduct = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:
                  AppTheme.lightTheme.colorScheme.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: Stack(
                children: [
                  CustomImageWidget(
                    imageUrl: product["image"] as String,
                    width: double.infinity,
                    // Slightly smaller height so the card needs less vertical space
                    height: 150.0,
                    fit: BoxFit.cover,
                  ),
                  // Gradient overlay for better contrast
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: true,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Color.fromARGB(150, 0, 0, 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Top tags: farming method (e.g., Organic) and freshness
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Row(
                      children: [
                        if ((product["farmingMethod"] ?? '').toString().isNotEmpty)
                          _PillTag(
                            label: (product["farmingMethod"] as String?) ?? '',
                            background: AppTheme.lightTheme.colorScheme.primary,
                            icon: Icons.eco,
                          ),
                        SizedBox(width: 1.5.w),
                        if ((product["freshness"] ?? '').toString().isNotEmpty)
                          _PillTag(
                            label: (product["freshness"] as String?) ?? '',
                            background: _getFreshnessColor((product["freshness"] as String?) ?? ''),
                            icon: Icons.check_circle,
                          ),
                        SizedBox(height: 0.6.h),
                      ],
                    ),
                  ),
                  // Price badge overlay (bottom-left)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: _PriceBadge(
                      text: "${product["price"]}${product["unit"] != null ? ' /${product["unit"]}' : ''}",
                    ),
                  ),
                  // SOLD ribbon for owner's sold-out products
                  if (isUserProduct && ((product["availableQuantity"] as num?)?.toInt() ?? 0) <= 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'SOLD',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  // Edit Button for User's Products
                  if (isUserProduct && onEdit != null)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onEdit,
                        child: Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit,
                            color: AppTheme.lightTheme.colorScheme.onPrimary,
                            size: 5.w,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Product Details (wrap content; no Expanded to avoid extra space)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Top section: name + farmer row
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product name
                        Text(
                          product["name"] as String,
                          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 1),

                        // Farmer name + verified icon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                product["farmerName"] as String,
                                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (product["isVerified"] as bool)
                              const Icon(Icons.verified, size: 16, color: Colors.green),
                          ],
                        ),
                      ],
                    ),

                    // Gap before price
                    const SizedBox(height: 4),
                    // Bottom: price or out of stock
                    Builder(builder: (context) {
                      final qty = (product["availableQuantity"] as num?)?.toInt() ?? 0;
                      if (qty <= 0) {
                        return Text(
                          'Out of stock',
                          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.redAccent,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      }
                      return Text(
                        "${product["price"]}${product["unit"] != null ? ' /${product["unit"]}' : ''}",
                        style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    }),
                  ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getFreshnessColor(String freshness) {
    switch (freshness.toLowerCase()) {
      case 'fresh':
        return AppTheme.lightTheme.colorScheme.tertiary;
      case 'good':
        return AppTheme.warningLight;
      case 'fair':
        return AppTheme.lightTheme.colorScheme.error;
      default:
        return AppTheme.lightTheme.colorScheme.onSurfaceVariant;
    }
  }
}

class _PriceBadge extends StatelessWidget {
  final String text;
  const _PriceBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PillTag extends StatelessWidget {
  final String label;
  final Color background;
  final IconData? icon;

  const _PillTag({
    required this.label,
    required this.background,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: Colors.white),
            SizedBox(width: 0.8.w),
          ],
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color foreground;

  const _SmallInfoChip({
    required this.icon,
    required this.label,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.amber),
          SizedBox(width: 1.w),
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
