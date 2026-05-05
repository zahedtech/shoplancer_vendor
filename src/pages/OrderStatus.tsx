import { useEffect, useState } from "react";
import { Link, Navigate, useLocation, useNavigate, useParams } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { CheckCircle2, ChefHat, PackageCheck, Truck, ArrowRight, MapPin, Phone, Clock, Receipt, Banknote, Wallet } from "lucide-react";
import { advanceStageIfDue, getOrder, STAGES, stageIndex, updateOrder, type Order } from "@/lib/orders";
import { formatPrice } from "@/lib/api";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { SEO } from "@/components/SEO";
import { listUserOrders } from "@/lib/shoplanserApi";
import { useShopAuth } from "@/context/ShopAuthContext";
import { useStore } from "@/context/StoreContext";

const STAGE_ICONS = {
  received: PackageCheck,
  preparing: ChefHat,
  out_for_delivery: Truck,
  completed: CheckCircle2,
} as const;

const OrderStatus = () => {
  const { orderId, storeSlug } = useParams<{ orderId: string; storeSlug: string }>();
  const navigate = useNavigate();
  const location = useLocation();
  const { t } = useTranslation();
  const { isAuthenticated, loading: authLoading } = useShopAuth();
  const { ctx } = useStore();
  const [order, setOrder] = useState<Order | undefined>(() =>
    orderId ? getOrder(orderId) : undefined,
  );

  // Soft guard: API-backed orders (id starts with "SL-") require auth.
  const isApiOrder = !!orderId && orderId.startsWith("SL-");
  const remoteId = isApiOrder ? Number(orderId!.slice(3)) : null;

  // Local stage progression (for local/guest orders).
  useEffect(() => {
    if (!order) return;
    document.title = t("order.seoTitle", {
      id: order.id,
      store: order.storeName ?? "Shoplanser",
    });
    if (isApiOrder) return; // API orders are driven by polling below.

    const tick = () => {
      const advanced = advanceStageIfDue(order);
      if (advanced.stage !== order.stage) {
        updateOrder(advanced.id, { stage: advanced.stage, nextStageAt: advanced.nextStageAt });
        setOrder(advanced);
      }
    };
    tick();
    const interval = window.setInterval(tick, 5_000);
    return () => window.clearInterval(interval);
  }, [order, t, isApiOrder]);

  // API polling for SL- orders: fetch every 30s, sync the displayed stage.
  useEffect(() => {
    if (!isApiOrder || !isAuthenticated || remoteId == null) return;

    const sync = async () => {
      try {
        const { orders } = await listUserOrders(ctx ?? undefined, { limit: 20 });
        const match = orders.find((o) => o.id === remoteId);
        if (!match) return;
        const stage: Order["stage"] =
          match.order_status === "delivered"
            ? "completed"
            : match.order_status === "out_for_delivery"
              ? "out_for_delivery"
              : match.order_status === "processing" || match.order_status === "confirmed"
                ? "preparing"
                : "received";

        setOrder((prev) => {
          if (prev) {
            if (prev.stage === stage) return prev;
            updateOrder(prev.id, { stage, nextStageAt: Date.now() });
            return { ...prev, stage };
          }
          return {
            id: `SL-${match.id}`,
            storeSlug: storeSlug ?? "",
            createdAt: new Date(match.created_at).getTime() || Date.now(),
            items: (match.details ?? []).map((d) => ({
              id: d.id,
              name: d.item_details?.name ?? "",
              image: d.item_details?.image_full_url ?? "",
              price: Number(d.price ?? 0),
              originalPrice: Number(d.price ?? 0),
              quantity: Number(d.quantity ?? 1),
            })),
            subtotal: Number(match.order_amount ?? 0),
            customer: {
              name: match.delivery_address?.contact_person_name ?? "",
              phone: "",
              address: match.delivery_address?.address ?? "",
            },
            slot: { day: "today", dayLabel: "—", window: "—" },
            stage,
            nextStageAt: Date.now(),
          } satisfies Order;
        });
      } catch {
        /* ignore transient errors */
      }
    };

    void sync();
    const interval = window.setInterval(() => {
      if (typeof document !== "undefined" && document.hidden) return;
      void sync();
    }, 30_000);
    const onVis = () => {
      if (typeof document !== "undefined" && !document.hidden) void sync();
    };
    document.addEventListener("visibilitychange", onVis);
    return () => {
      window.clearInterval(interval);
      document.removeEventListener("visibilitychange", onVis);
    };
  }, [isApiOrder, isAuthenticated, remoteId, ctx, storeSlug]);

  // Soft guard for API orders without auth.
  if (isApiOrder && !authLoading && !isAuthenticated && !order) {
    const next = encodeURIComponent(location.pathname + location.search);
    return <Navigate to={`/${storeSlug ?? "awaldrazq"}/login?redirect=${next}`} replace />;
  }

  const homeHref = `/${storeSlug ?? order?.storeSlug ?? "awaldrazq"}`;

  if (!order) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center p-6">
        <div className="text-center space-y-4 max-w-sm">
          <div className="h-20 w-20 mx-auto rounded-full bg-muted text-muted-foreground inline-flex items-center justify-center">
            <Receipt className="h-10 w-10" />
          </div>
          <h1 className="text-2xl font-extrabold">{t("order.notFoundTitle")}</h1>
          <p className="text-sm text-muted-foreground">{t("order.notFoundDesc")}</p>
          <Button onClick={() => navigate(homeHref)} className="rounded-full">
            {t("common.backToHome")}
          </Button>
        </div>
      </div>
    );
  }

  const currentIdx = stageIndex(order.stage);
  const totalQty = order.items.reduce((s, i) => s + i.quantity, 0);
  const currentStageKey = STAGES[currentIdx].key;

  return (
    <div className="min-h-screen bg-secondary/40">
      <SEO
        title={t("order.seoTitle", { id: order.id, store: order.storeName ?? "Shoplanser" })}
        noindex
      />
      <header className="bg-primary text-primary-foreground">
        <div className="container mx-auto px-4 py-4 flex items-center gap-3">
          <Link
            to={homeHref}
            className="h-10 w-10 rounded-full bg-primary-foreground/15 inline-flex items-center justify-center hover:bg-primary-foreground/25 transition-smooth"
            aria-label={t("common.back")}
          >
            <ArrowRight className="h-5 w-5 ltr:rotate-180" />
          </Link>
          <div className="flex-1">
            <h1 className="text-lg font-extrabold">{t("order.header")}</h1>
            <p className="text-xs opacity-90 flex items-center gap-2">
              <span>{order.storeName ?? order.storeSlug}</span>
              <span className="opacity-60">•</span>
              <span dir="ltr">{order.id}</span>
            </p>
          </div>
          {order.storeLogo && (
            <img
              src={order.storeLogo}
              alt={order.storeName ?? ""}
              className="h-10 w-10 rounded-full object-cover ring-2 ring-primary-foreground/40"
            />
          )}
        </div>
      </header>

      <main className="container mx-auto px-4 py-6 max-w-2xl space-y-5">
        <section className="bg-card border border-border/60 rounded-3xl p-5 shadow-soft">
          <div className="text-center space-y-1 mb-5">
            <p className="text-xs text-muted-foreground">{t("order.currentStatus")}</p>
            <h2 className="text-xl font-extrabold text-primary">
              {t(`order.stages.${currentStageKey}`)}
            </h2>
            {order.stage !== "completed" && (
              <p className="text-xs text-muted-foreground">{t("order.nextUpdate")}</p>
            )}
          </div>

          <ol className="relative">
            {STAGES.map((s, i) => {
              const Icon = STAGE_ICONS[s.key];
              const done = i <= currentIdx;
              const active = i === currentIdx;
              return (
                <li key={s.key} className="flex gap-3 pb-5 last:pb-0 relative">
                  {i < STAGES.length - 1 && (
                    <span
                      className={cn(
                        "absolute end-5 top-11 bottom-0 w-0.5",
                        i < currentIdx ? "bg-primary" : "bg-border",
                      )}
                    />
                  )}
                  <div
                    className={cn(
                      "h-10 w-10 rounded-full inline-flex items-center justify-center shrink-0 z-10 transition-smooth",
                      done
                        ? "bg-primary text-primary-foreground shadow-soft"
                        : "bg-secondary text-muted-foreground",
                      active && order.stage !== "completed" && "ring-4 ring-primary/20 animate-pulse",
                    )}
                  >
                    <Icon className="h-5 w-5" />
                  </div>
                  <div className="flex-1 pt-2">
                    <p className={cn("font-bold text-sm", done ? "text-foreground" : "text-muted-foreground")}>
                      {t(`order.stages.${s.key}`)}
                    </p>
                  </div>
                </li>
              );
            })}
          </ol>
        </section>

        <section className="bg-card border border-border/60 rounded-3xl p-5 shadow-soft space-y-3">
          <h3 className="font-extrabold text-base">{t("order.deliveryDetails")}</h3>
          <div className="space-y-2.5 text-sm">
            {order.slot.window && order.slot.window !== "—" && (
              <div className="flex gap-2.5">
                <Clock className="h-4 w-4 text-primary mt-0.5 shrink-0" />
                <div>
                  <p className="text-muted-foreground text-xs">{t("order.deliveryTime")}</p>
                  <p className="font-bold">
                    {order.slot.dayLabel} • <span dir="ltr">{order.slot.window}</span>
                  </p>
                </div>
              </div>
            )}
            <div className="flex gap-2.5">
              <MapPin className="h-4 w-4 text-primary mt-0.5 shrink-0" />
              <div>
                <p className="text-muted-foreground text-xs">{t("order.address")}</p>
                <p className="font-bold">{order.customer.address}</p>
              </div>
            </div>
            <div className="flex gap-2.5">
              <Phone className="h-4 w-4 text-primary mt-0.5 shrink-0" />
              <div>
                <p className="text-muted-foreground text-xs">{t("order.phone")}</p>
                <p className="font-bold" dir="ltr">{order.customer.phone}</p>
              </div>
            </div>
            <div className="flex gap-2.5">
              {order.paymentMethod === "offline" ? (
                <Wallet className="h-4 w-4 text-primary mt-0.5 shrink-0" />
              ) : (
                <Banknote className="h-4 w-4 text-primary mt-0.5 shrink-0" />
              )}
              <div>
                <p className="text-muted-foreground text-xs">{t("order.payment")}</p>
                <p className="font-bold">
                  {order.paymentMethod === "offline"
                    ? t("order.paymentLabel.offline")
                    : t("order.paymentLabel.cod")}
                </p>
              </div>
            </div>
          </div>
        </section>

        <section className="bg-card border border-border/60 rounded-3xl p-5 shadow-soft">
          <h3 className="font-extrabold text-base mb-3">
            {t("order.products")} ({t("ordersList.pieces", { count: totalQty })})
          </h3>
          <ul className="space-y-2.5">
            {order.items.map((it) => (
              <li key={it.id} className="flex items-center gap-3">
                <div className="h-12 w-12 rounded-xl bg-secondary overflow-hidden shrink-0">
                  {it.image && (
                    <img src={it.image} alt={it.name} className="h-full w-full object-cover" loading="lazy" />
                  )}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-bold text-sm line-clamp-1">{it.name}</p>
                  <p className="text-xs text-muted-foreground">× {it.quantity}</p>
                </div>
                <span className="font-bold text-primary text-sm">
                  {formatPrice(it.price * it.quantity)}
                </span>
              </li>
            ))}
          </ul>
          <div className="mt-4 pt-3 border-t border-border flex items-center justify-between">
            <span className="font-bold">{t("order.total")}</span>
            <span className="font-extrabold text-primary text-xl">{formatPrice(order.subtotal)}</span>
          </div>
        </section>

        <Button onClick={() => navigate(homeHref)} className="w-full h-12 rounded-full font-bold">
          {t("order.keepShopping")}
        </Button>
      </main>
    </div>
  );
};

export default OrderStatus;
