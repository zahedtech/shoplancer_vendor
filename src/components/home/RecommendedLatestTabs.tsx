import { useEffect, useState } from "react";
import { Plus, Minus, PackageX, Bookmark, BookmarkCheck } from "lucide-react";
import { useTranslation } from "react-i18next";
import { Product, formatPrice } from "@/lib/api";
import { cn } from "@/lib/utils";
import { RailSkeleton } from "@/components/skeletons/RailSkeleton";
import { EmptyRail } from "@/components/EmptyRail";
import { useProductCardLogic } from "@/hooks/useProductCardLogic";
import { AttarahPickerSheet, formatGrams } from "@/components/AttarahPickerSheet";
import { AlternativesSheet } from "@/components/AlternativesSheet";
import { useRegisterProducts } from "@/hooks/useRegisterProducts";
import { useWatchlist } from "@/context/WatchlistContext";

type TabKey = "recommended" | "latest";

interface RecommendedLatestTabsProps {
  slug: string;
  recommended: { products: Product[]; loading: boolean };
  latest: { products: Product[]; loading: boolean };
  onViewAll?: () => void;
}

const STORAGE_PREFIX = "home:lastTab:";

export const RecommendedLatestTabs = ({
  slug,
  recommended,
  latest,
  onViewAll,
}: RecommendedLatestTabsProps) => {
  const { t, i18n } = useTranslation();
  const storageKey = `${STORAGE_PREFIX}${slug}`;

  const showRecommended = recommended.loading || recommended.products.length > 0;
  const showLatest = latest.loading || latest.products.length > 0;

  const [tab, setTab] = useState<TabKey>(() => {
    if (typeof window === "undefined") return "recommended";
    const saved = window.localStorage.getItem(storageKey);
    return saved === "latest" ? "latest" : "recommended";
  });

  // Auto-switch to an available tab if current is hidden
  useEffect(() => {
    if (tab === "recommended" && !showRecommended && showLatest) {
      setTab("latest");
    } else if (tab === "latest" && !showLatest && showRecommended) {
      setTab("recommended");
    }
  }, [tab, showRecommended, showLatest]);

  useEffect(() => {
    try {
      window.localStorage.setItem(storageKey, tab);
    } catch {
      /* storage may be disabled — non-fatal */
    }
  }, [tab, storageKey]);

  const active = tab === "recommended" ? recommended : latest;
  useRegisterProducts(active.products);

  // When both tabs are empty (and not loading), render an invisible
  // placeholder that preserves the reserved height to avoid CLS.
  if (!showRecommended && !showLatest) {
    return null;
  }

  return (
    <section
      className="py-3 bg-secondary/30"
      dir={i18n.language === "ar" ? "rtl" : "ltr"}
    >
      <div className="container">
        <div className="flex items-center justify-between mb-3 gap-2">
          <div role="tablist" className="inline-flex bg-muted/70 rounded-full p-1 gap-1">
            {showRecommended && (
              <TabButton
                active={tab === "recommended"}
                onClick={() => setTab("recommended")}
              >
                {t("home.tabRecommended")}
              </TabButton>
            )}
            {showLatest && (
              <TabButton active={tab === "latest"} onClick={() => setTab("latest")}>
                {t("home.tabLatest")}
              </TabButton>
            )}
          </div>
          {onViewAll && (
            <button
              onClick={onViewAll}
              className="text-xs font-bold text-primary hover:underline shrink-0"
            >
              {t("home.viewAll")}
            </button>
          )}
        </div>

        <div className="mb-2 px-1 text-[11px] font-bold text-muted-foreground" aria-live="polite">
          {active.loading ? (
            <span className="inline-flex items-center gap-2">
              <span className="inline-block h-3 w-24 bg-muted animate-pulse rounded" />
              <span>{t("home.loadingProducts")}</span>
            </span>
          ) : (
            <span>{t("home.productsCount", { count: active.products.length })}</span>
          )}
        </div>

        {active.loading ? (
          <RailSkeleton />
        ) : active.products.length === 0 ? (
          <div className="min-h-[230px] flex items-stretch">
            <EmptyRail
              title={
                tab === "recommended"
                  ? t("home.emptyRecommendedTitle")
                  : t("home.emptyLatestTitle")
              }
              description={
                tab === "recommended"
                  ? t("home.emptyRecommendedDesc")
                  : t("home.emptyLatestDesc")
              }
              actionLabel={onViewAll ? t("home.browseAllCategories") : undefined}
              onAction={onViewAll}
            />
          </div>
        ) : (
          <div className="overflow-x-auto no-scrollbar -mx-4 px-4">
            <div className="flex items-start gap-3 snap-x snap-mandatory pb-2">
              {active.products.map((p) => (
                <CompactProductCard key={p.id} product={p} />
              ))}
            </div>
          </div>
        )}
      </div>
    </section>
  );
};

const TabButton = ({
  active,
  onClick,
  children,
}: {
  active: boolean;
  onClick: () => void;
  children: React.ReactNode;
}) => (
  <button
    role="tab"
    aria-selected={active}
    onClick={onClick}
    className={cn(
      "px-4 h-9 rounded-full text-xs font-extrabold transition-smooth",
      active
        ? "bg-background text-foreground shadow-soft"
        : "text-muted-foreground hover:text-foreground",
    )}
  >
    {children}
  </button>
);

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
      className={`group relative snap-start shrink-0 w-[130px] sm:w-[140px] bg-card rounded-2xl overflow-hidden border border-border/60 shadow-soft hover:shadow-card transition-smooth ${outOfStock ? "opacity-95" : ""}`}
    >
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
              {t("productCard.discount", { pct })}
            </span>
          )
        )}
      </div>

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

      <div className="relative aspect-[4/3] bg-white overflow-hidden flex items-center justify-center p-2">
        {product.image_full_url ? (
          <img
            src={product.image_full_url}
            alt={product.name}
            loading="lazy"
            decoding="async"
            width={400}
            height={300}
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
