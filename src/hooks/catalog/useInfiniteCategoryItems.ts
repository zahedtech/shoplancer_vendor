import { useCallback } from "react";
import { useInfiniteQuery, keepPreviousData, useQueryClient } from "@tanstack/react-query";
import { useTranslation } from "react-i18next";
import {
  fetchBrandItems,
  searchItems,
} from "@/lib/shoplanserApi";
import { fetchProducts, type ProductsResponse, type StoreContextData } from "@/lib/api";

const PAGE_SIZE = 20;

interface Options {
  ctx: StoreContextData | null | undefined;
  /** 0 means "all categories" — falls back to the store-scoped feed. */
  categoryId: number;
  /** Optional debounced search term (≥2 chars triggers backend search). */
  search?: string;
  /** Optional brand filter (uses /brand/items/{id} when no search). */
  brandId?: number | null;
  cacheVersion?: string;
}

/**
 * Unified infinite items feed for the Categories page. Picks the right
 * backend endpoint based on whether the user is searching, filtering by
 * brand, or browsing a category:
 *
 *   - search ≥ 2 chars  → /items/search (with optional category_id)
 *   - brandId set       → /brand/items/{id}
 *   - categoryId > 0    → /categories/items/{id}
 *   - otherwise         → /items/latest (store-scoped)
 */
export function useInfiniteCategoryItems({
  ctx,
  categoryId,
  search,
  brandId,
  cacheVersion = "v1",
}: Options) {
  const { i18n } = useTranslation();
  const trimmed = (search ?? "").trim();
  const useSearch = trimmed.length >= 2;
  const useBrand = !useSearch && !!brandId;

  // When there's no search & no brand filter, use the SAME query key and
  // endpoint as the home page (`useInfiniteProducts` → `/items/latest`) so
  // both pages share the react-query cache and feel instant when navigating.
  const isPlainBrowse = !useSearch && !useBrand;

  const queryKey = isPlainBrowse
    ? ["products-infinite", ctx?.slug ?? null, categoryId, cacheVersion]
    : [
        "catalog",
        "items-infinite",
        ctx?.slug ?? null,
        ctx?.zoneId ?? null,
        ctx?.moduleId ?? null,
        i18n.language,
        categoryId,
        useSearch ? trimmed : null,
        useBrand ? brandId : null,
        cacheVersion,
      ];

  const queryClient = useQueryClient();

  const query = useInfiniteQuery<ProductsResponse>({
    queryKey,
    enabled: !!ctx,
    initialPageParam: 1,
    queryFn: ({ pageParam, signal }) => {
      const offset = pageParam as number;
      if (useSearch) {
        return searchItems(
          {
            name: trimmed,
            storeId: ctx!.storeId,
            categoryId: categoryId > 0 ? categoryId : undefined,
            offset,
            limit: PAGE_SIZE,
            signal,
          },
          ctx!,
        );
      }
      if (useBrand) {
        return fetchBrandItems(
          { brandId: brandId as number, offset, limit: PAGE_SIZE, signal },
          ctx!,
        );
      }
      return fetchProducts(ctx!, { categoryId, offset, limit: PAGE_SIZE });
    },
    getNextPageParam: (lastPage, allPages) => {
      const loaded = allPages.reduce(
        (acc, p) => acc + (p.products?.length ?? 0),
        0,
      );
      const total = lastPage.total_size ?? 0;
      if (loaded >= total) return undefined;
      return allPages.length + 1;
    },
    placeholderData: keepPreviousData,
    staleTime: isPlainBrowse ? 60 * 1000 : 5 * 60 * 1000,
    gcTime: 30 * 60 * 1000,
    retry: 1,
  });

  /**
   * Reset to page 1 and re-fetch — used by retry buttons and after filter
   * changes so we don't re-request all previously loaded pages.
   */
  const retryFromStart = useCallback(async () => {
    await queryClient.resetQueries({ queryKey, exact: true });
  }, [queryClient, queryKey.join("|")]);

  return { ...query, retryFromStart };
}

export const CATEGORY_ITEMS_PAGE_SIZE = PAGE_SIZE;
