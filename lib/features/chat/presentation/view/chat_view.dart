import 'package:flutter/material.dart';
import 'package:flutter_ai_app/core/di/attachment_locator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../attachment/presentation/cubit/attachment_cubit.dart';
import '../../../attachment/presentation/cubit/attachment_state.dart';
import '../../../attachment/presentation/widgets/chat_input_field.dart';
import '../../../audio/presentation/cubit/audio_cubit.dart';
import '../../domain/usecases/get_chat_sessions_use_case.dart';
import '../cubit/chat_actor_cubit.dart';
import '../cubit/chat_actor_state.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../widgets/message_bubble.dart';

class ChatView extends StatelessWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ChatCubit, ChatState>(
          listenWhen: _shouldShowError,
          listener: _showError,
        ),
        BlocListener<ChatActorCubit, ChatActorState>(
          listenWhen:
              (previous, current) => current is ChatActorEditSuccess,
          listener: (context, state) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text('تم تعديل الرسالة، جارٍ توليد رد جديد...'),
                  duration: Duration(seconds: 3),
                ),
              );
          },
        ),
      ],
      child: Scaffold(
        drawer: const _ChatSessionsDrawer(),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1338), Color(0xFF0B0819)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                
                
                constraints: const BoxConstraints(maxWidth: 880),
                child: Column(
                  children: [
                    const _ChatHeader(),
                    const Expanded(child: _ChatMessagesList()),
                    const _ChatComposer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _shouldShowError(ChatState previous, ChatState current) {
    if (current is ChatError) return true;

    if (current is! ChatSuccess) return false;

    final previousSuccess = previous is ChatSuccess ? previous : null;

    return (current.sendError != null &&
            current.sendError != previousSuccess?.sendError) ||
        (current.paginationError != null &&
            current.paginationError != previousSuccess?.paginationError);
  }

  void _showError(BuildContext context, ChatState state) {
    String? message;

    if (state is ChatError) {
      message = state.message;
    } else if (state is ChatSuccess) {
      message = state.sendError ?? state.paginationError;
    }

    if (message == null) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'المحادثات السابقة',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          const SizedBox(width: 4),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8E6BFF), Color(0xFF5B3DD8)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9F7BFF).withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مساعدك الذكي',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.circle, color: Color(0xFF00D4A0), size: 8),
                    SizedBox(width: 4),
                    Text(
                      'متصل الآن',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_comment_outlined, size: 18),
            ),
            tooltip: 'محادثة جديدة',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/chat', arguments: '');
            },
          ),
        ],
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer();

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatCubit, ChatState>(
      listenWhen: (previous, current) {
        final wasSending = previous is ChatSuccess ? previous.isSending : false;
        final isSending = current is ChatSuccess ? current.isSending : false;

        return wasSending && !isSending;
      },
      listener: (context, state) {
        final attachmentCubit = context.read<AttachmentCubit>();
        final isAttachmentUploading =
            attachmentCubit.state is AttachmentUploading;

        final sendError =
            state is ChatSuccess
            ? state.sendError
            : state is ChatError
            ? state.message
            : null;

        if (sendError != null) {
          if (isAttachmentUploading) attachmentCubit.uploadFailed(sendError);
        } else {
          if (isAttachmentUploading) attachmentCubit.resetAttachment();
          context.read<AudioCubit>().resetAudio();
        }
      },
      child: BlocBuilder<ChatCubit, ChatState>(
        buildWhen: (previous, current) {
          final wasSending =
              previous is ChatSuccess ? previous.isSending : false;
          final isSending = current is ChatSuccess ? current.isSending : false;

          return wasSending != isSending;
        },
        builder: (context, state) {
          final isSending = state is ChatSuccess && state.isSending;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSending)
                const LinearProgressIndicator(
                  minHeight: 2,
                  color: Color(0xFF9F7BFF),
                  backgroundColor: Color(0xFF1E1840),
                ),
              IgnorePointer(
                ignoring: isSending,
                child: Opacity(
                  opacity: isSending ? 0.6 : 1,
                  child: ChatInputField(
                    onSendMessage: (
                      text,
                      attachment,
                      audio,
                      webSearch,
                      thinking,
                    ) {
                      final message = text.trim();

                      if (message.isEmpty &&
                          attachment == null &&
                          audio == null) {
                        return;
                      }

                      if (attachment != null) {
                        context.read<AttachmentCubit>().startUploading();
                      }

                      context.read<ChatCubit>().sendMessage(
                        message,
                        attachment: attachment,
                        audio: audio,
                        webSearch: webSearch,
                        thinking: thinking,
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChatSessionsDrawer extends StatelessWidget {
  const _ChatSessionsDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF151230),
      child: SafeArea(
        child: Column(
          children: [
            const ListTile(
              leading: Icon(Icons.history),
              title: Text(
                'المحادثات السابقة',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder(
                stream: getIt<GetChatSessionsUseCase>()(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final result = snapshot.data;

                  if (result == null) {
                    return const SizedBox.shrink();
                  }

                  return result.fold(
                    (failure) => Center(child: Text(failure.message)),
                    (sessions) {
                      if (sessions.isEmpty) {
                        return const Center(
                          child: Text('لا توجد محادثات سابقة'),
                        );
                      }

                      return ListView.builder(
                        itemCount: sessions.length,
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          final id = session.id;
                          final title = session.title;

                          return ListTile(
                            leading: const Icon(Icons.chat_bubble_outline),
                            title: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap:
                                id.isEmpty
                                    ? null
                                    : () {
                                      Navigator.pop(context);
                                      Navigator.pushReplacementNamed(
                                        context,
                                        '/chat',
                                        arguments: id,
                                      );
                                    },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessagesList extends StatefulWidget {
  const _ChatMessagesList();

  @override
  State<_ChatMessagesList> createState() => _ChatMessagesListState();
}

class _ChatMessagesListState extends State<_ChatMessagesList> {
  static const _loadMoreTriggerOffset = 200.0;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();

    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final distanceToOldestMessages = position.maxScrollExtent - position.pixels;

    if (distanceToOldestMessages <= _loadMoreTriggerOffset) {
      context.read<ChatCubit>().loadMoreMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        if (state is ChatLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ChatError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(state.message, textAlign: TextAlign.center),
            ),
          );
        }

        if (state is ChatSuccess) {
          return _buildMessages(state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMessages(ChatSuccess state) {
    if (state.messages.isEmpty) {
      return const _EmptyChatState();
    }

    final showFooter = state.isLoadingMore || state.paginationError != null;

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: state.messages.length + (showFooter ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.messages.length) {
          if (state.isLoadingMore) {
            return const _LoadingOlderMessagesIndicator();
          }

          return _LoadOlderMessagesError(
            message: state.paginationError!,
            onRetry: () {
              context.read<ChatCubit>().loadMoreMessages();
            },
          );
        }

        final message = state.messages[index];

        return MessageBubble(
          message: message,
          chatId: state.chatId,
          onRetry:
              message.isFailed
                  ? () {
                    context.read<ChatCubit>().retryMessage(message.id);
                  }
                  : null,
        );
      },
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

  static const _suggestions = [
    'اشرح لي Flutter في ثلاث نقاط',
    'اكتب لي خطة مذاكرة أسبوعية',
    'لخّص لي آخر أخبار التقنية',
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF8E6BFF), Color(0xFF5B3DD8)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9F7BFF).withValues(alpha: 0.35),
                    blurRadius: 26,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'اسألني أي حاجة',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'نص، صورة، أو صوت — وردّي يوصلك في ثواني',
              style: TextStyle(fontSize: 14, color: Colors.white60),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ..._suggestions.map(
              (suggestion) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap:
                      () => context.read<ChatCubit>().sendMessage(suggestion),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1840).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          color: Color(0xFF9F7BFF),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          suggestion,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingOlderMessagesIndicator extends StatelessWidget {
  const _LoadingOlderMessagesIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _LoadOlderMessagesError extends StatelessWidget {
  const _LoadOlderMessagesError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text('تعذر تحميل رسائل أقدم: $message'),
        ),
      ),
    );
  }
}
