import { Sheet, SheetContent, SheetHeader, SheetTitle } from "@/components/ui/sheet";
import { Button } from "@/components/ui/button";
import { Minus, Plus, Trash2, ShoppingBag, Smartphone, CheckCircle2, X, AlertTriangle, PackageX, ArrowLeftRight } from "lucide-react";
import { useCart } from "@/context/CartContext";
import { formatPrice, type Product } from "@/lib/api";
import { useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import { CheckoutDialog } from "./CheckoutDialog";
import { PhoneSyncDialog } from "./PhoneSyncDialog";
import { AlternativesSheet } from "./AlternativesSheet";
import { getProductFromRegistry } from "@/lib/productAlternatives";

export const CartSheet = () => {
  const { items, isOpen, setOpen, increment, decrement, removeItem, subtotal, count, linkedPhone } = useCart();
  const [checkoutOpen, setCheckoutOpen] = useState(false);
  const [syncOpen, setSyncOpen] = useState(false);
  const [altFor, setAltFor] = useState<number | null>(null);
  const { t } = useTranslation();

  /**
   * An item is "unavailable" when its known stock is 0, OR when the latest
   * registry data shows the product is now out of stock. Pure derivation —
   * no API roundtrip needed because rails/grids already feed the registry.
   */
  const enriched = useMemo(() => {
    return items.map((item) => {
      const fresh = getProductFromRegistry(item.id);
      const liveStock = fresh?.stock ?? item.stock ?? null;
      const unavailable = liveStock !== null && liveStock <= 0;
      // Quantity-too-large (only meaningful for piece/produce, not attarah)
      const quantityExceeds =
        liveStock !== null &&
        liveStock > 0 &&
        item.kind !== "attarah" &&
        item.quantity > liveStock;
      return { item, fresh, liveStock, unavailable, quantityExceeds };
    });
  }, [items]);

  const unavailableCount = enriched.filter((e) => e.unavailable).length;
  const exceedingCount = enriched.filter((e) => e.quantityExceeds).length;
  const hasIssues = unavailableCount > 0 || exceedingCount > 0;

  const altProduct = altFor != null
    ? (enriched.find((e) => e.item.id === altFor)?.fresh ??
       (() => {
         const it = items.find((i) => i.id === altFor);
         if (!it) return null;
         // Synthesize a minimal Product for AlternativesSheet (it only needs id + category_id + name + image)
         return {
           id: it.id,
           name: it.name,
           image_full_url: it.image,
           category_id: 0,
           // remainder filled with safe defaults
         } as Product;
       })())
    : null;

  return (
    <>
      <Sheet open={isOpen} onOpenChange={setOpen}>
        <SheetContent
          side="right"
          className="w-full sm:max-w-md flex flex-col p-0 [&>button]:hidden"
        >
          <SheetHeader className="relative p-4 pl-14 sm:pl-16 border-b border-border bg-primary text-primary-foreground text-start">
            <button
              type="button"
              onClick={() => setOpen(false)}
              aria-label={t("cart.close")}
              className="absolute left-3 sm:left-4 top-3 sm:top-4 h-9 w-9 inline-flex items-center justify-center rounded-full bg-primary-foreground text-primary shadow-card hover:scale-105 active:scale-95 transition-smooth focus:outline-none focus:ring-2 focus:ring-primary-foreground/60 focus:ring-offset-2 focus:ring-offset-primary"
            >
              <X className="h-5 w-5" strokeWidth={2.5} />
            </button>

            <SheetTitle className="text-primary-foreground flex items-center gap-2 justify-start text-start">
              <ShoppingBag className="h-5 w-5" />
              <span>{t("cart.title")} ({count})</span>
            </SheetTitle>
            <button
              type="button"
              onClick={() => setSyncOpen(true)}
              className="mt-1 inline-flex items-center gap-1.5 text-xs font-bold bg-primary-foreground/15 hover:bg-primary-foreground/25 transition-smooth rounded-full px-3 py-1.5 self-start"
            >
              {linkedPhone ? (
                <>
                  <CheckCircle2 className="h-3.5 w-3.5" />
                  <span>{t("cart.linkedTo")} <span dir="ltr">{linkedPhone}</span></span>
                </>
              ) : (
                <>
                  <Smartphone className="h-3.5 w-3.5" />
                  <span>{t("cart.linkPhone")}</span>
                </>
              )}
            </button>
          </SheetHeader>

          {items.length === 0 ? (
            <div className="flex-1 flex flex-col items-center justify-center p-8 text-center gap-3">
              <div className="h-20 w-20 rounded-full bg-primary-soft text-primary inline-flex items-center justify-center">
                <ShoppingBag className="h-10 w-10" />
              </div>
              <h3 className="font-bold text-lg">{t("cart.emptyTitle")}</h3>
              <p className="text-sm text-muted-foreground">{t("cart.emptySubtitle")}</p>
              <Button onClick={() => setOpen(false)} className="mt-2 rounded-full">
                {t("cart.continueShopping")}
              </Button>
            </div>
          ) : (
            <>
              {hasIssues && (
                <div
                  role="alert"
                  className="mx-3 mt-3 p-3 rounded-xl bg-discount/10 border border-discount/30 flex items-start gap-2 text-start"
                >
                  <AlertTriangle className="h-4 w-4 text-discount shrink-0 mt-0.5" />
                  <div className="space-y-0.5 min-w-0">
                    <p className="text-xs font-extrabold text-discount leading-snug">
                      {unavailableCount > 0
                        ? `لديك ${unavailableCount} منتج${unavailableCount > 1 ? "ات" : ""} غير متوفر${unavailableCount > 1 ? "ة" : ""} في المتجر`
                        : `كميات أكبر من المخزون المتاح في ${exceedingCount} منتج`}
                    </p>
                    <p className="text-[11px] text-discount/80 leading-snug">
                      راجع البدائل المقترحة أو حدّث الكمية قبل إتمام الطلب.
                    </p>
                  </div>
                </div>
              )}

              <div className="flex-1 overflow-y-auto p-3 space-y-3">
                {enriched.map(({ item, liveStock, unavailable, quantityExceeds }) => (
                  <div
                    key={item.id}
                    className={`flex gap-3 bg-card border rounded-2xl p-3 shadow-soft ${
                      unavailable ? "border-discount/40 bg-discount/5" : "border-border/60"
                    }`}
                  >
                    <div className={`h-20 w-20 rounded-xl bg-secondary overflow-hidden shrink-0 ${unavailable ? "grayscale opacity-70" : ""}`}>
                      {item.image && (
                        <img src={item.image} alt={item.name} className="h-full w-full object-cover" />
                      )}
                    </div>
                    <div className="flex-1 min-w-0 flex flex-col justify-between">
                      <div className="flex items-start justify-between gap-2">
                        <h4 className="font-bold text-sm line-clamp-2 text-start">{item.name}</h4>
                        <button
                          onClick={() => removeItem(item.id)}
                          aria-label={t("cart.remove")}
                          className="text-muted-foreground hover:text-discount transition-smooth shrink-0"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </div>

                      {unavailable && (
                        <p className="text-[11px] font-extrabold text-discount inline-flex items-center gap-1 mt-1">
                          <PackageX className="h-3 w-3" />
                          غير متوفر حاليًا
                        </p>
                      )}
                      {!unavailable && quantityExceeds && liveStock != null && (
                        <p className="text-[11px] font-extrabold text-discount mt-1">
                          المتوفر فقط {liveStock} — حدّث الكمية
                        </p>
                      )}

                      <div className="flex items-center justify-between gap-2 mt-2 flex-wrap">
                        {unavailable ? (
                          <button
                            onClick={() => setAltFor(item.id)}
                            className="inline-flex items-center gap-1 h-8 px-3 rounded-full bg-discount/15 text-discount text-xs font-extrabold hover:bg-discount/25 transition-smooth"
                          >
                            <ArrowLeftRight className="h-3.5 w-3.5" />
                            عرض البدائل
                          </button>
                        ) : (
                          <div className="flex items-center gap-1 bg-secondary rounded-full p-1">
                            <button
                              onClick={() => decrement(item.id)}
                              aria-label={t("cart.decrease")}
                              className="h-7 w-7 rounded-full bg-background text-foreground inline-flex items-center justify-center shadow-soft hover:bg-primary-soft transition-smooth"
                            >
                              <Minus className="h-3.5 w-3.5" />
                            </button>
                            <span className="min-w-7 text-center text-sm font-bold tabular-nums">
                              {item.quantity}
                            </span>
                            <button
                              onClick={() => increment(item.id)}
                              aria-label={t("cart.increase")}
                              className="h-7 w-7 rounded-full bg-primary text-primary-foreground inline-flex items-center justify-center shadow-soft hover:bg-primary-glow transition-smooth"
                            >
                              <Plus className="h-3.5 w-3.5" />
                            </button>
                          </div>
                        )}
                        <span className={`font-extrabold ${unavailable ? "text-muted-foreground line-through" : "text-primary"}`}>
                          {formatPrice(item.price * item.quantity)}
                        </span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>

              <div className="border-t border-border bg-card p-4 space-y-3">
                <div className="flex items-center justify-between text-sm">
                  <span className="text-muted-foreground text-start">{t("cart.subtotal")}</span>
                  <span className="font-bold text-end">{formatPrice(subtotal)}</span>
                </div>
                <div className="flex items-center justify-between text-base">
                  <span className="font-bold text-start">{t("cart.total")}</span>
                  <span className="font-extrabold text-primary text-xl text-end">
                    {formatPrice(subtotal)}
                  </span>
                </div>
                <Button
                  onClick={() => setCheckoutOpen(true)}
                  disabled={hasIssues}
                  className="w-full h-12 rounded-full text-base font-bold shadow-soft hover:shadow-glow disabled:opacity-60"
                >
                  {hasIssues ? "عالج المشاكل لإتمام الطلب" : t("cart.checkout")}
                </Button>
              </div>
            </>
          )}
        </SheetContent>
      </Sheet>

      <CheckoutDialog
        open={checkoutOpen}
        onOpenChange={setCheckoutOpen}
        onConfirmed={() => {
          setCheckoutOpen(false);
          setOpen(false);
        }}
      />

      <PhoneSyncDialog open={syncOpen} onOpenChange={setSyncOpen} />

      {altProduct && (
        <AlternativesSheet
          open={altFor != null}
          onOpenChange={(v) => !v && setAltFor(null)}
          product={altProduct}
          showRemoveFromCart
        />
      )}
    </>
  );
};
