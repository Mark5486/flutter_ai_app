import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_ai_app/features/audio/domain/entity/audio_entity.dart';
import 'package:flutter_ai_app/features/chat/domain/entities/message_source.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;

import '../../../attachment/domain/entity/attachment_entity.dart';
import '../models/chat_session_model.dart';
import '../models/chat_message_model.dart';

abstract class IChatRemoteDataSource {
  Stream<List<ChatSessionModel>> getChatSessions();

  Future<String> createNewChat();

  Stream<List<ChatMessageModel>> getMessages(String chatId, {int limit});

  Future<List<ChatMessageModel>> loadOlderMessages(
    String chatId, {
    required DateTime beforeTimestamp,
    required String beforeMessageId,
    int limit,
  });

  Future<void> sendMessage(
    String chatId,
    String text, {
    AttachmentEntity? attachment,
    AudioEntity? audio,
    bool webSearch,
    bool thinking,
  });

  Future<void> retryMessage(String chatId, String messageId);

  Future<void> editMessage(String chatId, String messageId, String newText);

  Future<void> deleteChatSession(String chatId);
}

class ChatRemoteDataSourceImpl implements IChatRemoteDataSource {
  ChatRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    http.Client? httpClient,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _httpClient = httpClient ?? http.Client();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final http.Client _httpClient;

  static const _usersCollection = 'users';
  static const _chatsCollection = 'chats';
  static const _messagesCollection = 'messages';

  static const _fieldTitle = 'title';
  static const _fieldCreatedAt = 'createdAt';
  static const _fieldUpdatedAt = 'updatedAt';

  static const _fieldText = 'text';
  static const _fieldSenderId = 'senderId';
  static const _fieldTimestamp = 'timestamp';
  static const _fieldStatus = 'status';
  static const _fieldReplyTo = 'replyTo';
  static const _fieldImageUrl = 'imageUrl';
  static const _fieldImageMimeType = 'imageMimeType';
  static const _fieldAudioUrl = 'audioUrl';
  static const _fieldThoughts = 'thoughts';
  static const _fieldSources = 'sources';
  static const _fieldIsEdited = 'isEdited';
  static const _fieldOriginalText = 'originalText';
  static const _fieldEditedAt = 'editedAt';

  static const _senderUser = 'user';
  static const _senderAi = 'ai';

  static const _statusSending = 'sending';
  static const _statusSent = 'sent';
  static const _statusFailed = 'failed';

  static const _defaultChatTitle = 'محادثة جديدة';
  static const _imageOnlyTitlePreview = 'صورة';
  static const _audioOnlyTitlePreview = 'رسالة صوتية';
  static const _defaultPageSize = 30;
  static const _contextMessagesLimit = 20;
  static const _titlePreviewLength = 25;
  static const _maxMessageLength = 6000;

  static const _backendUrl =
      'https://flutter-ai-backend.markrafik633.workers.dev';

  static const _compressedMime = 'image/jpeg';
  static const _maxEncodedImageChars = 900 * 1000;
  static const _hardEncodedImageLimit = 950 * 1000;

  String get _userId {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      throw FirebaseAuthException(
        code: 'unauthenticated',
        message: 'يجب تسجيل الدخول لاستخدام المحادثة.',
      );
    }

    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _userChatsCollection {
    return _firestore
        .collection(_usersCollection)
        .doc(_userId)
        .collection(_chatsCollection);
  }

  @override
  Stream<List<ChatSessionModel>> getChatSessions() {
    return _userChatsCollection
        .orderBy(_fieldUpdatedAt, descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(ChatSessionModel.fromFirestore).toList(),
        );
  }

  @override
  Future<String> createNewChat() async {
    final chatRef = await _userChatsCollection.add({
      _fieldTitle: _defaultChatTitle,
      _fieldCreatedAt: FieldValue.serverTimestamp(),
      _fieldUpdatedAt: FieldValue.serverTimestamp(),
    });

    return chatRef.id;
  }

  @override
  Stream<List<ChatMessageModel>> getMessages(
    String chatId, {
    int limit = _defaultPageSize,
  }) {
    _validateChatId(chatId);

    return _chatMessagesCollection(chatId)
        .orderBy(_fieldTimestamp, descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit)
        .snapshots()
        .map(_mapMessagesSnapshot);
  }

  @override
  Future<List<ChatMessageModel>> loadOlderMessages(
    String chatId, {
    required DateTime beforeTimestamp,
    required String beforeMessageId,
    int limit = _defaultPageSize,
  }) async {
    _validateChatId(chatId);

    final snapshot =
        await _chatMessagesCollection(chatId)
            .orderBy(_fieldTimestamp, descending: true)
            .orderBy(FieldPath.documentId, descending: true)
            .startAfter([Timestamp.fromDate(beforeTimestamp), beforeMessageId])
            .limit(limit)
            .get();

    return _mapMessagesSnapshot(snapshot);
  }

  @override
  Future<void> sendMessage(
    String chatId,
    String text, {
    AttachmentEntity? attachment,
    AudioEntity? audio,
    bool webSearch = false,
    bool thinking = false,
  }) async {
    _validateChatId(chatId);

    final messageText = text.trim();
    _validateMessage(
      messageText,
      allowEmpty: attachment != null || audio != null,
    );
    final chatRef = _userChatsCollection.doc(chatId);
    final messagesRef = chatRef.collection(_messagesCollection);
    final userMessageRef = messagesRef.doc();

    String? imageUrl;
    String? audioUrl;
    _PreparedImage? preparedImage;

    if (attachment != null) {
      preparedImage = await _prepareImageData(attachment.bytes);
      imageUrl = preparedImage.dataUrl;
    }
    if (audio != null) {
      audioUrl = audio.url;
    }

    final batch = _firestore.batch();
    batch.set(userMessageRef, {
      _fieldText: messageText,
      _fieldSenderId: _senderUser,
      _fieldStatus: _statusSending,
      _fieldTimestamp: FieldValue.serverTimestamp(),
      if (imageUrl != null) _fieldImageUrl: imageUrl,
      if (attachment != null) _fieldImageMimeType: _compressedMime,
      if (audioUrl != null) _fieldAudioUrl: audioUrl,
    });

    final preview =
        messageText.isNotEmpty
            ? messageText
            : attachment != null
            ? _imageOnlyTitlePreview
            : _audioOnlyTitlePreview;
    final title =
        preview.length > _titlePreviewLength
            ? '${preview.substring(0, _titlePreviewLength)}...'
            : preview;
    batch.set(chatRef, {
      _fieldTitle: title,
      _fieldUpdatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();

    await _generateAndSaveReply(
      chatId: chatId,
      userMessageRef: userMessageRef,
      imageBytes: preparedImage?.bytes,
      imageMimeType: preparedImage != null ? _compressedMime : null,
      webSearch: webSearch,
      thinking: thinking,
    );
  }

  @override
  Future<void> editMessage(
    String chatId,
    String messageId,
    String newText,
  ) async {
    _validateChatId(chatId);

    final messageText = newText.trim();
    _validateMessage(messageText);

    final messageRef = _chatMessagesCollection(chatId).doc(messageId);
    final messageSnapshot = await messageRef.get();

    if (!messageSnapshot.exists) {
      throw StateError('الرسالة غير موجودة.');
    }

    final data = messageSnapshot.data()!;

    if (data[_fieldSenderId] != _senderUser) {
      throw StateError('يمكن تعديل رسائلك الخاصة فقط.');
    }

    final editedTimestamp = data[_fieldTimestamp] as Timestamp?;
    final hasImage = data[_fieldImageUrl] != null;
    final imageMimeType = data[_fieldImageMimeType] as String?;

    // نحفظ النص قبل التعديل مرة واحدة فقط — أول تعديل يثبّت "النص الأصلي".
    final previousOriginal = data[_fieldOriginalText] as String?;
    final textBeforeEdit = data[_fieldText] as String? ?? '';

    final batch = _firestore.batch();

    batch.update(messageRef, {
      _fieldText: messageText,
      _fieldIsEdited: true,
      _fieldOriginalText:
          (previousOriginal != null && previousOriginal.trim().isNotEmpty)
              ? previousOriginal
              : textBeforeEdit,
      _fieldEditedAt: FieldValue.serverTimestamp(),
      _fieldStatus: _statusSending,
    });

    batch.set(_userChatsCollection.doc(chatId), {
      _fieldUpdatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (editedTimestamp != null) {
      final newerMessages =
          await _chatMessagesCollection(
            chatId,
          ).where(_fieldTimestamp, isGreaterThan: editedTimestamp).get();

      for (final message in newerMessages.docs) {
        batch.delete(message.reference);
      }
    }

    await batch.commit();

    final imageBytes =
        hasImage
            ? await _loadImageBytes(data[_fieldImageUrl] as String)
            : null;

    await _generateAndSaveReply(
      chatId: chatId,
      userMessageRef: messageRef,
      imageBytes: imageBytes,
      imageMimeType:
          imageBytes != null ? (imageMimeType ?? _compressedMime) : null,
    );
  }

  @override
  Future<void> retryMessage(String chatId, String messageId) async {
    _validateChatId(chatId);

    final userMessageRef = _chatMessagesCollection(chatId).doc(messageId);
    final userMessageSnapshot = await userMessageRef.get();

    if (!userMessageSnapshot.exists) {
      throw StateError('الرسالة غير موجودة.');
    }

    final data = userMessageSnapshot.data()!;

    if (data[_fieldSenderId] != _senderUser) {
      throw StateError('يمكن إعادة محاولة رسائل المستخدم فقط.');
    }

    if (data[_fieldStatus] != _statusFailed) {
      return;
    }

    final existingReply =
        await _chatMessagesCollection(
          chatId,
        ).where(_fieldReplyTo, isEqualTo: messageId).limit(1).get();

    if (existingReply.docs.isNotEmpty) {
      await userMessageRef.update({_fieldStatus: _statusSent});
      return;
    }

    await userMessageRef.update({_fieldStatus: _statusSending});

    final imageUrl = data[_fieldImageUrl] as String?;
    final imageMimeType = data[_fieldImageMimeType] as String?;

    final imageBytes = imageUrl != null ? await _loadImageBytes(imageUrl) : null;

    await _generateAndSaveReply(
      chatId: chatId,
      userMessageRef: userMessageRef,
      imageBytes: imageBytes,
      imageMimeType: imageBytes != null
          ? (imageMimeType ?? _compressedMime)
          : null,
    );
  }

  Future<void> _generateAndSaveReply({
    required String chatId,
    required DocumentReference<Map<String, dynamic>> userMessageRef,
    Uint8List? imageBytes,
    String? imageMimeType,
    bool webSearch = false,
    bool thinking = false,
  }) async {
    try {
      final history = await _loadConversationContext(chatId);

      final reply = await _generateAiResponse(
        history: history,
        clientMessageId: userMessageRef.id,
        imageBytes: imageBytes,
        imageMimeType: imageMimeType,
        webSearch: webSearch,
        thinking: thinking,
      );

      final aiMessageRef = _chatMessagesCollection(chatId).doc();
      final batch = _firestore.batch();

      batch.set(aiMessageRef, {
        _fieldText: reply.text,
        _fieldSenderId: _senderAi,
        _fieldStatus: _statusSent,
        _fieldReplyTo: userMessageRef.id,
        _fieldTimestamp: FieldValue.serverTimestamp(),
        if (reply.thoughts != null) _fieldThoughts: reply.thoughts,
        if (reply.sources.isNotEmpty)
          _fieldSources: reply.sources.map((source) => source.toMap()).toList(),
      });

      batch.update(userMessageRef, {_fieldStatus: _statusSent});

      await batch.commit();
    } catch (_) {
      await userMessageRef.update({_fieldStatus: _statusFailed});
      rethrow;
    }
  }

  Future<List<Map<String, String>>> _loadConversationContext(
    String chatId,
  ) async {
    final snapshot =
        await _chatMessagesCollection(chatId)
            .orderBy(_fieldTimestamp, descending: true)
            .limit(_contextMessagesLimit)
            .get();

    return snapshot.docs.reversed
        .map((doc) => doc.data())
        .where(
          (data) =>
              data[_fieldStatus] != _statusFailed &&
              ((data[_fieldText] as String? ?? '').trim().isNotEmpty ||
                  data[_fieldImageUrl] != null ||
                  data[_fieldAudioUrl] != null),
        )
        .map((data) {
          final text = (data[_fieldText] as String? ?? '').trim();
          final hasImage = data[_fieldImageUrl] != null;
          final hasAudio = data[_fieldAudioUrl] != null;
          return {
            'role': data[_fieldSenderId] == _senderUser ? 'user' : 'model',
            'text':
                text.isNotEmpty
                    ? text
                    : hasImage
                    ? 'أرسل صورة.'
                    : hasAudio
                    ? 'أرسل رسالة صوتية غير مفرغة.'
                    : '',
          };
        })
        .toList();
  }

  Future<_AiReply> _generateAiResponse({
    required List<Map<String, String>> history,
    required String clientMessageId,
    Uint8List? imageBytes,
    String? imageMimeType,
    bool webSearch = false,
    bool thinking = false,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'unauthenticated',
        message: 'انتهت جلسة تسجيل الدخول. سجّل الدخول مجددًا.',
      );
    }
    final idToken = await currentUser.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw StateError('تعذر التحقق من جلسة تسجيل الدخول.');
    }

    final response = await _httpClient
        .post(
          Uri.parse(_backendUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'messages': history,
            'clientMessageId': clientMessageId,
            if (webSearch) 'webSearch': true,
            if (thinking) 'thinking': true,
            if (imageBytes != null && imageMimeType != null)
              'image': {
                'mimeType': imageMimeType,
                'data': base64Encode(imageBytes),
              },
          }),
        )
        .timeout(const Duration(seconds: 40));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'تعذر الحصول على رد من المساعد (رمز ${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('استجابة الخادم غير صالحة.');
    }

    final text = decoded['text'];

    if (text is! String || text.trim().isEmpty) {
      throw const FormatException('استجابة الذكاء الاصطناعي فارغة.');
    }

    return _AiReply(
      text: text.trim(),
      thoughts: _parseThoughts(decoded['thoughts']),
      sources: _parseSources(decoded['sources']),
    );
  }

  String? _parseThoughts(dynamic value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }

  List<MessageSource> _parseSources(dynamic value) {
    if (value is! List) {
      return const [];
    }

    final sources = <MessageSource>[];

    for (final item in value) {
      if (item is Map<String, dynamic> &&
          item['title'] is String &&
          item['url'] is String &&
          (item['title'] as String).trim().isNotEmpty &&
          (item['url'] as String).trim().isNotEmpty) {
        sources.add(
          MessageSource(
            title: item['title'] as String,
            url: item['url'] as String,
          ),
        );
      }
    }

    return sources;
  }

  Future<_PreparedImage> _prepareImageData(Uint8List bytes) async {
    var compressed = bytes;

    // على الويب لا يتوفر ملحق الضغط — نستخدم الصورة الأصلية مع احترام حد الحجم.
    if (!kIsWeb) {
      try {
        final firstPass = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: 1024,
          minHeight: 1024,
          quality: 70,
          format: CompressFormat.jpeg,
        );
        compressed = Uint8List.fromList(firstPass);
      } catch (_) {}
    }

    if (base64Encode(compressed).length > _maxEncodedImageChars && !kIsWeb) {
      try {
        final secondPass = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: 800,
          minHeight: 800,
          quality: 60,
          format: CompressFormat.jpeg,
        );
        final smaller = Uint8List.fromList(secondPass);
        if (base64Encode(smaller).length < base64Encode(compressed).length) {
          compressed = smaller;
        }
      } catch (_) {}
    }

    final encoded = base64Encode(compressed);
    if (encoded.length > _hardEncodedImageLimit) {
      throw Exception('حجم الصورة كبير جداً حتى بعد الضغط. جرّب صورة أصغر.');
    }

    return _PreparedImage(
      dataUrl: 'data:$_compressedMime;base64,$encoded',
      bytes: compressed,
    );
  }

  Future<Uint8List> _loadImageBytes(String url) async {
    if (url.startsWith('data:')) {
      return base64Decode(url.substring(url.indexOf(',') + 1));
    }

    final response = await _httpClient
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('تعذر تحميل الصورة لإعادة المحاولة.');
    }

    return response.bodyBytes;
  }

  @override
  Future<void> deleteChatSession(String chatId) async {
    _validateChatId(chatId);

    final chatRef = _userChatsCollection.doc(chatId);
    final messages = await chatRef.collection(_messagesCollection).get();

    for (var start = 0; start < messages.docs.length; start += 500) {
      final batch = _firestore.batch();
      final end =
          start + 500 > messages.docs.length
          ? messages.docs.length
          : start + 500;

      for (final message in messages.docs.sublist(start, end)) {
        batch.delete(message.reference);
      }

      await batch.commit();
    }

    await chatRef.delete();
  }

  List<ChatMessageModel> _mapMessagesSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map((doc) => ChatMessageModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  CollectionReference<Map<String, dynamic>> _chatMessagesCollection(
    String chatId,
  ) {
    return _userChatsCollection.doc(chatId).collection(_messagesCollection);
  }

  void _validateChatId(String chatId) {
    if (chatId.trim().isEmpty) {
      throw ArgumentError.value(chatId, 'chatId', 'معرف المحادثة غير صالح');
    }
  }

  void _validateMessage(String text, {bool allowEmpty = false}) {
    if (!allowEmpty && text.isEmpty) {
      throw ArgumentError.value(text, 'text', 'لا يمكن إرسال رسالة فارغة');
    }

    if (text.length > _maxMessageLength) {
      throw ArgumentError.value(
        text,
        'text',
        'الرسالة طويلة جدًا. الحد الأقصى $_maxMessageLength حرف.',
      );
    }
  }
}

class _PreparedImage {
  const _PreparedImage({required this.dataUrl, required this.bytes});

  final String dataUrl;
  final Uint8List bytes;
}

class _AiReply {
  const _AiReply({required this.text, this.thoughts, this.sources = const []});

  final String text;
  final String? thoughts;
  final List<MessageSource> sources;
}
