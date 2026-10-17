import 'package:get_it/get_it.dart';

import '../../features/attachment/data/datasources/attachment_remote_data_source.dart';
import '../../features/attachment/data/repositories/attachment_repository_impl.dart';
import '../../features/attachment/domain/repository/attachment_repository.dart';
import '../../features/attachment/domain/usecases/pick_image_attachment_use_case.dart';
import '../../features/attachment/presentation/cubit/attachment_cubit.dart';

final getIt = GetIt.instance;

void setupAttachmentLocator() {
  getIt.registerLazySingleton<IAttachmentRemoteDataSource>(
    () => const AttachmentRemoteDataSourceImpl(),
  );

  getIt.registerLazySingleton<IAttachmentRepository>(
    () => AttachmentRepositoryImpl(getIt<IAttachmentRemoteDataSource>()),
  );

  getIt.registerLazySingleton<PickImageAttachmentUseCase>(
    () => PickImageAttachmentUseCase(getIt<IAttachmentRepository>()),
  );

  getIt.registerFactory<AttachmentCubit>(
    () => AttachmentCubit(getIt<PickImageAttachmentUseCase>()),
  );
}
