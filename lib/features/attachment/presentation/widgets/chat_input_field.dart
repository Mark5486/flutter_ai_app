import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entity/attachment_entity.dart';
import '../../../audio/domain/entity/audio_entity.dart';
import '../../../audio/presentation/cubit/audio_cubit.dart';
import '../../../audio/presentation/cubit/audio_state.dart';
import '../cubit/attachment_cubit.dart';
import '../cubit/attachment_state.dart';
import 'attachment_preview_widget.dart';

class ChatInputField extends StatefulWidget {
  const ChatInputField({super.key, required this.onSendMessage});

  final void Function(
    String text,
    AttachmentEntity? attachment,
    AudioEntity? audio,
    bool webSearch,
    bool thinking,
  )
  onSendMessage;

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _webSearchEnabled = false;
  bool _thinkingEnabled = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send(BuildContext context) {
    final typedText = _controller.text.trim();

    final attachmentState = context.read<AttachmentCubit>().state;
    final attachment =
        attachmentState is AttachmentReady ? attachmentState.attachment : null;
    final audioState = context.read<AudioCubit>().state;
    final audio = audioState is AudioReady ? audioState.audio : null;
    final transcript = audioState is AudioReady ? audioState.transcript : '';
    final text = typedText.isNotEmpty ? typedText : transcript;

    if (text.isEmpty && attachment == null && audio == null) return;

    widget.onSendMessage(
      text,
      attachment,
      audio,
      _webSearchEnabled,
      _thinkingEnabled,
    );
    _controller.clear();
  }

  Color? _activeColor(bool enabled) {
    return enabled ? const Color(0xFF9F7BFF) : null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioCubit, AudioState>(
      builder:
          (
            context,
            audioState,
          ) => BlocBuilder<AttachmentCubit, AttachmentState>(
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
                          style: const TextStyle(
                            color: Color(0xFFFF5C7A),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  if (audioState is AudioRecorded)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed:
                              () => context.read<AudioCubit>().uploadAudio(),
                          icon: const Icon(Icons.cloud_upload_outlined),
                          label: const Text('رفع التسجيل'),
                        ),
                      ),
                    ),
                  if (audioState is AudioUploading)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text('جارٍ تفريغ التسجيل الصوتي ورفعه...'),
                      ),
                    ),
                  if (audioState is AudioReady)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed:
                                () => context.read<AudioCubit>().resetAudio(),
                            icon: const Icon(Icons.close),
                            label: const Text('حذف التسجيل الصوتي'),
                          ),
                          Text(
                            audioState.transcript,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                  if (audioState is AudioFailure)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed:
                              audioState.bytes == null
                                  ? null
                                  : () => context.read<AudioCubit>().retry(),
                          icon: const Icon(Icons.refresh),
                          label: Text(audioState.message),
                        ),
                      ),
                    ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151230),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color:
                            _focusNode.hasFocus
                                ? const Color(0xFF9F7BFF).withValues(
                                  alpha: 0.65,
                                )
                                : Colors.white.withValues(alpha: 0.08),
                      ),
                      boxShadow: [
                        if (_focusNode.hasFocus)
                          BoxShadow(
                            color: const Color(0xFF9F7BFF).withValues(
                              alpha: 0.25,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip:
                              _webSearchEnabled
                                  ? 'البحث في الإنترنت (مفعّل)'
                                  : 'البحث في الإنترنت',
                          onPressed: () {
                            setState(() {
                              _webSearchEnabled = !_webSearchEnabled;
                            });
                          },
                          icon: Icon(
                            Icons.travel_explore,
                            color: _activeColor(_webSearchEnabled),
                          ),
                        ),
                        IconButton(
                          tooltip:
                              _thinkingEnabled
                                  ? 'وضع التفكير العميق (مفعّل)'
                                  : 'وضع التفكير العميق',
                          onPressed: () {
                            setState(() {
                              _thinkingEnabled = !_thinkingEnabled;
                            });
                          },
                          icon: Icon(
                            _thinkingEnabled
                                ? Icons.psychology
                                : Icons.psychology_outlined,
                            color: _activeColor(_thinkingEnabled),
                          ),
                        ),
                        IconButton(
                          icon:
                              attachmentState is AttachmentPicking
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.image_outlined),
                          tooltip: 'إرفاق صورة',
                          onPressed:
                              attachmentState is AttachmentPicking
                                  ? null
                                  : () =>
                                      context
                                          .read<AttachmentCubit>()
                                          .pickImage(),
                        ),
                        IconButton(
                          tooltip:
                              audioState is AudioRecording
                                  ? 'إيقاف التسجيل'
                                  : 'تسجيل رسالة صوتية',
                          onPressed:
                              audioState is AudioRecording
                                  ? () =>
                                      context.read<AudioCubit>().stopAndUpload()
                                  : audioState is AudioIdle ||
                                      audioState is AudioFailure
                                  ? () =>
                                      context
                                          .read<AudioCubit>()
                                          .startRecording()
                                  : null,
                          icon: Icon(
                            audioState is AudioRecording
                                ? Icons.stop_circle_outlined
                                : Icons.mic_none,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            style: const TextStyle(color: Colors.white),
                            cursorColor: const Color(0xFF9F7BFF),
                            decoration: const InputDecoration(
                              hintText: 'اكتب رسالتك هنا...',
                              border: InputBorder.none,
                              filled: false,
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            gradient:
                                _controller.text.trim().isNotEmpty
                                    ? const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF8E6BFF),
                                        Color(0xFF5B3DD8),
                                      ],
                                    )
                                    : null,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                            ),
                            tooltip: 'إرسال',
                            onPressed: () => _send(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }
}
