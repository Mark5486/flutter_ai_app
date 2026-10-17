import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../attachment/domain/entity/attachment_entity.dart';
import '../../../audio/domain/entity/audio_entity.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/create_new_chat_use_case.dart';
import '../../domain/usecases/get_messages_usecase.dart';
import '../../domain/usecases/load_older_messages.dart';
import '../../domain/usecases/retry_message_use_case.dart';
import '../../domain/usecases/send_message_usecase.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit(
    this._sendMessageUseCase,
    this._getMessagesUseCase,
    this._createNewChatUseCase,
    this._loadOlderMessagesUseCase,
    this._retryMessageUseCase, {
    required String chatId,
  }) : activeChatId = chatId,
       super(ChatInitial()) {
    initChat();
  }

  static const _pageSize = 30;

  final SendMessageUseCase _sendMessageUseCase;
  final GetMessagesUseCase _getMessagesUseCase;
  final CreateNewChatUseCase _createNewChatUseCase;
  final LoadOlderMessagesUseCase _loadOlderMessagesUseCase;
  final RetryMessageUseCase _retryMessageUseCase;

  String activeChatId;
  StreamSubscription? _messagesSubscription;

  bool _isSending = false;
  bool get isSending => _isSending;

  Future<void> initChat() async {
    if (activeChatId.isEmpty) {
      emit(const ChatSuccess(messages: [], chatId: '', hasMore: false));
      return;
    }

    getMessages();
  }

  void getMessages() {
    if (activeChatId.isEmpty) return;

    _messagesSubscription?.cancel();
    emit(ChatLoading());

    _messagesSubscription = _getMessagesUseCase(
      activeChatId,
      limit: _pageSize,
    ).listen((result) {
      if (isClosed) return;

      result.fold(
        (failure) {
          final currentState = state;

          if (currentState is ChatSuccess) {
            emit(
              currentState.copyWith(
                isLoadingMore: false,
                sendError: failure.message,
              ),
            );
          } else {
            emit(ChatError(failure.message));
          }
        },
        (liveMessages) {
          final previousState = state;

          final oldMessages =
              previousState is ChatSuccess
                  ? previousState.messages
                  : const <ChatMessage>[];

          final mergedMessages = _mergeMessages(liveMessages, oldMessages);

          emit(
            ChatSuccess(
              messages: mergedMessages,
              chatId: activeChatId,
              hasMore:
                  previousState is ChatSuccess
                      ? previousState.hasMore
                      : liveMessages.length >= _pageSize,
              isLoadingMore:
                  previousState is ChatSuccess
                      ? previousState.isLoadingMore
                      : false,
              isSending: _isSending,
            ),
          );
        },
      );
    });
  }

  Future<void> loadMoreMessages() async {
    final initialState = state;

    if (initialState is! ChatSuccess ||
        !initialState.hasMore ||
        initialState.isLoadingMore ||
        initialState.messages.isEmpty) {
      return;
    }

    emit(
      initialState.copyWith(isLoadingMore: true, clearPaginationError: true),
    );

    final oldestMessage = initialState.messages.last;

    final result = await _loadOlderMessagesUseCase(
      chatId: activeChatId,
      beforeMessage: oldestMessage,
      limit: _pageSize,
    );

    if (isClosed || state is! ChatSuccess) return;

    final latestState = state as ChatSuccess;

    result.fold(
      (failure) {
        emit(
          latestState.copyWith(
            isLoadingMore: false,
            paginationError: failure.message,
          ),
        );
      },
      (olderMessages) {
        emit(
          latestState.copyWith(
            messages: _mergeMessages(latestState.messages, olderMessages),
            hasMore: olderMessages.length >= _pageSize,
            isLoadingMore: false,
            clearPaginationError: true,
          ),
        );
      },
    );
  }

  Future<void> sendMessage(
    String text, {
    AttachmentEntity? attachment,
    AudioEntity? audio,
  }) async {
    if (_isSending ||
        (text.trim().isEmpty && attachment == null && audio == null)) {
      return;
    }

    _isSending = true;
    _emitSendingState();

    try {
      if (activeChatId.isEmpty) {
        final createResult = await _createNewChatUseCase();

        final newChatId = createResult.fold<String?>((failure) {
          _emitSendError(failure.message);
          return null;
        }, (chatId) => chatId);

        if (newChatId == null || newChatId.isEmpty) return;

        activeChatId = newChatId;
        getMessages();
      }

      final result = await _sendMessageUseCase(
        chatId: activeChatId,
        text: text.trim(),
        attachment: attachment,
        audio: audio,
      );

      result.fold(
        (failure) => _emitSendError(failure.message),
        (_) => _clearSendingState(),
      );
    } finally {
      _isSending = false;
      _clearSendingState();
    }
  }

  Future<void> retryMessage(String messageId) async {
    if (_isSending || activeChatId.isEmpty || messageId.trim().isEmpty) {
      return;
    }

    _isSending = true;
    _emitSendingState();

    try {
      final result = await _retryMessageUseCase(
        chatId: activeChatId,
        messageId: messageId,
      );

      result.fold(
        (failure) => _emitSendError(failure.message),
        (_) => _clearSendingState(),
      );
    } finally {
      _isSending = false;
      _clearSendingState();
    }
  }

  void _emitSendingState() {
    final currentState = state;

    if (currentState is ChatSuccess) {
      emit(currentState.copyWith(isSending: true, clearSendError: true));
    }
  }

  void _clearSendingState() {
    final currentState = state;

    if (currentState is ChatSuccess && currentState.isSending) {
      emit(currentState.copyWith(isSending: false, clearSendError: true));
    }
  }

  void _emitSendError(String message) {
    final currentState = state;

    if (currentState is ChatSuccess) {
      emit(currentState.copyWith(isSending: false, sendError: message));
    } else {
      emit(ChatError(message));
    }
  }

  List<ChatMessage> _mergeMessages(
    List<ChatMessage> first,
    List<ChatMessage> second,
  ) {
    final messagesById = <String, ChatMessage>{};

    for (final message in [...second, ...first]) {
      messagesById[message.id] = message;
    }

    final messages =
        messagesById.values.toList()..sort((a, b) {
          final timeComparison = b.timestamp.compareTo(a.timestamp);

          if (timeComparison != 0) {
            return timeComparison;
          }

          return b.id.compareTo(a.id);
        });

    return messages;
  }

  @override
  Future<void> close() async {
    await _messagesSubscription?.cancel();
    return super.close();
  }
}
