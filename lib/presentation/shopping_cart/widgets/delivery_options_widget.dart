import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum DeliveryType { standard, express }

class DeliveryOptionsWidget extends StatelessWidget {
  final DeliveryType selectedDelivery;
  final ValueChanged<DeliveryType> onDeliveryChanged;
  final String standardTime;
  final String expressTime;
  final double standardPrice;
  final double expressPrice;

  const DeliveryOptionsWidget({
    super.key,
    required this.selectedDelivery,
    required this.onDeliveryChanged,
    this.standardTime = '2-3 days',
    this.expressTime = 'Next day',
    this.standardPrice = 5.99,
    this.expressPrice = 12.99,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
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
          Text(
            'Delivery Options',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 16),

          // Standard Delivery
          _buildDeliveryOption(
            context,
            type: DeliveryType.standard,
            title: 'Standard Delivery',
            subtitle: standardTime,
            price: standardPrice,
            icon: Icons.local_shipping_outlined,
          ),
          const SizedBox(height: 12),

          // Express Delivery
          _buildDeliveryOption(
            context,
            type: DeliveryType.express,
            title: 'Express Delivery',
            subtitle: expressTime,
            price: expressPrice,
            icon: Icons.flash_on,
            isExpress: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryOption(
    BuildContext context, {
    required DeliveryType type,
    required String title,
    required String subtitle,
    required double price,
    required IconData icon,
    bool isExpress = false,
  }) {
    final bool isSelected = selectedDelivery == type;

    return InkWell(
      onTap: () => onDeliveryChanged(type),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color:
                    isSelected ? Theme.of(context).primaryColor : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      if (isExpress) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'FAST',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${price.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).primaryColor,
                    size: 16,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
