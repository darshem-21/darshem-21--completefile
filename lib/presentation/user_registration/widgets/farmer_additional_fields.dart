import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import 'custom_text_field.dart';

class FarmerAdditionalFields extends StatefulWidget {
  final TextEditingController farmLocationController;
  final TextEditingController primaryCropsController;
  final TextEditingController farmSizeController;
  final Function(String) onLocationSelected;

  const FarmerAdditionalFields({
    super.key,
    required this.farmLocationController,
    required this.primaryCropsController,
    required this.farmSizeController,
    required this.onLocationSelected,
  });

  @override
  State<FarmerAdditionalFields> createState() => _FarmerAdditionalFieldsState();
}

class _FarmerAdditionalFieldsState extends State<FarmerAdditionalFields> {
  String? selectedCrop;
  String? selectedFarmSize;

  final List<String> cropOptions = [
    'Rice',
    'Wheat',
    'Maize',
    'Sugarcane',
    'Cotton',
    'Pulses',
    'Vegetables',
    'Fruits',
    'Spices',
    'Tea',
    'Coffee',
    'Other'
  ];

  final List<String> farmSizeOptions = [
    'Less than 1 acre',
    '1-2 acres',
    '2-5 acres',
    '5-10 acres',
    '10-25 acres',
    '25-50 acres',
    'More than 50 acres'
  ];

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 60.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 10.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 1.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Text(
                'Select Farm Location',
                style: AppTheme.lightTheme.textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.outline,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconWidget(
                      iconName: 'location_on',
                      color: AppTheme.lightTheme.primaryColor,
                      size: 12.w,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'GPS Location Picker',
                      style: AppTheme.lightTheme.textTheme.titleMedium,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Tap to get current location or\nselect on map',
                      textAlign: TextAlign.center,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Mock location selection
                        const mockLocation = 'Rajkot, Gujarat, India';
                        widget.farmLocationController.text = mockLocation;
                        widget.onLocationSelected(mockLocation);
                        Navigator.pop(context);
                      },
                      icon: CustomIconWidget(
                        iconName: 'my_location',
                        color: AppTheme.lightTheme.colorScheme.onPrimary,
                        size: 4.w,
                      ),
                      label: Text('Use Current Location'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 1.5.h,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCropSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 50.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 10.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 1.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Text(
                'Select Primary Crops',
                style: AppTheme.lightTheme.textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: cropOptions.length,
                itemBuilder: (context, index) {
                  final crop = cropOptions[index];
                  return ListTile(
                    title: Text(
                      crop,
                      style: AppTheme.lightTheme.textTheme.bodyLarge,
                    ),
                    trailing: selectedCrop == crop
                        ? CustomIconWidget(
                            iconName: 'check',
                            color: AppTheme.lightTheme.primaryColor,
                            size: 5.w,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        selectedCrop = crop;
                        widget.primaryCropsController.text = crop;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFarmSizeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 45.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 10.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 1.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Text(
                'Select Farm Size',
                style: AppTheme.lightTheme.textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: farmSizeOptions.length,
                itemBuilder: (context, index) {
                  final size = farmSizeOptions[index];
                  return ListTile(
                    title: Text(
                      size,
                      style: AppTheme.lightTheme.textTheme.bodyLarge,
                    ),
                    trailing: selectedFarmSize == size
                        ? CustomIconWidget(
                            iconName: 'check',
                            color: AppTheme.lightTheme.primaryColor,
                            size: 5.w,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        selectedFarmSize = size;
                        widget.farmSizeController.text = size;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 2.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'agriculture',
                    color: AppTheme.lightTheme.primaryColor,
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Farm Details',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.lightTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              CustomTextField(
                label: 'Farm Location',
                hint: 'Tap to select location',
                controller: widget.farmLocationController,
                enabled: false,
                onTap: _showLocationPicker,
                suffixIcon: IconButton(
                  onPressed: _showLocationPicker,
                  icon: CustomIconWidget(
                    iconName: 'location_on',
                    color: AppTheme.lightTheme.primaryColor,
                    size: 5.w,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select farm location';
                  }
                  return null;
                },
              ),
              SizedBox(height: 2.h),
              CustomTextField(
                label: 'Primary Crops',
                hint: 'Select your main crops',
                controller: widget.primaryCropsController,
                enabled: false,
                onTap: _showCropSelector,
                suffixIcon: IconButton(
                  onPressed: _showCropSelector,
                  icon: CustomIconWidget(
                    iconName: 'arrow_drop_down',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 5.w,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select primary crops';
                  }
                  return null;
                },
              ),
              SizedBox(height: 2.h),
              CustomTextField(
                label: 'Farm Size',
                hint: 'Select farm size',
                controller: widget.farmSizeController,
                enabled: false,
                onTap: _showFarmSizeSelector,
                suffixIcon: IconButton(
                  onPressed: _showFarmSizeSelector,
                  icon: CustomIconWidget(
                    iconName: 'arrow_drop_down',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 5.w,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select farm size';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
