import 'package:flutter_ai_app/core/di/attachment_locator.dart';

import '../../features/chat/data/datasources/chat_remote_data_source.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';

import '../../features/chat/domain/repositories/i_chat_repository.dart';

import '../../features/chat/domain/usecases/create_new_chat_use_case.dart';
import '../../features/chat/domain/usecases/delete_chat_session_use_case.dart';
import '../../features/chat/domain/usecases/delete_message_usecase.dart';
import '../../features/chat/domain/usecases/get_chat_sessions_use_case.dart';
import '../../features/chat/domain/usecases/get_messages_usecase.dart';
import '../../features/chat/domain/usecases/load_older_messages.dart';
import '../../features/chat/domain/usecases/retry_message_use_case.dart';
import '../../features/chat/domain/usecases/send_message_usecase.dart';

import '../../features/chat/presentation/cubit/chat_actor_cubit.dart';
import '../../features/chat/presentation/cubit/chat_cubit.dart';

void setupChatDependencies() {
  getIt.registerLazySingleton<IChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(),
  );

  getIt.registerLazySingleton<IChatRepository>(
    () => ChatRepositoryImpl(getIt<IChatRemoteDataSource>()),
  );

  getIt.registerLazySingleton<SendMessageUseCase>(
    () => SendMessageUseCase(getIt<IChatRepository>()),
  );

  getIt.registerLazySingleton<RetryMessageUseCase>(
    () => RetryMessageUseCase(getIt<IChatRepository>()),
  );

  getIt.registerLazySingleton<DeleteMessageUseCase>(
    () => DeleteMessageUseCase(getIt<IChatRepository>()),
  );

  getIt.registerLazySingleton<GetMessagesUseCase>(
    () => GetMessagesUseCase(getIt<IChatRepository>()),
  );

  getIt.registerLazySingleton<GetChatSessionsUseCase>(
    () => GetChatSessionsUseCase(getIt<IChatRepository>()),
  );

  getIt.registerLazySingleton<CreateNewChatUseCase>(
    () => CreateNewChatUseCase(getIt<IChatRepository>()),
  );

  getIt.registerLazySingleton<DeleteChatSessionUseCase>(
    () => DeleteChatSessionUseCase(getIt<IChatRepository>()),
  );

  getIt.registerLazySingleton<LoadOlderMessagesUseCase>(
    () => LoadOlderMessagesUseCase(getIt<IChatRepository>()),
  );

  getIt.registerFactoryParam<ChatCubit, String, void>(
    (chatId, _) => ChatCubit(
      getIt<SendMessageUseCase>(),
      getIt<GetMessagesUseCase>(),
      getIt<CreateNewChatUseCase>(),
      getIt<LoadOlderMessagesUseCase>(),
      getIt<RetryMessageUseCase>(),
      chatId: chatId,
    ),
  );

  getIt.registerFactory<ChatActorCubit>(
    () => ChatActorCubit(getIt<DeleteMessageUseCase>()),
  );
}
