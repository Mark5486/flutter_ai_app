Flutter AI Assistant

A Flutter AI chat application with Firebase authentication, chat history, image attachments, and voice messages.

Features

Email, Google, and anonymous authentication.

Real-time chat history using Cloud Firestore.

Image attachments and Firebase Storage.

AI-powered responses through Cloudflare Worker.

Voice recording and Arabic audio transcription.

Message retry, deletion, and pagination.

Arabic interface with Cubit and Clean Architecture.

Architecture

The project follows Clean Architecture with three main layers:

Domain: Business logic, entities, repositories, and use cases.

Data: Firebase services, API requests, and local data handling.

Presentation: Flutter UI, Cubits, and application states.



Firebase Structure

users/
  {uid}/
    chats/
      {chatId}/
        messages/
          {messageId}
    chat_images/
    audio/

