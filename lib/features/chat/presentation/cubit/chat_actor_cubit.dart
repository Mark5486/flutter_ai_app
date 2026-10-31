import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/edit_message_usecase.dart';
import 'chat_actor_state.dart';

class ChatActorCubit extends Cubit<ChatActorState> {
  final EditMessageUseCase _editMessageUseCase;

  ChatActorCubit(this._editMessageUseCase) : super(ChatActorInitial());

  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String newText,
  }) async {
    emit(ChatActorLoading());

    final result = await _editMessageUseCase(
      chatId: chatId,
      messageId: messageId,
      newText: newText,
    );

    result.fold(
      (failure) => emit(ChatActorError(failure.message)),
      (_) => emit(ChatActorEditSuccess(messageId)),
    );
  }
}
