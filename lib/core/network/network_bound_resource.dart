import 'package:dartz/dartz.dart';

import '../errors/failures.dart';

enum CachePolicy { cacheFirst, networkFirst, networkOnly, cacheOnly }

mixin NetworkBoundResource {
  Future<Either<Failure, T>> execute<T>({
    required Future<T?> Function() getCache,
    required Future<T> Function() getRemote,
    required CachePolicy policy,
    required Future<void> Function(T data) saveCache,
  }) async {
    try {
      switch (policy) {
        case CachePolicy.cacheFirst:
          final cached = await getCache();

          if (cached != null) {
            return Right(cached);
          }

          final remote = await getRemote();
          await saveCache(remote);

          return Right(remote);

        case CachePolicy.networkFirst:
          try {
            final remote = await getRemote();
            await saveCache(remote);

            return Right(remote);
          } catch (_) {
            final cached = await getCache();

            if (cached != null) {
              return Right(cached);
            }

            rethrow;
          }

        case CachePolicy.networkOnly:
          final remote = await getRemote();
          await saveCache(remote);

          return Right(remote);

        case CachePolicy.cacheOnly:
          final cached = await getCache();

          if (cached != null) {
            return Right(cached);
          }

          return const Left(CacheFailure());
      }
    } on Failure catch (failure) {
      return Left(failure);
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }
}
