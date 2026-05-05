import { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { ArrowDownAZ, LayoutGrid, List, Search, SlidersHorizontal, X } from "lucide-react";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { SortKey } from "@/hooks/useCategoriesUrlState";
import { cn } from "@/lib/utils";
import { FiltersSheet, FiltersValue } from "./FiltersSheet";
import type { Brand } from "@/lib/shoplanserApi";
import { formatPrice } from "@/lib/api";

export type ViewMode = "grid" | "list";

interface CategoryToolbarProps {
  total: number;
  sort: SortKey;
  onSortChange: (s: SortKey) => void;
  filters: FiltersValue;
  onFiltersChange: (v: FiltersValue) => void;
  /** Bounds available in the current data set, used to seed the slider. */
  priceBounds: { min: number; max: number };
  /** Number of currently active filters — drives the badge on the button. */
  activeFiltersCount: number;
  /** When provided, renders a grid/list view-mode toggle next to filters. */
  viewMode?: ViewMode;
  onViewModeChange?: (m: ViewMode) => void;
  /** Optional search controls — when both provided a search input renders. */
  search?: string;
  onSearchChange?: (q: string) => void;
  /** Brand list for the FiltersSheet (optional). */
  brands?: Brand[];
  brandsLoading?: boolean;
}

/**
 * Sticky-ish toolbar above the Categories product grid: shows result count
 * on the right (in RTL), sort dropdown + filters button on the other side.
 */
export const CategoryToolbar = ({
  total,
  sort,
  onSortChange,
  filters,
  onFiltersChange,
  priceBounds,
  activeFiltersCount,
  viewMode,
  onViewModeChange,
  search,
  onSearchChange,
  brands,
  brandsLoading,
}: CategoryToolbarProps) => {
  const [filtersOpen, setFiltersOpen] = useState(false);
  const { t } = useTranslation();
  const showViewToggle = !!viewMode && !!onViewModeChange;
  const showSearch = typeof search === "string" && !!onSearchChange;

  // Local controlled value with debounced commit so typing doesn't refetch on every keystroke.
  const [localSearch, setLocalSearch] = useState(search ?? "");
  useEffect(() => {
    setLocalSearch(search ?? "");
  }, [search]);
  useEffect(() => {
    if (!showSearch) return;
    const trimmed = localSearch;
    if (trimmed === (search ?? "")) return;
    const id = window.setTimeout(() => onSearchChange?.(trimmed), 300);
    return () => window.clearTimeout(id);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [localSearch]);

  const SORT_OPTIONS: { value: SortKey; label: string }[] = [
    { value: "default", label: t("toolbar.sort.default") },
    { value: "price-asc", label: t("toolbar.sort.priceAsc") },
    { value: "price-desc", label: t("toolbar.sort.priceDesc") },
    { value: "popular", label: t("toolbar.sort.popular") },
  ];

  return (
    <>
      {showSearch && (
        <div className="relative mb-3">
          <Search className="absolute top-1/2 -translate-y-1/2 start-3 h-4 w-4 text-muted-foreground pointer-events-none" />
          <Input
            type="search"
            value={localSearch}
            onChange={(e) => setLocalSearch(e.target.value)}
            placeholder={t("categories.search.placeholder")}
            className="ps-10 pe-10 h-10 text-sm"
            aria-label={t("categories.search.placeholder")}
          />
          {localSearch && (
            <button
              type="button"
              onClick={() => {
                setLocalSearch("");
                onSearchChange?.("");
              }}
              aria-label={t("categories.search.clear")}
              className="absolute top-1/2 -translate-y-1/2 end-2 h-7 w-7 inline-flex items-center justify-center rounded-full text-muted-foreground hover:text-foreground hover:bg-muted transition-smooth"
            >
              <X className="h-4 w-4" />
            </button>
          )}
        </div>
      )}

      <div className="flex items-center justify-start gap-1.5 sm:gap-2 mb-3 md:mb-5">
        <div className="flex items-center gap-1.5 sm:gap-2 flex-wrap">
          {showViewToggle && (
            <div
              className="inline-flex items-center rounded-md border border-border bg-card overflow-hidden h-9"
              role="group"
              aria-label={t("toolbar.viewModeLabel")}
            >
              <button
                type="button"
                onClick={() => onViewModeChange!("grid")}
                aria-label={t("toolbar.viewGrid")}
                aria-pressed={viewMode === "grid"}
                className={cn(
                  "h-9 w-9 inline-flex items-center justify-center transition-smooth",
                  viewMode === "grid"
                    ? "bg-primary text-primary-foreground"
                    : "text-muted-foreground hover:text-foreground",
                )}
              >
                <LayoutGrid className="h-4 w-4" />
              </button>
              <button
                type="button"
                onClick={() => onViewModeChange!("list")}
                aria-label={t("toolbar.viewList")}
                aria-pressed={viewMode === "list"}
                className={cn(
                  "h-9 w-9 inline-flex items-center justify-center transition-smooth border-s border-border",
                  viewMode === "list"
                    ? "bg-primary text-primary-foreground"
                    : "text-muted-foreground hover:text-foreground",
                )}
              >
                <List className="h-4 w-4" />
              </button>
            </div>
          )}

          <Select value={sort} onValueChange={(v) => onSortChange(v as SortKey)}>
            <SelectTrigger
              className="h-9 text-xs md:text-sm font-bold gap-2 w-auto min-w-[130px] sm:min-w-[140px]"
              aria-label={t("toolbar.sortLabel")}
            >
              <ArrowDownAZ className="h-4 w-4" />
              <SelectValue />
            </SelectTrigger>
            <SelectContent align="end">
              {SORT_OPTIONS.map((o) => (
                <SelectItem key={o.value} value={o.value} className="text-sm">
                  {o.label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>

          <Button
            variant={activeFiltersCount > 0 ? "default" : "outline"}
            size="sm"
            className={cn(
              "h-9 text-xs md:text-sm font-bold gap-2 relative transition-smooth",
              activeFiltersCount > 0 &&
                "bg-primary text-primary-foreground hover:bg-primary/90 ring-2 ring-primary/30",
            )}
            onClick={() => setFiltersOpen(true)}
          >
            <SlidersHorizontal className="h-4 w-4" />
            {t("toolbar.filters")}
            {activeFiltersCount > 0 && (
              <span className="h-5 min-w-5 px-1.5 rounded-full bg-primary-foreground text-primary text-[10px] font-extrabold inline-flex items-center justify-center shadow-soft">
                {activeFiltersCount}
              </span>
            )}
          </Button>
        </div>
      </div>

      {activeFiltersCount > 0 && (
        <ActiveFilterChips
          filters={filters}
          brands={brands}
          onChange={onFiltersChange}
        />
      )}

      <FiltersSheet
        open={filtersOpen}
        onOpenChange={setFiltersOpen}
        value={filters}
        onChange={onFiltersChange}
        priceBounds={priceBounds}
        brands={brands}
        brandsLoading={brandsLoading}
      />
    </>
  );
};

interface ActiveFilterChipsProps {
  filters: FiltersValue;
  
  brands?: Brand[];
  onChange: (v: FiltersValue) => void;
}

/**
 * Compact summary of currently-active filters rendered as removable chips,
 * with a "clear all" action at the end. Mirrors the activeFiltersCount that
 * drives the badge on the Filters button so the two stay consistent.
 */
const ActiveFilterChips = ({
  filters,
  brands,
  onChange,
}: ActiveFilterChipsProps) => {
  const { t } = useTranslation();

  const chips: { key: string; label: string; clear: () => void }[] = [];

  // Price chip — covers any combination of min/max bounds.
  if (filters.min !== null || filters.max !== null) {
    let label: string;
    if (filters.min !== null && filters.max !== null) {
      label = t("toolbar.chip.price", {
        min: formatPrice(filters.min),
        max: formatPrice(filters.max),
      });
    } else if (filters.min !== null) {
      label = t("toolbar.chip.priceMin", { min: formatPrice(filters.min) });
    } else {
      label = t("toolbar.chip.priceMax", { max: formatPrice(filters.max!) });
    }
    chips.push({
      key: "price",
      label,
      clear: () => onChange({ ...filters, min: null, max: null }),
    });
  }

  if (filters.inStockOnly) {
    chips.push({
      key: "stock",
      label: t("toolbar.chip.inStock"),
      clear: () => onChange({ ...filters, inStockOnly: false }),
    });
  }

  if (filters.brand !== null) {
    const brand = brands?.find((b) => b.id === filters.brand);
    chips.push({
      key: "brand",
      label: t("toolbar.chip.brand", {
        name: brand?.name ?? `#${filters.brand}`,
      }),
      clear: () => onChange({ ...filters, brand: null }),
    });
  }

  if (chips.length === 0) return null;

  return (
    <div
      className="flex items-center flex-wrap gap-1.5 sm:gap-2 mb-3 md:mb-5"
      role="group"
      aria-label={t("toolbar.activeFilters")}
    >
      {chips.map((c) => (
        <span
          key={c.key}
          className="inline-flex items-center gap-1 h-7 ps-3 pe-1 rounded-full bg-secondary text-secondary-foreground text-[11px] sm:text-xs font-bold"
        >
          {c.label}
          <button
            type="button"
            onClick={c.clear}
            aria-label={t("toolbar.removeFilter")}
            className="h-5 w-5 inline-flex items-center justify-center rounded-full hover:bg-foreground/10 transition-smooth"
          >
            <X className="h-3 w-3" />
          </button>
        </span>
      ))}
      <button
        type="button"
        onClick={() =>
          onChange({ min: null, max: null, inStockOnly: false, brand: null })
        }
        className="inline-flex items-center gap-1 h-7 px-3 rounded-full border border-destructive/30 text-destructive text-[11px] sm:text-xs font-bold hover:bg-destructive/10 transition-smooth"
      >
        <X className="h-3 w-3" />
        {t("toolbar.clearAll")}
      </button>
    </div>
  );
};
