import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/delete_message_usecase.dart';
import 'chat_actor_state.dart';

class ChatActorCubit extends Cubit<ChatActorState> {
  final DeleteMessageUseCase _deleteMessageUseCase;

  ChatActorCubit(this._deleteMessageUseCase) : super(ChatActorInitial());

  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    emit(ChatActorLoading());

    final result = await _deleteMessageUseCase(
      chatId: chatId,
      messageId: messageId,
    );

    result.fold(
      (failure) => emit(ChatActorError(failure.message)),
      (_) => emit(ChatActorDeleteSuccess(messageId)),
    );
  }
}
