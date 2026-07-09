import { LayoutGrid, Home, ShoppingBag, User, Mic, Loader2 } from "lucide-react";
import { useLocation, useNavigate, useParams } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { useCart } from "@/context/CartContext";
import { cn } from "@/lib/utils";
import { useRef, useState, MouseEvent as ReactMouseEvent } from "react";
import { useVoiceRecorder } from "@/hooks/useVoiceRecorder";
import { toast } from "sonner";

interface Ripple {
  id: number;
  x: number;
  y: number;
  size: number;
}

export type BottomNavTarget = "home" | "categories" | "mic" | "cart" | "account";

interface BottomNavProps {
  active?: BottomNavTarget;
  onNavigate?: (target: BottomNavTarget) => void;
}

export const BottomNav = ({ active, onNavigate }: BottomNavProps) => {
  const { count, openCart } = useCart();
  const { t, i18n } = useTranslation();
  const navigate = useNavigate();
  const location = useLocation();
  const { storeSlug = "" } = useParams<{ storeSlug: string }>();

  const inferActive = (): BottomNavTarget => {
    const path = location.pathname;
    if (path.includes("/categories")) return "categories";
    if (path.endsWith("/account")) return "account";
    return "home";
  };
  const current: BottomNavTarget = active ?? inferActive();

  const recorder = useVoiceRecorder({
    lang: i18n.language === "en" ? "en" : "ar",
    onResult: (text) => {
      const trimmed = (text || "").trim();
      if (!trimmed) return;
      navigate(`/${storeSlug}/search?voice=${encodeURIComponent(trimmed)}`);
    },
    onError: (code) => {
      const map: Record<string, string> = {
        unsupported: t("voice.unsupported"),
        micDenied: t("voice.micDenied"),
        noSpeech: t("voice.noSpeech"),
        startFailed: t("voice.startFailed"),
      };
      toast.error(map[code] ?? t("voice.genericError"));
    },
  });

  const go = (target: BottomNavTarget) => {
    if (onNavigate) {
      onNavigate(target);
      return;
    }
    if (target === "cart") {
      openCart();
      return;
    }
    if (target === "mic") return;
    const map: Record<Exclude<BottomNavTarget, "cart" | "mic">, string> = {
      home: `/${storeSlug}`,
      categories: `/${storeSlug}/categories`,
      account: `/${storeSlug}/account`,
    };
    navigate(map[target as Exclude<BottomNavTarget, "cart" | "mic">]);
  };

  const items: {
    key: BottomNavTarget;
    label: string;
    icon: typeof Home;
    badge?: number;
  }[] = [
    { key: "home", label: t("nav.home"), icon: Home },
    { key: "categories", label: t("nav.categories"), icon: LayoutGrid },
    { key: "mic", label: "", icon: Mic }, // placeholder slot for the mic
    { key: "cart", label: t("nav.cart"), icon: ShoppingBag, badge: count },
    { key: "account", label: t("nav.account"), icon: User },
  ];

  const handleMicDown = (e: React.PointerEvent<HTMLButtonElement>) => {
    if (recorder.isProcessing) return;
    e.preventDefault();
    (e.currentTarget as HTMLElement).setPointerCapture?.(e.pointerId);
    recorder.start();
  };
  const handleMicEnd = (e: React.PointerEvent<HTMLButtonElement>) => {
    if (!recorder.isRecording) return;
    e.preventDefault();
    try {
      (e.currentTarget as HTMLElement).releasePointerCapture?.(e.pointerId);
    } catch {
      void 0;
    }
    recorder.stop();
  };

  return (
    <nav
      data-bottom-nav
      className="md:hidden fixed bottom-0 inset-x-0 z-40 bg-background/95 backdrop-blur border-t border-border shadow-card"
      style={{ paddingBottom: "env(safe-area-inset-bottom)" }}
    >
      <ul className="grid grid-cols-5 relative">
        {items.map(({ key, label, icon: Icon, badge }) => {
          if (key === "mic") {
            return (
              <li key={key} className="flex items-center justify-center">
                <div className="relative -mt-7 flex flex-col items-center">
                  {recorder.isRecording && (
                    <>
                      <span className="absolute inset-0 rounded-full bg-primary/30 animate-ping" />
                      <span
                        className="absolute -inset-2 rounded-full bg-primary/15 animate-ping"
                        style={{ animationDuration: "1.6s" }}
                      />
                    </>
                  )}
                  <button
                    type="button"
                    aria-label={
                      recorder.isRecording
                        ? i18n.language === "en"
                          ? "Recording... release to search"
                          : "جاري التسجيل... ارفع إيدك للبحث"
                        : i18n.language === "en"
                        ? "Press and hold to talk"
                        : "اضغط مطولاً للتحدث"
                    }
                    aria-pressed={recorder.isRecording}
                    disabled={recorder.isProcessing}
                    onPointerDown={handleMicDown}
                    onPointerUp={handleMicEnd}
                    onPointerCancel={handleMicEnd}
                    onPointerLeave={handleMicEnd}
                    onContextMenu={(e) => e.preventDefault()}
                    className={cn(
                      "relative z-10 inline-flex items-center justify-center rounded-full text-primary-foreground shadow-glow transition-all duration-200 touch-none ring-4 ring-background",
                      "h-16 w-16",
                      recorder.isRecording
                        ? "bg-primary scale-110"
                        : "bg-gradient-to-br from-primary to-primary/80 active:scale-95",
                      recorder.isProcessing && "opacity-70 cursor-not-allowed",
                    )}
                    style={{ WebkitTapHighlightColor: "transparent" }}
                  >
                    {recorder.isProcessing ? (
                      <Loader2 className="h-7 w-7 animate-spin" />
                    ) : (
                      <Mic className="h-7 w-7" strokeWidth={2.2} />
                    )}
                  </button>
                </div>
              </li>
            );
          }
          const isActive = current === key;
          return (
            <li key={key}>
              <NavTabButton
                isActive={isActive}
                onClick={() => go(key)}
                label={label}
                icon={Icon}
                badge={badge}
              />
            </li>
          );
        })}
      </ul>
    </nav>
  );
};

interface NavTabButtonProps {
  isActive: boolean;
  onClick: () => void;
  label: string;
  icon: typeof Home;
  badge?: number;
}

const NavTabButton = ({ isActive, onClick, label, icon: Icon, badge }: NavTabButtonProps) => {
  const [ripples, setRipples] = useState<Ripple[]>([]);
  const [pressed, setPressed] = useState(false);
  const idRef = useRef(0);

  const spawnRipple = (e: ReactMouseEvent<HTMLButtonElement> | React.PointerEvent<HTMLButtonElement>) => {
    const target = e.currentTarget.querySelector<HTMLSpanElement>("[data-ripple-host]");
    if (!target) return;
    const rect = target.getBoundingClientRect();
    const size = Math.max(rect.width, rect.height);
    const x = ("clientX" in e ? e.clientX : 0) - rect.left - size / 2;
    const y = ("clientY" in e ? e.clientY : 0) - rect.top - size / 2;
    const id = ++idRef.current;
    setRipples((rs) => [...rs, { id, x, y, size }]);
    window.setTimeout(() => {
      setRipples((rs) => rs.filter((r) => r.id !== id));
    }, 650);
  };

  return (
    <button
      onClick={onClick}
      onPointerDown={(e) => {
        setPressed(true);
        spawnRipple(e);
      }}
      onPointerUp={() => setPressed(false)}
      onPointerLeave={() => setPressed(false)}
      onPointerCancel={() => setPressed(false)}
      className={cn(
        "w-full flex flex-col items-center justify-center gap-0.5 py-2 select-none",
        "transition-transform duration-150 ease-out",
        pressed && "scale-95",
        "text-muted-foreground hover:text-primary",
      )}
    >
      <span className="relative inline-flex items-center justify-center">
        <span
          data-ripple-host
          className={cn(
            "relative inline-flex items-center justify-center h-9 min-w-[3.5rem] px-3 rounded-full overflow-hidden",
            "transition-[background-color,color,transform] duration-300 ease-out",
            isActive ? "bg-primary/15 text-primary" : "bg-transparent",
          )}
        >
          <Icon
            className={cn(
              "h-5 w-5 transition-transform duration-300",
              isActive && "animate-nav-bounce",
            )}
            key={isActive ? "active" : "inactive"}
          />
          {ripples.map((r) => (
            <span
              key={r.id}
              className="absolute rounded-full bg-primary/30 animate-ripple pointer-events-none"
              style={{
                left: r.x,
                top: r.y,
                width: r.size,
                height: r.size,
              }}
            />
          ))}
        </span>
        {badge && badge > 0 ? (
          <span className="absolute -top-1 -right-1 bg-accent text-accent-foreground text-[10px] font-bold h-4 min-w-4 px-1 rounded-full inline-flex items-center justify-center leading-none ring-2 ring-background pointer-events-none tabular-nums">
            {badge}
          </span>
        ) : null}
      </span>
      <span
        className={cn(
          "text-[11px] font-bold transition-colors duration-300",
          isActive ? "text-primary" : "text-muted-foreground",
        )}
      >
        {label}
      </span>
    </button>
  );
};
