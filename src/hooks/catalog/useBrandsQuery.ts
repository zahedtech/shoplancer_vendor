import { useQuery } from "@tanstack/react-query";
import { useTranslation } from "react-i18next";
import { fetchBrands, type Brand } from "@/lib/shoplanserApi";
import type { StoreContextData } from "@/lib/api";

/** All brands available in the current zone/module. */
export function useBrandsQuery(ctx: StoreContextData | null | undefined) {
  const { i18n } = useTranslation();
  return useQuery<Brand[]>({
    queryKey: [
      "catalog",
      "brands",
      ctx?.zoneId ?? null,
      ctx?.moduleId ?? null,
      i18n.language,
    ],
    queryFn: () => fetchBrands(ctx ?? undefined),
    enabled: !!ctx,
    staleTime: 10 * 60 * 1000,
    gcTime: 30 * 60 * 1000,
    retry: 1,
  });
}
