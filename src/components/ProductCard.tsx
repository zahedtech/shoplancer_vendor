import { useState } from "react";
import { Link } from "react-router-dom";
import { Star, Plus, Minus, PackageX, Bookmark, BookmarkCheck, ShoppingBasket } from "lucide-react";
import { useTranslation } from "react-i18next";
import { Product, formatPrice } from "@/lib/api";
import { useStoreSettings } from "@/hooks/useStoreSettings";
import { useStore, useStoreSlug } from "@/context/StoreContext";
import { useProductCardLogic } from "@/hooks/useProductCardLogic";
import { useWatchlist } from "@/context/WatchlistContext";
import { AttarahPickerSheet, formatGrams } from "@/components/AttarahPickerSheet";
import { AlternativesSheet } from "@/components/AlternativesSheet";
import { getStoreKind } from "@/lib/storeKind";

interface ProductCardProps {
  product: Product;
  /** When true, image is loaded eagerly with fetchpriority=high (use for LCP candidate). */
  priority?: boolean;
}

export function ProductCard({ product, priority = false }: ProductCardProps) {
  const { t } = useTranslation();
  const slug = useStoreSlug();
  const { store } = useStore();
  const settings = useStoreSettings(slug);
  const isClothes = getStoreKind(store) === "clothes";
  const productHref = `/${slug}/product/${product.id}`;

  const {
    final,
    hasDiscount,
    pct,
    isAttarah,
    byWeight,
    referenceGramPrice,
    minGrams,
    displayUnit,
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

  const [imgLoaded, setImgLoaded] = useState(false);
  const { isWatched, toggle: toggleWatch } = useWatchlist();
  const watched = isWatched(product.id);

  const stock = product.stock ?? 0;
  const threshold = Math.max(0, settings.lowStockThreshold ?? 0);
  const showStockBadge =
    stock === 0 || (threshold > 0 && stock > 0 && stock <= threshold);
  const stockBadgeText =
    stock === 0
      ? t("productCard.outOfStock")
      : t("productCard.inStock", { count: stock, unit: displayUnit });

  return (
    <article
      
      className={`group relative bg-card rounded-2xl overflow-hidden border border-border/60 shadow-soft hover:shadow-card transition-smooth hover:-translate-y-0.5 ${outOfStock ? "opacity-95" : ""}`}
    >
      {/* Top-end — minus / edit when in cart, otherwise promo badges */}
      <div className="absolute top-1.5 end-1.5 z-10 flex flex-col gap-1 items-end">
        {inCart && !outOfStock ? (
          <button
            onClick={handleDecrement}
            aria-label={
              isAttarah
                ? "تعديل الوزن"
                : byWeight
                  ? t("productCard.decreaseHalfKilo")
                  : t("productCard.decrease")
            }
            className={`h-7 rounded-full bg-background text-foreground border border-border inline-flex items-center justify-center gap-1 shadow-soft hover:bg-muted transition-smooth animate-scale-in ${
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
        ) : (
          <>
            {hasDiscount && (
              <span className="bg-discount text-discount-foreground text-[10px] font-bold px-1.5 py-0.5 rounded-full shadow-soft">
                {t("productCard.discount", { pct })}
              </span>
            )}
            {!hasDiscount && product.recommended === 1 && (
              <span className="bg-accent text-accent-foreground text-[10px] font-bold px-1.5 py-0.5 rounded-full shadow-soft">
                {t("productCard.bestSeller")}
              </span>
            )}
            {!hasDiscount &&
              product.recommended !== 1 &&
              product.organic === 1 && (
                <span className="bg-fresh text-fresh-foreground text-[10px] font-bold px-1.5 py-0.5 rounded-full shadow-soft">
                  {t("productCard.organic")}
                </span>
              )}
          </>
        )}
      </div>

      {/* Top-start — count chip when in cart */}
      {inCart && (
        <span
          key={inCart.quantity}
          className="absolute top-1.5 start-1.5 z-10 animate-scale-in inline-flex items-center justify-center bg-primary text-primary-foreground text-xs md:text-sm font-extrabold h-8 w-8 rounded-full shadow-soft tabular-nums leading-none p-0"
        >
          {cartQtyDisplay}
        </span>
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
          className={`absolute top-1.5 start-1.5 z-10 h-7 w-7 rounded-full inline-flex items-center justify-center shadow-soft transition-smooth active:scale-90 ${
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

      {/* Image with unit chip — clickable on clothes stores */}
      {isClothes && (
        <Link
          to={productHref}
          aria-label={product.name}
          className="absolute inset-0 z-[1]"
        />
      )}
      <div className="relative aspect-[4/3] bg-white overflow-hidden flex items-center justify-center p-2">
        {product.image_full_url ? (
          <>
            {!imgLoaded && (
              <div className="absolute inset-0 bg-muted animate-pulse" aria-hidden />
            )}
            <img
              src={product.image_full_url}
              alt={product.name}
              loading={priority ? "eager" : "lazy"}
              // @ts-expect-error - fetchpriority is a valid HTML attribute
              fetchpriority={priority ? "high" : "auto"}
              decoding={priority ? "sync" : "async"}
              width={400}
              height={300}
              onLoad={() => setImgLoaded(true)}
              onError={() => setImgLoaded(true)}
              className={`max-h-full max-w-full object-contain group-hover:scale-105 transition-smooth ${
                imgLoaded ? "opacity-100" : "opacity-0"
              } ${outOfStock ? "grayscale" : ""}`}
            />
          </>
        ) : (
          <div className="h-full w-full bg-muted rounded-xl" />
        )}

        {showStockBadge && (
          <span
            className={`absolute top-1.5 left-1/2 -translate-x-1/2 inline-flex items-center px-2 py-0.5 rounded-full text-[9px] font-extrabold shadow-soft border ${
              stock === 0
                ? "bg-discount text-discount-foreground border-transparent"
                : "bg-background/95 backdrop-blur text-foreground border-border"
            }`}
          >
            {stockBadgeText}
          </span>
        )}

        {unitChipText && (
          <span className="absolute bottom-1.5 left-1.5 inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-background/95 backdrop-blur text-[10px] font-bold text-foreground border border-border shadow-soft max-w-[calc(100%-12px)] truncate">
            {unitChipText}
          </span>
        )}
      </div>

      {/* Content */}
      <div className="relative z-[2] p-2 space-y-1">
        {product.avg_rating > 0 && (
          <div className="inline-flex items-center gap-1 text-[10px]">
            <Star className="h-3 w-3 fill-accent text-accent" />
            <span className="font-bold">{product.avg_rating.toFixed(1)}</span>
            <span className="text-muted-foreground">
              ({product.rating_count})
            </span>
          </div>
        )}

        <h3 className="font-bold text-xs md:text-sm text-foreground line-clamp-2 min-h-[2rem] leading-snug">
          {product.name}
        </h3>

        {product.description && (
          <p className="text-[10px] md:text-[11px] text-muted-foreground line-clamp-1 leading-snug">
            {product.description}
          </p>
        )}

        <div className="flex items-end justify-between gap-2 pt-0.5">
          <div className="flex flex-col min-w-0">
            <span className="text-base md:text-lg font-extrabold text-primary leading-none truncate">
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
                {inCart ? <Plus className="h-4 w-4" /> : <ShoppingBasket className="h-4 w-4" />}
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
}

