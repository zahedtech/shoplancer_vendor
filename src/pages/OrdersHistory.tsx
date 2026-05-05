import { useEffect, useMemo, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { ArrowRight, Package, RotateCcw, ChevronLeft } from "lucide-react";
import { useStore } from "@/context/StoreContext";
import { useShopAuth } from "@/context/ShopAuthContext";
import { useCart } from "@/context/CartContext";
import {
  listUserOrders,
  listRemoteOrders,
  getGuestId,
  type RemoteOrder,
} from "@/lib/shoplanserApi";
import { formatPrice } from "@/lib/api";
import { reorderFromRemoteOrder } from "@/lib/reorder";
import { TopBar } from "@/components/TopBar";
import { BottomNav } from "@/components/BottomNav";
import { StoreSkeleton } from "@/components/StoreSkeleton";
import { StoreNotFound } from "@/components/StoreNotFound";
import { SEO } from "@/components/SEO";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

type Filter = "all" | "active" | "completed" | "canceled";

const FILTERS: { key: Filter; label: string }[] = [
  { key: "all", label: "الكل" },
  { key: "active", label: "قيد التنفيذ" },
  { key: "completed", label: "مكتملة" },
  { key: "canceled", label: "ملغاة" },
];

const ACTIVE_STATUSES = new Set([
  "pending",
  "confirmed",
  "processing",
  "handover",
  "picked_up",
  "out_for_delivery",
]);
const COMPLETED_STATUSES = new Set(["delivered"]);
const CANCELED_STATUSES = new Set([
  "canceled",
  "cancelled",
  "failed",
  "returned",
  "refunded",
]);

function statusLabel(s: string) {
  if (COMPLETED_STATUSES.has(s)) return "تم التوصيل";
  if (CANCELED_STATUSES.has(s)) return "ملغي";
  if (s === "out_for_delivery" || s === "picked_up") return "في الطريق";
  if (s === "processing" || s === "confirmed" || s === "handover")
    return "قيد التحضير";
  return "تم الاستلام";
}

function statusTone(s: string) {
  if (COMPLETED_STATUSES.has(s))
    return "bg-primary/15 text-primary";
  if (CANCELED_STATUSES.has(s))
    return "bg-destructive/15 text-destructive";
  return "bg-accent/15 text-accent-foreground";
}

const OrdersHistory = () => {
  const { storeSlug = "" } = useParams<{ storeSlug: string }>();
  const navigate = useNavigate();
  const { slug, store, ctx, isLoading, isError } = useStore();
  const { isAuthenticated } = useShopAuth();
  const { addItem, openCart } = useCart();

  const [orders, setOrders] = useState<RemoteOrder[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<Filter>("all");

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    const fetcher = isAuthenticated
      ? listUserOrders(ctx ?? undefined, { limit: 50 })
      : (() => {
          const gid = getGuestId();
          return gid && ctx
            ? listRemoteOrders(gid, ctx, { limit: 50 })
            : Promise.resolve({ total_size: 0, orders: [] });
        })();
    fetcher
      .then(({ orders: list }) => {
        if (cancelled) return;
        setOrders(list);
      })
      .catch(() => undefined)
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [ctx, isAuthenticated]);

  const filtered = useMemo(() => {
    if (filter === "all") return orders;
    return orders.filter((o) => {
      if (filter === "completed") return COMPLETED_STATUSES.has(o.order_status);
      if (filter === "canceled") return CANCELED_STATUSES.has(o.order_status);
      return ACTIVE_STATUSES.has(o.order_status);
    });
  }, [orders, filter]);

  if (isLoading) return <StoreSkeleton />;
  if (isError || !store) return <StoreNotFound slug={storeSlug} />;

  const handleReorder = (order: RemoteOrder) => {
    const { added } = reorderFromRemoteOrder(order, addItem);
    if (added > 0) openCart();
  };

  return (
    <div className="min-h-screen flex flex-col bg-background">
      <SEO title={`سجل الطلبات — ${store.name}`} noindex />
      <TopBar store={store} />

      <header className="sticky top-0 z-30 bg-background/95 backdrop-blur border-b border-border md:hidden">
        <div className="container py-3 flex items-center gap-2">
          <button
            type="button"
            onClick={() => navigate(`/${slug}/account`)}
            aria-label="رجوع"
            className="shrink-0 h-10 w-10 rounded-full bg-secondary inline-flex items-center justify-center text-muted-foreground hover:text-foreground transition-smooth"
          >
            <ArrowRight className="h-5 w-5 ltr:rotate-180" />
          </button>
          <h1 className="flex-1 text-center text-lg font-extrabold">
            سجل الطلبات
          </h1>
          <span className="w-10" />
        </div>
      </header>

      <main className="flex-1 container py-4 pb-32 md:pb-8">
        {/* Filters */}
        <div className="flex items-center gap-2 overflow-x-auto pb-2 -mx-1 px-1 no-scrollbar">
          {FILTERS.map((f) => {
            const active = filter === f.key;
            const count =
              f.key === "all"
                ? orders.length
                : f.key === "completed"
                  ? orders.filter((o) =>
                      COMPLETED_STATUSES.has(o.order_status),
                    ).length
                  : f.key === "canceled"
                    ? orders.filter((o) =>
                        CANCELED_STATUSES.has(o.order_status),
                      ).length
                    : orders.filter((o) =>
                        ACTIVE_STATUSES.has(o.order_status),
                      ).length;
            return (
              <button
                key={f.key}
                type="button"
                onClick={() => setFilter(f.key)}
                className={cn(
                  "shrink-0 inline-flex items-center gap-1.5 rounded-full border text-xs font-extrabold px-3.5 py-1.5 transition-smooth",
                  active
                    ? "bg-primary text-primary-foreground border-primary shadow-soft"
                    : "bg-card text-foreground border-border hover:bg-muted",
                )}
              >
                {f.label}
                <span
                  className={cn(
                    "text-[10px] rounded-full px-1.5 py-px tabular-nums",
                    active
                      ? "bg-primary-foreground/20 text-primary-foreground"
                      : "bg-muted text-muted-foreground",
                  )}
                >
                  {count}
                </span>
              </button>
            );
          })}
        </div>

        {/* List */}
        {loading ? (
          <div className="grid gap-3 mt-4">
            {Array.from({ length: 4 }).map((_, i) => (
              <div
                key={i}
                className="h-28 rounded-2xl bg-muted/50 animate-pulse border border-border"
              />
            ))}
          </div>
        ) : filtered.length === 0 ? (
          <div className="text-center py-16">
            <div className="mx-auto h-16 w-16 rounded-full bg-secondary inline-flex items-center justify-center mb-3">
              <Package className="h-7 w-7 text-muted-foreground" />
            </div>
            <p className="text-sm font-bold text-foreground">
              لا توجد طلبات في هذه الفئة
            </p>
            <p className="text-xs text-muted-foreground mt-1">
              {orders.length === 0
                ? "ابدأ بطلبك الأول من الصفحة الرئيسية"
                : "جرّب فلتراً آخر"}
            </p>
            {orders.length === 0 && (
              <Button
                onClick={() => navigate(`/${slug}`)}
                size="sm"
                className="mt-4 font-extrabold"
              >
                تسوّق الآن
              </Button>
            )}
          </div>
        ) : (
          <ul className="grid gap-3 mt-4">
            {filtered.map((o) => {
              const date = new Date(o.created_at);
              const dateLabel = isNaN(date.getTime())
                ? ""
                : new Intl.DateTimeFormat("ar", {
                    day: "numeric",
                    month: "short",
                    year: "numeric",
                    hour: "2-digit",
                    minute: "2-digit",
                  }).format(date);
              const itemsCount = o.details?.length ?? o.details_count ?? 0;
              return (
                <li key={o.id}>
                  <article className="rounded-2xl bg-card border border-border shadow-soft p-3">
                    <div className="flex items-start gap-3">
                      {store.logo_full_url ? (
                        <img
                          src={store.logo_full_url}
                          alt={store.name}
                          className="h-11 w-11 rounded-xl object-cover border border-border shrink-0"
                          loading="lazy"
                        />
                      ) : (
                        <div className="h-11 w-11 rounded-xl bg-muted shrink-0" />
                      )}
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 mb-0.5">
                          <p
                            className="text-xs font-extrabold text-foreground"
                            dir="ltr"
                          >
                            SL-{o.id}
                          </p>
                          <span
                            className={cn(
                              "text-[10px] font-extrabold rounded-full px-2 py-0.5",
                              statusTone(o.order_status),
                            )}
                          >
                            {statusLabel(o.order_status)}
                          </span>
                        </div>
                        <p className="text-[11px] text-muted-foreground truncate">
                          {dateLabel}
                          {itemsCount ? ` · ${itemsCount} منتج` : ""}
                        </p>
                        <p className="text-sm font-extrabold text-primary mt-1">
                          {formatPrice(Number(o.order_amount ?? 0))}
                        </p>
                      </div>
                    </div>

                    <div className="mt-3 flex items-center gap-2 pt-3 border-t border-border">
                      <Link
                        to={`/${slug}/orders/SL-${o.id}`}
                        className="flex-1 inline-flex items-center justify-center gap-1 rounded-xl bg-secondary text-foreground text-xs font-extrabold px-3 py-2 hover:bg-muted transition-smooth"
                      >
                        تتبّع
                        <ChevronLeft className="h-3.5 w-3.5 ltr:rotate-180" />
                      </Link>
                      <button
                        type="button"
                        onClick={() => handleReorder(o)}
                        className="flex-1 inline-flex items-center justify-center gap-1 rounded-xl bg-primary text-primary-foreground text-xs font-extrabold px-3 py-2 hover:bg-primary-glow transition-smooth"
                      >
                        <RotateCcw className="h-3.5 w-3.5" />
                        أعد الطلب
                      </button>
                    </div>
                  </article>
                </li>
              );
            })}
          </ul>
        )}
      </main>

      <BottomNav />
    </div>
  );
};

export default OrdersHistory;
