import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/chat_message.dart';
import '../cubit/chat_actor_cubit.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.chatId,
    this.onRetry,
  });

  final ChatMessage message;
  final String chatId;

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    final theme = Theme.of(context);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showActions(context),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: EdgeInsets.all(message.hasImage ? 6 : 0).add(
            message.text.trim().isEmpty
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          decoration: BoxDecoration(
            color: isUser ? theme.colorScheme.primary : Colors.grey.shade800,
            border:
                message.isFailed
                    ? Border.all(color: theme.colorScheme.error, width: 1.5)
                    : null,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: Radius.circular(isUser ? 12 : 0),
              bottomRight: Radius.circular(isUser ? 0 : 12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.hasImage) _MessageImage(imageUrl: message.imageUrl!),
              if (message.text.trim().isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(
                    top: message.hasImage ? 6 : 10,
                    bottom: 10,
                    left: message.hasImage ? 2 : 14,
                    right: message.hasImage ? 2 : 14,
                  ),
                  child: Text(
                    message.text,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              if (isUser) ...[
                Padding(
                  padding: EdgeInsets.only(
                    bottom: 6,
                    left: message.hasImage ? 2 : 14,
                    right: message.hasImage ? 2 : 14,
                  ),
                  child: _MessageStatusRow(
                    status: message.status,
                    onRetry: onRetry,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('حذف الرسالة'),
            onTap: () {
              Navigator.pop(context);
              context.read<ChatActorCubit>().deleteMessage(
                chatId: chatId,
                messageId: message.id,
              );
            },
          ),
        );
      },
    );
  }
}

class _MessageImage extends StatelessWidget {
  const _MessageImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;

          return const SizedBox(
            height: 180,
            width: 240,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox(
            height: 120,
            width: 200,
            child: Center(
              child: Icon(Icons.broken_image_outlined, color: Colors.white70),
            ),
          );
        },
      ),
    );
  }
}

class _MessageStatusRow extends StatelessWidget {
  const _MessageStatusRow({required this.status, required this.onRetry});

  final MessageStatus status;
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
            Icon(Icons.done, color: Colors.white70, size: 14),
            SizedBox(width: 4),
            Text(
              'تم الإرسال',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        );
    }
  }
}
