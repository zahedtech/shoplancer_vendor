import { useMemo } from "react";
import { Product } from "@/lib/api";
import { useStoreSettings } from "@/hooks/useStoreSettings";
import { useProductOverrides } from "@/hooks/useUnitSizeOverrides";
import {
  DEFAULT_ATTARAH_MIN_GRAMS,
  DEFAULT_ATTARAH_REFERENCE,
  type ProductOverride,
} from "@/lib/unitSizeOverrides";

export type ProductKind = "produce" | "attarah" | "piece";

export interface ProductKindInfo {
  kind: ProductKind;
  override?: ProductOverride;
  /** For attarah: grams that the API `price` covers. Default 100. */
  referenceGramPrice: number;
  /** For attarah: minimum grams a customer can order. Default 50. */
  minGrams: number;
}

/**
 * Resolve how a product should be sold:
 * - produce: ½ kg steps (existing behavior)
 * - attarah: by weight (grams) or by amount (price)
 * - piece: single-unit steps
 *
 * Resolution order:
 *   1. category_id ∈ store.attarahCategoryIds → attarah
 *   2. category_id ∈ store.produceCategoryIds → produce
 *   3. fallback: legacy unit_type heuristic (kg / kilo / gram → produce)
 *   4. otherwise: piece
 */
export function useProductKind(slug: string, product: Product): ProductKindInfo {
  const settings = useStoreSettings(slug);
  const overrides = useProductOverrides(slug);

  return useMemo(() => {
    const override = overrides[product.id];
    const cat = Number(product.category_id);
    const inSet = (ids: number[]) =>
      Number.isFinite(cat) && ids.includes(cat);

    let kind: ProductKind = "piece";
    if (inSet(settings.attarahCategoryIds)) kind = "attarah";
    else if (inSet(settings.produceCategoryIds)) kind = "produce";
    else {
      // Legacy heuristic: weight unit string → treat as produce
      const u = (product.unit_type ?? "").toLowerCase().trim();
      if (
        u &&
        (u.includes("كيلو") ||
          u.includes("كغ") ||
          u.includes("جرام") ||
          u.includes("غرام") ||
          u === "kg" ||
          u === "g" ||
          u.includes("kilo") ||
          u.includes("gram"))
      ) {
        kind = "produce";
      }
    }

    return {
      kind,
      override,
      referenceGramPrice:
        override?.referenceGramPrice ?? DEFAULT_ATTARAH_REFERENCE,
      minGrams: override?.minGrams ?? DEFAULT_ATTARAH_MIN_GRAMS,
    };
  }, [
    product.id,
    product.category_id,
    product.unit_type,
    settings.attarahCategoryIds,
    settings.produceCategoryIds,
    overrides,
  ]);
}
