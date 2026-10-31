// flutter-ai-backend v4.2
// v4.2: 504 fix - thinking generations were exceeding the 22s per-attempt cap.
//  - attempt 1 keeps thinking (18s budget); retries drop thinking (fast, 12s cap)
//  - total deadline 28s -> 34s (still under the app's 40s client timeout)
// Changes vs v3.2:
//  1. AI thinking: OPTIONAL — requested only when the client sends `thinking:true`.
//     Thought parts come back flagged (part.thought=true) and are returned to the app
//     as a separate `thoughts` field (displayed in a collapsible "how I thought" panel).
//  2. Web search: request flag `webSearch:true` -> DuckDuckGo HTML/Lite search from the
//     worker, results injected as systemInstruction context, sources returned to the app
//     as `sources:[{title,url}]`. Degrades gracefully: search failure never blocks the reply.
//  3. Selftest extended with thinkingProbe + searchProbe (same token guard).
// Public contract: 200 {text, thoughts?, sources?} / 429 / 504 / 502 {error, detail}.
// Old app versions send no `webSearch`/`thinking` and read only `text` -> fully backward compatible.

const MODELS_LIST_URL = "https://generativelanguage.googleapis.com/v1beta/models";

const FIREBASE_JWKS_URL =
  "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com";
const GEMINI_API_BASE = "https://generativelanguage.googleapis.com/v1beta/models";
const DEFAULT_MODEL = "gemini-3.5-flash";
const FALLBACK_MODELS = ["gemini-3.5-flash-lite"];
const MAX_ATTEMPTS_PER_MODEL = 3;
const RETRY_DELAYS_MS = [800, 1600];
const TOTAL_DEADLINE_MS = 34e3;
const MIN_REMAINING_MS = 3e3;
const PER_ATTEMPT_TIMEOUT_MS = 12e3;
const FIRST_ATTEMPT_TIMEOUT_MS = 18e3;
const MAX_RAW_BODY_CHARS = 3e7;
const MAX_IMAGE_BASE64_CHARS = 26e6;
const SELFTEST_TIMEOUT_MS = 15e3;
const EMPTY_REPLY_FALLBACK =
  "عذراً، لم أتمكن من توليد رد مناسبة لهذه الرسالة. جرّب صياغة أخرى من فضلك.";
// Secondary guard for /selftest alongside FIREBASE_WEB_API_KEY.
const SELFTEST_TOKEN = "st-7k2m9vqx41";

// --- Web search settings -----------------------------------------------------
// Datacenter IPs get bot-walled by DDG/Bing/Mojeek HTML search, so we use
// keyless APIs that are proven to work from Cloudflare Workers' network:
//   1. Wikipedia search API (ar/en picked by query script) — encyclopedic grounding.
//   2. DuckDuckGo Instant Answers API — entity/definition summaries (HTTP 202 is its normal code).
//   3. HN Algolia API — tech news/posts (great for "latest version of X" style queries).
const WIKIPEDIA_ENDPOINTS = {
  ar: "https://ar.wikipedia.org/w/api.php",
  en: "https://en.wikipedia.org/w/api.php",
};
const DDG_IA_ENDPOINT = "https://api.duckduckgo.com/";
const HN_ENDPOINT = "https://hn.algolia.com/api/v1/search";
const SEARCH_TIMEOUT_MS = 8000;
const SEARCH_RESULTS_LIMIT = 5;
const SEARCH_USER_AGENT =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36";

let cachedJwks;
let cachedJwksAt = 0;

// ---------------------------------------------------------------------------
// Key hygiene
// ---------------------------------------------------------------------------

// A healthy Gemini key is printable ASCII only — classic "AIza..." format or the
// newer "AQ." format. Zero-width chars, smart quotes, stray unicode or control
// characters pasted into the secret end up as invalid header bytes -> Google's
// frontend answers with an instant 400 and an EMPTY body. Stripping them fixes
// that silently.
function sanitizeKey(raw) {
  return (raw || "").replace(/[^\x21-\x7e]/g, "").trim();
}

function keyFingerprint(raw, clean) {
  return {
    rawLen: (raw || "").length,
    cleanLen: clean.length,
    hadInvalidChars: (raw || "") !== clean,
    startsAiza: /^AIza[A-Za-z0-9_-]{10,}$/.test(clean),
  };
}

// ---------------------------------------------------------------------------
// Model chain
// ---------------------------------------------------------------------------

function pickModel(env) {
  const override =
    typeof env.GEMINI_MODEL === "string" ? env.GEMINI_MODEL.trim() : "";
  return override || DEFAULT_MODEL;
}

function buildModelChain(env) {
  const primary = pickModel(env);
  return [primary, ...FALLBACK_MODELS.filter((m) => m !== primary)];
}

function buildPayload(model, contents, options) {
  const opts = options || {};
  const payload = { contents };
  if (/^gemini-2\.5-(flash|flash-lite)/.test(model)) {
    payload.generationConfig = {
      thinkingConfig: { thinkingBudget: 0 },
    };
  } else if (/^gemini-3/.test(model) && opts.includeThoughts) {
    // 3.x thinking models: ask for thought summaries alongside the reply.
    payload.generationConfig = {
      thinkingConfig: { includeThoughts: true },
    };
  }
  if (opts.systemText) {
    payload.systemInstruction = { parts: [{ text: opts.systemText }] };
  }
  return payload;
}

// ---------------------------------------------------------------------------
// Gemini calls
// ---------------------------------------------------------------------------

async function callGeminiChain({ env, contents, reqId, startedAt, options }) {
  const rawKey = env.GEMINI_API_KEY || "";
  const key = sanitizeKey(rawKey);
  const fingerprint = keyFingerprint(rawKey, key);
  console.log(
    `[${reqId}] key check: rawLen=${fingerprint.rawLen} cleanLen=${fingerprint.cleanLen} hadInvalidChars=${fingerprint.hadInvalidChars} startsAiza=${fingerprint.startsAiza}`,
  );
  if (!key) {
    return {
      ok: false,
      failure: { status: 0, body: "GEMINI_API_KEY is missing or empty" },
    };
  }

  const models = buildModelChain(env);
  console.log(`[${reqId}] plan: models=${models.join(" -> ")}`);

  const failures = [];
  for (const model of models) {
    let lastFailure = null;

    for (let attempt = 1; attempt <= MAX_ATTEMPTS_PER_MODEL; attempt += 1) {
      const remaining = TOTAL_DEADLINE_MS - (Date.now() - startedAt);
      if (remaining < MIN_REMAINING_MS) {
        console.error(`[${reqId}] attempt ${attempt}: skipped, no time left`);
        lastFailure = lastFailure || { status: 0, body: "no time left" };
        break;
      }
      const attemptBudget = attempt === 1 ? FIRST_ATTEMPT_TIMEOUT_MS : PER_ATTEMPT_TIMEOUT_MS;
      const timeoutMs = Math.min(attemptBudget, remaining);
      const payload = buildPayload(
        model,
        contents,
        attempt === 1 ? options : { ...options, includeThoughts: false },
      );
      const t0 = Date.now();
      try {
        const response = await fetchWithTimeout(
          `${GEMINI_API_BASE}/${model}:generateContent`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              "x-goog-api-key": key,
            },
            body: JSON.stringify(payload),
          },
          timeoutMs,
        );
        if (response.ok) {
          const data = await response.json().catch(() => null);
          const reply = extractReply(data);
          const ms = Date.now() - t0;
          if (reply.text) {
            console.log(
              `[${reqId}] ok model=${model} attempt=${attempt} in ${ms}ms replyChars=${reply.text.length} thoughtsChars=${reply.thoughts.length}`,
            );
            return {
              ok: true,
              text: reply.text,
              thoughts: reply.thoughts,
              model,
              attempt,
            };
          }
          console.error(
            `[${reqId}] model=${model} attempt=${attempt}: 200 with no text, body=${snippet(
              JSON.stringify(data),
            )}`,
          );
          return {
            ok: true,
            text: EMPTY_REPLY_FALLBACK,
            thoughts: reply.thoughts,
            model,
            attempt,
          };
        }
        const errorBody = await response.text().catch(() => "");
        const ms = Date.now() - t0;
        console.error(
          `[${reqId}] attempt ${attempt} model=${model}: status ${response.status} in ${ms}ms ctype=${response.headers.get("content-type") || "-"} bodyLen=${errorBody.length} body=${snippet(errorBody)}`,
        );
        lastFailure = { model, status: response.status, body: snippet(errorBody) };
        const isRetryable = response.status === 429 || response.status >= 500;
        if (!isRetryable) {
          break;
        }
      } catch (error) {
        const isTimeout = error && error.name === "AbortError";
        console.error(
          `[${reqId}] attempt ${attempt} model=${model}: ${isTimeout ? "timeout" : "network error"} ${error && error.name}: ${error && error.message}`,
        );
        lastFailure = {
          model,
          status: 0,
          body: `${(error && error.name) || "Error"}: ${(error && error.message) || ""}`,
        };
      }
      if (attempt < MAX_ATTEMPTS_PER_MODEL) {
        const delay = RETRY_DELAYS_MS[attempt - 1] || 1200;
        const timeLeft = TOTAL_DEADLINE_MS - (Date.now() - startedAt);
        if (timeLeft < delay + MIN_REMAINING_MS) {
          console.error(
            `[${reqId}] no time to retry after attempt ${attempt} (model=${model})`,
          );
          break;
        }
        console.log(
          `[${reqId}] retrying model=${model} attempt ${attempt + 1} in ${delay}ms...`,
        );
        await sleep(delay);
      }
    }

    if (lastFailure) {
      failures.push(lastFailure);
      const hardRejection = [400, 401, 403, 404].includes(lastFailure.status);
      console.log(
        `[${reqId}] model=${model} exhausted (${hardRejection ? "hard rejection" : "retries used up"}), moving to next model`,
      );
    }
  }

  return {
    ok: false,
    failure:
      failures[failures.length - 1] || { status: 0, body: "no attempt was made" },
    failures,
  };
}

// ---------------------------------------------------------------------------
// Web search (DuckDuckGo HTML/Lite — free, keyless)
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Web search parsers (Wikipedia / DDG Instant Answers / HN Algolia)
// ---------------------------------------------------------------------------

function stripTags(html) {
  return String(html || "")
    .replace(/<[^>]*>/g, " ")
    .replace(/&nbsp;/gi, " ")
    .replace(/&amp;/gi, "&")
    .replace(/&quot;/gi, '"')
    .replace(/&#x27;/gi, "'")
    .replace(/&#39;/gi, "'")
    .replace(/&lt;/gi, "<")
    .replace(/&gt;/gi, ">")
    .replace(/\s+/g, " ")
    .trim();
}

function isArabicQuery(query) {
  return /[\u0600-\u06FF]/.test(query);
}

function parseWikipediaResults(bodyText, lang) {
  const results = [];
  try {
    const parsed = JSON.parse(bodyText);
    const items =
      parsed && parsed.query && Array.isArray(parsed.query.search)
        ? parsed.query.search
        : [];
    for (const item of items.slice(0, SEARCH_RESULTS_LIMIT)) {
      const title = String(item.title || "").trim();
      if (!title) continue;
      const snippet = stripTags(String(item.snippet || "")).slice(0, 300);
      results.push({
        title,
        url: `https://${lang}.wikipedia.org/wiki/${encodeURIComponent(title.replace(/ /g, "_"))}`,
        snippet,
      });
    }
  } catch (_) {
    // malformed JSON -> no results
  }
  return results;
}

function parseDdgIaResults(bodyText) {
  const results = [];
  try {
    const parsed = JSON.parse(bodyText);
    if (parsed.AbstractText && parsed.AbstractURL) {
      results.push({
        title: String(parsed.Heading || parsed.AbstractSource || "DuckDuckGo"),
        url: String(parsed.AbstractURL),
        snippet: String(parsed.AbstractText).slice(0, 300),
      });
    }
    const flat = [];
    for (const topic of parsed.RelatedTopics || []) {
      if (!topic || typeof topic !== "object") continue;
      if (topic.FirstURL) {
        flat.push(topic);
      } else if (Array.isArray(topic.Topics)) {
        for (const nested of topic.Topics) {
          if (nested && nested.FirstURL) {
            flat.push(nested);
          }
        }
      }
    }
    for (const topic of flat) {
      if (results.length >= SEARCH_RESULTS_LIMIT) break;
      const url = String(topic.FirstURL || "");
      const text = String(topic.Text || "");
      if (!url || !text) continue;
      const firstDash = text.indexOf(" -");
      const title = firstDash > 0 ? text.slice(0, firstDash) : text.slice(0, 120);
      results.push({
        title: title.slice(0, 200),
        url,
        snippet: text.slice(0, 300),
      });
    }
  } catch (_) {
    // malformed JSON -> no results
  }
  return results.slice(0, SEARCH_RESULTS_LIMIT);
}

function parseHnResults(bodyText) {
  const results = [];
  try {
    const parsed = JSON.parse(bodyText);
    const hits = Array.isArray(parsed.hits) ? parsed.hits : [];
    for (const hit of hits) {
      if (results.length >= SEARCH_RESULTS_LIMIT) break;
      const title = String(hit.title || "").trim();
      if (!title) continue;
      const url =
        (hit.url && String(hit.url)) ||
        `https://news.ycombinator.com/item?id=${hit.objectID}`;
      results.push({ title: title.slice(0, 200), url, snippet: null });
    }
  } catch (_) {
    // malformed JSON -> no results
  }
  return results;
}

async function performWebSearch(query) {
  const q = String(query || "")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, 256);
  if (!q) {
    return null;
  }

  const arabic = isArabicQuery(q);
  const attempts = [];
  const diagnostics = [];

  // 1. Wikipedia — language endpoint picked from the query script.
  attempts.push({
    name: arabic ? "wikipedia-ar" : "wikipedia-en",
    run: async () => {
      const lang = arabic ? "ar" : "en";
      const params = new URLSearchParams({
        action: "query",
        list: "search",
        format: "json",
        srlimit: String(SEARCH_RESULTS_LIMIT),
        srsearch: q,
      });
      const response = await fetchWithTimeout(
        `${WIKIPEDIA_ENDPOINTS[lang]}?${params.toString()}`,
        {
          method: "GET",
          headers: {
            "User-Agent": "flutter-ai-app/1.0 (educational project)",
            Accept: "application/json",
          },
        },
        SEARCH_TIMEOUT_MS,
      );
      const bodyText = await response.text();
      if (!response.ok) {
        diagnostics.push(`wikipedia-${lang}: status ${response.status}`);
        return [];
      }
      return parseWikipediaResults(bodyText, lang);
    },
  });

  // 2. DuckDuckGo Instant Answers — fast entity summaries (202 is its normal status).
  attempts.push({
    name: "ddg-ia",
    run: async () => {
      const params = new URLSearchParams({ q, format: "json", no_html: "1" });
      const response = await fetchWithTimeout(
        `${DDG_IA_ENDPOINT}?${params.toString()}`,
        {
          method: "GET",
          headers: {
            "User-Agent": SEARCH_USER_AGENT,
            Accept: "application/json",
          },
        },
        SEARCH_TIMEOUT_MS,
      );
      const bodyText = await response.text();
      if (!response.ok) {
        diagnostics.push(`ddg-ia: status ${response.status}`);
        return [];
      }
      return parseDdgIaResults(bodyText);
    },
  });

  // 3. HN Algolia — tech news/posts.
  attempts.push({
    name: "hn",
    run: async () => {
      const params = new URLSearchParams({
        query: q,
        hitsPerPage: String(SEARCH_RESULTS_LIMIT),
      });
      const response = await fetchWithTimeout(
        `${HN_ENDPOINT}?${params.toString()}`,
        {
          method: "GET",
          headers: { "User-Agent": "flutter-ai-app/1.0" },
        },
        SEARCH_TIMEOUT_MS,
      );
      const bodyText = await response.text();
      if (!response.ok) {
        diagnostics.push(`hn: status ${response.status}`);
        return [];
      }
      return parseHnResults(bodyText);
    },
  });

  for (const attempt of attempts) {
    const t0 = Date.now();
    try {
      const results = await attempt.run();
      if (results.length > 0) {
        console.log(
          `[search] ${attempt.name} ok results=${results.length} in ${Date.now() - t0}ms`,
        );
        return {
          query: q,
          results,
          endpoint: attempt.name,
          ms: Date.now() - t0,
          diagnostics,
        };
      }
      diagnostics.push(`${attempt.name}: reachable but 0 parsed results`);
    } catch (error) {
      diagnostics.push(
        `${attempt.name}: ${(error && error.name) || "Error"}: ${(error && error.message) || ""}`,
      );
      console.error(
        `[search] ${attempt.name} failed: ${(error && error.name) || "Error"}: ${(error && error.message) || ""}`,
      );
    }
  }
  console.error(`[search] all engines failed: ${JSON.stringify(diagnostics)}`);
  return { query: q, results: [], endpoint: null, ms: 0, diagnostics };
}

function buildSearchSystemText(searchInfo) {
  const lines = [
    "أنت مساعد ذكي. فعّل المستخدم خاصية البحث في الإنترنت، وهذه أحدث نتائج بحث مرتبطة بسؤاله:",
  ];
  searchInfo.results.forEach((result, index) => {
    lines.push(`[${index + 1}] العنوان: ${result.title}`);
    lines.push(`المصدر: ${result.url}`);
    if (result.snippet) {
      lines.push(`ملخص: ${result.snippet}`);
    }
  });
  lines.push(
    "استعن بهذه النتائج في صياغة إجابتك عندما تكون مفيدة، واذكر أن المعلومة من الإنترنت عند الحاجة. إذا لم تكن النتائج متعلقة بالسؤال فتجاهلها واعتمد على معرفتك العامة.",
  );
  return lines.join("\n");
}

function buildContents(body) {
  if (!body || !Array.isArray(body.messages) || body.messages.length === 0) {
    return {
      error: "قائمة الرسائل مفقودة أو غير صالحة.",
    };
  }
  const image = normalizeImage(body.image);
  if (image && image.error) {
    return { error: image.error };
  }
  const contents = [];
  for (const message of body.messages) {
    if (!message || typeof message !== "object") {
      continue;
    }
    const role =
      message.role === "user" ? "user" : message.role === "model" ? "model" : null;
    if (!role) {
      continue;
    }
    const text = typeof message.text === "string" ? message.text.trim() : "";
    const parts = [];
    if (text) {
      parts.push({ text });
    }
    contents.push({ role, parts });
  }
  if (contents.length === 0 && image) {
    contents.push({ role: "user", parts: [] });
  }
  if (contents.length === 0) {
    return {
      error: "لا توجد رسائل صالحة في الطلب.",
    };
  }
  if (image) {
    const lastContent = contents[contents.length - 1];
    lastContent.parts.push({
      inlineData: { mimeType: image.mimeType, data: image.data },
    });
  }
  return { contents, hasImage: Boolean(image) };
}

function normalizeImage(image) {
  if (image == null) {
    return null;
  }
  if (typeof image !== "object") {
    return {
      error: "بيانات الصورة غير صالحة.",
    };
  }
  const mimeType =
    typeof image.mimeType === "string" ? image.mimeType.trim() : "";
  let data = typeof image.data === "string" ? image.data.trim() : "";
  if (!mimeType || !data) {
    return {
      error: "بيانات الصورة غير مكتملة.",
    };
  }
  if (!mimeType.toLowerCase().startsWith("image/")) {
    return {
      error: "نوع الصورة غير مدعوم.",
    };
  }
  if (data.length > MAX_IMAGE_BASE64_CHARS) {
    return {
      error: "حجم الصورة كبير جداً.",
    };
  }
  data = data.replace(/-/g, "+").replace(/_/g, "/");
  const pad = data.length % 4;
  if (pad === 1) {
    return {
      error: "بيانات الصورة غير صالحة.",
    };
  }
  if (pad > 0) {
    data += "=".repeat(4 - pad);
  }
  return { mimeType, data };
}

// Splits the model answer into the visible reply and the thought summaries.
// Gemini flags thought parts with thought:true when includeThoughts is on.
function extractReply(data) {
  if (!data) {
    return { text: "", thoughts: "" };
  }
  const candidate =
    Array.isArray(data.candidates) && data.candidates.length > 0
      ? data.candidates[0]
      : null;
  const parts =
    candidate && candidate.content && Array.isArray(candidate.content.parts)
      ? candidate.content.parts
      : [];
  let text = "";
  let thoughts = "";
  for (const part of parts) {
    if (!part || typeof part.text !== "string") {
      continue;
    }
    if (part.thought === true) {
      thoughts += part.text;
    } else {
      text += part.text;
    }
  }
  return { text: text.trim(), thoughts: thoughts.trim() };
}

// ---------------------------------------------------------------------------
// Firebase ID token verification
// ---------------------------------------------------------------------------

class AuthenticationError extends Error {}

function readBearerToken(value) {
  const match = /^Bearer\s+(.+)$/i.exec(value || "");
  if (!match) {
    throw new AuthenticationError("سجّل الدخول ثم حاول مرة أخرى.");
  }
  return match[1];
}

async function verifyFirebaseIdToken(token, projectId) {
  const parts = token.split(".");
  if (parts.length !== 3) {
    throw new AuthenticationError("رمز تسجيل الدخول غير صالح.");
  }
  const header = decodeJsonPart(parts[0]);
  const claims = decodeJsonPart(parts[1]);
  if (header.alg !== "RS256" || typeof header.kid !== "string") {
    throw new AuthenticationError("توقيع رمز تسجيل الدخول غير مدعوم.");
  }
  const jwk = await findFirebaseKey(header.kid);
  if (!jwk) {
    throw new AuthenticationError("تعذر التحقق من رمز تسجيل الدخول.");
  }
  const publicKey = await crypto.subtle.importKey(
    "jwk",
    jwk,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["verify"],
  );
  const signature = decodeBase64Url(parts[2]);
  const signedContent = new TextEncoder().encode(`${parts[0]}.${parts[1]}`);
  const signatureIsValid = await crypto.subtle.verify(
    "RSASSA-PKCS1-v1_5",
    publicKey,
    signature,
    signedContent,
  );
  const now = Math.floor(Date.now() / 1e3);
  if (
    !signatureIsValid ||
    claims.aud !== projectId ||
    claims.iss !== `https://securetoken.google.com/${projectId}` ||
    typeof claims.sub !== "string" ||
    claims.sub.length === 0 ||
    typeof claims.exp !== "number" ||
    claims.exp <= now ||
    typeof claims.iat !== "number" ||
    claims.iat > now
  ) {
    throw new AuthenticationError(
      "انتهت صلاحية تسجيل الدخول أو الرمز غير صالح.",
    );
  }
  return claims;
}

async function findFirebaseKey(kid) {
  const cacheIsFresh = cachedJwks && Date.now() - cachedJwksAt < 36e5;
  if (!cacheIsFresh) {
    await refreshFirebaseKeys();
  }
  let key = cachedJwks.keys.find((item) => item.kid === kid);
  if (!key) {
    await refreshFirebaseKeys();
    key = cachedJwks.keys.find((item) => item.kid === kid);
  }
  return key;
}

async function refreshFirebaseKeys() {
  const response = await fetch(FIREBASE_JWKS_URL);
  if (!response.ok) {
    throw new Error("Unable to load Firebase signing keys.");
  }
  cachedJwks = await response.json();
  cachedJwksAt = Date.now();
}

function decodeJsonPart(part) {
  try {
    return JSON.parse(new TextDecoder().decode(decodeBase64Url(part)));
  } catch (_) {
    throw new AuthenticationError("رمز تسجيل الدخول غير صالح.");
  }
}

function decodeBase64Url(value) {
  const base64 = value.replace(/-/g, "+").replace(/_/g, "/");
  const padded = base64.padEnd(Math.ceil(base64.length / 4) * 4, "=");
  const binary = atob(padded);
  return Uint8Array.from(binary, (character) => character.charCodeAt(0));
}

// ---------------------------------------------------------------------------
// Selftest (guarded diagnostic) + probes for thinking & search
// ---------------------------------------------------------------------------

async function runSelfTest(env) {
  const rawKey = env.GEMINI_API_KEY || "";
  const key = sanitizeKey(rawKey);
  const fingerprint = keyFingerprint(rawKey, key);

  const availableModels = await listAvailableModels(key);

  const probes = [
    { model: "gemini-3.5-flash" },
    { model: "gemini-3.5-flash-lite" },
  ];

  const results = [];
  for (const probe of probes) {
    const payload = {
      contents: [{ role: "user", parts: [{ text: "اكتب كلمة واحدة فقط: تم" }] }],
      generationConfig: {
        maxOutputTokens: 256,
      },
    };
    const t0 = Date.now();
    try {
      const response = await fetchWithTimeout(
        `${GEMINI_API_BASE}/${probe.model}:generateContent`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "x-goog-api-key": key,
          },
          body: JSON.stringify(payload),
        },
        SELFTEST_TIMEOUT_MS,
      );
      const bodyText = await response.text().catch(() => "");
      let parsed = null;
      try {
        parsed = JSON.parse(bodyText);
      } catch (_) {
        parsed = null;
      }
      const reply = extractReply(parsed);
      const candidate =
        parsed && Array.isArray(parsed.candidates) && parsed.candidates[0]
          ? parsed.candidates[0]
          : null;
      results.push({
        model: probe.model,
        status: response.status,
        ms: Date.now() - t0,
        httpOk: response.ok,
        finishReason: (candidate && candidate.finishReason) || null,
        textPreview: reply.text ? reply.text.slice(0, 80) : null,
        bodySnippet: response.ok ? null : bodyText.slice(0, 400),
      });
    } catch (error) {
      results.push({
        model: probe.model,
        status: 0,
        ms: Date.now() - t0,
        httpOk: false,
        thrown: `${(error && error.name) || "Error"}: ${(error && error.message) || ""}`,
      });
    }
  }

  const thinkingProbe = await probeThinking(key);
  const searchProbe = await probeSearch();

  const keyWorks = results.some((r) => r.httpOk);
  return {
    ok: keyWorks,
    version: "v4.2",
    keyFingerprint: fingerprint,
    availableModels,
    results,
    thinkingProbe,
    searchProbe,
  };
}

// Verifies includeThoughts actually returns thought summaries on the primary model.
async function probeThinking(key) {
  const payload = {
    contents: [
      {
        role: "user",
        parts: [{ text: "لماذا السماء زرقاء؟ أجب بإيجاز شديد." }],
      },
    ],
    generationConfig: {
      thinkingConfig: { includeThoughts: true },
    },
  };
  const t0 = Date.now();
  try {
    const response = await fetchWithTimeout(
      `${GEMINI_API_BASE}/gemini-3.5-flash:generateContent`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-goog-api-key": key,
        },
        body: JSON.stringify(payload),
      },
      SELFTEST_TIMEOUT_MS,
    );
    const bodyText = await response.text().catch(() => "");
    let parsed = null;
    try {
      parsed = JSON.parse(bodyText);
    } catch (_) {
      parsed = null;
    }
    const reply = extractReply(parsed);
    return {
      status: response.status,
      ms: Date.now() - t0,
      httpOk: response.ok,
      hasThoughts: Boolean(reply.thoughts),
      thoughtsChars: reply.thoughts.length,
      thoughtsPreview: reply.thoughts ? reply.thoughts.slice(0, 120) : null,
      textPreview: reply.text ? reply.text.slice(0, 80) : null,
      bodySnippet: response.ok ? null : bodyText.slice(0, 300),
    };
  } catch (error) {
    return {
      status: 0,
      httpOk: false,
      thrown: `${(error && error.name) || "Error"}: ${(error && error.message) || ""}`,
    };
  }
}

// Verifies the search engine chain works from the worker's network.
async function probeSearch() {
  const searchInfo = await performWebSearch("flutter latest stable version");
  if (!searchInfo) {
    return { ok: false, note: "empty query" };
  }
  return {
    ok: searchInfo.results.length > 0,
    endpoint: searchInfo.endpoint,
    ms: searchInfo.ms,
    resultsCount: searchInfo.results.length,
    topTitles: searchInfo.results
      .slice(0, 3)
      .map((r) => r.title.slice(0, 60)),
    diagnostics: searchInfo.diagnostics || [],
  };
}

// Lists generateContent-capable models visible to this key. Diagnostic only —
// used by /selftest so we can see exactly which model names the key can use.
async function listAvailableModels(key) {
  try {
    const response = await fetchWithTimeout(
      `${MODELS_LIST_URL}?pageSize=200`,
      { method: "GET", headers: { "x-goog-api-key": key } },
      10000,
    );
    const bodyText = await response.text().catch(() => "");
    if (!response.ok) {
      return {
        error: true,
        status: response.status,
        snippet: bodyText.slice(0, 200),
      };
    }
    const parsed = JSON.parse(bodyText);
    const names = (parsed.models || [])
      .filter(
        (m) =>
          Array.isArray(m.supportedGenerationMethods) &&
          m.supportedGenerationMethods.includes("generateContent"),
      )
      .map((m) => String(m.name || "").replace(/^models\//, ""))
      .filter(Boolean);
    return { error: false, models: names.slice(0, 40) };
  } catch (error) {
    return {
      error: true,
      snippet: `${(error && error.name) || "Error"}: ${(error && error.message) || ""}`,
    };
  }
}

// ---------------------------------------------------------------------------
// Small helpers
// ---------------------------------------------------------------------------

function getCorsHeaders(request) {
  return {
    "Access-Control-Allow-Origin": request.headers.get("Origin") || "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Authorization, Content-Type",
    "Access-Control-Max-Age": "86400",
    Vary: "Origin",
  };
}

function json(body, status, headers) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...headers,
      "Content-Type": "application/json; charset=utf-8",
    },
  });
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

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function snippet(text) {
  if (!text) {
    return "";
  }
  return text.length > 500 ? `${text.slice(0, 500)}...` : text;
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

export default {
  async fetch(request, env) {
    const corsHeaders = getCorsHeaders(request);
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders });
    }
    const url = new URL(request.url);
    if (url.pathname === "/" && request.method === "GET") {
      return json({ status: "ok", version: "v4.1" }, 200, corsHeaders);
    }

    // Guarded diagnostic endpoint. No Firebase auth needed; a secret-ish token
    // (or the Firebase web API key) is required. Reveals only statuses,
    // Google error snippets and a key fingerprint — never the key itself.
    const isSelfTest =
      request.method === "GET" &&
      (url.pathname === "/selftest" || url.pathname.startsWith("/selftest/"));
    if (isSelfTest) {
      const pathToken = decodeURIComponent(
        url.pathname.slice("/selftest/".length).trim(),
      );
      const t = url.searchParams.get("t") || pathToken;
      const allowed =
        (typeof env.FIREBASE_WEB_API_KEY === "string" &&
          env.FIREBASE_WEB_API_KEY.length > 0 &&
          t === env.FIREBASE_WEB_API_KEY) ||
        t === SELFTEST_TOKEN;
      if (!allowed) {
        return json({ error: "not found" }, 404, corsHeaders);
      }
      try {
        const report = await runSelfTest(env);
        console.log(`[selftest] ${JSON.stringify(report)}`);
        return json(report, 200, corsHeaders);
      } catch (error) {
        console.error(`[selftest] failed: ${(error && error.stack) || error}`);
        return json({ error: "selftest failed" }, 500, corsHeaders);
      }
    }

    const isChatRequest =
      request.method === "POST" &&
      (url.pathname === "/" || url.pathname === "/chat");
    if (!isChatRequest) {
      return json(
        {
          error: "المسار أو طريقة الطلب غير مدعومين.",
        },
        404,
        corsHeaders,
      );
    }

    const reqId = crypto.randomUUID().slice(0, 8);
    const startedAt = Date.now();
    if (!env.FIREBASE_PROJECT_ID || !env.GEMINI_API_KEY) {
      console.error(
        `[${reqId}] server config missing: FIREBASE_PROJECT_ID=${!!env.FIREBASE_PROJECT_ID} GEMINI_API_KEY=${!!env.GEMINI_API_KEY}`,
      );
      return json(
        {
          error: "إعدادات خدمة المحادثة غير مكتملة على السيرفر.",
        },
        503,
        corsHeaders,
      );
    }

    try {
      const token = readBearerToken(request.headers.get("Authorization"));
      const firebaseUser = await verifyFirebaseIdToken(
        token,
        env.FIREBASE_PROJECT_ID,
      );
      const raw = await request.text();
      if (raw.length > MAX_RAW_BODY_CHARS) {
        return json(
          {
            error: "حجم الطلب كبير جداً.",
          },
          413,
          corsHeaders,
        );
      }
      let body;
      try {
        body = JSON.parse(raw);
      } catch (_) {
        return json(
          {
            error: "صيغة الطلب غير صالحة.",
          },
          400,
          corsHeaders,
        );
      }
      const built = buildContents(body);
      if (built.error) {
        console.log(`[${reqId}] rejected: ${built.error}`);
        return json({ error: built.error }, 400, corsHeaders);
      }
      console.log(
        `[${reqId}] start uid=${firebaseUser.sub} messages=${built.contents.length} hasImage=${built.hasImage} webSearch=${body.webSearch === true} thinking=${body.thinking === true} bodyKB=${Math.round(raw.length / 1024)}`,
      );

      // --- Web search (optional, graceful) --------------------------------
      let searchInfo = null;
      if (body.webSearch === true) {
        const lastUserText = [...built.contents]
          .reverse()
          .filter((content) => content.role === "user")
          .flatMap((content) => content.parts.map((part) => part.text || ""))
          .join(" ")
          .trim();
        if (lastUserText) {
          const searchResult = await performWebSearch(lastUserText);
          if (searchResult && searchResult.results.length > 0) {
            searchInfo = searchResult;
            console.log(
              `[${reqId}] webSearch ok: query="${searchInfo.query.slice(0, 80)}" results=${searchInfo.results.length} via=${searchInfo.endpoint}`,
            );
          } else {
            console.error(
              `[${reqId}] webSearch failed for query="${lastUserText.slice(0, 80)}" diagnostics=${JSON.stringify(searchResult && searchResult.diagnostics)}`,
            );
          }
        }
      }
      const systemText =
        searchInfo && searchInfo.results.length > 0
          ? buildSearchSystemText(searchInfo)
          : null;

      // --- AI generation (thought summaries only when the client asks for them) ---
      const result = await callGeminiChain({
        env,
        contents: built.contents,
        reqId,
        startedAt,
        options: { includeThoughts: body.thinking === true, systemText },
      });
      const elapsedMs = Date.now() - startedAt;
      if (result.ok) {
        console.log(
          `[${reqId}] done in ${elapsedMs}ms model=${result.model} attempt=${result.attempt} replyChars=${result.text.length} thoughtsChars=${result.thoughts ? result.thoughts.length : 0} sources=${searchInfo ? searchInfo.results.length : 0}`,
        );
        const responseBody = { text: result.text };
        if (result.thoughts) {
          responseBody.thoughts = result.thoughts;
        }
        if (searchInfo && searchInfo.results.length > 0) {
          responseBody.sources = searchInfo.results.map((result2) => ({
            title: result2.title,
            url: result2.url,
          }));
        }
        return json(responseBody, 200, corsHeaders);
      }
      const failure = result.failure;
      console.error(
        `[${reqId}] final failure after ${elapsedMs}ms: ${JSON.stringify(
          result.failures || [failure],
        )}`,
      );
      if (failure.status === 429) {
        return json(
          {
            error:
              "وصلت الخدمة إلى حد الاستخدام المجاني. حاول بعد دقيقة.",
          },
          429,
          corsHeaders,
        );
      }
      if (failure.status === 0) {
        return json(
          {
            error:
              "استغرق توليد الرد وقتاً أطول من المتاح. حاول مرة أخرى.",
          },
          504,
          corsHeaders,
        );
      }
      return json(
        {
          error: "تعذر توليد الرد لدى مزود الخدمة.",
          detail: failure.body,
        },
        502,
        corsHeaders,
      );
    } catch (error) {
      if (error instanceof AuthenticationError) {
        return json({ error: error.message }, 401, corsHeaders);
      }
      console.error(`[chat] unexpected error: ${(error && error.stack) || error}`);
      return json(
        {
          error: "حدث خطأ غير متوقع في خدمة المحادثة.",
        },
        500,
        corsHeaders,
      );
    }
  },
};
