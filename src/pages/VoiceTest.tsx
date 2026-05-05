import { useEffect, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { ArrowRight, Mic, Square, Trash2, Copy, CheckCircle2 } from "lucide-react";
import { useVoiceRecognition } from "@/hooks/useVoiceRecognition";
import { Button } from "@/components/ui/button";
import { VoiceLangPicker } from "@/components/search/VoiceLangPicker";
import {
  getVoiceDialect,
  setVoiceDialect,
  type VoiceLangCode,
} from "@/lib/voiceSearchHistory";
import { toast } from "sonner";

interface Sample {
  id: string;
  at: number;
  lang: VoiceLangCode;
  text: string;
  duplicateWords: number;
}

/**
 * Standalone diagnostic page to validate voice recognition on iPhone/Android.
 * Captures every final transcript, highlights consecutive duplicate words,
 * and surfaces device/UA info to make cross-device QA easier.
 */
const VoiceTestPage = () => {
  const navigate = useNavigate();
  const [lang, setLang] = useState<VoiceLangCode>(() => getVoiceDialect("ar-JO"));
  const [samples, setSamples] = useState<Sample[]>([]);
  const ua = typeof navigator !== "undefined" ? navigator.userAgent : "";
  const isAndroid = /Android/i.test(ua);
  const isIOS = /iPad|iPhone|iPod/i.test(ua);
  const isStandaloneRef = useRef(false);

  useEffect(() => {
    isStandaloneRef.current =
      window.matchMedia?.("(display-mode: standalone)")?.matches ?? false;
  }, []);

  const voice = useVoiceRecognition({
    lang,
    onFinal: (text) => {
      const dups = countConsecutiveDuplicates(text);
      const sample: Sample = {
        id: `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
        at: Date.now(),
        lang,
        text,
        duplicateWords: dups,
      };
      setSamples((prev) => [sample, ...prev].slice(0, 30));
      if (dups > 0) {
        toast.warning(`اكتُشفت ${dups} كلمة مكررة متتالية في النتيجة`);
      } else {
        toast.success("نتيجة نظيفة بدون تكرار");
      }
    },
  });

  useEffect(() => {
    if (voice.error) toast.error(voice.error);
  }, [voice.error]);

  const changeLang = (v: VoiceLangCode) => {
    setLang(v);
    setVoiceDialect(v);
  };

  const copyDiagnostics = () => {
    const lines = [
      `UA: ${ua}`,
      `Platform: ${isIOS ? "iOS" : isAndroid ? "Android" : "Other"}`,
      `Standalone: ${isStandaloneRef.current}`,
      `Supported: ${voice.isSupported}`,
      `Lang: ${lang}`,
      `Samples: ${samples.length}`,
      `Total duplicates: ${samples.reduce((s, x) => s + x.duplicateWords, 0)}`,
      "",
      ...samples.map(
        (s) =>
          `[${new Date(s.at).toISOString()}] (${s.lang}, dup=${s.duplicateWords}) "${s.text}"`,
      ),
    ];
    navigator.clipboard
      ?.writeText(lines.join("\n"))
      .then(() => toast.success("تم نسخ تقرير التشخيص"))
      .catch(() => toast.error("تعذّر النسخ"));
  };

  const totalDups = samples.reduce((s, x) => s + x.duplicateWords, 0);

  return (
    <div className="min-h-screen bg-background flex flex-col" dir="rtl">
      <header className="sticky top-0 z-30 bg-background/95 backdrop-blur border-b border-border">
        <div className="container py-3 flex items-center gap-2">
          <button
            type="button"
            onClick={() => navigate(-1)}
            aria-label="رجوع"
            className="shrink-0 h-10 w-10 rounded-full bg-secondary inline-flex items-center justify-center text-muted-foreground hover:text-foreground"
          >
            <ArrowRight className="h-5 w-5" />
          </button>
          <h1 className="flex-1 text-center text-base font-extrabold">
            اختبار البحث الصوتي
          </h1>
          <span className="w-10" />
        </div>
      </header>

      <main className="flex-1 container py-4 space-y-4 pb-24">
        {/* Device info */}
        <section className="rounded-2xl border border-border bg-card p-3 space-y-1.5 text-xs">
          <h2 className="font-extrabold text-sm mb-1">معلومات الجهاز</h2>
          <Row label="النظام" value={isIOS ? "iOS" : isAndroid ? "Android" : "آخر"} />
          <Row
            label="الدعم"
            value={voice.isSupported ? "مدعوم ✓" : "غير مدعوم ✗"}
            tone={voice.isSupported ? "ok" : "bad"}
          />
          <Row label="اللهجة الحالية" value={lang} />
          <Row
            label="UA"
            value={ua}
            mono
          />
        </section>

        {/* Controls */}
        <section className="rounded-2xl border border-border bg-card p-4 space-y-3">
          <div className="flex items-center justify-between gap-2">
            <h2 className="font-extrabold text-sm">تجربة مباشرة</h2>
            <VoiceLangPicker value={lang} onChange={changeLang} />
          </div>

          <div className="flex flex-col items-center gap-3 py-4">
            <button
              type="button"
              disabled={!voice.isSupported}
              onClick={voice.isListening ? voice.stop : voice.start}
              className="relative h-20 w-20 rounded-full bg-primary text-primary-foreground inline-flex items-center justify-center shadow-glow disabled:opacity-50 disabled:cursor-not-allowed"
              aria-label={voice.isListening ? "إيقاف" : "ابدأ التسجيل"}
            >
              {voice.isListening && (
                <span className="absolute inset-0 rounded-full bg-primary/40 animate-ping" />
              )}
              {voice.isListening ? (
                <Square className="h-7 w-7" fill="currentColor" />
              ) : (
                <Mic className="h-8 w-8" />
              )}
            </button>
            <p className="text-xs text-muted-foreground text-center">
              {voice.isListening
                ? "جاري الاستماع... تكلم بوضوح ثم اضغط للإيقاف"
                : "اضغط الميكروفون وانطق جملة عادية للاختبار"}
            </p>
            {voice.transcript && (
              <div className="w-full rounded-xl bg-primary-soft text-primary px-3 py-2 text-sm font-bold text-center">
                « {voice.transcript} »
              </div>
            )}
          </div>
        </section>

        {/* Stats */}
        <section className="grid grid-cols-3 gap-2">
          <Stat label="عدد المحاولات" value={samples.length} />
          <Stat label="كلمات مكررة" value={totalDups} tone={totalDups > 0 ? "bad" : "ok"} />
          <Stat
            label="نظافة"
            value={samples.length === 0 ? "—" : totalDups === 0 ? "100%" : `${Math.round(((samples.length - samples.filter((s) => s.duplicateWords > 0).length) / samples.length) * 100)}%`}
            tone={totalDups === 0 ? "ok" : "bad"}
          />
        </section>

        {/* Samples */}
        <section className="space-y-2">
          <div className="flex items-center justify-between">
            <h2 className="font-extrabold text-sm">سجل المحاولات</h2>
            <div className="flex items-center gap-1">
              <Button
                size="sm"
                variant="outline"
                onClick={copyDiagnostics}
                disabled={samples.length === 0}
                className="h-8 text-xs"
              >
                <Copy className="h-3.5 w-3.5 me-1" /> نسخ التقرير
              </Button>
              <Button
                size="sm"
                variant="outline"
                onClick={() => setSamples([])}
                disabled={samples.length === 0}
                className="h-8 text-xs"
              >
                <Trash2 className="h-3.5 w-3.5 me-1" /> مسح
              </Button>
            </div>
          </div>

          {samples.length === 0 ? (
            <p className="text-center text-xs text-muted-foreground py-6">
              لا توجد محاولات بعد. اضغط الميكروفون لبدء الاختبار.
            </p>
          ) : (
            <ul className="space-y-2">
              {samples.map((s) => (
                <li
                  key={s.id}
                  className={`rounded-xl border p-3 text-xs ${
                    s.duplicateWords > 0
                      ? "border-destructive/40 bg-destructive/5"
                      : "border-border bg-card"
                  }`}
                >
                  <div className="flex items-center justify-between gap-2 mb-1">
                    <span className="font-extrabold inline-flex items-center gap-1">
                      {s.duplicateWords === 0 && (
                        <CheckCircle2 className="h-3.5 w-3.5 text-primary" />
                      )}
                      {new Date(s.at).toLocaleTimeString()}
                    </span>
                    <span className="text-[10px] text-muted-foreground">
                      {s.lang} · {s.duplicateWords > 0 ? `تكرار: ${s.duplicateWords}` : "نظيف"}
                    </span>
                  </div>
                  <p className="font-bold break-words">{s.text}</p>
                </li>
              ))}
            </ul>
          )}
        </section>
      </main>
    </div>
  );
};

/**
 * Normalize Arabic + Latin text for "same word" comparison so that minor
 * differences in diacritics (تشكيل), hamza forms (أ/إ/آ → ا), ya/alef-maqsura
 * (ى → ي), ta-marbuta (ة → ه), case, punctuation, and digit script don't
 * cause us to miss a real duplicate. Used only for *comparison*; the original
 * word is still displayed to the user.
 */
function normalizeForCompare(word: string): string {
  return word
    .normalize("NFKD")
    // Strip Arabic harakat (fatha, kasra, damma, sukun, shadda, dagger alef…)
    .replace(/[\u064B-\u0652\u0670\u0640]/g, "")
    // Strip Latin combining marks that NFKD just exposed
    .replace(/[\u0300-\u036F]/g, "")
    // Unify Arabic letter variants
    .replace(/[\u0623\u0625\u0622]/g, "\u0627") // أ إ آ -> ا
    .replace(/\u0649/g, "\u064A")               // ى -> ي
    .replace(/\u0629/g, "\u0647")               // ة -> ه
    .replace(/\u0624/g, "\u0648")               // ؤ -> و
    .replace(/\u0626/g, "\u064A")               // ئ -> ي
    // Drop punctuation (Arabic + Latin) — leftover from dedupe split on \s
    .replace(/[.,،؛!؟?:"'`(){}[\]\u060C\u061B\u061F]/g, "")
    // Convert Arabic-Indic digits to Latin
    .replace(/[\u0660-\u0669]/g, (d) => String(d.charCodeAt(0) - 0x0660))
    .replace(/[\u06F0-\u06F9]/g, (d) => String(d.charCodeAt(0) - 0x06F0))
    .toLocaleLowerCase()
    .trim();
}

function countConsecutiveDuplicates(text: string): number {
  const words = text.split(/\s+/).filter(Boolean);
  let count = 0;
  for (let i = 1; i < words.length; i++) {
    const a = normalizeForCompare(words[i]);
    const b = normalizeForCompare(words[i - 1]);
    if (a && a === b) count++;
  }
  return count;
}

const Row = ({
  label,
  value,
  tone,
  mono,
}: {
  label: string;
  value: string;
  tone?: "ok" | "bad";
  mono?: boolean;
}) => (
  <div className="flex items-start justify-between gap-2">
    <span className="text-muted-foreground shrink-0">{label}</span>
    <span
      className={`text-end font-bold break-all ${
        tone === "ok"
          ? "text-primary"
          : tone === "bad"
            ? "text-destructive"
            : "text-foreground"
      } ${mono ? "font-mono text-[10px] leading-tight" : ""}`}
    >
      {value}
    </span>
  </div>
);

const Stat = ({
  label,
  value,
  tone,
}: {
  label: string;
  value: number | string;
  tone?: "ok" | "bad";
}) => (
  <div
    className={`rounded-xl border p-3 text-center ${
      tone === "bad"
        ? "border-destructive/40 bg-destructive/5"
        : tone === "ok"
          ? "border-primary/30 bg-primary-soft"
          : "border-border bg-card"
    }`}
  >
    <div
      className={`text-xl font-extrabold ${
        tone === "bad" ? "text-destructive" : tone === "ok" ? "text-primary" : "text-foreground"
      }`}
    >
      {value}
    </div>
    <div className="text-[10px] font-bold text-muted-foreground mt-0.5">{label}</div>
  </div>
);

export default VoiceTestPage;
