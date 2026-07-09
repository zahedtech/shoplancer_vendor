// Per-store storefront settings (vendor-tunable, persisted locally).

const keyFor = (slug: string) => `store_settings_${slug}`;
const eventName = (slug: string) => `store-settings-changed:${slug}`;

export type HeroPattern = "none" | "stripe" | "flowers" | "denim";

export interface AudienceMap {
  men: number[];
  women: number[];
  kids: number[];
}

export interface StoreSettings {
  /** Show "متوفر: N" badge only when stock is at or below this number. 0 disables. */
  lowStockThreshold: number;
  /** Category IDs that should be treated as produce (fruits/veg) — sold by ½ kg steps. */
  produceCategoryIds: number[];
  /** Category IDs that should be treated as attarah (spices/bulk) — sold by weight or by amount. */
  attarahCategoryIds: number[];
  /** Hero background pattern (clothing stores). */
  heroPattern: HeroPattern;
  /** Manual audience-to-category mapping (clothing stores). */
  audienceMap: AudienceMap;
}

export const DEFAULT_SETTINGS: StoreSettings = {
  lowStockThreshold: 20,
  produceCategoryIds: [],
  attarahCategoryIds: [],
  heroPattern: "none",
  audienceMap: { men: [], women: [], kids: [] },
};

export function getStoreSettings(slug: string): StoreSettings {
  if (typeof window === "undefined") return DEFAULT_SETTINGS;
  try {
    const raw = window.localStorage.getItem(keyFor(slug));
    if (!raw) return DEFAULT_SETTINGS;
    const parsed = JSON.parse(raw) as Partial<StoreSettings>;
    const am = (parsed.audienceMap ?? {}) as Partial<AudienceMap>;
    const cleanIds = (xs: unknown) =>
      Array.isArray(xs) ? xs.map(Number).filter(Number.isFinite) : [];
    return {
      ...DEFAULT_SETTINGS,
      ...parsed,
      produceCategoryIds: cleanIds(parsed.produceCategoryIds),
      attarahCategoryIds: cleanIds(parsed.attarahCategoryIds),
      heroPattern: (parsed.heroPattern as HeroPattern) ?? "none",
      audienceMap: {
        men: cleanIds(am.men),
        women: cleanIds(am.women),
        kids: cleanIds(am.kids),
      },
    };
  } catch {
    return DEFAULT_SETTINGS;
  }
}

export function setStoreSettings(slug: string, patch: Partial<StoreSettings>) {
  const next = { ...getStoreSettings(slug), ...patch };
  window.localStorage.setItem(keyFor(slug), JSON.stringify(next));
  window.dispatchEvent(new CustomEvent(eventName(slug)));
}

export function subscribeStoreSettings(
  slug: string,
  cb: () => void,
): () => void {
  if (typeof window === "undefined") return () => {};
  const onCustom = () => cb();
  const onStorage = (e: StorageEvent) => {
    if (e.key === keyFor(slug)) cb();
  };
  window.addEventListener(eventName(slug), onCustom);
  window.addEventListener("storage", onStorage);
  return () => {
    window.removeEventListener(eventName(slug), onCustom);
    window.removeEventListener("storage", onStorage);
  };
}
