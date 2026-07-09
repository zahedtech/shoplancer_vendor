import { Mic, Loader2 } from "lucide-react";
import { useTranslation } from "react-i18next";
import { cn } from "@/lib/utils";

interface Props {
  isRecording: boolean;
  isProcessing: boolean;
  onPressStart: () => void;
  onPressEnd: () => void;
  disabled?: boolean;
}

/**
 * Big circular push-to-talk microphone button.
 * Hold to record, release to send.
 */
export const BigVoiceMicButton = ({
  isRecording,
  isProcessing,
  onPressStart,
  onPressEnd,
  disabled,
}: Props) => {
  const { t, i18n } = useTranslation();

  const handlePointerDown = (e: React.PointerEvent) => {
    if (disabled || isProcessing) return;
    e.preventDefault();
    (e.currentTarget as HTMLElement).setPointerCapture?.(e.pointerId);
    onPressStart();
  };

  const handlePointerEnd = (e: React.PointerEvent) => {
    if (!isRecording) return;
    e.preventDefault();
    try {
      (e.currentTarget as HTMLElement).releasePointerCapture?.(e.pointerId);
    } catch {
      void 0;
    }
    onPressEnd();
  };

  const label = isProcessing
    ? i18n.language === "en"
      ? "Processing..."
      : "جاري المعالجة..."
    : isRecording
    ? i18n.language === "en"
      ? "Speak now... release to send"
      : "تكلم الآن... ارفع إيدك للإرسال"
    : i18n.language === "en"
    ? "Press and hold to talk"
    : "اضغط مطولاً للتحدث";

  return (
    <div className="flex flex-col items-center gap-4 select-none">
      <div className="relative flex items-center justify-center">
        {/* Animated ripples while recording */}
        {isRecording && (
          <>
            <span className="absolute inset-0 rounded-full bg-primary/30 animate-ping" />
            <span
              className="absolute -inset-4 rounded-full bg-primary/15 animate-ping"
              style={{ animationDuration: "1.6s" }}
            />
            <span
              className="absolute -inset-8 rounded-full bg-primary/10 animate-ping"
              style={{ animationDuration: "2.2s" }}
            />
          </>
        )}

        <button
          type="button"
          aria-label={label}
          aria-pressed={isRecording}
          disabled={disabled || isProcessing}
          onPointerDown={handlePointerDown}
          onPointerUp={handlePointerEnd}
          onPointerCancel={handlePointerEnd}
          onPointerLeave={handlePointerEnd}
          onContextMenu={(e) => e.preventDefault()}
          className={cn(
            "relative z-10 inline-flex items-center justify-center rounded-full text-primary-foreground shadow-glow transition-all duration-200 touch-none",
            "h-40 w-40",
            isRecording
              ? "bg-primary scale-110"
              : "bg-gradient-to-br from-primary to-primary/80 hover:scale-105 active:scale-95",
            (disabled || isProcessing) && "opacity-70 cursor-not-allowed",
          )}
          style={{ WebkitTapHighlightColor: "transparent" }}
        >
          {isProcessing ? (
            <Loader2 className="h-14 w-14 animate-spin" />
          ) : (
            <Mic className="h-16 w-16" strokeWidth={2.2} />
          )}
        </button>
      </div>

      <p
        className={cn(
          "text-sm font-bold text-center transition-colors min-h-[1.5rem]",
          isRecording ? "text-primary" : "text-muted-foreground",
        )}
      >
        {label}
      </p>
    </div>
  );
};
