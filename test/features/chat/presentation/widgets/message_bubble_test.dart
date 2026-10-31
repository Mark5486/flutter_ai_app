import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_app/features/chat/domain/entities/chat_message.dart';
import 'package:flutter_ai_app/features/chat/domain/entities/message_source.dart';
import 'package:flutter_ai_app/features/chat/domain/usecases/edit_message_usecase.dart';
import 'package:flutter_ai_app/features/chat/presentation/cubit/chat_actor_cubit.dart';
import 'package:flutter_ai_app/features/chat/presentation/widgets/message_bubble.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_chat_repository.dart';

void main() {
  late MockChatRepository repository;

  setUp(() {
    repository = MockChatRepository();
  });

  ChatActorCubit buildActorCubit() {
    final cubit = ChatActorCubit(
      EditMessageUseCase(repository),
    );
    addTearDown(cubit.close);
    return cubit;
  }

  Widget wrapApp(Widget child, {ChatActorCubit? cubit}) {
    return BlocProvider<ChatActorCubit>.value(
      value: cubit ?? buildActorCubit(),
      child: MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  ChatMessage userMessage({
    String text = 'محتوى الرسالة',
    MessageStatus status = MessageStatus.sent,
    bool isEdited = false,
    String? originalText,
  }) {
    return fakeChatMessage(
      text: text,
      sender: MessageSender.user,
      status: status,
      isEdited: isEdited,
      originalText: originalText,
    );
  }

  group('MessageBubble', () {
    testWidgets('renders the text and the sent status of a user message', (tester) async {
      await tester.pumpWidget(wrapApp(
        MessageBubble(message: userMessage(), chatId: 'chat-1'),
      ));

      expect(find.text('محتوى الرسالة'), findsOneWidget);
      expect(find.text('تم الإرسال'), findsOneWidget);
    });

    testWidgets('shows the edited toggle only on edited messages that keep the original text', (tester) async {
      await tester.pumpWidget(wrapApp(
        SingleChildScrollView(
          child: Column(
            children: [
              MessageBubble(
                message: fakeChatMessage(text: 'رسالة عادية'),
                chatId: 'chat-1',
              ),
            ],
          ),
        ),
      ));

      expect(find.text('معدّلة'), findsNothing);

      await tester.pumpWidget(wrapApp(
        SingleChildScrollView(
          child: Column(
            children: [
              MessageBubble(
                message: userMessage(
                  text: 'رسالة معدلة',
                  isEdited: true,
                  originalText: 'النص القديم',
                ),
                chatId: 'chat-1',
              ),
            ],
          ),
        ),
      ));

      expect(find.text('معدّلة'), findsOneWidget);
    });

    testWidgets('the edited toggle reveals the original text and hides the new one, then toggles back', (tester) async {
      await tester.pumpWidget(wrapApp(
        SingleChildScrollView(
          child: Column(
            children: [
              MessageBubble(
                message: userMessage(
                  text: 'النص بعد التعديل',
                  isEdited: true,
                  originalText: 'النص قبل التعديل',
                ),
                chatId: 'chat-1',
              ),
            ],
          ),
        ),
      ));

      
      expect(find.text('النص بعد التعديل'), findsOneWidget);
      expect(find.text('النص قبل التعديل'), findsNothing);

      
      await tester.tap(find.text('معدّلة'));
      await tester.pumpAndSettle();

      expect(find.text('النص قبل التعديل'), findsOneWidget);
      expect(find.text('النص بعد التعديل'), findsNothing);
      expect(find.text('المعدّلة'), findsOneWidget);

      
      await tester.tap(find.text('المعدّلة'));
      await tester.pumpAndSettle();

      expect(find.text('النص بعد التعديل'), findsOneWidget);
      expect(find.text('النص قبل التعديل'), findsNothing);
    });

    testWidgets('shows the failure state with a retry action when provided', (tester) async {
      await tester.pumpWidget(wrapApp(
        MessageBubble(
          message: userMessage(status: MessageStatus.failed),
          chatId: 'chat-1',
          onRetry: () {},
        ),
      ));

      expect(find.text('فشل الإرسال'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
    });

    testWidgets('shows the sending indicator for a message still in flight', (tester) async {
      await tester.pumpWidget(wrapApp(
        MessageBubble(message: userMessage(status: MessageStatus.sending), chatId: 'chat-1'),
      ));

      expect(find.text('جارٍ الإرسال'), findsOneWidget);
    });

    testWidgets('long-press on a user text message opens the edit dialog directly', (tester) async {
      await tester.pumpWidget(wrapApp(
        MessageBubble(message: userMessage(), chatId: 'chat-1'),
      ));

      await tester.longPress(find.text('محتوى الرسالة'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('تعديل الرسالة'), findsOneWidget);
      expect(find.text('حذف الرسالة'), findsNothing);
    });

    testWidgets('long-press on an AI message does nothing', (tester) async {
      final aiMessage = fakeChatMessage(text: 'رد الذكاء الاصطناعي', sender: MessageSender.ai);

      await tester.pumpWidget(wrapApp(
        MessageBubble(message: aiMessage, chatId: 'chat-1'),
      ));

      await tester.longPress(find.text('رد الذكاء الاصطناعي'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('the thinking panel expands and reveals the thought summary', (tester) async {
      final aiMessage = fakeChatMessage(
        text: 'الرد النهائي',
        sender: MessageSender.ai,
        thoughts: 'فكرت في المسألة خطوة بخطوة وجربت طريقتين',
      );

      await tester.pumpWidget(wrapApp(
        MessageBubble(message: aiMessage, chatId: 'chat-1'),
      ));

      expect(find.text('كيف فكرت؟'), findsOneWidget);
      expect(find.text('فكرت في المسألة خطوة بخطوة وجربت طريقتين'), findsNothing);

      await tester.tap(find.text('كيف فكرت؟'));
      await tester.pumpAndSettle();

      expect(find.text('فكرت في المسألة خطوة بخطوة وجربت طريقتين'), findsOneWidget);
      expect(find.text('إخفاء التفكير'), findsOneWidget);
    });

    testWidgets('the sources section renders the label and host chips', (tester) async {
      final aiMessage = fakeChatMessage(
        text: 'رد مبني على بحث حقيقي',
        sender: MessageSender.ai,
        sources: const [
          MessageSource(title: 'موسوعة ويكيبيديا', url: 'https://ar.wikipedia.org/wiki/Flutter'),
        ],
      );

      await tester.pumpWidget(wrapApp(
        MessageBubble(message: aiMessage, chatId: 'chat-1'),
      ));

      expect(find.text('المصادر:'), findsOneWidget);
      expect(find.text('ar.wikipedia.org'), findsOneWidget);
    });

    testWidgets('the edit dialog submits the new text through the cubit', (tester) async {
      when(() => repository.editMessage('chat-1', 'msg-1', 'النص بعد التعديل'))
          .thenAnswer((_) async => const Right(null));

      final cubit = buildActorCubit();

      await tester.pumpWidget(wrapApp(
        MessageBubble(message: userMessage(), chatId: 'chat-1'),
        cubit: cubit,
      ));

      await tester.longPress(find.text('محتوى الرسالة'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'النص بعد التعديل');
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();

      verify(() => repository.editMessage('chat-1', 'msg-1', 'النص بعد التعديل')).called(1);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
