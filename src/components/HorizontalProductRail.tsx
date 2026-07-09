import { Plus, Minus, PackageX, Bookmark, BookmarkCheck } from "lucide-react";
import { useTranslation } from "react-i18next";
import { Product, formatPrice } from "@/lib/api";
import { cn } from "@/lib/utils";
import { RailSkeleton } from "./skeletons/RailSkeleton";
import { useProductCardLogic } from "@/hooks/useProductCardLogic";
import { AttarahPickerSheet, formatGrams } from "@/components/AttarahPickerSheet";
import { AlternativesSheet } from "@/components/AlternativesSheet";
import { useRegisterProducts } from "@/hooks/useRegisterProducts";
import { useWatchlist } from "@/context/WatchlistContext";

interface HorizontalProductRailProps {
  title: string;
  subtitle?: string;
  products: Product[];
  loading?: boolean;
  /** Optional id used by the offers rail to give it a tinted surface. */
  tone?: "default" | "offers";
  /** When provided, shows a "اعرض الكل" link in the rail header. */
  onViewAll?: () => void;
}

/**
 * Horizontal, snap-scrolling rail of compact product cards. Mirrors the
 * "موصى به لك" design from the reference store: rounded card with badges
 * top-right, discount badge top-left, large +/- pill at the bottom.
 *
 * Hidden gracefully when there are no products and not loading.
 */
export const HorizontalProductRail = ({
  title,
  subtitle,
  products,
  loading,
  tone = "default",
  onViewAll,
}: HorizontalProductRailProps) => {
  const { t, i18n } = useTranslation();
  useRegisterProducts(products);
  if (!loading && products.length === 0) return null;

  return (
    <section
      className={cn(
        "py-6",
        tone === "offers" ? "bg-primary-soft/40" : "bg-secondary/40",
      )}
      dir={i18n.language === "ar" ? "rtl" : "ltr"}
    >
      <div className="container">
        <div className="flex items-end justify-between mb-4">
          <div className="text-start">
            <h2 className="text-xl md:text-2xl font-extrabold text-foreground">
              {title}
            </h2>
            {subtitle && (
              <p className="text-sm text-muted-foreground mt-0.5">{subtitle}</p>
            )}
          </div>
          {onViewAll && (
            <button
              onClick={onViewAll}
              className="text-xs md:text-sm font-bold text-primary hover:underline shrink-0"
            >
              {t("productCard.viewAll")}
            </button>
          )}
        </div>

        {loading ? (
          <RailSkeleton />
        ) : (
          <div className="overflow-x-auto no-scrollbar -mx-4 px-4">
            <div className="flex gap-3 snap-x snap-mandatory pb-2">
              {products.map((p) => (
                <CompactProductCard key={p.id} product={p} />
              ))}
            </div>
          </div>
        )}
      </div>
    </section>
  );
};

const CompactProductCard = ({ product }: { product: Product }) => {
  const { t } = useTranslation();
  const {
    final,
    hasDiscount,
    pct,
    isAttarah,
    byWeight,
    referenceGramPrice,
    minGrams,
    unitChipText,
    cartQtyDisplay,
    inCart,
    handleAdd,
    handleDecrement,
    handleAttarahConfirm,
    attarahOpen,
    setAttarahOpen,
    alternativesOpen,
    setAlternativesOpen,
    outOfStock,
  } = useProductCardLogic(product);
  const { isWatched, toggle: toggleWatch } = useWatchlist();
  const watched = isWatched(product.id);

  return (
    <article
      className={`group relative snap-start shrink-0 w-[150px] sm:w-[160px] bg-card rounded-2xl overflow-hidden border border-border/60 shadow-soft hover:shadow-card transition-smooth ${outOfStock ? "opacity-95" : ""}`}
    >
      {/* Top end — qty chip (in cart) or discount badge */}
      <div className="absolute top-2 end-2 z-10 flex flex-col gap-1 items-end">
        {inCart ? (
          <span
            key={inCart.quantity}
            className="animate-scale-in inline-flex items-center justify-center bg-primary text-primary-foreground text-xs font-extrabold min-w-[2rem] h-7 px-2 rounded-md shadow-soft tabular-nums text-center"
          >
            {cartQtyDisplay}
          </span>
        ) : (
          hasDiscount && (
            <span className="bg-discount text-discount-foreground text-[10px] font-bold px-1.5 py-0.5 rounded-full shadow-soft">
              OFF {pct}%
            </span>
          )
        )}
      </div>

      {/* Top start — minus/edit when in cart */}
      {inCart && !outOfStock && (
        <button
          onClick={handleDecrement}
          aria-label={
            isAttarah
              ? "تعديل الوزن"
              : byWeight
                ? t("productCard.decreaseHalfKilo")
                : t("productCard.decrease")
          }
          className={`absolute top-2 start-2 z-10 h-7 rounded-full bg-background text-foreground border border-border inline-flex items-center justify-center gap-1 shadow-soft hover:bg-muted transition-smooth animate-scale-in ${
            byWeight || isAttarah ? "px-2" : "w-7"
          }`}
        >
          <Minus className="h-3.5 w-3.5" />
          {byWeight && (
            <span className="text-[10px] font-extrabold leading-none">
              {t("productCard.halfKilo")}
            </span>
          )}
          {isAttarah && (
            <span className="text-[10px] font-extrabold leading-none">تعديل</span>
          )}
        </button>
      )}

      {/* Top-start — Watchlist toggle (when not in cart, in stock) */}
      {!inCart && !outOfStock && (
        <button
          onClick={(e) => {
            e.stopPropagation();
            void toggleWatch(product);
          }}
          aria-label={watched ? "إزالة من المتابعة" : "أضف للمتابعة"}
          aria-pressed={watched}
          className={`absolute top-2 start-2 z-10 h-7 w-7 rounded-full inline-flex items-center justify-center shadow-soft transition-smooth active:scale-90 ${
            watched
              ? "bg-primary text-primary-foreground"
              : "bg-background/95 backdrop-blur text-foreground border border-border hover:bg-muted"
          }`}
        >
          {watched ? (
            <BookmarkCheck className="h-3.5 w-3.5" />
          ) : (
            <Bookmark className="h-3.5 w-3.5" />
          )}
        </button>
      )}

      <div className="relative aspect-square bg-white overflow-hidden flex items-center justify-center p-3">
        {product.image_full_url ? (
          <img
            src={product.image_full_url}
            alt={product.name}
            loading="lazy"
            className={`max-h-full max-w-full object-contain group-hover:scale-105 transition-smooth ${outOfStock ? "grayscale" : ""}`}
          />
        ) : (
          <div className="h-full w-full bg-muted rounded-xl" />
        )}

        {outOfStock && (
          <span className="absolute top-1.5 left-1/2 -translate-x-1/2 inline-flex items-center px-2 py-0.5 rounded-full text-[9px] font-extrabold shadow-soft bg-discount text-discount-foreground">
            نفد المخزون
          </span>
        )}

        {/* Unit chip — single source of truth (buildUnitChipDisplay) */}
        {unitChipText && (
          <span className="absolute bottom-1.5 left-1.5 inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-background/95 backdrop-blur text-[10px] font-bold text-foreground border border-border shadow-soft max-w-[calc(100%-12px)] truncate">
            {unitChipText}
          </span>
        )}
      </div>

      <div className="p-2.5 space-y-1.5">
        <h3 className="font-bold text-sm text-foreground line-clamp-1 text-start">
          {product.name}
        </h3>
        {product.description && (
          <p className="text-[11px] text-muted-foreground line-clamp-1 text-start">
            {product.description}
          </p>
        )}

        <div className="flex items-end justify-between gap-2 pt-1">
          <button
            onClick={handleAdd}
            aria-label={
              outOfStock
                ? "اعرض البدائل"
                : isAttarah
                  ? "اختر الوزن أو المبلغ"
                  : byWeight
                    ? inCart
                      ? t("productCard.increaseHalfKilo")
                      : t("productCard.addHalfKilo")
                    : inCart
                      ? t("productCard.increase")
                      : t("productCard.addToCart")
            }
            className={`h-8 rounded-full inline-flex items-center justify-center gap-1 shadow-soft transition-smooth active:scale-90 shrink-0 ${
              outOfStock
                ? "bg-discount/15 text-discount border border-discount/40 hover:bg-discount/20 px-2.5"
                : "bg-primary text-primary-foreground hover:bg-primary-glow hover:shadow-glow"
            } ${!outOfStock && (byWeight || isAttarah) ? "px-2.5" : !outOfStock ? "w-8" : ""}`}
          >
            {outOfStock ? (
              <>
                <PackageX className="h-3.5 w-3.5" />
                <span className="text-[10px] font-extrabold leading-none">بدائل</span>
              </>
            ) : (
              <>
                <Plus className="h-4 w-4" />
                {byWeight && (
                  <span className="text-[10px] font-extrabold leading-none">
                    {t("productCard.halfKilo")}
                  </span>
                )}
                {isAttarah && (
                  <span className="text-[10px] font-extrabold leading-none">وزن/مبلغ</span>
                )}
              </>
            )}
          </button>
          <div className="flex flex-col items-end leading-none min-w-0">
            <span className="text-base font-extrabold text-primary truncate">
              {formatPrice(final)}
            </span>
            {hasDiscount && (
              <span className="text-[10px] text-muted-foreground line-through mt-0.5">
                {formatPrice(product.price)}
              </span>
            )}
            {isAttarah && (
              <span className="text-[9px] text-muted-foreground mt-0.5 font-bold truncate">
                لكل {formatGrams(referenceGramPrice)}
              </span>
            )}
          </div>
        </div>
      </div>

      {isAttarah && (
        <AttarahPickerSheet
          open={attarahOpen}
          onOpenChange={setAttarahOpen}
          product={product}
          unitPrice={final}
          referenceGramPrice={referenceGramPrice}
          minGrams={minGrams}
          currentUnits={inCart?.quantity ?? 0}
          onConfirm={handleAttarahConfirm}
        />
      )}

      <AlternativesSheet
        open={alternativesOpen}
        onOpenChange={setAlternativesOpen}
        product={product}
      />
    </article>
  );
};
