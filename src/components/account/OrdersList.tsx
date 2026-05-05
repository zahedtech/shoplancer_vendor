import { Link } from "react-router-dom";
import { ChevronLeft, Receipt, ShoppingBag } from "lucide-react";
import { useTranslation } from "react-i18next";
import { Order, stageIndex, STAGES } from "@/lib/orders";
import { formatPrice } from "@/lib/api";
import { cn } from "@/lib/utils";

interface Props {
  slug: string;
  orders: Order[];
}

export const OrdersList = ({ slug, orders }: Props) => {
  const { t, i18n } = useTranslation();

  const stageBadge = (order: Order) => {
    const idx = stageIndex(order.stage);
    const key = STAGES[idx]?.key ?? "received";
    const label = t(`order.stages.${key}`);
    const tone =
      order.stage === "completed"
        ? "bg-fresh/15 text-fresh"
        : order.stage === "out_for_delivery"
          ? "bg-accent/15 text-accent"
          : "bg-primary/15 text-primary";
    return (
      <span
        className={cn(
          "px-2 py-0.5 rounded-full text-[10px] font-extrabold whitespace-nowrap",
          tone,
        )}
      >
        {label}
      </span>
    );
  };

  const formatDate = (ts: number) =>
    new Date(ts).toLocaleString(i18n.language === "en" ? "en-GB" : "ar-EG", {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });

  if (orders.length === 0) {
    return (
      <div className="rounded-2xl border border-dashed border-border bg-card/40 p-6 text-center space-y-3">
        <div className="h-12 w-12 mx-auto rounded-full bg-secondary inline-flex items-center justify-center text-muted-foreground">
          <Receipt className="h-6 w-6" />
        </div>
        <p className="text-sm font-bold">{t("ordersList.empty")}</p>
        <p className="text-xs text-muted-foreground">{t("ordersList.emptyHint")}</p>
        <Link
          to={`/${slug}`}
          className="inline-flex items-center gap-2 bg-primary text-primary-foreground rounded-full h-10 px-4 font-bold text-sm shadow-soft"
        >
          <ShoppingBag className="h-4 w-4" />
          {t("ordersList.startShopping")}
        </Link>
      </div>
    );
  }

  return (
    <ul className="rounded-2xl bg-card border border-border overflow-hidden divide-y divide-border">
      {orders.map((o) => {
        const totalQty = o.items.reduce((s, i) => s + i.quantity, 0);
        return (
          <li key={o.id}>
            <Link
              to={`/${slug}/orders/${o.id}`}
              className="flex items-center gap-3 px-4 py-3 hover:bg-secondary/40 transition-smooth"
            >
              <div className="h-11 w-11 rounded-xl bg-primary-soft text-primary inline-flex items-center justify-center shrink-0">
                <Receipt className="h-5 w-5" />
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <p className="font-bold text-sm truncate" dir="ltr">
                    {o.id}
                  </p>
                  {stageBadge(o)}
                </div>
                <p className="text-[11px] text-muted-foreground mt-0.5">
                  {formatDate(o.createdAt)} · {t("ordersList.pieces", { count: totalQty })}
                </p>
              </div>
              <div className="text-left shrink-0">
                <p className="font-extrabold text-primary text-sm">
                  {formatPrice(o.subtotal)}
                </p>
              </div>
              <ChevronLeft className="h-4 w-4 text-muted-foreground shrink-0 ltr:rotate-180" />
            </Link>
          </li>
        );
      })}
    </ul>
  );
};
