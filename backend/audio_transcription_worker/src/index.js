// flutter-ai-audio-transcription v2
// Changes vs v1:
//  1. GROQ_API_KEY sanitization — strips invisible/invalid characters (same defense
//     as the chat worker; a single stray zero-width char inside the secret makes the
//     provider reject every request with an opaque error).
//  2. GET /selftest?t=<token> (or /selftest/<token>) — guarded diagnostic: key
//     fingerprint + a real Groq models-list probe. Never reveals the key itself.
// Public contract unchanged: POST /transcribe -> 200 {text, uid} / 400 / 401 / 413 / 415 / 422 / 429 / 500 / 502.

const FIREBASE_JWKS_URL =
  'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';
const GROQ_TRANSCRIPTION_URL =
  'https://api.groq.com/openai/v1/audio/transcriptions';
const GROQ_MODELS_URL = 'https://api.groq.com/openai/v1/models';
const MAX_AUDIO_BYTES = 25 * 1024 * 1024;
// Secondary guard for /selftest. The audio worker has no FIREBASE_WEB_API_KEY.
const SELFTEST_TOKEN = 'st-7k2m9vqx41';
const SELFTEST_TIMEOUT_MS = 10000;

let cachedJwks;
let cachedJwksAt = 0;

// ---------------------------------------------------------------------------
// Key hygiene (same as chat worker v3)
// ---------------------------------------------------------------------------

function sanitizeKey(raw) {
  return (raw || '').replace(/[^\x21-\x7e]/g, '').trim();
}

function keyFingerprint(raw, clean) {
  return {
    rawLen: (raw || '').length,
    cleanLen: clean.length,
    hadInvalidChars: (raw || '') !== clean,
  };
}

async function runSelfTest(env) {
  const rawKey = env.GROQ_API_KEY || '';
  const key = sanitizeKey(rawKey);
  const fingerprint = keyFingerprint(rawKey, key);

  let groqCheck;
  if (!key) {
    groqCheck = { status: 0, error: 'GROQ_API_KEY is missing or empty' };
  } else {
    const t0 = Date.now();
    try {
      const response = await fetchWithTimeout(
        GROQ_MODELS_URL,
        { method: 'GET', headers: { Authorization: `Bearer ${key}` } },
        SELFTEST_TIMEOUT_MS,
      );
      const bodyText = await response.text().catch(() => '');
      let modelsCount = null;
      try {
        const parsed = JSON.parse(bodyText);
        if (Array.isArray(parsed.data)) modelsCount = parsed.data.length;
      } catch (_) {
        // non-JSON body — keep modelsCount null
      }
      groqCheck = {
        status: response.status,
        ms: Date.now() - t0,
        modelsCount,
        bodySnippet: response.ok ? null : bodyText.slice(0, 300),
      };
    } catch (error) {
      groqCheck = {
        status: 0,
        ms: Date.now() - t0,
        error: `${(error && error.name) || 'Error'}: ${(error && error.message) || ''}`,
      };
    }
  }

  return {
    ok: groqCheck.status === 200,
    keyFingerprint: fingerprint,
    groqCheck,
  };
}

async function fetchWithTimeout(url, options, timeoutMs) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(url, { ...options, signal: controller.signal });
  } finally {
    clearTimeout(timer);
  }
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

export default {
  async fetch(request, env) {
    const corsHeaders = getCorsHeaders(request);

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    const url = new URL(request.url);
    if (url.pathname === '/' && request.method === 'GET') {
      return json({ status: 'ok' }, 200, corsHeaders);
    }

    const isSelfTest =
      request.method === 'GET' &&
      (url.pathname === '/selftest' ||
        url.pathname.startsWith('/selftest/'));
    if (isSelfTest) {
      const pathToken = decodeURIComponent(
        url.pathname.slice('/selftest/'.length).trim(),
      );
      const t = url.searchParams.get('t') || pathToken;
      if (t !== SELFTEST_TOKEN) {
        return json({ error: 'not found' }, 404, corsHeaders);
      }
      try {
        const report = await runSelfTest(env);
        console.log(`[selftest] ${JSON.stringify(report)}`);
        return json(report, 200, corsHeaders);
      } catch (error) {
        console.error(`[selftest] failed: ${(error && error.stack) || error}`);
        return json({ error: 'selftest failed' }, 500, corsHeaders);
      }
    }

    if (url.pathname !== '/transcribe' || request.method !== 'POST') {
      return json({ error: 'المسار أو طريقة الطلب غير مدعومين.' }, 404, corsHeaders);
    }

    if (!env.FIREBASE_PROJECT_ID || !env.GROQ_API_KEY) {
      return json({ error: 'إعدادات خدمة الصوت غير مكتملة على السيرفر.' }, 503, corsHeaders);
    }

    try {
      const token = readBearerToken(request.headers.get('Authorization'));
      const firebaseUser = await verifyFirebaseIdToken(token, env.FIREBASE_PROJECT_ID);

      const form = await request.formData();
      const audio = form.get('file');
      if (!(audio instanceof File) || audio.size === 0) {
        return json({ error: 'ملف التسجيل الصوتي مفقود أو فارغ.' }, 400, corsHeaders);
      }
      if (audio.size > MAX_AUDIO_BYTES) {
        return json({ error: 'حجم التسجيل يتجاوز 25 ميجابايت.' }, 413, corsHeaders);
      }
      if (!isSupportedAudio(audio.name, audio.type)) {
        return json({ error: 'صيغة التسجيل الصوتي غير مدعومة.' }, 415, corsHeaders);
      }

      const providerForm = new FormData();
      const mimeType = audio.name.toLowerCase().endsWith('.webm')
        ? 'audio/webm'
        : 'audio/mp4';
      providerForm.append('file', new File([audio], audio.name, { type: mimeType }));
      providerForm.append('model', 'whisper-large-v3-turbo');
      providerForm.append('language', 'ar');
      providerForm.append('response_format', 'json');

      const groqKey = sanitizeKey(env.GROQ_API_KEY);
      console.log(
        `[transcribe] uid=${firebaseUser.sub} bytes=${audio.size} keyCheck: rawLen=${(env.GROQ_API_KEY || '').length} cleanLen=${groqKey.length}`,
      );

      const providerResponse = await fetch(GROQ_TRANSCRIPTION_URL, {
        method: 'POST',
        headers: { Authorization: `Bearer ${groqKey}` },
        body: providerForm,
      });

      if (!providerResponse.ok) {
        const status = providerResponse.status === 429 ? 429 : 502;
        const providerBody = await providerResponse.text().catch(() => '');
        console.error(
          `[transcribe] provider status ${providerResponse.status} body=${providerBody.slice(0, 300)}`,
        );
        return json(
          {
            error:
              status === 429
                ? 'وصلت الخدمة إلى حد الاستخدام المجاني. حاول لاحقًا.'
                : 'تعذر تفريغ التسجيل لدى مزود الخدمة.',
          },
          status,
          corsHeaders,
        );
      }

      const result = await providerResponse.json();
      const text = typeof result.text === 'string' ? result.text.trim() : '';
      if (!text) {
        return json({ error: 'لم يتم التعرف على كلام في التسجيل.' }, 422, corsHeaders);
      }

      return json({ text, uid: firebaseUser.sub }, 200, corsHeaders);
    } catch (error) {
      const message =
        error instanceof AuthenticationError
          ? error.message
          : 'حدث خطأ أثناء معالجة التسجيل الصوتي.';
      const status = error instanceof AuthenticationError ? 401 : 500;
      return json({ error: message }, status, corsHeaders);
    }
  },
};

// ---------------------------------------------------------------------------
// Helpers (unchanged from v1)
// ---------------------------------------------------------------------------

function getCorsHeaders(request) {
  return {
    'Access-Control-Allow-Origin': request.headers.get('Origin') ?? '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Authorization, Content-Type',
    'Access-Control-Max-Age': '86400',
    Vary: 'Origin',
  };
}

function json(body, status, headers) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...headers, 'Content-Type': 'application/json; charset=utf-8' },
  });
}

function readBearerToken(value) {
  const match = /^Bearer\s+(.+)$/i.exec(value ?? '');
  if (!match) throw new AuthenticationError('سجّل الدخول ثم حاول مرة أخرى.');
  return match[1];
}

async function verifyFirebaseIdToken(token, projectId) {
  const parts = token.split('.');
  if (parts.length !== 3) throw new AuthenticationError('رمز تسجيل الدخول غير صالح.');

  const header = decodeJsonPart(parts[0]);
  const claims = decodeJsonPart(parts[1]);
  if (header.alg !== 'RS256' || typeof header.kid !== 'string') {
    throw new AuthenticationError('توقيع رمز تسجيل الدخول غير مدعوم.');
  }

  const jwk = await findFirebaseKey(header.kid);
  if (!jwk) throw new AuthenticationError('تعذر التحقق من رمز تسجيل الدخول.');

  const publicKey = await crypto.subtle.importKey(
    'jwk',
    jwk,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['verify'],
  );

  const signature = decodeBase64Url(parts[2]);
  const signedContent = new TextEncoder().encode(`${parts[0]}.${parts[1]}`);
  const signatureIsValid = await crypto.subtle.verify(
    'RSASSA-PKCS1-v1_5',
    publicKey,
    signature,
    signedContent,
  );

  const now = Math.floor(Date.now() / 1000);
  if (
    !signatureIsValid ||
    claims.aud !== projectId ||
    claims.iss !== `https://securetoken.google.com/${projectId}` ||
    typeof claims.sub !== 'string' ||
    claims.sub.length === 0 ||
    typeof claims.exp !== 'number' ||
    claims.exp <= now ||
    typeof claims.iat !== 'number' ||
    claims.iat > now
  ) {
    throw new AuthenticationError('انتهت صلاحية تسجيل الدخول أو الرمز غير صالح.');
  }

  return claims;
}

async function findFirebaseKey(kid) {
  const cacheIsFresh = cachedJwks && Date.now() - cachedJwksAt < 60 * 60 * 1000;
  if (!cacheIsFresh) await refreshFirebaseKeys();

  let key = cachedJwks.keys.find((item) => item.kid === kid);
  if (!key) {
    await refreshFirebaseKeys();
    key = cachedJwks.keys.find((item) => item.kid === kid);
  }
  return key;
}

async function refreshFirebaseKeys() {
  const response = await fetch(FIREBASE_JWKS_URL);
  if (!response.ok) throw new Error('Unable to load Firebase signing keys.');
  cachedJwks = await response.json();
  cachedJwksAt = Date.now();
}

function decodeJsonPart(part) {
  try {
    return JSON.parse(new TextDecoder().decode(decodeBase64Url(part)));
  } catch (_) {
    throw new AuthenticationError('رمز تسجيل الدخول غير صالح.');
  }
}

function decodeBase64Url(value) {
  const base64 = value.replace(/-/g, '+').replace(/_/g, '/');
  const padded = base64.padEnd(Math.ceil(base64.length / 4) * 4, '=');
  const binary = atob(padded);
  return Uint8Array.from(binary, (character) => character.charCodeAt(0));
}

function isSupportedAudio(name, mimeType) {
  const extensionIsSupported = /\.(m4a|mp4|webm)$/i.test(name);
  const mimeIsSupported = /^(audio\/(mp4|webm|aac)|application\/octet-stream)$/i.test(
    mimeType,
  );
  return extensionIsSupported && mimeIsSupported;
}

class AuthenticationError extends Error {}
