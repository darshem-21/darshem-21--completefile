import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CartSummaryWidget extends StatefulWidget {
  final double subtotal;
  final double deliveryFee;
  final double taxAmount;
  final double discount;
  final String? promoCode;
  final ValueChanged<String>? onPromoCodeApplied;
  final VoidCallback? onPromoCodeRemoved;
  final bool showPromoSection;

  const CartSummaryWidget({
    super.key,
    required this.subtotal,
    required this.deliveryFee,
    required this.taxAmount,
    this.discount = 0,
    this.promoCode,
    this.onPromoCodeApplied,
    this.onPromoCodeRemoved,
    this.showPromoSection = true,
  });

  @override
  State<CartSummaryWidget> createState() => _CartSummaryWidgetState();
}

class _CartSummaryWidgetState extends State<CartSummaryWidget> {
  final TextEditingController _promoController = TextEditingController();
  bool _isApplyingPromo = false;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _applyPromoCode() {
    if (_promoController.text.trim().isNotEmpty) {
      setState(() {
        _isApplyingPromo = true;
      });

      // Simulate API call
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isApplyingPromo = false;
          });
          widget.onPromoCodeApplied?.call(_promoController.text.trim());
          _promoController.clear();
        }
      });
    }
  }

  double get total => widget.subtotal - widget.discount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Order Summary',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 16),

          // Promo Code Section (optional)
          if (widget.showPromoSection && widget.promoCode != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_offer, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Promo "${widget.promoCode}" applied',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: widget.onPromoCodeRemoved,
                    child:
                        const Icon(Icons.close, color: Colors.green, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else if (widget.showPromoSection) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    decoration: InputDecoration(
                      hintText: 'Enter promo code',
                      prefixIcon: const Icon(Icons.local_offer),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isApplyingPromo ? null : _applyPromoCode,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  child: _isApplyingPromo
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Apply',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Summary Details
          _buildSummaryRow('Subtotal', widget.subtotal),
          if (widget.discount > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow('Discount', -widget.discount, isDiscount: true),
          ],
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              Text(
                '₹${total.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount,
      {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        Text(
          '${isDiscount ? '-' : ''}₹${amount.abs().toStringAsFixed(2)}',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDiscount
                ? Colors.green
                : Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }
}
