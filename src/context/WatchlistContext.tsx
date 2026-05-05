import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import { toast } from "@/hooks/use-toast";
import { useAuth } from "@/hooks/useAuth";
import type { Product } from "@/lib/api";
import {
  deleteRemote,
  fetchRemote,
  insertRemote,
  mergeLocalIntoRemote,
  productToSnapshot,
  readLocal,
  writeLocal,
  type WatchlistItem,
} from "@/lib/watchlist";

interface WatchlistContextValue {
  items: WatchlistItem[];
  ids: Set<number>;
  isWatched: (productId: number) => boolean;
  toggle: (product: Product) => Promise<void>;
}

const WatchlistContext = createContext<WatchlistContextValue | undefined>(undefined);

interface WatchlistProviderProps {
  children: ReactNode;
  storeSlug: string;
}

export const WatchlistProvider = ({ children, storeSlug }: WatchlistProviderProps) => {
  const { user, loading: authLoading } = useAuth();
  const [items, setItems] = useState<WatchlistItem[]>(() => readLocal(storeSlug));

  // Reload when slug changes
  useEffect(() => {
    setItems(readLocal(storeSlug));
  }, [storeSlug]);

  // Merge local into remote on sign-in, then load remote.
  useEffect(() => {
    if (authLoading) return;
    let cancelled = false;
    (async () => {
      if (user) {
        await mergeLocalIntoRemote(user.id, storeSlug);
        const remote = await fetchRemote(user.id, storeSlug);
        if (!cancelled) setItems(remote);
      } else {
        setItems(readLocal(storeSlug));
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [user, authLoading, storeSlug]);

  // Persist local copy when signed-out
  useEffect(() => {
    if (!user) writeLocal(storeSlug, items);
  }, [items, storeSlug, user]);

  const ids = useMemo(() => new Set(items.map((i) => i.product_id)), [items]);

  const isWatched = useCallback((id: number) => ids.has(id), [ids]);

  const toggle = useCallback(
    async (product: Product) => {
      const exists = ids.has(product.id);
      if (exists) {
        setItems((prev) => prev.filter((i) => i.product_id !== product.id));
        if (user) await deleteRemote(user.id, storeSlug, product.id);
        toast({ description: "أُزيل من المتابعة" });
      } else {
        const item: WatchlistItem = {
          product_id: product.id,
          store_slug: storeSlug,
          snapshot: productToSnapshot(product),
          created_at: new Date().toISOString(),
        };
        setItems((prev) => [item, ...prev]);
        if (user) await insertRemote(user.id, item);
        toast({ description: "تمت الإضافة للمتابعة" });
      }
    },
    [ids, user, storeSlug],
  );

  return (
    <WatchlistContext.Provider value={{ items, ids, isWatched, toggle }}>
      {children}
    </WatchlistContext.Provider>
  );
};

export const useWatchlist = () => {
  const ctx = useContext(WatchlistContext);
  if (!ctx) throw new Error("useWatchlist must be used within WatchlistProvider");
  return ctx;
};
