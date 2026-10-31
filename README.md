# Flutter AI Assistant

Flutter chat application with Firebase authentication, Firestore-backed conversation history, image attachments, and an AI response service hosted behind a Cloudflare Worker.

## Features

- Email/password, Google, and anonymous Firebase Authentication.
- Per-user chat sessions and real-time message updates in Cloud Firestore.
- Image attachments stored in Firebase Storage and included with AI requests.
- Message retry, deletion, and cursor-based older-message pagination.
- Audio recording, Firebase Storage upload, Arabic transcription through a separate Cloudflare Worker, transcript-aware AI messages, and in-chat playback.
- Arabic interface, Cubit state management, GetIt dependency injection, and Clean Architecture feature boundaries.

## Architecture

Features are divided into `domain`, `data`, and `presentation` layers. Domain repositories and use cases define application behavior; Firebase, file picking, recording, and HTTP are isolated in data sources; Cubits expose immutable state to Flutter widgets. Firebase and HTTP clients are injectable into remote data sources to support focused unit testing.

## Setup

1. Install Flutter (Dart SDK `>=3.7.2 <4.0.0`) and configure a Firebase project for the platforms you target.
2. Generate or provide `lib/firebase_options.dart` with FlutterFire CLI. Do not commit service-account credentials or private API keys.
3. Configure Firebase Authentication providers, Firestore, and Storage. Deploy the included rules with `firebase deploy --only firestore:rules,storage` after selecting your own Firebase project.
4. Configure the existing AI Worker endpoint and secrets on the server. The client must not contain provider API keys.
5. Deploy the separate transcription Worker and configure `AUDIO_TRANSCRIPTION_API_URL`; follow `backend/audio_transcription_worker/README.md`.
6. Run `flutter pub get`, then `flutter run`.

## Firebase data layout

```text
users/{uid}/chats/{chatId}
users/{uid}/chats/{chatId}/messages/{messageId}
users/{uid}/chat_images/{chatId}/{fileName}
users/{uid}/audio/{fileName}
```

Firestore queries that combine multiple ordering/filter fields may require a composite index; follow the index link returned by Firebase and commit the resulting `firestore.indexes.json` when needed.

## Quality checks

```sh
dart format --output=none --set-exit-if-changed lib
flutter analyze
flutter test
```

## Security notes

Firebase rules enforce per-user ownership and media size/type limits. The AI Worker must independently validate authentication, payload size, MIME type, rate limits, and idempotency keys. Firebase download URLs are bearer-like URLs; keep them private and delete associated objects when messages are removed.
