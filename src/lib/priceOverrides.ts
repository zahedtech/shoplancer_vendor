// Per-store price overrides. Vendors edit prices from their dashboard and the
// storefront reads them live. Stored in localStorage until Vendor API is ready.
//
// Storage keys:
//   `price_overrides_{slug}` -> Record<productId, newPrice>   (current effective overrides)
//   `price_history_{slug}`   -> PriceHistoryEntry[]           (audit log of every change)
//
// Reactivity: dispatches a CustomEvent on write so any consumer in the same
// tab re-renders instantly. Cross-tab sync happens via the native `storage` event.

const keyFor = (slug: string) => `price_overrides_${slug}`;
const historyKeyFor = (slug: string) => `price_history_${slug}`;
const eventName = (slug: string) => `price-overrides-changed:${slug}`;

const MAX_HISTORY = 500;

export type PriceOverrides = Record<number, number>;

export interface PriceHistoryEntry {
  id: string;
  productId: number;
  productName: string;
  /** The previous effective price (before this change). */
  oldPrice: number;
  /** The new effective price. For "reset" actions this equals the original API price. */
  newPrice: number;
  /** "set" = vendor set a custom price. "reset" = vendor cleared the override. */
  action: "set" | "reset";
  /** Display name of who made the change. Mock for now ("التاجر"). */
  actor: string;
  /** ISO timestamp. */
  timestamp: string;
}

export function getOverrides(slug: string): PriceOverrides {
  if (typeof window === "undefined") return {};
  try {
    return JSON.parse(window.localStorage.getItem(keyFor(slug)) || "{}");
  } catch {
    return {};
  }
}

export function getOverride(slug: string, productId: number): number | undefined {
  return getOverrides(slug)[productId];
}

function persist(slug: string, data: PriceOverrides) {
  window.localStorage.setItem(keyFor(slug), JSON.stringify(data));
  window.dispatchEvent(new CustomEvent(eventName(slug)));
}

// ---------- History helpers ----------

export function getHistory(slug: string): PriceHistoryEntry[] {
  if (typeof window === "undefined") return [];
  try {
    const raw = window.localStorage.getItem(historyKeyFor(slug));
    return raw ? (JSON.parse(raw) as PriceHistoryEntry[]) : [];
  } catch {
    return [];
  }
}

export function getHistoryFor(slug: string, productId: number): PriceHistoryEntry[] {
  return getHistory(slug).filter((h) => h.productId === productId);
}

function appendHistory(slug: string, entry: PriceHistoryEntry) {
  const all = getHistory(slug);
  all.unshift(entry); // newest first
  if (all.length > MAX_HISTORY) all.length = MAX_HISTORY;
  window.localStorage.setItem(historyKeyFor(slug), JSON.stringify(all));
}

function makeEntry(input: Omit<PriceHistoryEntry, "id" | "timestamp">): PriceHistoryEntry {
  return {
    ...input,
    id: `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
    timestamp: new Date().toISOString(),
  };
}

// ---------- Mutations ----------

export interface SetOverrideOptions {
  /** Original API price — used as the "old" value if there's no current override. */
  originalPrice: number;
  productName: string;
  actor?: string;
}

export function setOverride(
  slug: string,
  productId: number,
  price: number,
  opts: SetOverrideOptions,
) {
  const current = getOverrides(slug);
  const oldEffective = current[productId] ?? opts.originalPrice;
  if (oldEffective === price) return; // no-op, don't pollute history

  const next = { ...current, [productId]: price };
  persist(slug, next);
  appendHistory(
    slug,
    makeEntry({
      productId,
      productName: opts.productName,
      oldPrice: oldEffective,
      newPrice: price,
      action: "set",
      actor: opts.actor ?? "التاجر",
    }),
  );
}

export interface RemoveOverrideOptions {
  originalPrice: number;
  productName: string;
  actor?: string;
}

export function removeOverride(
  slug: string,
  productId: number,
  opts: RemoveOverrideOptions,
) {
  const current = getOverrides(slug);
  if (!(productId in current)) return;
  const oldEffective = current[productId];
  const next = { ...current };
  delete next[productId];
  persist(slug, next);
  appendHistory(
    slug,
    makeEntry({
      productId,
      productName: opts.productName,
      oldPrice: oldEffective,
      newPrice: opts.originalPrice,
      action: "reset",
      actor: opts.actor ?? "التاجر",
    }),
  );
}

export function clearOverrides(slug: string) {
  persist(slug, {});
}

export function clearHistory(slug: string) {
  if (typeof window === "undefined") return;
  window.localStorage.removeItem(historyKeyFor(slug));
  window.dispatchEvent(new CustomEvent(eventName(slug)));
}

/** Subscribe to changes for a given store (same-tab + cross-tab). */
export function subscribeOverrides(slug: string, cb: () => void): () => void {
  if (typeof window === "undefined") return () => {};
  const onCustom = () => cb();
  const onStorage = (e: StorageEvent) => {
    if (e.key === keyFor(slug) || e.key === historyKeyFor(slug)) cb();
  };
  window.addEventListener(eventName(slug), onCustom);
  window.addEventListener("storage", onStorage);
  return () => {
    window.removeEventListener(eventName(slug), onCustom);
    window.removeEventListener("storage", onStorage);
  };
}
