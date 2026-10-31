
import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message.dart';
import '../../../attachment/domain/entity/attachment_entity.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatSuccess extends ChatState {
  const ChatSuccess({
    required this.messages,
    required this.chatId,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.isSending = false,
    this.paginationError,
    this.sendError,
    this.attachment,
  });

  final List<ChatMessage> messages;
  final String chatId;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isSending;
  final String? paginationError;
  final String? sendError;
  final AttachmentEntity? attachment;

  ChatSuccess copyWith({
    List<ChatMessage>? messages,
    String? chatId,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isSending,
    String? paginationError,
    String? sendError,
    AttachmentEntity? attachment,
    bool clearPaginationError = false,
    bool clearSendError = false,
  }) {
    return ChatSuccess(
      messages: messages ?? this.messages,
      chatId: chatId ?? this.chatId,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSending: isSending ?? this.isSending,
      paginationError:
          clearPaginationError ? null : paginationError ?? this.paginationError,
      sendError: clearSendError ? null : sendError ?? this.sendError,
      attachment: attachment ?? this.attachment,
    );
  }

  @override
  List<Object?> get props => [
    messages,
    chatId,
    hasMore,
    isLoadingMore,
    isSending,
    paginationError,
    sendError,
    attachment,
  ];
}

class ChatError extends ChatState {
  const ChatError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
