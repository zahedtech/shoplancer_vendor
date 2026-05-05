import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import {
  CheckCircle2,
  ChefHat,
  PackageCheck,
  Truck,
  ChevronLeft,
  X,
} from "lucide-react";
import { useLatestOrder } from "@/hooks/useLatestOrder";
import { cn } from "@/lib/utils";

const STAGES = [
  { key: "received", icon: PackageCheck, label: "تم الاستلام" },
  { key: "preparing", icon: ChefHat, label: "قيد التحضير" },
  { key: "out_for_delivery", icon: Truck, label: "في الطريق" },
  { key: "completed", icon: CheckCircle2, label: "تم التوصيل" },
] as const;

type StageKey = (typeof STAGES)[number]["key"];

function statusToStage(status: string): StageKey {
  if (status === "delivered") return "completed";
  if (status === "out_for_delivery" || status === "picked_up")
    return "out_for_delivery";
  if (
    status === "processing" ||
    status === "confirmed" ||
    status === "handover"
  )
    return "preparing";
  return "received";
}

const TERMINAL = new Set([
  "delivered",
  "canceled",
  "cancelled",
  "failed",
  "returned",
  "refunded",
]);

const SESSION_KEY = "activeOrderBar:dismissedId";

/**
 * Persistent compact bar showing the user's currently active order with a
 * 4-step progress indicator. Renders just above the BottomNav on mobile and
 * pinned to the bottom on desktop.
 */
export const ActiveOrderBar = () => {
  const { storeSlug = "" } = useParams<{ storeSlug: string }>();
  const { order } = useLatestOrder();
  const [dismissedId, setDismissedId] = useState<string | null>(null);

  useEffect(() => {
    try {
      setDismissedId(sessionStorage.getItem(SESSION_KEY));
    } catch {
      /* ignore */
    }
  }, []);

  if (!order) return null;
  if (TERMINAL.has(order.order_status)) return null;
  if (dismissedId && dismissedId === String(order.id)) return null;

  const stage = statusToStage(order.order_status);
  const currentIdx = STAGES.findIndex((s) => s.key === stage);
  const StageIcon = STAGES[currentIdx]?.icon ?? PackageCheck;
  const stageLabel = STAGES[currentIdx]?.label ?? "—";

  const handleDismiss = () => {
    try {
      sessionStorage.setItem(SESSION_KEY, String(order.id));
    } catch {
      /* ignore */
    }
    setDismissedId(String(order.id));
  };

  return (
    <div
      data-active-order-bar
      className={cn(
        "fixed inset-x-0 z-30 px-2 pointer-events-none",
        // Sit above the mobile BottomNav (≈64px + safe-area)
        "bottom-[calc(64px+env(safe-area-inset-bottom))] md:bottom-3",
      )}
    >
      <div className="mx-auto max-w-2xl pointer-events-auto">
        <div className="rounded-2xl bg-card/95 backdrop-blur border border-border shadow-card overflow-hidden">
          <div className="flex items-stretch gap-2 p-2">
            {/* Stage icon */}
            <div className="shrink-0 self-center">
              <span className="relative inline-flex h-10 w-10 rounded-full bg-primary/15 text-primary items-center justify-center">
                <StageIcon className="h-5 w-5" />
                <span className="absolute -top-0.5 -right-0.5 h-2.5 w-2.5 rounded-full bg-primary animate-pulse ring-2 ring-card" />
              </span>
            </div>

            {/* Text + progress */}
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2">
                <p className="text-xs font-extrabold text-foreground truncate">
                  {stageLabel}
                </p>
                <span
                  className="text-[10px] text-muted-foreground font-bold shrink-0"
                  dir="ltr"
                >
                  SL-{order.id}
                </span>
              </div>
              {/* Tiny 4-step progress */}
              <div className="mt-1.5 grid grid-cols-4 gap-1">
                {STAGES.map((_, i) => (
                  <span
                    key={i}
                    className={cn(
                      "h-1 rounded-full",
                      i <= currentIdx ? "bg-primary" : "bg-border",
                    )}
                  />
                ))}
              </div>
            </div>

            {/* Actions */}
            <div className="shrink-0 self-center flex items-center gap-1">
              <Link
                to={`/${storeSlug}/orders/SL-${order.id}`}
                className="inline-flex items-center gap-0.5 rounded-full bg-primary text-primary-foreground text-[11px] font-extrabold px-3 py-1.5 hover:bg-primary-glow transition-smooth"
              >
                تتبّع
                <ChevronLeft className="h-3.5 w-3.5 ltr:rotate-180" />
              </Link>
              <button
                type="button"
                onClick={handleDismiss}
                aria-label="إخفاء"
                className="h-7 w-7 inline-flex items-center justify-center rounded-full text-muted-foreground hover:text-foreground hover:bg-muted transition-smooth"
              >
                <X className="h-3.5 w-3.5" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
