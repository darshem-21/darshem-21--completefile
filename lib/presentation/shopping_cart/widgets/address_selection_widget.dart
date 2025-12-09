import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddressSelectionWidget extends StatelessWidget {
  final String selectedAddress;
  final List<String> savedAddresses;
  final ValueChanged<String>? onAddressSelected;
  final VoidCallback? onEditAddress;
  final VoidCallback? onAddNewAddress;

  const AddressSelectionWidget({
    super.key,
    required this.selectedAddress,
    this.savedAddresses = const [],
    this.onAddressSelected,
    this.onEditAddress,
    this.onAddNewAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, size: 20),
              const SizedBox(width: 8),
              Text(
                'Delivery Address',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _showAddressOptions,
                child: Text(
                  'Change',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onEditAddress,
            child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedAddress,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onEditAddress,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }

  void _showAddressOptions() {
    // Prefer edit flow if provided; otherwise, just call selection callback
    if (onEditAddress != null) {
      onEditAddress!.call();
    } else {
      onAddressSelected?.call(selectedAddress);
    }
  }
}
