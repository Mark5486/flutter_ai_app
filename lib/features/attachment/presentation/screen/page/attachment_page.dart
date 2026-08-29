import 'package:flutter/material.dart';
import 'package:flutter_ai_app/core/di/attachment_locator.dart';
import 'package:flutter_ai_app/features/attachment/presentation/cubit/attachment_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../views/attachment_view.dart';

class AttachmentScreen extends StatelessWidget {
  const AttachmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AttachmentCubit>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('رفع صورة'), centerTitle: true),
        body: const AttachmentView(),
      ),
    );
  }
}
