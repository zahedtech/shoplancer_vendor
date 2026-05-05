/**
 * Watchlist storage layer — local (per-store, anonymous) + remote (per-user, Cloud).
 * Public surface is small: the WatchlistContext is the consumer.
 */
import { supabase } from "@/integrations/supabase/client";
import type { Product } from "@/lib/api";

export interface WatchlistItem {
  product_id: number;
  store_slug: string;
  snapshot: {
    name: string;
    image: string;
    price: number;
  };
  created_at: string;
}

const localKey = (slug: string) => `watchlist_${slug}_v1`;

export const readLocal = (slug: string): WatchlistItem[] => {
  try {
    const raw = localStorage.getItem(localKey(slug));
    return raw ? (JSON.parse(raw) as WatchlistItem[]) : [];
  } catch {
    return [];
  }
};

export const writeLocal = (slug: string, items: WatchlistItem[]) => {
  try {
    localStorage.setItem(localKey(slug), JSON.stringify(items));
  } catch {
    /* ignore quota errors */
  }
};

export const clearLocal = (slug: string) => {
  try {
    localStorage.removeItem(localKey(slug));
  } catch {
    /* ignore */
  }
};

export const productToSnapshot = (p: Product) => ({
  name: p.name,
  image: p.image_full_url,
  price: p.price,
});

export const fetchRemote = async (
  userId: string,
  slug: string,
): Promise<WatchlistItem[]> => {
  const { data, error } = await supabase
    .from("watchlist")
    .select("product_id, store_slug, product_snapshot, created_at")
    .eq("user_id", userId)
    .eq("store_slug", slug)
    .order("created_at", { ascending: false });
  if (error || !data) return [];
  return data.map((r) => ({
    product_id: Number(r.product_id),
    store_slug: r.store_slug,
    snapshot: (r.product_snapshot as WatchlistItem["snapshot"]) ?? {
      name: "",
      image: "",
      price: 0,
    },
    created_at: r.created_at,
  }));
};

export const insertRemote = async (
  userId: string,
  item: Omit<WatchlistItem, "created_at">,
) => {
  await supabase.from("watchlist").upsert(
    {
      user_id: userId,
      store_slug: item.store_slug,
      product_id: item.product_id,
      product_snapshot: item.snapshot,
    },
    { onConflict: "user_id,store_slug,product_id" },
  );
};

export const deleteRemote = async (
  userId: string,
  slug: string,
  productId: number,
) => {
  await supabase
    .from("watchlist")
    .delete()
    .eq("user_id", userId)
    .eq("store_slug", slug)
    .eq("product_id", productId);
};

/** Merge local items into the remote list when the user signs in. */
export const mergeLocalIntoRemote = async (userId: string, slug: string) => {
  const local = readLocal(slug);
  if (local.length === 0) return;
  const rows = local.map((i) => ({
    user_id: userId,
    store_slug: i.store_slug,
    product_id: i.product_id,
    product_snapshot: i.snapshot,
  }));
  await supabase
    .from("watchlist")
    .upsert(rows, { onConflict: "user_id,store_slug,product_id" });
  clearLocal(slug);
};
