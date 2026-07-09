import { AlertTriangle, Keyboard, X } from "lucide-react";

interface Props {
  message: string;
  onDismiss: () => void;
  onFocusInput?: () => void;
}

/**
 * Compact dismissible inline banner shown when voice recognition fails.
 * Suggests typing the query manually as a fallback so the user is never stuck.
 */
export const VoiceErrorBanner = ({ message, onDismiss, onFocusInput }: Props) => (
  <div
    role="alert"
    className="relative flex items-start gap-2 rounded-xl border border-destructive/30 bg-destructive/10 p-2.5 pe-8 text-xs text-foreground"
  >
    <AlertTriangle className="h-4 w-4 mt-0.5 shrink-0 text-destructive" />
    <div className="flex-1 min-w-0 space-y-1.5">
      <p className="font-bold leading-snug">{message}</p>
      <p className="text-[11px] text-muted-foreground leading-snug">
        جرّب الكتابة يدوياً في صندوق البحث أو إعادة المحاولة لاحقاً.
      </p>
      {onFocusInput && (
        <button
          type="button"
          onClick={onFocusInput}
          className="inline-flex items-center gap-1 text-[11px] font-extrabold text-primary hover:underline"
        >
          <Keyboard className="h-3.5 w-3.5" />
          اكتب يدوياً
        </button>
      )}
    </div>
    <button
      type="button"
      onClick={onDismiss}
      aria-label="إغلاق"
      className="absolute top-1.5 end-1.5 h-6 w-6 inline-flex items-center justify-center rounded-full text-muted-foreground hover:text-foreground hover:bg-background/60"
    >
      <X className="h-3.5 w-3.5" />
    </button>
  </div>
);
