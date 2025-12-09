import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/custom_image_widget.dart';

class OrderItem {
  final String id;
  final String name;
  final String imageUrl;
  final int quantity;
  final double price;
  final String status;
  final Color statusColor;

  OrderItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.quantity,
    required this.price,
    required this.status,
    required this.statusColor,
  });
}

class OrderItemsList extends StatelessWidget {
  final List<OrderItem> items;
  final bool showIndividualStatus;
  final ValueChanged<OrderItem>? onDeleteItem;

  const OrderItemsList({
    super.key,
    required this.items,
    this.showIndividualStatus = false,
    this.onDeleteItem,
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
                  offset: const Offset(0, 2)),
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Order Items',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color)),
            const Spacer(),
            Text('${items.length} item${items.length > 1 ? 's' : ''}',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color)),
          ]),
          const SizedBox(height: 16),
          ...items.map((item) => _buildOrderItem(context, item)),
        ]));
  }

  Widget _buildOrderItem(BuildContext context, OrderItem item) {
    return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
        child: Row(children: [
          // Product Image
          ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child:
                  CustomImageWidget(imageUrl: item.imageUrl, width: 50, height: 50, fit: BoxFit.cover)),
          const SizedBox(width: 12),

          // Product Details
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(item.name,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  Text('Qty: ${item.quantity}',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color)),
                  const SizedBox(width: 16),
                  Text('₹${item.price.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor)),
                ]),
                if (showIndividualStatus) ...[
                  const SizedBox(height: 6),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: item.statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text(item.status,
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: item.statusColor))),
                ],
              ])),
          // Delete icon in the corner
          if (onDeleteItem != null)
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 20),
              tooltip: 'Remove item',
              onPressed: () => onDeleteItem?.call(item),
            ),
        ]));
  }
}