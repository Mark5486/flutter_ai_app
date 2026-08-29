import 'package:flutter/material.dart';
import 'package:flutter_ai_app/core/di/attachment_locator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../attachment/presentation/cubit/attachment_cubit.dart';
import '../../../attachment/presentation/cubit/attachment_state.dart';
import '../../../attachment/presentation/widgets/chat_input_field.dart';
import '../../domain/usecases/get_chat_sessions_use_case.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../widgets/message_bubble.dart';

class ChatView extends StatelessWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatCubit, ChatState>(
      listenWhen: _shouldShowError,
      listener: _showError,
      child: Scaffold(
        appBar: _buildAppBar(context),
        drawer: const _ChatSessionsDrawer(),
        body: const Column(
          children: [Expanded(child: _ChatMessagesList()), _ChatComposer()],
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

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('المحادثة'),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_comment_outlined),
          tooltip: 'محادثة جديدة',
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/chat', arguments: '');
          },
        ),
      ],
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

        if (attachmentCubit.state is! AttachmentUploading) return;

        final sendError = state is ChatSuccess ? state.sendError : null;

        if (sendError != null) {
          attachmentCubit.uploadFailed(sendError);
        } else {
          attachmentCubit.resetAttachment();
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
              if (isSending) const LinearProgressIndicator(minHeight: 2),
              IgnorePointer(
                ignoring: isSending,
                child: Opacity(
                  opacity: isSending ? 0.6 : 1,
                  child: ChatInputField(
                    onSendMessage: (text, attachment) {
                      final message = text.trim();

                      if (message.isEmpty && attachment == null) return;

                      if (attachment != null) {
                        context.read<AttachmentCubit>().startUploading();
                      }

                      context.read<ChatCubit>().sendMessage(
                        message,
                        attachment: attachment,
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
                          final id = session['id'] as String? ?? '';
                          final title = session['title'] as String? ?? 'محادثة';

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
      return const Center(child: Text('ابدأ المحادثة الآن...'));
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
