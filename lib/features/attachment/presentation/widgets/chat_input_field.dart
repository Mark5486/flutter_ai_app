import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entity/attachment_entity.dart';
import '../cubit/attachment_cubit.dart';
import '../cubit/attachment_state.dart';
import 'attachment_preview_widget.dart';

class ChatInputField extends StatefulWidget {
  const ChatInputField({super.key, required this.onSendMessage});

  final void Function(String text, AttachmentEntity? attachment) onSendMessage;

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send(BuildContext context) {
    final text = _controller.text.trim();

    final attachmentState = context.read<AttachmentCubit>().state;
    final attachment =
        attachmentState is AttachmentReady ? attachmentState.attachment : null;

    if (text.isEmpty && attachment == null) return;

    widget.onSendMessage(text, attachment);
    _controller.clear();
    context.read<AttachmentCubit>().resetAttachment();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttachmentCubit, AttachmentState>(
      builder: (context, attachmentState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (attachmentState is AttachmentReady)
              AttachmentPreviewBar(
                attachment: attachmentState.attachment,
                onRemove: () {
                  context.read<AttachmentCubit>().resetAttachment();
                },
              ),
            if (attachmentState is AttachmentFailure)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    attachmentState.message,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Row(
                children: [
                  IconButton(
                    icon:
                        attachmentState is AttachmentPicking
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.image_outlined),
                    tooltip: 'إرفاق صورة',
                    onPressed:
                        attachmentState is AttachmentPicking
                            ? null
                            : () => context.read<AttachmentCubit>().pickImage(),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالتك هنا...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.deepPurple,
                    ),
                    onPressed: () => _send(context),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
