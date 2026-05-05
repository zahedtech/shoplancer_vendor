import { useMemo, useState, type ReactNode } from "react";
import { Plus, Minus, Star } from "lucide-react";
import {
  applyOverrides,
  formatPrice,
  getDiscountedPrice,
  Product,
  StoreCategory,
  StoreContextData,
} from "@/lib/api";
import { useInfiniteProducts } from "@/hooks/useInfiniteProducts";
import { SortKey } from "@/hooks/useCategoriesUrlState";
import { useCart } from "@/context/CartContext";
import type { PriceOverrides } from "@/lib/priceOverrides";
import { CategoryPills } from "@/components/CategoryPills";
import {
  CategoryToolbar,
  ViewMode,
} from "@/components/categories/CategoryToolbar";
import { ProductGrid } from "@/components/ProductGrid";
import { Button } from "@/components/ui/button";
import { FiltersValue } from "@/components/categories/FiltersSheet";
import { QuickCategoryChips } from "@/components/categories/QuickCategoryChips";
import { EmptyState } from "@/components/EmptyState";
import { PackageSearch } from "lucide-react";

interface Props {
  slug: string;
  ctx: StoreContextData | null;
  categories: StoreCategory[];
  overrides: PriceOverrides;
  /** When true, render the wrap-style QuickCategoryChips instead of the
   *  horizontally-scrolling CategoryPills. Used by the Categories page. */
  quickChips?: boolean;
  /** Pre-select a category id on mount (e.g. first sub-category). */
  initialCategoryId?: number | null;
  /** When provided, clicking a category navigates instead of selecting inline.
   *  In that mode the products grid is hidden — the bar acts purely as nav. */
  onCategoryNavigate?: (categoryId: number) => void;
  /** Optional controlled selection. When provided, internal state is bypassed. */
  selectedCategoryId?: number | null;
  onSelectedCategoryChange?: (id: number | null) => void;
  /** Hide the built-in chips/pills bar (e.g. when selection UI is rendered elsewhere). */
  hideCategoryBar?: boolean;
  /** Optional content rendered between the category bar and the toolbar (e.g. sub-category chips). */
  subCategoriesSlot?: ReactNode;
}

export const CategoryProductsSection = ({
  slug,
  ctx,
  categories,
  overrides,
  quickChips = false,
  initialCategoryId = null,
  onCategoryNavigate,
  selectedCategoryId,
  onSelectedCategoryChange,
  hideCategoryBar = false,
  subCategoriesSlot,
}: Props) => {
  const navMode = !!onCategoryNavigate;
  const isControlled = selectedCategoryId !== undefined;
  const [internalSelected, setInternalSelected] = useState<number | null>(
    initialCategoryId,
  );
  const selectedCategory = isControlled ? selectedCategoryId! : internalSelected;
  const setSelectedCategory = (id: number | null) => {
    if (isControlled) onSelectedCategoryChange?.(id);
    else setInternalSelected(id);
  };
  const [sort, setSort] = useState<SortKey>("default");
  const [viewMode, setViewMode] = useState<ViewMode>("grid");
  const [filters, setFilters] = useState<FiltersValue>({
    min: null,
    max: null,
    inStockOnly: false,
    brand: null,
  });

  const queryCategoryId = selectedCategory ?? 0;
  const {
    data,
    isLoading: productsLoading,
    isFetchingNextPage,
    hasNextPage,
    fetchNextPage,
    retryFromStart,
    isError,
  } = useInfiniteProducts({
    slug,
    ctx,
    categoryId: queryCategoryId,
    cacheVersion: "home-v1",
  });

  const loadedProducts = useMemo(() => {
    const flat: Product[] = [];
    data?.pages.forEach((p) => flat.push(...(p.products ?? [])));
    return applyOverrides(flat, overrides);
  }, [data, overrides]);

  const priceBounds = useMemo(() => {
    if (loadedProducts.length === 0) return { min: 0, max: 1000 };
    const finals = loadedProducts.map((p) => getDiscountedPrice(p).final);
    return {
      min: Math.floor(Math.min(...finals)),
      max: Math.ceil(Math.max(...finals)),
    };
  }, [loadedProducts]);

  const visibleProducts = useMemo(() => {
    let list = loadedProducts;
    if (filters.inStockOnly) list = list.filter((p) => (p.stock ?? 0) > 0);
    if (filters.min !== null || filters.max !== null) {
      const lo = filters.min ?? -Infinity;
      const hi = filters.max ?? Infinity;
      list = list.filter((p) => {
        const f = getDiscountedPrice(p).final;
        return f >= lo && f <= hi;
      });
    }
    if (sort !== "default") {
      list = [...list].sort((a, b) => {
        const fa = getDiscountedPrice(a).final;
        const fb = getDiscountedPrice(b).final;
        if (sort === "price-asc") return fa - fb;
        if (sort === "price-desc") return fb - fa;
        const ratingDiff = (b.avg_rating ?? 0) - (a.avg_rating ?? 0);
        if (ratingDiff !== 0) return ratingDiff;
        return (b.rating_count ?? 0) - (a.rating_count ?? 0);
      });
    }
    return list;
  }, [loadedProducts, filters, sort]);

  const activeFiltersCount =
    (filters.min !== null ? 1 : 0) +
    (filters.max !== null ? 1 : 0) +
    (filters.inStockOnly ? 1 : 0);

  return (
    <section className="pt-0 pb-3 md:pb-4 px-0 md:px-1" dir="rtl">
      {hideCategoryBar ? null : quickChips ? (
        <div className="pb-2">
          <QuickCategoryChips
            categories={categories}
            selected={selectedCategory}
            onSelect={(id) => {
              setSelectedCategory(id);
              setFilters({ min: null, max: null, inStockOnly: false, brand: null });
            }}
          />
        </div>
      ) : (
        <div className="sticky top-[56px] md:top-[64px] z-20 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/80 border-b border-border/60 shadow-soft">
          <CategoryPills
            variant="inline-only"
            categories={categories}
            selected={navMode ? null : selectedCategory}
            onSelect={(id) => {
              if (navMode && id != null) {
                onCategoryNavigate!(id);
                return;
              }
              setSelectedCategory(id);
              setFilters({ min: null, max: null, inStockOnly: false, brand: null });
            }}
          />
        </div>
      )}

      {subCategoriesSlot ? <div className="px-1 md:px-0">{subCategoriesSlot}</div> : null}

      <div className="mt-1">
        <CategoryToolbar
          total={visibleProducts.length}
          sort={sort}
          onSortChange={setSort}
          filters={filters}
          onFiltersChange={setFilters}
          priceBounds={priceBounds}
          activeFiltersCount={activeFiltersCount}
          viewMode={viewMode}
          onViewModeChange={setViewMode}
        />
      </div>

      {viewMode === "grid" ? (
        <ProductGrid
          products={visibleProducts}
          loading={productsLoading}
          fetchingMore={isFetchingNextPage}
          hideHeader
          emptyState={
            selectedCategory ? (
              <EmptyState
                icon={PackageSearch}
                title={isError ? "تعذّر تحميل المنتجات" : "لا توجد منتجات في هذا التصنيف الفرعي"}
                description={
                  isError
                    ? "حدث خطأ أثناء جلب المنتجات. حاول مرة أخرى."
                    : "ربما لم يتم إضافة منتجات بعد. حاول مجدداً أو تصفح كل منتجات الصنف."
                }
                action={{
                  label: "إعادة المحاولة",
                  onClick: () => retryFromStart(),
                }}
                secondaryAction={{
                  label: "عرض كل المنتجات",
                  onClick: () => {
                    setSelectedCategory(null);
                    setFilters({ min: null, max: null, inStockOnly: false, brand: null });
                  },
                }}
              />
            ) : (
              <EmptyState
                icon={PackageSearch}
                title="لا توجد منتجات في هذا القسم"
                description="لا توجد منتجات متاحة لهذا الصنف حاليًا."
                action={{
                  label: "إعادة المحاولة",
                  onClick: () => retryFromStart(),
                }}
              />
            )
          }
        />
      ) : (
        <ProductList
          products={visibleProducts}
          loading={productsLoading}
          isError={isError}
          hasSubFilter={!!selectedCategory}
          onRetry={() => retryFromStart()}
          onClearSub={() => {
            setSelectedCategory(null);
            setFilters({ min: null, max: null, inStockOnly: false, brand: null });
          }}
        />
      )}

      {!productsLoading && visibleProducts.length > 0 && hasNextPage && (
        <div className="flex justify-center pt-6">
          <Button
            variant="outline"
            size="sm"
            onClick={() => fetchNextPage()}
            disabled={isFetchingNextPage}
            className="text-xs font-bold"
          >
            {isFetchingNextPage ? "جارٍ التحميل…" : "تحميل المزيد"}
          </Button>
        </div>
      )}
    </section>
  );
};

/* ---------------- List view: horizontal cards ---------------- */

const ProductList = ({
  products,
  loading,
  isError,
  hasSubFilter,
  onRetry,
  onClearSub,
}: {
  products: Product[];
  loading?: boolean;
  isError?: boolean;
  hasSubFilter?: boolean;
  onRetry?: () => void;
  onClearSub?: () => void;
}) => {
  if (loading) {
    return (
      <div className="grid gap-3">
        {Array.from({ length: 6 }).map((_, i) => (
          <div
            key={i}
            className="h-24 rounded-2xl bg-muted/50 animate-pulse border border-border/60"
          />
        ))}
      </div>
    );
  }

  if (products.length === 0) {
    return (
      <EmptyState
        icon={PackageSearch}
        title={isError ? "تعذّر تحميل المنتجات" : hasSubFilter ? "لا توجد منتجات في هذا التصنيف الفرعي" : "لا توجد منتجات في هذا القسم"}
        description={
          isError
            ? "حدث خطأ أثناء جلب المنتجات. حاول مرة أخرى."
            : hasSubFilter
            ? "ربما لم يتم إضافة منتجات بعد. حاول مجدداً أو تصفح كل منتجات الصنف."
            : "لم يتم إضافة أي منتجات لهذا التصنيف بعد."
        }
        action={onRetry ? { label: "إعادة المحاولة", onClick: onRetry } : undefined}
        secondaryAction={
          hasSubFilter && onClearSub
            ? { label: "عرض كل المنتجات", onClick: onClearSub }
            : undefined
        }
      />
    );
  }

  return (
    <div className="grid gap-3">
      {products.map((p) => (
        <ProductListRow key={p.id} product={p} />
      ))}
    </div>
  );
};

const ProductListRow = ({ product }: { product: Product }) => {
  const { final, hasDiscount, pct } = getDiscountedPrice(product);
  const { items, addItem, increment, decrement } = useCart();
  const inCart = items.find((i) => i.id === product.id);
  const unit = product.unit_type?.trim() || "قطعة";

  return (
    <article className="flex items-center gap-3 bg-card rounded-2xl border border-border/60 shadow-soft p-2.5 hover:shadow-card transition-smooth">
      <div className="h-20 w-20 shrink-0 rounded-xl bg-white overflow-hidden flex items-center justify-center p-1.5 border border-border/60">
        {product.image_full_url ? (
          <img
            src={product.image_full_url}
            alt={product.name}
            loading="lazy"
            className="max-h-full max-w-full object-contain"
          />
        ) : (
          <div className="h-full w-full bg-muted rounded-lg" />
        )}
      </div>

      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2 mb-0.5">
          {hasDiscount && (
            <span className="bg-discount text-discount-foreground text-[10px] font-bold px-1.5 py-0.5 rounded-full">
              خصم {pct}%
            </span>
          )}
          {product.avg_rating > 0 && (
            <span className="inline-flex items-center gap-1 text-[11px]">
              <Star className="h-3 w-3 fill-accent text-accent" />
              <span className="font-bold">{product.avg_rating.toFixed(1)}</span>
            </span>
          )}
          <span className="text-[10px] font-bold text-muted-foreground border border-border rounded-full px-2 py-0.5">
            {unit}
          </span>
        </div>
        <h3 className="font-bold text-sm text-foreground line-clamp-1">
          {product.name}
        </h3>
        <div className="flex items-baseline gap-2 mt-1">
          <span className="text-base font-extrabold text-primary">
            {formatPrice(final)}
          </span>
          {hasDiscount && (
            <span className="text-[11px] text-muted-foreground line-through">
              {formatPrice(product.price)}
            </span>
          )}
        </div>
      </div>

      <div className="shrink-0">
        {inCart ? (
          <div className="flex items-center gap-1.5">
            <button
              onClick={() => decrement(product.id)}
              aria-label="تقليل"
              className="h-7 w-7 rounded-full bg-secondary text-foreground inline-flex items-center justify-center shadow-soft hover:bg-muted transition-smooth"
            >
              <Minus className="h-3.5 w-3.5" />
            </button>
            <span className="text-xs font-extrabold whitespace-nowrap">
              {inCart.quantity} {unit}
            </span>
            <button
              onClick={() => increment(product.id)}
              aria-label="زيادة"
              className="h-7 w-7 rounded-full bg-primary text-primary-foreground inline-flex items-center justify-center shadow-soft hover:bg-primary-glow transition-smooth"
            >
              <Plus className="h-3.5 w-3.5" />
            </button>
          </div>
        ) : (
          <button
            onClick={() => addItem(product)}
            aria-label="أضف للسلة"
            className="h-9 w-9 rounded-full bg-primary text-primary-foreground inline-flex items-center justify-center shadow-soft hover:bg-primary-glow hover:shadow-glow transition-smooth"
          >
            <Plus className="h-4 w-4" />
          </button>
        )}
      </div>
    </article>
  );
};
