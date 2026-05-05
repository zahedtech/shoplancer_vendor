import { Mic, RefreshCw, Trash2 } from "lucide-react";
import { useTranslation } from "react-i18next";
import { VoiceHistoryEntry } from "@/lib/voiceSearchHistory";

interface Props {
  items: VoiceHistoryEntry[];
  onPick: (transcript: string) => void;
  onClear: () => void;
}

function timeAgo(ts: number, locale: string): string {
  const diff = Date.now() - ts;
  const min = Math.floor(diff / 60000);
  if (min < 1) return locale === "en" ? "just now" : "الآن";
  if (min < 60) return locale === "en" ? `${min}m ago` : `قبل ${min} د`;
  const h = Math.floor(min / 60);
  if (h < 24) return locale === "en" ? `${h}h ago` : `قبل ${h} س`;
  const d = Math.floor(h / 24);
  return locale === "en" ? `${d}d ago` : `قبل ${d} ي`;
}

export const VoiceHistoryList = ({ items, onPick, onClear }: Props) => {
  const { t, i18n } = useTranslation();
  if (items.length === 0) return null;
  const reRun = t("voiceHistory.reRun", { defaultValue: "إعادة البحث" });
  return (
    <section className="space-y-2">
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-extrabold text-foreground flex items-center gap-2">
          <Mic className="h-4 w-4 text-primary" />
          {t("voiceHistory.title", { defaultValue: "آخر عمليات البحث الصوتي" })}
        </h3>
        <button
          type="button"
          onClick={onClear}
          className="text-xs text-muted-foreground hover:text-destructive transition-smooth inline-flex items-center gap-1"
        >
          <Trash2 className="h-3 w-3" />
          {t("voiceHistory.clear", { defaultValue: "مسح" })}
        </button>
      </div>
      <ul className="divide-y divide-border rounded-2xl border border-border bg-card overflow-hidden">
        {items.map((entry) => (
          <li key={entry.at} className="flex items-stretch">
            <button
              type="button"
              onClick={() => onPick(entry.transcript)}
              className="flex-1 min-w-0 text-start px-3 py-2.5 flex items-center gap-3 hover:bg-secondary/50 transition-smooth"
            >
              <span className="h-8 w-8 shrink-0 rounded-full bg-primary-soft text-primary inline-flex items-center justify-center">
                <Mic className="h-4 w-4" />
              </span>
              <span className="flex-1 min-w-0">
                <span className="block text-sm font-bold text-foreground truncate">
                  {entry.transcript}
                </span>
                <span className="block text-[11px] text-muted-foreground">
                  {timeAgo(entry.at, i18n.language)}
                  {typeof entry.matched === "number" && typeof entry.total === "number" && (
                    <>
                      {" · "}
                      {t("voiceHistory.matched", {
                        matched: entry.matched,
                        total: entry.total,
                        defaultValue: "{{matched}}/{{total}} متاح",
                      })}
                    </>
                  )}
                </span>
              </span>
            </button>
            <button
              type="button"
              onClick={(e) => {
                e.stopPropagation();
                onPick(entry.transcript);
              }}
              aria-label={reRun}
              title={reRun}
              className="shrink-0 my-1.5 me-2 inline-flex items-center gap-1 px-3 rounded-full bg-primary text-primary-foreground text-[11px] font-extrabold hover:shadow-glow transition-smooth"
            >
              <RefreshCw className="h-3.5 w-3.5" />
              <span className="hidden xs:inline">{reRun}</span>
            </button>
          </li>
        ))}
      </ul>
    </section>
  );
};
