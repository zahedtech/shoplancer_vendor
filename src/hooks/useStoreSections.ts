import { useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import {
  fetchDiscounted,
  fetchPopular,
  fetchRecommended,
  Product,
  StoreContextData,
} from "@/lib/api";

/**
 * Loads the three homepage rails (recommended / offers / new) and applies
 * sensible local fallbacks so we still surface something when an endpoint is
 * empty for a particular tenant.
 */
export function useStoreSections(
  slug: string | undefined,
  ctx: StoreContextData | null,
  allProducts: Product[],
) {
  const enabled = !!ctx;

  const recommended = useQuery({
    queryKey: ["section-recommended", slug],
    queryFn: () => fetchRecommended(ctx!),
    enabled,
    staleTime: 5 * 60 * 1000,
  });

  const discounted = useQuery({
    queryKey: ["section-discounted", slug],
    queryFn: () => fetchDiscounted(ctx!),
    enabled,
    staleTime: 5 * 60 * 1000,
  });

  const popular = useQuery({
    queryKey: ["section-popular", slug],
    queryFn: () => fetchPopular(ctx!),
    enabled,
    staleTime: 5 * 60 * 1000,
  });

  // Defensive filter: Shoplanser's discounted/popular endpoints sometimes return
  // products from sibling stores. Drop anything that isn't this store's items.
  const storeId = ctx?.storeId;
  const belongsToStore = (p: Product) =>
    storeId == null || p.store_id == null || Number(p.store_id) === Number(storeId);

  const recommendedProducts = useMemo(() => {
    const fromApi = (recommended.data?.products ?? []).filter(belongsToStore);
    if (fromApi.length > 0) return fromApi;
    // Fallback: locally flagged recommended items.
    return allProducts.filter((p) => p.recommended === 1).slice(0, 12);
  }, [recommended.data, allProducts, storeId]);

  const offersProducts = useMemo(() => {
    const fromApi = (discounted.data?.products ?? []).filter(belongsToStore);
    if (fromApi.length > 0) return fromApi;
    return allProducts.filter((p) => (p.discount ?? 0) > 0).slice(0, 12);
  }, [discounted.data, allProducts, storeId]);

  const newProducts = useMemo(() => {
    const fromApi = (popular.data?.products ?? []).filter(belongsToStore);
    if (fromApi.length > 0) return fromApi;
    // Fallback: latest items from the global feed (already sorted by API).
    return allProducts.slice(0, 12);
  }, [popular.data, allProducts, storeId]);

  return {
    recommended: {
      products: recommendedProducts,
      loading: recommended.isLoading,
    },
    offers: { products: offersProducts, loading: discounted.isLoading },
    latest: { products: newProducts, loading: popular.isLoading },
  };
}
