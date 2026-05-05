import { useCallback, useEffect, useRef, useState } from "react";
import i18n from "@/lib/i18n";

// Minimal types for the Web Speech API (not in lib.dom by default in TS).
type SpeechRecognitionResult = ArrayLike<{ transcript: string }> & {
  [k: number]: { transcript: string };
  0: { transcript: string };
  isFinal?: boolean;
};

type SpeechRecognitionEvent = {
  results: ArrayLike<SpeechRecognitionResult> & {
    [k: number]: SpeechRecognitionResult;
    length: number;
  };
  resultIndex: number;
};

type SpeechRecognitionInstance = {
  lang: string;
  continuous: boolean;
  interimResults: boolean;
  maxAlternatives: number;
  start: () => void;
  stop: () => void;
  abort: () => void;
  onresult: ((e: SpeechRecognitionEvent) => void) | null;
  onerror: ((e: { error: string }) => void) | null;
  onend: (() => void) | null;
};

function getSpeechCtor(): { new (): SpeechRecognitionInstance } | null {
  if (typeof window === "undefined") return null;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const w = window as any;
  return w.SpeechRecognition || w.webkitSpeechRecognition || null;
}

/**
 * Collapse consecutive duplicate words. Some Android engines emit a final
 * result that contains the same word repeated (e.g. "حليب حليب حليب"); also
 * helps when interim+final overlap. Compares case-insensitively.
 */
function dedupeConsecutiveWords(text: string): string {
  const words = text.split(/\s+/).filter(Boolean);
  const out: string[] = [];
  for (const w of words) {
    const last = out[out.length - 1];
    if (!last || last.toLocaleLowerCase() !== w.toLocaleLowerCase()) {
      out.push(w);
    }
  }
  return out.join(" ");
}

interface Options {
  lang?: string;
  onFinal?: (text: string) => void;
  /** Auto-stop after N ms of silence (no new results). 0 = disabled. */
  silenceTimeoutMs?: number;
}

export function useVoiceRecognition({
  lang = "ar-JO",
  onFinal,
  silenceTimeoutMs = 0,
}: Options = {}) {
  const [isSupported, setIsSupported] = useState(false);
  const [isListening, setIsListening] = useState(false);
  const [transcript, setTranscript] = useState("");
  const [error, setError] = useState<string | null>(null);
  const recogRef = useRef<SpeechRecognitionInstance | null>(null);
  const activeRef = useRef(false);
  const finalRef = useRef("");
  const submittedRef = useRef(false);
  const onFinalRef = useRef(onFinal);
  const silenceTimerRef = useRef<number | null>(null);
  const silenceMsRef = useRef(silenceTimeoutMs);

  // Keep latest onFinal & silence timeout without re-creating start()
  useEffect(() => {
    onFinalRef.current = onFinal;
  }, [onFinal]);

  useEffect(() => {
    silenceMsRef.current = silenceTimeoutMs;
  }, [silenceTimeoutMs]);

  useEffect(() => {
    setIsSupported(!!getSpeechCtor());
  }, []);

  const clearSilenceTimer = useCallback(() => {
    if (silenceTimerRef.current !== null) {
      window.clearTimeout(silenceTimerRef.current);
      silenceTimerRef.current = null;
    }
  }, []);

  const armSilenceTimer = useCallback(() => {
    clearSilenceTimer();
    const ms = silenceMsRef.current;
    if (!ms || ms <= 0) return;
    silenceTimerRef.current = window.setTimeout(() => {
      try {
        recogRef.current?.stop();
      } catch {
        /* ignore */
      }
    }, ms);
  }, [clearSilenceTimer]);

  const start = useCallback(() => {
    if (activeRef.current || isListening) return;
    setError(null);
    setTranscript("");
    finalRef.current = "";
    submittedRef.current = false;
    const Ctor = getSpeechCtor();
    if (!Ctor) {
      setError(i18n.t("voice.unsupported"));
      return;
    }
    const rec = new Ctor();
    rec.lang = lang;
    rec.continuous = false;
    rec.interimResults = true;
    rec.maxAlternatives = 1;

    rec.onresult = (e) => {
      // Reset silence timer on every new chunk (interim or final).
      armSilenceTimer();
      // Only process new results since resultIndex — prevents Android from
      // reprocessing old final results and producing duplicated words.
      let interim = "";
      for (let i = e.resultIndex; i < e.results.length; i++) {
        const res = e.results[i];
        const text = (res?.[0]?.transcript ?? "").trim();
        if (!text) continue;
        if (res.isFinal) {
          const merged = dedupeConsecutiveWords(
            `${finalRef.current} ${text}`.replace(/\s+/g, " ").trim(),
          );
          finalRef.current = merged;
        } else {
          interim = `${interim} ${text}`.replace(/\s+/g, " ").trim();
        }
      }
      const display = dedupeConsecutiveWords(
        `${finalRef.current} ${interim}`.replace(/\s+/g, " ").trim(),
      );
      setTranscript(display);
    };
    rec.onerror = (e) => {
      clearSilenceTimer();
      if (e.error === "not-allowed" || e.error === "service-not-allowed") {
        setError(i18n.t("voice.micDenied"));
      } else if (e.error === "no-speech") {
        setError(i18n.t("voice.noSpeech"));
      } else if (e.error === "network") {
        setError(i18n.t("voice.networkError"));
      } else if (e.error === "audio-capture") {
        setError(i18n.t("voice.audioCapture"));
      } else if (e.error === "language-not-supported" || e.error === "bad-grammar") {
        setError(i18n.t("voice.langNotSupported"));
      } else if (e.error !== "aborted") {
        setError(`${i18n.t("voice.genericError")} (${e.error})`);
      }
      activeRef.current = false;
      setIsListening(false);
    };
    rec.onend = () => {
      clearSilenceTimer();
      activeRef.current = false;
      setIsListening(false);
      const text = dedupeConsecutiveWords(finalRef.current.trim());
      if (text && onFinalRef.current && !submittedRef.current) {
        submittedRef.current = true;
        onFinalRef.current(text);
      }
      recogRef.current = null;
    };
    try {
      activeRef.current = true;
      rec.start();
      recogRef.current = rec;
      setIsListening(true);
      armSilenceTimer();
    } catch {
      activeRef.current = false;
      setError(i18n.t("voice.startFailed"));
    }
  }, [isListening, lang, armSilenceTimer, clearSilenceTimer]);

  const stop = useCallback(() => {
    clearSilenceTimer();
    try {
      recogRef.current?.stop();
    } catch {
      /* ignore */
    }
  }, [clearSilenceTimer]);

  const cancel = useCallback(() => {
    // Use abort() so onend doesn't fire with stale transcript.
    submittedRef.current = true;
    clearSilenceTimer();
    try {
      recogRef.current?.abort();
    } catch {
      /* ignore */
    }
    activeRef.current = false;
    setIsListening(false);
    finalRef.current = "";
    setTranscript("");
  }, [clearSilenceTimer]);

  // Cleanup on unmount only (don't abort on every re-render)
  useEffect(() => {
    return () => {
      clearSilenceTimer();
      try {
        recogRef.current?.abort();
      } catch {
        /* ignore */
      }
    };
  }, [clearSilenceTimer]);

  return { isSupported, isListening, transcript, error, start, stop, cancel };
}
