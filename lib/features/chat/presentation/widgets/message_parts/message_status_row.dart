import 'package:flutter/material.dart';

import '../../../domain/entities/chat_message.dart';

class MessageStatusRow extends StatelessWidget {
  const MessageStatusRow({
    super.key,
    required this.status,
    required this.isEdited,
    required this.onRetry,
  });

  final MessageStatus status;
  final bool isEdited;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.sending:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Colors.white70,
              ),
            ),
            SizedBox(width: 6),
            Text(
              'جارٍ الإرسال',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        );

      case MessageStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 15),
            const SizedBox(width: 4),
            const Text(
              'فشل الإرسال',
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: onRetry,
                child: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(
                    color: Colors.white,
                    decoration: TextDecoration.underline,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        );

      case MessageStatus.sent:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.done_all_rounded, color: Color(0xFF00D4A0), size: 14),
            SizedBox(width: 4),
            Text(
              'تم الإرسال',
              style: TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        );
    }
  }
}
