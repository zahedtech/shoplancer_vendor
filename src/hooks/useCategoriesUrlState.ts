import { useCallback, useMemo } from "react";
import { useSearchParams } from "react-router-dom";

export type SortKey = "default" | "price-asc" | "price-desc" | "popular";

export interface CategoriesUrlState {
  cat: number | null;
  sub: number | null;
  sub2: number | null;
  sort: SortKey;
  min: number | null;
  max: number | null;
  inStockOnly: boolean;
  q: string;
  brand: number | null;
}

const VALID_SORTS: SortKey[] = ["default", "price-asc", "price-desc", "popular"];

const parseNum = (v: string | null): number | null => {
  if (v === null || v === "") return null;
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
};

/**
 * URL-state for the Categories page. Every visible decision lives in the URL
 * so refresh + share + back/forward all restore the same view exactly.
 *
 * - cat / sub: selected category and sub-category ids
 * - sort:      one of `default | price-asc | price-desc | popular`
 * - min / max: optional price bounds
 * - stock=in:  show only in-stock items
 *
 * Defaults are stripped from the URL to keep links clean.
 */
export function useCategoriesUrlState() {
  const [params, setParams] = useSearchParams();

  const state = useMemo<CategoriesUrlState>(() => {
    const sortRaw = params.get("sort") ?? "default";
    const sort = (VALID_SORTS as string[]).includes(sortRaw)
      ? (sortRaw as SortKey)
      : "default";
    return {
      cat: parseNum(params.get("cat")),
      sub: parseNum(params.get("sub")),
      sub2: parseNum(params.get("sub2")),
      sort,
      min: parseNum(params.get("min")),
      max: parseNum(params.get("max")),
      inStockOnly: params.get("stock") === "in",
      q: params.get("q") ?? "",
      brand: parseNum(params.get("brand")),
    };
  }, [params]);

  /**
   * Patch a subset of the URL state. Pass `null` for a key to clear it.
   * `replace` controls whether the change pushes a new history entry; we use
   * `false` for user-driven changes (so back/forward works) and `true` only
   * for internal cleanups.
   */
  const update = useCallback(
    (patch: Partial<CategoriesUrlState>, opts: { replace?: boolean } = {}) => {
      const next = new URLSearchParams(params);
      const setOrDelete = (key: string, value: string | null | undefined) => {
        if (value === null || value === undefined || value === "") {
          next.delete(key);
        } else {
          next.set(key, value);
        }
      };
      if ("cat" in patch) setOrDelete("cat", patch.cat == null ? null : String(patch.cat));
      if ("sub" in patch) setOrDelete("sub", patch.sub == null ? null : String(patch.sub));
      if ("sub2" in patch) setOrDelete("sub2", patch.sub2 == null ? null : String(patch.sub2));
      if ("sort" in patch)
        setOrDelete("sort", patch.sort && patch.sort !== "default" ? patch.sort : null);
      if ("min" in patch) setOrDelete("min", patch.min == null ? null : String(patch.min));
      if ("max" in patch) setOrDelete("max", patch.max == null ? null : String(patch.max));
      if ("inStockOnly" in patch)
        setOrDelete("stock", patch.inStockOnly ? "in" : null);
      if ("q" in patch) setOrDelete("q", patch.q && patch.q.trim() !== "" ? patch.q.trim() : null);
      if ("brand" in patch)
        setOrDelete("brand", patch.brand == null ? null : String(patch.brand));
      setParams(next, { replace: opts.replace ?? false });
    },
    [params, setParams],
  );

  /** Clear category, sub, and all filters at once. Keeps default sort. */
  const reset = useCallback(() => {
    setParams(new URLSearchParams(), { replace: false });
  }, [setParams]);

  /** Clear only the filter fields (keep cat/sub/sort/q). */
  const resetFilters = useCallback(() => {
    update({ min: null, max: null, inStockOnly: false, brand: null });
  }, [update]);

  return { state, update, reset, resetFilters };
}
