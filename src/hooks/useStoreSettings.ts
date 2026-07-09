import { useEffect, useState } from "react";
import {
  getStoreSettings,
  subscribeStoreSettings,
  type StoreSettings,
} from "@/lib/storeSettings";

/**
 * Reactive accessor for per-store settings (low-stock threshold, etc.).
 * Re-renders on any save (same tab via custom event, cross-tab via storage).
 */
export function useStoreSettings(slug: string): StoreSettings {
  const [settings, setSettings] = useState<StoreSettings>(() =>
    getStoreSettings(slug),
  );

  useEffect(() => {
    setSettings(getStoreSettings(slug));
    return subscribeStoreSettings(slug, () =>
      setSettings(getStoreSettings(slug)),
    );
  }, [slug]);

  return settings;
}
