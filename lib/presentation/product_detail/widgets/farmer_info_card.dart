import 'package:flutter/material.dart';

import '../../../../core/app_export.dart';

class FarmerInfoCard extends StatelessWidget {
  final Map<String, dynamic> farmerData;
  final VoidCallback onTap;
  final bool showActions;
  final VoidCallback? onEditPrice;
  final VoidCallback? onDelete;

  const FarmerInfoCard({
    super.key,
    required this.farmerData,
    required this.onTap,
    this.showActions = false,
    this.onEditPrice,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(0),
          border: Border.all(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Removed large avatar to make the card cleaner
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          farmerData["name"] as String,
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (farmerData["isVerified"] as bool)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomIconWidget(
                                iconName: 'verified',
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Verified',
                                style: AppTheme.lightTheme.textTheme.labelSmall
                                    ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (showActions)
                        PopupMenuButton<String>(
                          icon: CustomIconWidget(
                            iconName: 'more_vert',
                            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                            size: 18,
                          ),
                          onSelected: (value) {
                            if (value == 'edit') {
                              onEditPrice?.call();
                            } else if (value == 'delete') {
                              onDelete?.call();
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  CustomIconWidget(iconName: 'edit', size: 18),
                                  const SizedBox(width: 8),
                                  const Text('Edit price'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  CustomIconWidget(iconName: 'delete', size: 18),
                                  const SizedBox(width: 8),
                                  const Text('Delete product'),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomIconWidget(
                        iconName: 'location_on',
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Builder(builder: (context) {
                          final addr = ((farmerData['location'] as String?) ??
                                  (farmerData['pickup_address'] as String?) ??
                                  '')
                              .trim();
                          final text = addr.isEmpty ? 'Address not available' : addr;
                          return Text(
                            text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Phone
                  if ((farmerData['phone'] as String?)?.trim().isNotEmpty ?? false)
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'phone',
                          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            (farmerData['phone'] as String).trim(),
                            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  // Account number
                  if ((farmerData['account_number'] as String?)?.trim().isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'account_balance',
                            color:
                                AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              (farmerData['account_number'] as String).trim(),
                              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // IFSC
                  if ((farmerData['ifsc'] as String?)?.trim().isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'credit_card',
                            color:
                                AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              (farmerData['ifsc'] as String).trim(),
                              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
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
            if (!showActions)
              CustomIconWidget(
                iconName: 'chevron_right',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
