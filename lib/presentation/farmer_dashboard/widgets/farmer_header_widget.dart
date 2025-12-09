import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FarmerHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> farmerData;
  final bool isConnected;
  final VoidCallback onProfileTap;

  const FarmerHeaderWidget({
    super.key,
    required this.farmerData,
    required this.isConnected,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final farmerName = farmerData['name'] as String? ?? 'Farmer';
    final farmerImage = farmerData['profileImage'] as String? ?? '';
    final isVerified = farmerData['isVerified'] as bool? ?? false;
    final farmName = farmerData['farmName'] as String? ?? 'My Farm';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: onProfileTap,
                        child: Container(
                          width: 12.w,
                          height: 12.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: AppTheme.lightTheme.colorScheme.onPrimary,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(23),
                            child: farmerImage.isNotEmpty
                                ? CustomImageWidget(
                                    imageUrl: farmerImage,
                                    width: 12.w,
                                    height: 12.w,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: AppTheme
                                        .lightTheme.colorScheme.onPrimary
                                        .withValues(alpha: 0.2),
                                    child: CustomIconWidget(
                                      iconName: 'person',
                                      color: AppTheme
                                          .lightTheme.colorScheme.onPrimary,
                                      size: 24,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'Welcome, $farmerName',
                                    style: AppTheme
                                        .lightTheme.textTheme.titleMedium
                                        ?.copyWith(
                                      color: AppTheme
                                          .lightTheme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isVerified) ...[
                                  SizedBox(width: 1.w),
                                  Container(
                                    padding: EdgeInsets.all(0.5.w),
                                    decoration: BoxDecoration(
                                      color: AppTheme
                                          .lightTheme.colorScheme.tertiary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: CustomIconWidget(
                                      iconName: 'verified',
                                      color: AppTheme
                                          .lightTheme.colorScheme.onPrimary,
                                      size: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              farmName,
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme.lightTheme.colorScheme.onPrimary
                                    .withValues(alpha: 0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? AppTheme.lightTheme.colorScheme.tertiary
                            .withValues(alpha: 0.2)
                        : AppTheme.lightTheme.colorScheme.error
                            .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 2.w,
                        height: 2.w,
                        decoration: BoxDecoration(
                          color: isConnected
                              ? AppTheme.lightTheme.colorScheme.tertiary
                              : AppTheme.lightTheme.colorScheme.error,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        isConnected ? 'Online' : 'Offline',
                        style:
                            AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.onPrimary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'info_outline',
                    color: AppTheme.lightTheme.colorScheme.onPrimary,
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Last synced: ${_getLastSyncTime()}',
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onPrimary
                            .withValues(alpha: 0.9),
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

  String _getLastSyncTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}
