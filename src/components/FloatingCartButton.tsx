import { ShoppingBasket } from "lucide-react";
import { useTranslation } from "react-i18next";
import { useLocation } from "react-router-dom";
import { useCart } from "@/context/CartContext";
import { formatPrice } from "@/lib/api";
import { cn } from "@/lib/utils";
import { useCartButtonPosition } from "@/hooks/useCartButtonPosition";
import { useElementHeight } from "@/hooks/useElementHeight";

/**
 * Floating cart button — shown app-wide whenever the cart has items.
 * Sits above BottomNav on mobile and respects safe-area insets so it never
 * collides with iOS home indicators or system gesture bars.
 * Horizontal side (start/end) is user-tunable from Settings.
 */
export const FloatingCartButton = () => {
  const { count, subtotal, openCart, isOpen } = useCart();
  const { t } = useTranslation();
  const [position] = useCartButtonPosition();
  const location = useLocation();
  // Measure live heights so we always sit above whatever bottom UI is mounted
  // (BottomNav on mobile, custom bottom banners, etc.) without hard-coding 76px.
  // Gate measurement on visibility so we don't run a body-wide MutationObserver
  // during initial render when the cart is empty (avoids forced-reflow cost).
  const measureEnabled = count > 0 && !isOpen;
  const bottomNavH = useElementHeight("[data-bottom-nav]", measureEnabled);
  const bottomBannerH = useElementHeight("[data-app-banner-bottom]", measureEnabled);
  const gap = 12;

  if (count <= 0 || isOpen) return null;

  // Hide on admin / vendor / auth surfaces — they don't show BottomNav or cart.
  const path = location.pathname;
  if (
    path.startsWith("/admin") ||
    path.startsWith("/auth") ||
    path.includes("/dashboard")
  ) {
    return null;
  }

  // BottomNav is mobile-only (h ≈ 64px). Lift the button above it on mobile,
  // and keep a comfortable bottom padding on desktop. Always add safe-area.
  // Using arbitrary values + responsive `md:` for desktop.
  return (
    <button
      type="button"
      onClick={openCart}
      aria-label={t("cart.title")}
      style={{
        bottom: `calc(env(safe-area-inset-bottom, 0px) + ${bottomNavH + bottomBannerH + gap}px)`,
        transition: "bottom 200ms ease-out",
      }}
      className={cn(
        "fixed z-40 inline-flex items-center gap-2 rounded-full",
        "bg-primary text-primary-foreground shadow-glow",
        "h-12 ps-3 pe-4 font-extrabold text-sm",
        "hover:bg-primary-glow active:scale-95 transition-smooth animate-scale-in",
        position === "bottom-end" ? "end-4" : "start-4",
      )}
    >
      <span className="relative inline-flex items-center justify-center h-9 w-9 rounded-full bg-primary-foreground/15">
        <ShoppingBasket className="h-5 w-5" />
        <span className="absolute -top-1 -end-1 bg-accent text-accent-foreground text-[10px] font-extrabold h-5 min-w-5 px-1 rounded-full inline-flex items-center justify-center leading-none ring-2 ring-primary tabular-nums">
          {count}
        </span>
      </span>
      <span className="tabular-nums">{formatPrice(subtotal)}</span>
    </button>
  );
};
