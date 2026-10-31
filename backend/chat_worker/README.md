# flutter-ai-backend (chat worker) — الإصدار الثاني v2

وسيط بين تطبيق Flutter ومحرك Gemini، مع التحقق من رمز تسجيل دخول Firebase (RS256).

## الجديد في الإصدار الثاني
1. **إعادة المحاولة تلقائيًا**: حتى 3 محاولات إذا رجّع Gemini خطأ مؤقت (429 / 5xx) أو حدث خطأ شبكة — بدل ما يظهر 502 للتطبيق.
2. **موديل افتراضي أحدث وأهدى**: `gemini-2.5-flash` (مع إيقاف وضع التفكير للردود السريعة). يمكن تغييره بمتغير `GEMINI_MODEL` في wrangler.toml.
3. **تسجيل تفصيلي**: كل طلب بيطبع أسطر `[reqId] ...` تشوفها بأمر `npx wrangler tail flutter-ai-backend` — بتقول الموديل وعدد الرسائل وهل فيه صورة، وإذا فشل: كود الخطأ ونصه الحقيقي من Gemini.
4. **حد زمني إجمالي 28 ثانية** أقل من مهلة التطبيق (30 ثانية) حتى لا يظهر خطأ قطع اتصال غامض.

## الأسرار (Secrets) — موجودة على Cloudflare ولا تُمس عند إعادة النشر
- `GEMINI_API_KEY` ← مفتاح من https://aistudio.google.com/apikey

## النشر
```powershell
$env:CLOUDFLARE_API_TOKEN="ضع التوكن هنا"
npx wrangler deploy
```

## مراقبة السجلات الحية
```powershell
npx wrangler tail flutter-ai-backend
```

## اختبار سريع أن الخدمة حية
افتح في المتصفح: `https://flutter-ai-backend.markrafik633.workers.dev` ← يجب أن يظهر `{"status":"ok"}`
