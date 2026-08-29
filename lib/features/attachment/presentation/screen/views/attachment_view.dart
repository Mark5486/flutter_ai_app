import 'package:flutter/material.dart';
import 'package:flutter_ai_app/features/attachment/presentation/cubit/attachment_cubit.dart';
import 'package:flutter_ai_app/features/attachment/presentation/cubit/attachment_state.dart';
import 'package:flutter_ai_app/features/attachment/presentation/widgets/attachment_preview_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AttachmentView extends StatelessWidget {
  const AttachmentView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () => context.read<AttachmentCubit>().pickImage(),
            icon: const Icon(Icons.image_outlined),
            label: const Text('اختيار صورة'),
          ),
          const SizedBox(height: 24),
          BlocBuilder<AttachmentCubit, AttachmentState>(
            builder: (context, state) {
              if (state is AttachmentPicking) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (state is AttachmentReady) {
                return AttachmentPreviewBar(
                  attachment: state.attachment,
                  onRemove:
                      () => context.read<AttachmentCubit>().resetAttachment(),
                );
              }

              if (state is AttachmentFailure) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          state.message,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed:
                              () => context.read<AttachmentCubit>().retry(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'قم باختيار صورة لعرضها هنا',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
