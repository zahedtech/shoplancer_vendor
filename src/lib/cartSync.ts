import type { CartItem } from "@/context/CartContext";

export const PHONE_KEY = "shoplanser_sync_phone";
const SNAPSHOT_PREFIX = "shoplanser_cart_snapshot_";

export function normalizePhone(phone: string): string {
  return phone.replace(/[\s-]/g, "").trim();
}

export function getStoredPhone(): string | null {
  try {
    const legacy = localStorage.getItem("hashem_sync_phone");
    if (legacy && !localStorage.getItem(PHONE_KEY)) {
      localStorage.setItem(PHONE_KEY, legacy);
      localStorage.removeItem("hashem_sync_phone");
    }
    return localStorage.getItem(PHONE_KEY);
  } catch {
    return null;
  }
}

export function setStoredPhone(phone: string | null) {
  try {
    if (phone) localStorage.setItem(PHONE_KEY, phone);
    else localStorage.removeItem(PHONE_KEY);
  } catch {
    /* ignore */
  }
}

function snapshotKey(phone: string, storeSlug: string): string {
  return `${SNAPSHOT_PREFIX}${normalizePhone(phone)}_${storeSlug}`;
}

function readSnapshot(phone: string, storeSlug: string): CartItem[] | null {
  try {
    const raw = localStorage.getItem(snapshotKey(phone, storeSlug));
    if (!raw) return null;
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? (parsed as CartItem[]) : null;
  } catch {
    return null;
  }
}

function writeSnapshot(phone: string, storeSlug: string, items: CartItem[]) {
  try {
    localStorage.setItem(snapshotKey(phone, storeSlug), JSON.stringify(items));
  } catch {
    /* ignore */
  }
}

/**
 * Remove all cart snapshots for a given phone (across every store) and
 * optionally wipe the active per-store local cart key as well.
 */
export function clearSnapshotsForPhone(phone: string | null) {
  try {
    const normalized = phone ? normalizePhone(phone) : null;
    const toRemove: string[] = [];
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (!key) continue;
      if (!key.startsWith(SNAPSHOT_PREFIX)) continue;
      if (!normalized || key.startsWith(`${SNAPSHOT_PREFIX}${normalized}_`)) {
        toRemove.push(key);
      }
    }
    for (const k of toRemove) localStorage.removeItem(k);
  } catch {
    /* ignore */
  }
}

/** Wipe the active local cart for a specific store slug. */
export function clearLocalCart(storeSlug: string) {
  try {
    localStorage.removeItem(`cart_${storeSlug}_v1`);
  } catch {
    /* ignore */
  }
}

/** Merge two carts by item id. Quantities sum; latest metadata wins. */
function mergeCarts(a: CartItem[], b: CartItem[]): CartItem[] {
  const byId = new Map<number, CartItem>();
  for (const item of a) byId.set(item.id, { ...item });
  for (const item of b) {
    const existing = byId.get(item.id);
    if (existing) {
      const nextQty =
        item.kind === "attarah"
          ? Math.max(existing.quantity, item.quantity)
          : existing.quantity + item.quantity;
      byId.set(item.id, { ...existing, ...item, quantity: nextQty });
    } else {
      byId.set(item.id, { ...item });
    }
  }
  return Array.from(byId.values());
}

/**
 * Pull the per-phone snapshot for this store and merge it with whatever
 * the caller already has locally. Returns the merged cart (or null if
 * nothing on either side).
 */
export async function pullCart(
  phone: string,
  storeSlug: string,
): Promise<CartItem[] | null> {
  const snapshot = readSnapshot(phone, storeSlug);
  return snapshot ?? null;
}

/** Persist the current cart under (phone, storeSlug) snapshot. */
export async function pushCart(
  phone: string,
  storeSlug: string,
  items: CartItem[],
): Promise<void> {
  writeSnapshot(phone, storeSlug, items);
}

/**
 * Convenience helper: merge the local cart with the stored snapshot
 * for this phone+store, persist the result, and return it.
 */
export async function mergeOnLink(
  phone: string,
  storeSlug: string,
  localItems: CartItem[],
): Promise<CartItem[]> {
  const snapshot = readSnapshot(phone, storeSlug) ?? [];
  const merged = mergeCarts(snapshot, localItems);
  writeSnapshot(phone, storeSlug, merged);
  return merged;
}
