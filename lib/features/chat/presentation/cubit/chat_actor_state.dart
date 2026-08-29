import 'package:equatable/equatable.dart';

abstract class ChatActorState extends Equatable {
  const ChatActorState();

  @override
  List<Object?> get props => [];
}

class ChatActorInitial extends ChatActorState {}

class ChatActorLoading extends ChatActorState {}

class ChatActorDeleteSuccess extends ChatActorState {
  final String messageId;

  const ChatActorDeleteSuccess(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

class ChatActorError extends ChatActorState {
  final String message;

  const ChatActorError(this.message);

  @override
  List<Object?> get props => [message];
}
