import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/chat_message.dart';
import '../cubit/chat_actor_cubit.dart';
import 'message_parts/message_audio_player.dart';
import 'message_parts/message_image.dart';
import 'message_parts/message_sources.dart';
import 'message_parts/message_status_row.dart';
import 'message_parts/message_thoughts.dart';

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

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress:
            message.canBeEdited ? () => _showEditDialog(context) : null,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth =
                constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : MediaQuery.sizeOf(context).width;

            final maxBubbleWidth =
                (availableWidth * (isUser ? 0.78 : 0.88))
                    .clamp(240.0, isUser ? 560.0 : 760.0)
                    .toDouble();

            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              constraints: BoxConstraints(maxWidth: maxBubbleWidth),
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              padding: EdgeInsets.all(message.hasImage || message.hasAudio ? 6 : 0).add(
                message.text.trim().isEmpty
                    ? EdgeInsets.zero
                    : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              decoration: BoxDecoration(
                gradient:
                    isUser
                        ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF7C5CFF), Color(0xFF5B3DD8)],
                        )
                        : null,
                color:
                    message.isFailed
                        ? const Color(0xFF2A1420)
                        : isUser
                        ? null
                        : const Color(0xFF1E1840),
                border:
                    message.isFailed
                        ? Border.all(color: const Color(0xFFFF5C7A), width: 1.2)
                        : !isUser
                        ? Border.all(color: Colors.white.withValues(alpha: 0.07))
                        : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.hasImage) MessageImage(imageUrl: message.imageUrl!),
                  if (message.hasAudio)
                    MessageAudioPlayer(audioUrl: message.audioUrl!),
                  if (message.hasThoughts)
                    MessageThoughts(thoughts: message.thoughts!),
                  if (message.text.trim().isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(
                        top: message.hasImage || message.hasThoughts ? 6 : 10,
                        bottom: 10,
                        left: message.hasImage ? 2 : 14,
                        right: message.hasImage ? 2 : 14,
                      ),
                      child:
                          isUser && message.hasOriginalText
                              ? _EditedMessageText(message: message)
                              : Text(
                                  message.text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    height: 1.45,
                                  ),
                                ),
                    ),
                  if (message.hasSources) MessageSources(sources: message.sources),
                  if (isUser) ...[
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: 6,
                        left: message.hasImage ? 2 : 14,
                        right: message.hasImage ? 2 : 14,
                      ),
                      child: MessageStatusRow(
                        status: message.status,
                        isEdited: message.isEdited,
                        onRetry: onRetry,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _EditMessageDialog(
          initialText: message.text,
          onSave: (newText) {
            context.read<ChatActorCubit>().editMessage(
              chatId: chatId,
              messageId: message.id,
              newText: newText,
            );
          },
        );
      },
    );
  }
}



class _EditMessageDialog extends StatefulWidget {
  const _EditMessageDialog({required this.initialText, required this.onSave});

  final String initialText;
  final void Function(String newText) onSave;

  @override
  State<_EditMessageDialog> createState() => _EditMessageDialogState();
}

class _EditMessageDialogState extends State<_EditMessageDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1840),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text('تعديل الرسالة'),
      content: TextField(
        controller: _controller,
        maxLines: 5,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'اكتب النص الجديد...',
          border: InputBorder.none,
          filled: true,
          fillColor: Color(0xFF151230),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF9F7BFF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            final newText = _controller.text.trim();
            Navigator.pop(context);

            if (newText.isEmpty ||
                newText == widget.initialText.trim()) {
              return;
            }

            widget.onSave(newText);
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}



class _EditedMessageText extends StatefulWidget {
  const _EditedMessageText({required this.message});

  final ChatMessage message;

  @override
  State<_EditedMessageText> createState() => _EditedMessageTextState();
}

class _EditedMessageTextState extends State<_EditedMessageText> {
  bool _showingOriginal = false;

  @override
  Widget build(BuildContext context) {
    final showingOriginal = _showingOriginal;
    final text =
        showingOriginal
            ? widget.message.originalText!
            : widget.message.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Text(
            key: ValueKey<bool>(showingOriginal),
            text,
            style: TextStyle(
              color: showingOriginal ? Colors.white60 : Colors.white,
              fontSize: 15,
              height: 1.45,
              fontStyle:
                  showingOriginal ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Align(
          alignment: Alignment.centerRight,
          child: _EditedTogglePill(
            showingOriginal: showingOriginal,
            onToggle:
                () => setState(() => _showingOriginal = !showingOriginal),
          ),
        ),
      ],
    );
  }
}

class _EditedTogglePill extends StatelessWidget {
  const _EditedTogglePill({
    required this.showingOriginal,
    required this.onToggle,
  });

  final bool showingOriginal;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: showingOriginal ? 'عرض النص المعدّل' : 'عرض النص الأصلي',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                showingOriginal
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 14,
                color: Colors.white54,
              ),
              const SizedBox(width: 2),
              Text(
                showingOriginal ? 'المعدّلة' : 'معدّلة',
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
