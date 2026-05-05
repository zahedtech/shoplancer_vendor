import { useState } from "react";
import { Mic } from "lucide-react";
import { useTranslation } from "react-i18next";
import { VoiceLangPicker } from "@/components/search/VoiceLangPicker";
import {
  getVoiceDialect,
  setVoiceDialect,
  VoiceLangCode,
} from "@/lib/voiceSearchHistory";

export const VoiceSettingsCard = () => {
  const { t, i18n } = useTranslation();
  const [lang, setLang] = useState<VoiceLangCode>(() =>
    getVoiceDialect(i18n.language === "en" ? "en-US" : "ar-JO"),
  );

  return (
    <div className="rounded-2xl bg-card border border-border overflow-hidden">
      <div className="flex items-center gap-2 px-3 py-2.5 border-b border-border bg-primary-soft/30">
        <Mic className="h-4 w-4 text-primary" />
        <h3 className="text-sm font-extrabold text-foreground">
          {t("voiceSettings.title", { defaultValue: "لهجة البحث الصوتي" })}
        </h3>
      </div>

      <div className="p-3">
        <div className="flex items-center justify-between gap-2 flex-wrap">
          <span className="text-xs font-bold text-foreground">
            {t("voiceLang.label", { defaultValue: "اختر اللهجة" })}
          </span>
          <VoiceLangPicker
            value={lang}
            onChange={(v) => {
              setLang(v);
              setVoiceDialect(v);
            }}
          />
        </div>
      </div>
    </div>
  );
};
