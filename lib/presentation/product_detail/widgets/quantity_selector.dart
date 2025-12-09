import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class QuantitySelector extends StatefulWidget {
  final int initialQuantity;
  final int minQuantity;
  final int maxQuantity;
  final String unit;
  final Function(int) onQuantityChanged;

  const QuantitySelector({
    super.key,
    this.initialQuantity = 1,
    this.minQuantity = 1,
    required this.maxQuantity,
    required this.unit,
    required this.onQuantityChanged,
  });

  @override
  State<QuantitySelector> createState() => _QuantitySelectorState();
}

class _QuantitySelectorState extends State<QuantitySelector> {
  late int _quantity;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
    _textController = TextEditingController(text: _quantity.toString());
  }

  void _updateQuantity(int newQuantity) {
    if (newQuantity >= widget.minQuantity &&
        newQuantity <= widget.maxQuantity) {
      setState(() {
        _quantity = newQuantity;
        _textController.text = _quantity.toString();
      });
      widget.onQuantityChanged(_quantity);

      // Haptic feedback for iOS
      HapticFeedback.selectionClick();
    }
  }

  void _increment() {
    _updateQuantity(_quantity + 1);
  }

  void _decrement() {
    _updateQuantity(_quantity - 1);
  }

  void _onTextChanged(String value) {
    final newQuantity = int.tryParse(value);
    if (newQuantity != null) {
      _updateQuantity(newQuantity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quantity',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              _buildQuantityControl(),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Available: ${widget.maxQuantity} ${widget.unit}',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (_quantity < widget.minQuantity || _quantity > widget.maxQuantity)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Quantity must be between ${widget.minQuantity} and ${widget.maxQuantity}',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuantityControl() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(2.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildControlButton(
            icon: 'remove',
            onPressed: _quantity > widget.minQuantity ? _decrement : null,
          ),
          Container(
            width: 20.w,
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: TextField(
              controller: _textController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 2.h),
                isDense: true,
              ),
              onChanged: _onTextChanged,
              onSubmitted: _onTextChanged,
            ),
          ),
          _buildControlButton(
            icon: 'add',
            onPressed: _quantity < widget.maxQuantity ? _increment : null,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required String icon,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(2.w),
      child: Container(
        padding: EdgeInsets.all(3.w),
        child: CustomIconWidget(
          iconName: icon,
          color: onPressed != null
              ? AppTheme.lightTheme.colorScheme.primary
              : AppTheme.lightTheme.colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.5),
          size: 5.w,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
