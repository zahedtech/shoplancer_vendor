import { useEffect, useState } from "react";
import {
  getOverrides,
  subscribeOverrides,
  type PriceOverrides,
} from "@/lib/priceOverrides";

/**
 * Reactive accessor for the current store's price overrides.
 * Re-renders whenever the vendor saves/clears a price (same tab or another tab).
 */
export function usePriceOverrides(slug: string): PriceOverrides {
  const [overrides, setOverridesState] = useState<PriceOverrides>(() =>
    getOverrides(slug),
  );

  useEffect(() => {
    setOverridesState(getOverrides(slug));
    return subscribeOverrides(slug, () => setOverridesState(getOverrides(slug)));
  }, [slug]);

  return overrides;
}
