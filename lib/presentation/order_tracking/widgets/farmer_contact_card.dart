import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/custom_image_widget.dart';

class FarmerContactCard extends StatelessWidget {
  final String farmerName;
  final String farmerImage;
  final String farmName;
  final double rating;
  final int reviewCount;
  final VoidCallback? onChat;
  final VoidCallback? onCall;

  const FarmerContactCard({
    super.key,
    required this.farmerName,
    required this.farmerImage,
    required this.farmName,
    this.rating = 4.5,
    this.reviewCount = 0,
    this.onChat,
    this.onCall,
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
          Text('Contact Farmer',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color)),
          const SizedBox(height: 16),

          Row(children: [
            // Farmer Avatar
            Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.2),
                        width: 2)),
                child: ClipOval(
                    child: CustomImageWidget(
                        imageUrl: farmerImage,
                        fit: BoxFit.cover, width: 60, height: 60))),
            const SizedBox(width: 16),

            // Farmer Info
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(farmerName,
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color)),
                  const SizedBox(height: 4),
                  Text(farmName,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(rating.toString(),
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color)),
                    if (reviewCount > 0) ...[
                      const SizedBox(width: 4),
                      Text('($reviewCount reviews)',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color)),
                    ],
                  ]),
                ])),
          ]),
          const SizedBox(height: 16),

          // Contact Buttons (shown only if callbacks provided)
          if (onChat != null || onCall != null)
            Row(children: [
              if (onChat != null)
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: onChat,
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: Text('Chat',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8))))),
              if (onChat != null && onCall != null) const SizedBox(width: 12),
              if (onCall != null)
                Expanded(
                    child: ElevatedButton.icon(
                        onPressed: onCall,
                        icon: const Icon(Icons.phone, size: 18),
                        label: Text('Call',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8))))),
            ]),
        ]));
  }
}