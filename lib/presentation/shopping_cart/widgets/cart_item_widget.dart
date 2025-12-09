import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_export.dart';
import '../../../widgets/custom_image_widget.dart';

class CartItemWidget extends StatefulWidget {
  final String productId;
  final String productName;
  final String farmerName;
  final String imageUrl;
  final double unitPrice;
  final int quantity;
  final bool isInStock;
  final String freshnessIndicator;
  final int? maxQuantity;
  final String? unit;
  final VoidCallback? onRemove;
  final ValueChanged<int>? onQuantityChanged;
  final VoidCallback? onMoveToWishlist;
  final VoidCallback? onShare;

  const CartItemWidget({
    super.key,
    required this.productId,
    required this.productName,
    required this.farmerName,
    required this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    this.isInStock = true,
    this.freshnessIndicator = 'Fresh',
    this.maxQuantity,
    this.unit,
    this.onRemove,
    this.onQuantityChanged,
    this.onMoveToWishlist,
    this.onShare,
  });

  @override
  State<CartItemWidget> createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget> {
  bool _showUndoOption = false;
  late int _currentQuantity;

  @override
  void initState() {
    super.initState();
    final maxQ = widget.maxQuantity ?? 0;
    _currentQuantity = (maxQ > 0 && widget.quantity > maxQ)
        ? maxQ
        : widget.quantity;
  }

  void _handleQuantityChange(int newQuantity) {
    final maxQ = widget.maxQuantity ?? 0;
    final int clamped = (maxQ > 0)
        ? newQuantity.clamp(1, maxQ)
        : newQuantity.clamp(1, 99);
    if (clamped != _currentQuantity) {
      setState(() {
        _currentQuantity = clamped;
      });
      widget.onQuantityChanged?.call(clamped);
    }
  }

  void _showLongPressMenu() {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                  leading: const Icon(Icons.favorite_border),
                  title: Text('Move to Wishlist',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onMoveToWishlist?.call();
                  }),
              ListTile(
                  leading: const Icon(Icons.share_outlined),
                  title: Text('Share with Others',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onShare?.call();
                  }),
              ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text('Remove from Cart',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500, color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onRemove?.call();
                  }),
            ])));
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
        key: Key(widget.productId),
        direction: DismissDirection.endToStart,
        background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white, size: 24)),
        confirmDismiss: (direction) async {
          setState(() {
            _showUndoOption = true;
          });

          await Future.delayed(const Duration(seconds: 3));

          if (mounted && _showUndoOption) {
            widget.onRemove?.call();
            return true;
          }
          return false;
        },
        child: GestureDetector(
            onLongPress: _showLongPressMenu,
            child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2)),
                    ]),
                child:
                    _showUndoOption ? _buildUndoWidget() : _buildCartItem())));
  }

  Widget _buildUndoWidget() {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          const Icon(Icons.delete_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
              child: Text('Item removed from cart',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500, color: Colors.red))),
          TextButton(
              onPressed: () {
                setState(() {
                  _showUndoOption = false;
                });
              },
              child: Text('UNDO',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, color: Colors.red))),
        ]));
  }

  Widget _buildCartItem() {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Product Image
      ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CustomImageWidget(
              imageUrl: widget.imageUrl,
              height: 80, 
              width: 80, 
              fit: BoxFit.cover)),
      const SizedBox(width: 12),

      // Product Details
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(widget.productName,
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis)),
          if (!widget.isInStock)
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4)),
                child: Text('Out of Stock',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.red))),
          IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.delete_outline),
            color: Colors.red,
            onPressed: widget.onRemove,
          ),
        ]),
        const SizedBox(height: 4),

        Text('by ${widget.farmerName}',
            style: GoogleFonts.inter(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color)),
        const SizedBox(height: 4),

        Row(children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4)),
              child: Text(widget.freshnessIndicator,
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.green))),
          const Spacer(),
          Text('₹${widget.unitPrice.toStringAsFixed(2)}/${widget.unit?.isNotEmpty == true ? widget.unit : 'unit'}',
              // show provided unit if available (e.g., kg, liter)
              // falls back to generic 'unit'
              // ignore: prefer_single_quotes
              // updated to display correct unit label
              // (no change to business logic)
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor)),
        ]),
        const SizedBox(height: 8),

        // Quantity and Total (read-only)
        Row(children: [
          Text('Qty: '+_currentQuantity.toString(),
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('₹${(widget.unitPrice * _currentQuantity).toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodyLarge?.color)),
        ]),
      ])),
    ]);
  }
}