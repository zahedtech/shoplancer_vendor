// Per-store voice-search history persisted in localStorage.
// Records the raw transcript + timestamp + (optional) match count so the user
// can re-run an earlier voice search with one tap.

const KEY = (slug: string) => `voice_search_history_${slug}_v1`;
const MAX = 12;

export interface VoiceHistoryEntry {
  transcript: string;
  at: number; // epoch ms
  matched?: number; // how many products matched
  total?: number; // how many items the AI extracted
}

export function getVoiceHistory(slug: string): VoiceHistoryEntry[] {
  try {
    const raw = localStorage.getItem(KEY(slug));
    if (!raw) return [];
    const arr = JSON.parse(raw);
    if (!Array.isArray(arr)) return [];
    return (arr as VoiceHistoryEntry[])
      .filter((e) => e && typeof e.transcript === "string" && e.transcript.trim())
      .slice(0, MAX);
  } catch {
    return [];
  }
}

export function pushVoiceHistory(slug: string, entry: VoiceHistoryEntry) {
  const t = (entry.transcript || "").trim();
  if (!t) return;
  const current = getVoiceHistory(slug).filter(
    (e) => e.transcript.trim().toLowerCase() !== t.toLowerCase(),
  );
  const next = [{ ...entry, transcript: t }, ...current].slice(0, MAX);
  try {
    localStorage.setItem(KEY(slug), JSON.stringify(next));
  } catch {
    /* ignore */
  }
}

export function clearVoiceHistory(slug: string) {
  try {
    localStorage.removeItem(KEY(slug));
  } catch {
    /* ignore */
  }
}

// ----- Voice dialect preference -----
const DIALECT_KEY = "voice_dialect_v1";

// Common Arabic dialects + English. Codes follow BCP-47.
export const VOICE_LANGS = [
  { code: "ar-JO", labelAr: "العربية (الأردن/الشام)", labelEn: "Arabic (Levant)" },
  { code: "ar-SA", labelAr: "العربية (السعودية)", labelEn: "Arabic (Saudi)" },
  { code: "ar-EG", labelAr: "العربية (مصر)", labelEn: "Arabic (Egypt)" },
  { code: "ar-AE", labelAr: "العربية (الإمارات)", labelEn: "Arabic (UAE)" },
  { code: "ar-MA", labelAr: "العربية (المغرب)", labelEn: "Arabic (Morocco)" },
  { code: "ar", labelAr: "العربية الفصحى", labelEn: "Arabic (MSA)" },
  { code: "en-US", labelAr: "English (US)", labelEn: "English (US)" },
  { code: "en-GB", labelAr: "English (UK)", labelEn: "English (UK)" },
] as const;

export type VoiceLangCode = (typeof VOICE_LANGS)[number]["code"];

export function getVoiceDialect(fallback: VoiceLangCode = "ar-JO"): VoiceLangCode {
  try {
    const v = localStorage.getItem(DIALECT_KEY) as VoiceLangCode | null;
    if (v && VOICE_LANGS.some((l) => l.code === v)) return v;
  } catch {
    /* ignore */
  }
  return fallback;
}

export function setVoiceDialect(code: VoiceLangCode) {
  try {
    localStorage.setItem(DIALECT_KEY, code);
  } catch {
    /* ignore */
  }
}

// ----- Cleanup options preference -----
const CLEAN_OPTS_KEY = "voice_clean_opts_v1";

export interface CleanOptions {
  enabled: boolean; // master switch
  removeFillers: boolean;
  normalizeDigits: boolean;
}

export const DEFAULT_CLEAN_OPTS: CleanOptions = {
  enabled: true,
  removeFillers: true,
  normalizeDigits: true,
};

export function getCleanOptions(): CleanOptions {
  try {
    const raw = localStorage.getItem(CLEAN_OPTS_KEY);
    if (!raw) return { ...DEFAULT_CLEAN_OPTS };
    const parsed = JSON.parse(raw);
    return {
      enabled: parsed.enabled ?? true,
      removeFillers: parsed.removeFillers ?? true,
      normalizeDigits: parsed.normalizeDigits ?? true,
    };
  } catch {
    return { ...DEFAULT_CLEAN_OPTS };
  }
}

export function setCleanOptions(opts: CleanOptions) {
  try {
    localStorage.setItem(CLEAN_OPTS_KEY, JSON.stringify(opts));
  } catch {
    /* ignore */
  }
}

// ----- Transcript cleanup -----
const ARABIC_FILLERS = [
  "يعني", "يعنى", "اه", "اها", "امم", "ام", "اممم",
  "والله", "بصراحه", "بصراحة", "تمام", "اوكي", "اوك",
  "من فضلك", "لو سمحت", "لو تكرمت", "ممكن", "بدي اطلب", "اطلب",
];

const ENGLISH_FILLERS = [
  "um", "uh", "uhh", "like", "you know", "please", "i want to order", "i want", "can i get",
];

export function normalizeDigits(s: string): string {
  return s
    .replace(/[\u0660-\u0669]/g, (d) => String(d.charCodeAt(0) - 0x0660))
    .replace(/[\u06F0-\u06F9]/g, (d) => String(d.charCodeAt(0) - 0x06F0));
}

// ----- Listening options (auto-submit / silence timeout / min length) -----
const LISTEN_OPTS_KEY = "voice_listen_opts_v1";

export interface VoiceListenOptions {
  /** When true, finishing a recording immediately runs the AI search.
   *  When false, the recognized text only fills the search input. */
  autoSubmit: boolean;
  /** Auto-stop the mic after this many ms of silence. 0 = disabled. */
  silenceTimeoutMs: number;
  /** Reject final transcripts shorter than this length (chars, after trim). */
  minLength: number;
}

export const DEFAULT_LISTEN_OPTS: VoiceListenOptions = {
  autoSubmit: true,
  silenceTimeoutMs: 5000,
  minLength: 2,
};

export function getVoiceListenOptions(): VoiceListenOptions {
  try {
    const raw = localStorage.getItem(LISTEN_OPTS_KEY);
    if (!raw) return { ...DEFAULT_LISTEN_OPTS };
    const p = JSON.parse(raw);
    return {
      autoSubmit: typeof p.autoSubmit === "boolean" ? p.autoSubmit : true,
      silenceTimeoutMs:
        typeof p.silenceTimeoutMs === "number" ? p.silenceTimeoutMs : 5000,
      minLength: typeof p.minLength === "number" ? p.minLength : 2,
    };
  } catch {
    return { ...DEFAULT_LISTEN_OPTS };
  }
}

export function setVoiceListenOptions(opts: VoiceListenOptions) {
  try {
    localStorage.setItem(LISTEN_OPTS_KEY, JSON.stringify(opts));
  } catch {
    /* ignore */
  }
}

export function cleanTranscript(input: string, opts?: Partial<CleanOptions>): string {
  if (!input) return "";
  const o: CleanOptions = { ...DEFAULT_CLEAN_OPTS, ...(opts ?? {}) };
  let out = input.normalize("NFKC").trim();
  if (!o.enabled) return out;
  if (o.normalizeDigits) out = normalizeDigits(out);
  // Collapse repeated punctuation
  out = out.replace(/[.!؟?]+/g, " , ").replace(/[،;]/g, " , ");
  if (o.removeFillers) {
    const fillers = [...ARABIC_FILLERS, ...ENGLISH_FILLERS];
    for (const f of fillers) {
      const re = new RegExp(`(?:^|\\s)${f.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}(?=\\s|$|,)`, "gi");
      out = out.replace(re, " ");
    }
  }
  out = out.replace(/\b(\S+)(\s+\1\b)+/gi, "$1");
  out = out.replace(/\s+,\s+,\s+/g, " , ").replace(/\s+/g, " ").trim();
  out = out.replace(/^[,،\s]+|[,،\s]+$/g, "").trim();
  return out;
}
