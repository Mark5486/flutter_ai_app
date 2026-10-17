import 'package:flutter_ai_app/core/di/attachment_locator.dart';
import 'package:flutter_ai_app/core/di/audio_locator.dart';
import 'package:flutter_ai_app/core/di/auth_locator.dart';
import 'package:flutter_ai_app/core/di/chat_locator.dart';
import 'package:flutter_ai_app/core/di/core_locator.dart';

Future<void> initServiceLocator() async {
  await setupCoreLocator();

  setupAuthLocator();
  setupChatDependencies();
  setupAttachmentLocator();
  setupAudioDependencies();
}
