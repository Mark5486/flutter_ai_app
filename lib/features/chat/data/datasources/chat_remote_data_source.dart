import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_ai_app/features/audio/domain/entity/audio_entity.dart';
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
  });

  Future<void> retryMessage(String chatId, String messageId);

  Future<void> deleteMessage(String chatId, String messageId);

  Future<void> deleteChatSession(String chatId);
}

class ChatRemoteDataSourceImpl implements IChatRemoteDataSource {
  ChatRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
    http.Client? httpClient,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _httpClient = httpClient ?? http.Client();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;
  final http.Client _httpClient;

  static const _usersCollection = 'users';
  static const _chatsCollection = 'chats';
  static const _messagesCollection = 'messages';
  static const _chatImagesFolder = 'chat_images';

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

    if (attachment != null) {
      imageUrl = await _uploadImage(
        chatId: chatId,
        messageId: userMessageRef.id,
        bytes: attachment.bytes,
        mimeType: attachment.mimeType,
      );
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
      if (attachment != null) _fieldImageMimeType: attachment.mimeType,
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
    try {
      await batch.commit();
    } catch (_) {
      await _deleteStorageObjectQuietly(imageUrl);
      rethrow;
    }

    await _generateAndSaveReply(
      chatId: chatId,
      userMessageRef: userMessageRef,
      imageBytes: attachment?.bytes,
      imageMimeType: attachment?.mimeType,
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

    final imageBytes = imageUrl != null ? await _downloadImage(imageUrl) : null;

    await _generateAndSaveReply(
      chatId: chatId,
      userMessageRef: userMessageRef,
      imageBytes: imageBytes,
      imageMimeType: imageMimeType,
    );
  }

  Future<void> _generateAndSaveReply({
    required String chatId,
    required DocumentReference<Map<String, dynamic>> userMessageRef,
    Uint8List? imageBytes,
    String? imageMimeType,
  }) async {
    try {
      final history = await _loadConversationContext(chatId);

      final aiText = await _generateAiResponse(
        history: history,
        clientMessageId: userMessageRef.id,
        imageBytes: imageBytes,
        imageMimeType: imageMimeType,
      );

      final aiMessageRef = _chatMessagesCollection(chatId).doc();
      final batch = _firestore.batch();

      batch.set(aiMessageRef, {
        _fieldText: aiText,
        _fieldSenderId: _senderAi,
        _fieldStatus: _statusSent,
        _fieldReplyTo: userMessageRef.id,
        _fieldTimestamp: FieldValue.serverTimestamp(),
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

  Future<String> _generateAiResponse({
    required List<Map<String, String>> history,
    required String clientMessageId,
    Uint8List? imageBytes,
    String? imageMimeType,
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
            if (imageBytes != null && imageMimeType != null)
              'image': {
                'mimeType': imageMimeType,
                'data': base64Encode(imageBytes),
              },
          }),
        )
        .timeout(const Duration(seconds: 30));

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

    return text.trim();
  }

  Future<String> _uploadImage({
    required String chatId,
    required String messageId,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final extension = _extensionFromMime(mimeType);

    final ref = _storage
        .ref()
        .child(_usersCollection)
        .child(_userId)
        .child(_chatImagesFolder)
        .child(chatId)
        .child('$messageId.$extension');

    final uploadTask = await ref.putData(
      bytes,
      SettableMetadata(contentType: mimeType),
    );

    return uploadTask.ref.getDownloadURL();
  }

  Future<Uint8List> _downloadImage(String url) async {
    final response = await _httpClient
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('تعذر تحميل الصورة لإعادة المحاولة.');
    }

    return response.bodyBytes;
  }

  Future<void> _deleteStorageObjectQuietly(String? downloadUrl) async {
    if (downloadUrl == null) return;

    try {
      await _storage.refFromURL(downloadUrl).delete();
    } catch (_) {}
  }

  String _extensionFromMime(String mimeType) {
    switch (mimeType) {
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      case 'image/jpeg':
      default:
        return 'jpg';
    }
  }

  @override
  Future<void> deleteMessage(String chatId, String messageId) async {
    _validateChatId(chatId);

    final messagesRef = _chatMessagesCollection(chatId);
    final messageSnapshot = await messagesRef.doc(messageId).get();
    final replySnapshot =
        await messagesRef.where(_fieldReplyTo, isEqualTo: messageId).get();

    final batch = _firestore.batch();

    batch.delete(messagesRef.doc(messageId));

    for (final reply in replySnapshot.docs) {
      batch.delete(reply.reference);
    }

    batch.set(_userChatsCollection.doc(chatId), {
      _fieldUpdatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();

    await _deleteStorageObjectQuietly(
      messageSnapshot.data()?[_fieldImageUrl] as String?,
    );
    await _deleteStorageObjectQuietly(
      messageSnapshot.data()?[_fieldAudioUrl] as String?,
    );
  }

  @override
  Future<void> deleteChatSession(String chatId) async {
    _validateChatId(chatId);

    final chatRef = _userChatsCollection.doc(chatId);
    final messages = await chatRef.collection(_messagesCollection).get();

    for (final message in messages.docs) {
      await _deleteStorageObjectQuietly(
        message.data()[_fieldImageUrl] as String?,
      );
      await _deleteStorageObjectQuietly(
        message.data()[_fieldAudioUrl] as String?,
      );
    }

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
