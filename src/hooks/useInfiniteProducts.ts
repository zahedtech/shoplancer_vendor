import { useCallback } from "react";
import { useInfiniteQuery, useQueryClient } from "@tanstack/react-query";
import { fetchProducts, ProductsResponse, StoreContextData } from "@/lib/api";

const PAGE_SIZE = 20;

interface Options {
  slug: string | undefined;
  ctx: StoreContextData | null;
  categoryId: number;
  /** Included in the queryKey so changes invalidate the paginated cache. */
  cacheVersion?: string;
}

/**
 * Paginated products feed for the Categories page. Wraps Shoplanser's
 * `/items/latest` (which uses 1-based `offset` in pages) into a clean
 * react-query infinite query.
 */
export function useInfiniteProducts({
  slug,
  ctx,
  categoryId,
  cacheVersion = "v1",
}: Options) {
  const queryClient = useQueryClient();
  const queryKey = ["products-infinite", slug, categoryId, cacheVersion];

  const query = useInfiniteQuery<ProductsResponse>({
    queryKey,
    enabled: !!ctx,
    initialPageParam: 1,
    queryFn: ({ pageParam }) =>
      fetchProducts(ctx!, {
        categoryId,
        offset: pageParam as number,
        limit: PAGE_SIZE,
      }),
    getNextPageParam: (lastPage, allPages) => {
      const loaded = allPages.reduce(
        (acc, p) => acc + (p.products?.length ?? 0),
        0,
      );
      const total = lastPage.total_size ?? 0;
      if (loaded >= total) return undefined;
      return allPages.length + 1;
    },
    staleTime: 60 * 1000,
  });

  /**
   * Wipe loaded pages and re-fetch starting from page 1. Use this for
   * "Retry" actions and after filter changes so users always start clean
   * instead of refetching every previously loaded page.
   */
  const retryFromStart = useCallback(async () => {
    await queryClient.resetQueries({ queryKey, exact: true });
  }, [queryClient, queryKey.join("|")]);

  return { ...query, retryFromStart };
}

export const PRODUCTS_PAGE_SIZE = PAGE_SIZE;
