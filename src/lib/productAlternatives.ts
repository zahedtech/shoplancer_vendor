/**
 * Lightweight in-memory registry of every Product the app has rendered so far,
 * grouped by `category_id`. We use this to suggest alternatives when a product
 * is out of stock — purely client side, no extra API calls.
 *
 * Components register the products they receive (rails, grids, recommended,
 * latest, deals) via `registerProducts`. Lookups by category return only
 * in-stock items, optionally excluding a given product id.
 */
import type { Product } from "@/lib/api";

const byId = new Map<number, Product>();
const byCategory = new Map<number, Set<number>>();
const subscribers = new Set<() => void>();

export const registerProducts = (products: Product[] | undefined | null) => {
  if (!products?.length) return;
  let changed = false;
  for (const p of products) {
    if (!p || typeof p.id !== "number") continue;
    const prev = byId.get(p.id);
    byId.set(p.id, p);
    if (!prev || prev.category_id !== p.category_id || prev.stock !== p.stock) {
      changed = true;
    }
    const catId = Number(p.category_id ?? 0);
    if (!byCategory.has(catId)) byCategory.set(catId, new Set());
    byCategory.get(catId)!.add(p.id);
  }
  if (changed) subscribers.forEach((cb) => cb());
};

export const findAlternatives = (
  product: Pick<Product, "id" | "category_id">,
  limit = 8,
): Product[] => {
  const catId = Number(product.category_id ?? 0);
  const ids = byCategory.get(catId);
  if (!ids) return [];
  const out: Product[] = [];
  for (const id of ids) {
    if (id === product.id) continue;
    const p = byId.get(id);
    if (!p) continue;
    if ((p.stock ?? 0) <= 0) continue;
    out.push(p);
    if (out.length >= limit) break;
  }
  return out;
};

export const getProductFromRegistry = (id: number): Product | undefined =>
  byId.get(id);

export const subscribeProducts = (cb: () => void) => {
  subscribers.add(cb);
  return () => {
    subscribers.delete(cb);
  };
};
