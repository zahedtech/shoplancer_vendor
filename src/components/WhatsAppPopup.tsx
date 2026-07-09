import { useEffect, useState } from "react";
import { MessageCircle, X } from "lucide-react";
import { cn } from "@/lib/utils";
import { buildWhatsAppUrl } from "@/lib/whatsapp";

interface Props {
  phone?: string;
  storeName?: string;
  /** When true, also shows a floating bubble after dismissing the popup. */
  alwaysShowBubble?: boolean;
}

const STORAGE_KEY_PREFIX = "wa_popup_dismissed_";

/**
 * WhatsApp contact popup — shows once after a short delay, then collapses
 * to a small floating bubble. Used for clothes/fashion stores where
 * direct chat for sizes/availability is the norm.
 */
export const WhatsAppPopup = ({ phone, storeName, alwaysShowBubble = true }: Props) => {
  const [open, setOpen] = useState(false);
  const [dismissed, setDismissed] = useState(true);

  const key = `${STORAGE_KEY_PREFIX}${phone ?? "x"}`;

  useEffect(() => {
    if (!phone) return;
    try {
      const flag = sessionStorage.getItem(key);
      setDismissed(!!flag);
      if (!flag) {
        const id = window.setTimeout(() => setOpen(true), 2500);
        return () => window.clearTimeout(id);
      }
    } catch {
      // ignore
    }
  }, [phone, key]);

  if (!phone) return null;

  const message = storeName ? `مرحباً، أتواصل معكم بخصوص متجر ${storeName}` : "مرحباً";
  const waUrl = buildWhatsAppUrl(phone, message);

  const close = () => {
    setOpen(false);
    setDismissed(true);
    try {
      sessionStorage.setItem(key, "1");
    } catch {
      // ignore
    }
  };

  return (
    <>
      {/* Popup card */}
      {open && (
        <div
          className="fixed bottom-24 md:bottom-6 right-3 md:right-6 z-50 max-w-[300px] w-[calc(100vw-1.5rem)] bg-card border border-border rounded-2xl shadow-card p-4 animate-fade-in"
          dir="rtl"
        >
          <button
            onClick={close}
            aria-label="إغلاق"
            className="absolute top-2 left-2 h-7 w-7 inline-flex items-center justify-center rounded-full hover:bg-muted text-muted-foreground"
          >
            <X className="h-4 w-4" />
          </button>
          <div className="flex items-start gap-3">
            <div className="h-11 w-11 rounded-full bg-[hsl(142_70%_45%)] text-white inline-flex items-center justify-center shrink-0">
              <MessageCircle className="h-5 w-5" />
            </div>
            <div className="flex-1 min-w-0">
              <h4 className="font-extrabold text-sm text-foreground">
                تحتاج مساعدة بالمقاس أو الستايل؟
              </h4>
              <p className="text-xs text-muted-foreground mt-1 leading-relaxed">
                تواصل معنا مباشرة على واتساب — نرد عليك بسرعة.
              </p>
              <a
                href={waUrl}
                target="_blank"
                rel="noopener noreferrer"
                onClick={close}
                className="mt-3 inline-flex items-center gap-1.5 bg-[hsl(142_70%_45%)] text-white font-bold text-xs px-3.5 py-2 rounded-full hover:opacity-90 transition-smooth"
              >
                <MessageCircle className="h-3.5 w-3.5" />
                ابدأ المحادثة
              </a>
            </div>
          </div>
        </div>
      )}

      {/* Floating bubble (always visible after first dismiss) */}
      {(dismissed || !open) && alwaysShowBubble && (
        <a
          href={waUrl}
          target="_blank"
          rel="noopener noreferrer"
          aria-label="WhatsApp"
          className={cn(
            "fixed z-40 h-12 w-12 rounded-full bg-[hsl(142_70%_45%)] text-white inline-flex items-center justify-center shadow-card hover:scale-105 transition-smooth",
            "bottom-24 md:bottom-6 right-3 md:right-6",
          )}
        >
          <MessageCircle className="h-6 w-6" />
        </a>
      )}
    </>
  );
};
