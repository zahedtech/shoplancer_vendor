import { Languages } from "lucide-react";
import { useTranslation } from "react-i18next";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { VOICE_LANGS, VoiceLangCode } from "@/lib/voiceSearchHistory";

interface Props {
  value: VoiceLangCode;
  onChange: (v: VoiceLangCode) => void;
}

export const VoiceLangPicker = ({ value, onChange }: Props) => {
  const { t, i18n } = useTranslation();
  const isAr = i18n.language !== "en";
  return (
    <div className="inline-flex items-center gap-2">
      <Languages className="h-4 w-4 text-muted-foreground" aria-hidden="true" />
      <span className="text-xs text-muted-foreground font-bold">
        {t("voiceLang.label", { defaultValue: "لهجة الصوت" })}
      </span>
      <Select value={value} onValueChange={(v) => onChange(v as VoiceLangCode)}>
        <SelectTrigger className="h-8 w-auto min-w-[10rem] rounded-full bg-secondary border-transparent text-xs font-bold">
          <SelectValue />
        </SelectTrigger>
        <SelectContent align="end">
          {VOICE_LANGS.map((l) => (
            <SelectItem key={l.code} value={l.code} className="text-xs">
              {isAr ? l.labelAr : l.labelEn}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
    </div>
  );
};
