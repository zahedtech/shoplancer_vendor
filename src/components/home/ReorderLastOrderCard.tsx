import { useMemo } from "react";
import { RotateCcw, ShoppingBag } from "lucide-react";
import { useLatestOrder } from "@/hooks/useLatestOrder";
import { useCart } from "@/context/CartContext";
import { formatPrice } from "@/lib/api";
import { reorderFromRemoteOrder } from "@/lib/reorder";
import { Button } from "@/components/ui/button";

/**
 * Home-page card encouraging the customer to re-add their previous order to
 * the cart in one tap. Hides itself when the user has no prior order.
 */
export const ReorderLastOrderCard = () => {
  const { order } = useLatestOrder();
  const { addItem, openCart } = useCart();

  const summary = useMemo(() => {
    if (!order?.details?.length) return null;
    const names = order.details
      .map((d) => d.item_details?.name)
      .filter((n): n is string => !!n);
    const total = Number(order.order_amount ?? 0);
    return {
      count: order.details.length,
      preview: names.slice(0, 2).join(" · "),
      total,
    };
  }, [order]);

  if (!order || !summary) return null;

  const handleReorder = () => {
    const { added } = reorderFromRemoteOrder(order, addItem);
    if (added > 0) openCart();
  };

  return (
    <section className="px-3 md:px-4" dir="rtl">
      <div className="mx-auto max-w-3xl">
        <div className="flex items-center gap-3 rounded-2xl bg-gradient-to-l from-primary/10 via-primary/5 to-card border border-primary/20 p-3 shadow-soft">
          <div className="shrink-0 h-11 w-11 rounded-full bg-primary text-primary-foreground inline-flex items-center justify-center shadow-glow">
            <RotateCcw className="h-5 w-5" />
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-extrabold text-foreground">
              أعد طلبك السابق
            </p>
            <p className="text-[11px] text-muted-foreground truncate">
              {summary.count} منتجات
              {summary.total > 0 ? ` · ${formatPrice(summary.total)}` : ""}
              {summary.preview ? ` · ${summary.preview}` : ""}
            </p>
          </div>
          <Button
            size="sm"
            onClick={handleReorder}
            className="shrink-0 font-extrabold"
          >
            <ShoppingBag className="me-1 h-4 w-4" />
            للسلة
          </Button>
        </div>
      </div>
    </section>
  );
};
