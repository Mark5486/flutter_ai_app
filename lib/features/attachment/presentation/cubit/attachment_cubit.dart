import 'package:flutter_ai_app/features/attachment/domain/usecases/PickImage_attachment.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'attachment_state.dart';

class AttachmentCubit extends Cubit<AttachmentState> {
  AttachmentCubit(this._pickImageAttachmentUseCase) : super(AttachmentIdle());

  final PickImageAttachmentUseCase _pickImageAttachmentUseCase;

  Future<void> pickImage() async {
    emit(AttachmentPicking());

    final result = await _pickImageAttachmentUseCase();

    result.fold((failure) => emit(AttachmentFailure(failure.message)), (
      attachment,
    ) {
      if (attachment != null) {
        emit(AttachmentReady(attachment));
      } else {
        emit(AttachmentIdle());
      }
    });
  }

  void startUploading() {
    final currentState = state;

    if (currentState is AttachmentReady) {
      emit(AttachmentUploading(currentState.attachment));
    }
  }

  void uploadFailed(String message) {
    final currentState = state;

    final previousAttachment =
        currentState is AttachmentUploading ? currentState.attachment : null;

    emit(AttachmentFailure(message, previousAttachment: previousAttachment));
  }

  void retry() {
    final currentState = state;

    if (currentState is AttachmentFailure &&
        currentState.previousAttachment != null) {
      emit(AttachmentReady(currentState.previousAttachment!));
      return;
    }

    pickImage();
  }

  void resetAttachment() {
    emit(AttachmentIdle());
  }
}
