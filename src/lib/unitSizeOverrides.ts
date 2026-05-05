// Per-store, per-product overrides. Stored in localStorage:
//   key: `unit_size_overrides_{slug}` (legacy key kept for back-compat)
// Schema (new):
//   Record<productId, { size?: string; referenceGramPrice?: number; minGrams?: number }>
// Legacy entries (string instead of object) are auto-migrated on read.

const keyFor = (slug: string) => `unit_size_overrides_${slug}`;
const eventName = (slug: string) => `unit-size-overrides-changed:${slug}`;

export interface ProductOverride {
  /** Vendor-defined package size label, e.g. "500 جم", "1 لتر". Used for piece-style products. */
  size?: string;
  /** For attarah: how many grams the API `price` is for. Defaults to 100. */
  referenceGramPrice?: number;
  /** For attarah: minimum grams a customer can order. Defaults to 50. */
  minGrams?: number;
}

export type ProductOverrides = Record<number, ProductOverride>;
/** @deprecated use ProductOverrides — kept for callers that only need size labels. */
export type UnitSizeOverrides = Record<number, string>;

/** Common package-size presets for groceries. Vendors can also type their own. */
export const UNIT_SIZE_PRESETS: string[] = [
  "100 جم",
  "250 جم",
  "500 جم",
  "750 جم",
  "1 كجم",
  "2 كجم",
  "5 كجم",
  "250 مل",
  "500 مل",
  "1 لتر",
  "1.5 لتر",
  "2 لتر",
  "عبوة",
  "علبة",
  "كرتونة",
];

/** Reference-weight presets for attarah pricing (price per N grams). */
export const ATTARAH_REFERENCE_PRESETS = [10, 50, 100, 250, 500, 1000];
/** Min-weight presets for attarah orders. */
export const ATTARAH_MIN_PRESETS = [10, 25, 50, 100, 250];

export const DEFAULT_ATTARAH_REFERENCE = 100;
export const DEFAULT_ATTARAH_MIN_GRAMS = 50;

function readRaw(slug: string): Record<string, unknown> {
  if (typeof window === "undefined") return {};
  try {
    return JSON.parse(window.localStorage.getItem(keyFor(slug)) || "{}");
  } catch {
    return {};
  }
}

/** Read all per-product overrides, migrating legacy string entries. */
export function getProductOverrides(slug: string): ProductOverrides {
  const raw = readRaw(slug);
  const out: ProductOverrides = {};
  for (const [k, v] of Object.entries(raw)) {
    const id = Number(k);
    if (!Number.isFinite(id)) continue;
    if (typeof v === "string") {
      if (v.trim()) out[id] = { size: v.trim() };
    } else if (v && typeof v === "object") {
      const o = v as Partial<ProductOverride>;
      const entry: ProductOverride = {};
      if (typeof o.size === "string" && o.size.trim()) entry.size = o.size.trim();
      if (Number.isFinite(o.referenceGramPrice) && (o.referenceGramPrice as number) > 0)
        entry.referenceGramPrice = o.referenceGramPrice;
      if (Number.isFinite(o.minGrams) && (o.minGrams as number) > 0)
        entry.minGrams = o.minGrams;
      if (Object.keys(entry).length > 0) out[id] = entry;
    }
  }
  return out;
}

export function getProductOverride(slug: string, productId: number): ProductOverride | undefined {
  return getProductOverrides(slug)[productId];
}

/** Legacy helper — returns just the size label map (used by old call sites). */
export function getUnitSizes(slug: string): UnitSizeOverrides {
  const all = getProductOverrides(slug);
  const out: UnitSizeOverrides = {};
  for (const [id, o] of Object.entries(all)) {
    if (o.size) out[Number(id)] = o.size;
  }
  return out;
}

export function getUnitSize(slug: string, productId: number): string | undefined {
  return getProductOverride(slug, productId)?.size;
}

function persist(slug: string, data: ProductOverrides) {
  window.localStorage.setItem(keyFor(slug), JSON.stringify(data));
  window.dispatchEvent(new CustomEvent(eventName(slug)));
}

/** Patch a single product's override entry. Removes empty entries. */
export function setProductOverride(
  slug: string,
  productId: number,
  patch: Partial<ProductOverride>,
) {
  const current = getProductOverrides(slug);
  const merged: ProductOverride = { ...(current[productId] ?? {}), ...patch };
  // Normalize: drop empty/zero fields
  if (!merged.size || !merged.size.trim()) delete merged.size;
  if (!merged.referenceGramPrice || merged.referenceGramPrice <= 0)
    delete merged.referenceGramPrice;
  if (!merged.minGrams || merged.minGrams <= 0) delete merged.minGrams;

  const next = { ...current };
  if (Object.keys(merged).length === 0) {
    delete next[productId];
  } else {
    next[productId] = merged;
  }
  persist(slug, next);
}

export function setUnitSize(slug: string, productId: number, size: string) {
  setProductOverride(slug, productId, { size });
}

export function removeUnitSize(slug: string, productId: number) {
  setProductOverride(slug, productId, { size: undefined });
}

export function removeProductOverride(slug: string, productId: number) {
  const current = getProductOverrides(slug);
  if (!(productId in current)) return;
  const next = { ...current };
  delete next[productId];
  persist(slug, next);
}

export function clearUnitSizes(slug: string) {
  persist(slug, {});
}

export function subscribeUnitSizes(slug: string, cb: () => void): () => void {
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
