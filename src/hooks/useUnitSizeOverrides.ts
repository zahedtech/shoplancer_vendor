import { useEffect, useState } from "react";
import {
  getProductOverrides,
  getUnitSizes,
  subscribeUnitSizes,
  type ProductOverrides,
  type UnitSizeOverrides,
} from "@/lib/unitSizeOverrides";

/**
 * Reactive accessor for per-store unit-size labels (legacy string map).
 * Kept for callers that only need size strings (e.g. ProductCard size chip).
 */
export function useUnitSizeOverrides(slug: string): UnitSizeOverrides {
  const [sizes, setSizes] = useState<UnitSizeOverrides>(() => getUnitSizes(slug));

  useEffect(() => {
    setSizes(getUnitSizes(slug));
    return subscribeUnitSizes(slug, () => setSizes(getUnitSizes(slug)));
  }, [slug]);

  return sizes;
}

/** Reactive accessor for the full per-product override map. */
export function useProductOverrides(slug: string): ProductOverrides {
  const [overrides, setOverrides] = useState<ProductOverrides>(() =>
    getProductOverrides(slug),
  );

  useEffect(() => {
    setOverrides(getProductOverrides(slug));
    return subscribeUnitSizes(slug, () => setOverrides(getProductOverrides(slug)));
  }, [slug]);

  return overrides;
}
