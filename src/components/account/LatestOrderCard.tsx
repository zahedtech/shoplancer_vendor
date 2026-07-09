import { Link, useParams } from "react-router-dom";
import { CheckCircle2, ChefHat, PackageCheck, Truck, RefreshCw, ChevronLeft } from "lucide-react";
import { useLatestOrder } from "@/hooks/useLatestOrder";
import { formatPrice } from "@/lib/api";
import { cn } from "@/lib/utils";

const STAGES = [
  { key: "received", icon: PackageCheck, label: "تم الاستلام" },
  { key: "preparing", icon: ChefHat, label: "قيد التحضير" },
  { key: "out_for_delivery", icon: Truck, label: "في الطريق" },
  { key: "completed", icon: CheckCircle2, label: "تم التوصيل" },
] as const;

function statusToStage(status: string): (typeof STAGES)[number]["key"] {
  if (status === "delivered") return "completed";
  if (status === "out_for_delivery" || status === "picked_up") return "out_for_delivery";
  if (status === "processing" || status === "confirmed" || status === "handover")
    return "preparing";
  return "received";
}

export const LatestOrderCard = () => {
  const { storeSlug = "" } = useParams<{ storeSlug: string }>();
  const { order, loading } = useLatestOrder();

  if (!order) return null;

  const stage = statusToStage(order.order_status);
  const currentIdx = STAGES.findIndex((s) => s.key === stage);
  const orderHref = `/${storeSlug}/orders/SL-${order.id}`;
  const date = new Date(order.created_at);
  const dateLabel = isNaN(date.getTime())
    ? ""
    : new Intl.DateTimeFormat("ar", {
        day: "numeric",
        month: "short",
        hour: "2-digit",
        minute: "2-digit",
      }).format(date);

  return (
    <div className="rounded-2xl bg-card border border-border p-4 shadow-soft mt-2">
      <div className="flex items-center justify-between mb-3">
        <div className="min-w-0">
          <p className="text-[11px] text-muted-foreground">آخر طلب</p>
          <p className="font-extrabold text-sm" dir="ltr">
            SL-{order.id}
          </p>
        </div>
        <div className="flex items-center gap-2">
          {loading && (
            <span className="inline-flex items-center gap-1 text-[10px] text-muted-foreground">
              <RefreshCw className="h-3 w-3 animate-spin" />
              تحديث…
            </span>
          )}
          {dateLabel && (
            <span className="text-[11px] text-muted-foreground">{dateLabel}</span>
          )}
        </div>
      </div>

      {/* Stages bar */}
      <ol className="flex items-center justify-between gap-1 mb-4">
        {STAGES.map((s, i) => {
          const Icon = s.icon;
          const done = i <= currentIdx;
          const active = i === currentIdx;
          return (
            <li key={s.key} className="flex-1 flex flex-col items-center gap-1">
              <div className="flex items-center w-full">
                {i > 0 && (
                  <span
                    className={cn(
                      "h-0.5 flex-1",
                      i <= currentIdx ? "bg-primary" : "bg-border",
                    )}
                  />
                )}
                <span
                  className={cn(
                    "h-8 w-8 rounded-full inline-flex items-center justify-center shrink-0 transition-smooth",
                    done
                      ? "bg-primary text-primary-foreground"
                      : "bg-secondary text-muted-foreground",
                    active && stage !== "completed" && "ring-4 ring-primary/20 animate-pulse",
                  )}
                >
                  <Icon className="h-4 w-4" />
                </span>
                {i < STAGES.length - 1 && (
                  <span
                    className={cn(
                      "h-0.5 flex-1",
                      i < currentIdx ? "bg-primary" : "bg-border",
                    )}
                  />
                )}
              </div>
              <span
                className={cn(
                  "text-[10px] font-bold text-center",
                  done ? "text-foreground" : "text-muted-foreground",
                )}
              >
                {s.label}
              </span>
            </li>
          );
        })}
      </ol>

      <div className="flex items-center justify-between pt-3 border-t border-border">
        <span className="font-extrabold text-primary text-sm">
          {formatPrice(Number(order.order_amount ?? 0))}
        </span>
        <Link
          to={orderHref}
          className="inline-flex items-center gap-1 text-xs font-bold text-primary hover:underline"
        >
          تتبع الطلب
          <ChevronLeft className="h-3.5 w-3.5 ltr:rotate-180" />
        </Link>
      </div>
    </div>
  );
};
