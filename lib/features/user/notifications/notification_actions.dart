import 'package:flutter/material.dart';

/// Bildirim aksiyon butonları (Onayla/Reddet)
class NotificationActions extends StatelessWidget {
  final int notificationId;
  final int requestId;
  final String? requestStatus;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const NotificationActions({
    super.key,
    required this.notificationId,
    required this.requestId,
    required this.requestStatus,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (requestStatus == 'pending') {
      return Padding(
        padding: const EdgeInsets.only(left: 58, bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onReject,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(
                    color: Colors.red.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text('Reddet', style: TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: onApprove,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text('Onayla', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      );
    }

    if (requestStatus == 'approved' || requestStatus == 'rejected') {
      return Padding(
        padding: const EdgeInsets.only(left: 58, bottom: 8),
        child: Row(
          children: [
            Icon(
              requestStatus == 'approved' ? Icons.check_circle : Icons.cancel,
              color: requestStatus == 'approved' ? Colors.green : Colors.red,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              requestStatus == 'approved' ? 'Onaylandı' : 'Reddedildi',
              style: TextStyle(
                fontSize: 12,
                color: requestStatus == 'approved' ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
