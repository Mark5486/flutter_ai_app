abstract final class FirestoreCollections {
  static const String users = 'users';
  static const String conversations = 'conversations';
  static const String messages = 'messages';
  static const String memories = 'memories';
}

abstract final class LocalStorageKeys {
  
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String userName = 'user_name';
  static const String authToken = 'auth_token';

  
  static const String themeMode = 'theme_mode';
  static const String locale = 'app_locale';
  static const String onboardingCompleted = 'onboarding_completed';

  
  static const String lastConversationId = 'last_conversation_id';
  static const String voiceEnabled = 'voice_enabled';
  static const String memoryEnabled = 'memory_enabled';
  static const String selectedSystemPrompt = 'selected_system_prompt';
}

abstract final class HiveBoxes {
  static const String chatHistory = 'chat_history_box';
  static const String cachedMessages = 'cached_messages_box';
  static const String userPreferences = 'user_preferences_box';
  static const String aiMemories = 'ai_memories_box';
}
