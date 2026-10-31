import 'package:flutter/material.dart';
import 'package:flutter_ai_app/core/di/attachment_locator.dart';
import 'package:flutter_ai_app/features/chat/presentation/view/chat_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../attachment/presentation/cubit/attachment_cubit.dart';
import '../../../audio/presentation/cubit/audio_cubit.dart';
import '../cubit/chat_actor_cubit.dart';
import '../cubit/chat_cubit.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key, required this.chatId});

  final String chatId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AttachmentCubit>(create: (_) => getIt<AttachmentCubit>()),
        BlocProvider<AudioCubit>(create: (_) => getIt<AudioCubit>()),
        BlocProvider<ChatCubit>(
          create: (_) => getIt<ChatCubit>(param1: chatId),
        ),
        BlocProvider<ChatActorCubit>(create: (_) => getIt<ChatActorCubit>()),
      ],
      child: const ChatView(),
    );
  }
}
