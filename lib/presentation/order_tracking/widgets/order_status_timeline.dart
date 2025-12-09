import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum OrderStatus {
  confirmed,
  preparing,
  readyForPickup,
  packed,
  paymentConfirmation,
  outForDelivery,
  delivered,
}

class OrderStatusData {
  final OrderStatus status;
  final String title;
  final String subtitle;
  final DateTime? timestamp;
  final bool isCompleted;
  final String? estimatedTime;

  OrderStatusData({
    required this.status,
    required this.title,
    required this.subtitle,
    this.timestamp,
    this.isCompleted = false,
    this.estimatedTime,
  });
}

class OrderStatusTimeline extends StatelessWidget {
  final List<OrderStatusData> statusList;
  final OrderStatus currentStatus;
  final VoidCallback? onApproveCurrent;
  final VoidCallback? onRejectCurrent;

  const OrderStatusTimeline({
    super.key,
    required this.statusList,
    required this.currentStatus,
    this.onApproveCurrent,
    this.onRejectCurrent,
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
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Progress',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 20),
          ...statusList.asMap().entries.map((entry) {
            final index = entry.key;
            final statusData = entry.value;
            final isLast = index == statusList.length - 1;

            return _buildTimelineItem(
              context,
              statusData: statusData,
              isLast: isLast,
              isCurrentOrPast: _isCurrentOrPast(statusData.status),
            );
          }),
        ],
      ),
    );
  }

  bool _isCurrentOrPast(OrderStatus status) {
    // Determine order based on provided list order
    final provided = statusList.map((e) => e.status).toList();
    final currentIndex = provided.indexOf(currentStatus);
    final statusIndex = provided.indexOf(status);
    if (currentIndex == -1 || statusIndex == -1) return false;
    return statusIndex <= currentIndex;
  }

  Widget _buildTimelineItem(
    BuildContext context, {
    required OrderStatusData statusData,
    required bool isLast,
    required bool isCurrentOrPast,
  }) {
    final bool isCurrent = statusData.status == currentStatus;
    final Color currentColor = Colors.red;
    final Color pastColor = Colors.green;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrentOrPast
                    ? (isCurrent ? currentColor : pastColor)
                    : Colors.grey.withOpacity(0.3),
                border: Border.all(
                  color: isCurrentOrPast
                      ? (isCurrent ? currentColor : pastColor)
                      : Colors.grey.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                isCurrentOrPast
                    ? (statusData.isCompleted || !isCurrent
                        ? Icons.check
                        : Icons.access_time)
                    : Icons.radio_button_unchecked,
                size: 12,
                color: isCurrentOrPast
                    ? Colors.white
                    : Colors.grey.withOpacity(0.5),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCurrentOrPast
                    ? (isCurrent
                        ? currentColor.withOpacity(0.3)
                        : pastColor.withOpacity(0.3))
                    : Colors.grey.withOpacity(0.2),
              ),
          ],
        ),
        const SizedBox(width: 16),

        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        statusData.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isCurrent
                              ? currentColor
                              : (isCurrentOrPast
                                  ? Theme.of(context).textTheme.bodyLarge?.color
                                  : Colors.grey),
                        ),
                      ),
                    ),
                    if (isCurrent && !statusData.isCompleted &&
                        (onApproveCurrent != null || onRejectCurrent != null)) ...[
                      // Approve / Reject controls for the current step
                      IconButton(
                        tooltip: 'Approve',
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: onApproveCurrent,
                      ),
                      IconButton(
                        tooltip: 'Reject',
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: onRejectCurrent,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  statusData.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isCurrentOrPast
                        ? Theme.of(context).textTheme.bodyMedium?.color
                        : Colors.grey,
                  ),
                ),
                if (statusData.timestamp != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(statusData.timestamp!),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
                if (statusData.estimatedTime != null && isCurrent) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: currentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ETA: ${statusData.estimatedTime}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: currentColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} at ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
