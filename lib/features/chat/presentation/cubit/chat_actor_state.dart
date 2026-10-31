import 'package:equatable/equatable.dart';

abstract class ChatActorState extends Equatable {
  const ChatActorState();

  @override
  List<Object?> get props => [];
}

class ChatActorInitial extends ChatActorState {
  const ChatActorInitial();
}

class ChatActorLoading extends ChatActorState {
  const ChatActorLoading();
}

class ChatActorEditSuccess extends ChatActorState {
  final String messageId;

  const ChatActorEditSuccess(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

class ChatActorError extends ChatActorState {
  final String message;

  const ChatActorError(this.message);

  @override
  List<Object?> get props => [message];
}
