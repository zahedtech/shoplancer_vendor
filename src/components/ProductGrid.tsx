import { ReactNode } from "react";
import { useTranslation } from "react-i18next";
import { Product } from "@/lib/api";
import { ProductCard } from "./ProductCard";
import { ProductCardSkeleton } from "./skeletons/ProductCardSkeleton";
import { EmptyState } from "./EmptyState";
import { useRegisterProducts } from "@/hooks/useRegisterProducts";

interface ProductGridProps {
  products: Product[];
  loading?: boolean;
  total?: number;
  title?: string;
  /** Compact mode: tighter grid for the mobile rail layout (1 col on phones). */
  compact?: boolean;
  /** Render extra skeleton cards at the end (used during infinite-scroll fetches). */
  fetchingMore?: boolean;
  /** Custom empty state. Falls back to a generic message. */
  emptyState?: ReactNode;
  /** Hide the section header when the page already provides one. */
  hideHeader?: boolean;
}

export const ProductGrid = ({
  products,
  loading,
  total,
  title,
  compact,
  fetchingMore,
  emptyState,
  hideHeader,
}: ProductGridProps) => {
  const { t } = useTranslation();
  useRegisterProducts(products);
  const resolvedTitle = title ?? t("productGrid.ourProducts");
  const gridCols = compact
    ? "grid-cols-2 xs:grid-cols-2 sm:grid-cols-3"
    : "grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5";

  return (
    <section
      id="products"
      className={
        compact
          ? ""
          : hideHeader
            ? "py-4 md:py-6"
            : "container py-8 md:py-10"
      }
    >
      {!compact && !hideHeader && (
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-3">
            <span className="h-7 w-1.5 rounded-full bg-primary" />
            <div>
              <h2 className="text-2xl md:text-3xl font-extrabold text-foreground">
                {resolvedTitle}
              </h2>
              {!loading && (
                <p className="text-sm text-muted-foreground mt-0.5">
                  {t("productGrid.productsAvailable", { count: total ?? products.length })}
                </p>
              )}
            </div>
          </div>
        </div>
      )}

      {loading ? (
        <div className={`grid gap-3 md:gap-5 ${gridCols}`}>
          {Array.from({ length: compact ? 4 : 8 }).map((_, i) => (
            <ProductCardSkeleton key={i} compact={compact} />
          ))}
        </div>
      ) : products.length === 0 ? (
        emptyState ?? (
          <EmptyState
            title={t("productGrid.emptyTitle")}
            description={t("productGrid.emptyDesc")}
          />
        )
      ) : (
        <>
          <div className={`grid gap-3 md:gap-5 ${gridCols}`}>
            {products.map((p, idx) => (
              <ProductCard key={p.id} product={p} priority={idx < 4} />
            ))}
            {fetchingMore &&
              Array.from({ length: compact ? 2 : 4 }).map((_, i) => (
                <ProductCardSkeleton key={`more-${i}`} compact={compact} />
              ))}
          </div>
        </>
      )}
    </section>
  );
};
