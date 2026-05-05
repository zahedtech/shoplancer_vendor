import { useQuery } from "@tanstack/react-query";
import { useTranslation } from "react-i18next";
import { fetchCategoriesTopLevel } from "@/lib/shoplanserApi";
import type { StoreContextData } from "@/lib/api";

/**
 * Top-level categories for the current zone/module/locale. Cache key includes
 * locale so switching language refetches translated names.
 */
export function useCategoriesQuery(ctx: StoreContextData | null | undefined) {
  const { i18n } = useTranslation();
  return useQuery({
    queryKey: [
      "catalog",
      "categories",
      ctx?.zoneId ?? null,
      ctx?.moduleId ?? null,
      i18n.language,
    ],
    queryFn: () => fetchCategoriesTopLevel(ctx ?? undefined),
    enabled: !!ctx,
    staleTime: 5 * 60 * 1000,
    gcTime: 30 * 60 * 1000,
    retry: 1,
  });
}
