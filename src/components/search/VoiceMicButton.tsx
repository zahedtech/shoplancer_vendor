import { Mic, Square } from "lucide-react";
import { useTranslation } from "react-i18next";
import { cn } from "@/lib/utils";

interface Props {
  isListening: boolean;
  onStart: () => void;
  onStop: () => void;
  size?: "sm" | "md" | "lg";
  disabled?: boolean;
}

const sizes = {
  sm: "h-9 w-9",
  md: "h-11 w-11",
  lg: "h-16 w-16",
};

export const VoiceMicButton = ({
  isListening,
  onStart,
  onStop,
  size = "md",
  disabled,
}: Props) => {
  const { t } = useTranslation();
  return (
    <button
      type="button"
      aria-label={isListening ? t("voice.stopRecording") : t("voice.voiceSearch")}
      disabled={disabled}
      onClick={isListening ? onStop : onStart}
      className={cn(
        "relative inline-flex items-center justify-center rounded-full text-primary-foreground shadow-soft transition-smooth",
        "bg-primary hover:shadow-glow disabled:opacity-50 disabled:cursor-not-allowed",
        sizes[size],
      )}
    >
      {isListening && (
        <span className="absolute inset-0 rounded-full bg-primary/40 animate-ping" />
      )}
      {isListening ? (
        <Square className={size === "lg" ? "h-6 w-6" : "h-4 w-4"} fill="currentColor" />
      ) : (
        <Mic className={size === "lg" ? "h-7 w-7" : "h-4 w-4"} />
      )}
    </button>
  );
};
