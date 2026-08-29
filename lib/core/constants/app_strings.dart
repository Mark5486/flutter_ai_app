abstract final class AppStrings {
  static const String appName = 'Gemini AI Assistant';

  // Auth
  static const String login = 'تسجيل الدخول';
  static const String register = 'إنشاء حساب';
  static const String logout = 'تسجيل الخروج';
  static const String email = 'البريد الإلكتروني';
  static const String password = 'كلمة المرور';
  static const String confirmPassword = 'تأكيد كلمة المرور';
  static const String name = 'الاسم الكامل';
  static const String welcome = 'أهلاً بك';
  static const String welcomeBack = 'مرحباً بعودتك';

  // Validation
  static const String emailRequired = 'البريد الإلكتروني مطلوب';
  static const String invalidEmail = 'صيغة البريد الإلكتروني غير صحيحة';
  static const String passwordRequired = 'كلمة المرور مطلوبة';
  static const String passwordTooShort =
      'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
  static const String confirmPasswordRequired = 'تأكيد كلمة المرور مطلوب';
  static const String passwordsNotMatch = 'كلمتا المرور غير متطابقتين';
  static const String nameRequired = 'الاسم مطلوب';

  // State Messages
  static const String loginSuccess = 'تم تسجيل الدخول بنجاح';
  static const String registerSuccess = 'تم إنشاء الحساب بنجاح';
  static const String logoutSuccess = 'تم تسجيل الخروج بنجاح';
  static const String somethingWentWrong =
      'حدث خطأ غير متوقع، يرجى المحاولة لاحقاً';
  static const String noInternet = 'لا يوجد اتصال بالإنترنت';
  static const String apiQuotaExceeded =
      'تم تجاوز الحد المسموح به من الطلبات المجانية';

  // Chat & AI Features
  static const String chat = 'المحادثة';
  static const String newChat = 'محادثة جديدة';
  static const String conversations = 'سجل المحادثات';
  static const String send = 'إرسال';
  static const String typeMessage = 'اسأل الـ AI أي شيء...';
  static const String thinking = 'جاري التفكير والاستجابة...';
  static const String analyzingFile = 'جاري تحليل المستند...';

  // Multimodal & Media
  static const String uploadFile = 'إرفاق ملف';
  static const String uploadImage = 'تحليل صورة';
  static const String uploadPdf = 'تحليل مستند PDF';
  static const String uploadVideo = 'تحليل فيديو';
  static const String fileTooLarge = 'حجم الملف يتجاوز الحد المسموح';

  // Voice Engine
  static const String voiceInput = 'اضغط للتحدث';
  static const String stopListening = 'إيقاف الاستماع';
  static const String listening = 'جاري الاستماع لك...';
  static const String speaking = 'جاري النطق...';

  // Advanced AI Features
  static const String memory = 'ذاكرة المساعد';
  static const String systemPrompts = 'تخصيص شخصية الـ AI';
  static const String deleteConversation = 'حذف المحادثة';
  static const String clearConversation = 'مسح السجل';
  static const String settings = 'الإعدادات';
}
