import type { StoreDetails } from "@/lib/api";

export type StoreKind = "grocery" | "clothes" | "pharmacy" | "food" | "other";

/**
 * Detect the storefront "kind" from the Shoplanser module metadata.
 * We use this to swap hero copy, feature bar, popups, and other UI bits
 * so the storefront feels appropriate for the vertical (e.g. fashion vs grocery).
 */
export function getStoreKind(store?: StoreDetails | null): StoreKind {
  if (!store) return "other";
  const m = store.module;
  const haystack = `${m?.slug ?? ""} ${m?.module_name ?? ""}`.toLowerCase();
  if (/(mlabs|ملابس|cloth|fashion|apparel|wear|boutique)/i.test(haystack)) return "clothes";
  if (/(pharm|صيدل|دواء|medicine)/i.test(haystack)) return "pharmacy";
  if (/(food|مطعم|restaurant|طعام)/i.test(haystack)) return "food";
  if (/(grocer|بقال|سوبر|market)/i.test(haystack)) return "grocery";
  return "other";
}
