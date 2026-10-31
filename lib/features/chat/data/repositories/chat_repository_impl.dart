import 'package:dartz/dartz.dart';
import 'package:flutter_ai_app/features/audio/domain/entity/audio_entity.dart';

import '../../../../core/errors/failures.dart';
import '../../../attachment/domain/entity/attachment_entity.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/repositories/i_chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';

class ChatRepositoryImpl implements IChatRepository {
  final IChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl(this.remoteDataSource);

  @override
  Stream<Either<Failure, List<ChatSession>>> getChatSessions() async* {
    try {
      await for (final sessions in remoteDataSource.getChatSessions()) {
        yield Right(sessions.map((model) => model.toEntity()).toList());
      }
    } catch (error) {
      yield Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createNewChat() async {
    try {
      final chatId = await remoteDataSource.createNewChat();
      return Right(chatId);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<ChatMessage>>> getMessages(
    String chatId, {
    int limit = 30,
  }) async* {
    try {
      await for (final models in remoteDataSource.getMessages(
        chatId,
        limit: limit,
      )) {
        yield Right(models.map((model) => model.toEntity()).toList());
      }
    } catch (e) {
      yield Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessage>>> loadOlderMessages(
    String chatId, {
    required DateTime beforeTimestamp,
    required String beforeMessageId,
    int limit = 30,
  }) async {
    try {
      final models = await remoteDataSource.loadOlderMessages(
        chatId,
        beforeTimestamp: beforeTimestamp,
        beforeMessageId: beforeMessageId,
        limit: limit,
      );

      return Right(models.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendMessage(
    String chatId,
    String text, {
    AttachmentEntity? attachment,
    AudioEntity? audio,
    bool webSearch = false,
    bool thinking = false,
  }) async {
    try {
      await remoteDataSource.sendMessage(
        chatId,
        text,
        attachment: attachment,
        audio: audio,
        webSearch: webSearch,
        thinking: thinking,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> retryMessage(
    String chatId,
    String messageId,
  ) async {
    try {
      await remoteDataSource.retryMessage(chatId, messageId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> editMessage(
    String chatId,
    String messageId,
    String newText,
  ) async {
    try {
      await remoteDataSource.editMessage(chatId, messageId, newText);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteChatSession(String chatId) async {
    try {
      await remoteDataSource.deleteChatSession(chatId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
