# Audio transcription Worker

This separate Cloudflare Worker protects the Groq API key and accepts audio only from authenticated Firebase users. It does not replace the existing chat Worker.

## Deploy

1. Create a Groq account and an API key. Do not send the key in chat or place it in Flutter.
2. Open PowerShell in `D:\vs code\project1\flutter-ai-backend` (the folder containing Wrangler) and sign in if needed with `npx wrangler login`.
3. Save the key as a Cloudflare secret:

   ```powershell
   npx wrangler secret put GROQ_API_KEY --config "..\flutter_ai_app\backend\audio_transcription_worker\wrangler.toml"
   ```

4. Deploy this new Worker without replacing the existing chat Worker:

   ```powershell
   npx wrangler deploy --config "..\flutter_ai_app\backend\audio_transcription_worker\wrangler.toml"
   ```

5. Copy the new `workers.dev` URL. From the Flutter project folder, run:

   ```powershell
   flutter run --dart-define=AUDIO_TRANSCRIPTION_API_URL=https://YOUR-WORKER.workers.dev
   ```

The Groq key belongs only in the Worker secret. Never add it to Flutter source or commit it. Requests are verified against Firebase Authentication tokens and capped at 25 MB.
