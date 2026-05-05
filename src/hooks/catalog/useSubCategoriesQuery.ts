import { useQuery } from "@tanstack/react-query";
import { useTranslation } from "react-i18next";
import { fetchCategoryChildren } from "@/lib/shoplanserApi";
import type { StoreContextData } from "@/lib/api";

/** Children of `parentId` — disabled when `parentId` is null. */
export function useSubCategoriesQuery(
  ctx: StoreContextData | null | undefined,
  parentId: number | null,
) {
  const { i18n } = useTranslation();
  return useQuery({
    queryKey: [
      "catalog",
      "sub-categories",
      ctx?.zoneId ?? null,
      ctx?.moduleId ?? null,
      i18n.language,
      parentId,
    ],
    queryFn: () => fetchCategoryChildren(parentId as number, ctx ?? undefined),
    enabled: !!ctx && parentId !== null,
    staleTime: 5 * 60 * 1000,
    gcTime: 30 * 60 * 1000,
    retry: 1,
  });
}
