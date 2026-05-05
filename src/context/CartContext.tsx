import { createContext, useContext, useEffect, useMemo, useRef, useState, ReactNode } from "react";
import { Product, getDiscountedPrice } from "@/lib/api";
import {
  PHONE_KEY,
  clearLocalCart,
  clearSnapshotsForPhone,
  getStoredPhone,
  mergeOnLink,
  pullCart,
  pushCart,
  setStoredPhone,
} from "@/lib/cartSync";
import { useStore } from "@/context/StoreContext";
import {
  addRemoteCartItem,
  ensureGuestId,
  getAuthToken,
  getGuestId,
  listRemoteCart,
  removeRemoteCartItem,
  updateRemoteCartItem,
} from "@/lib/shoplanserApi";
import { useShopAuth } from "@/context/ShopAuthContext";

export interface CartItem {
  id: number;
  name: string;
  image: string;
  price: number;
  originalPrice: number;
  quantity: number;
  /** Remote cart row id from /customer/cart/list (set after server sync). */
  remoteCartId?: number;
  // ---- Product-kind metadata (persisted so reload / slug change keeps consistent display) ----
  /** "attarah" = quantity is a count of `referenceGramPrice` blocks. */
  kind?: "attarah" | "produce_or_piece";
  /** For attarah only: grams covered by `price`. */
  referenceGramPrice?: number;
  /** For attarah only: minimum grams allowed. */
  minGrams?: number;
  /** Last known stock value at the moment the item was added/updated. */
  stock?: number;
}

export interface AddItemOptions {
  /** Initial quantity (used for attarah blocks). Default 1. */
  quantity?: number;
  kind?: CartItem["kind"];
  referenceGramPrice?: number;
  minGrams?: number;
  stock?: number;
}

interface CartContextValue {
  items: CartItem[];
  count: number;
  subtotal: number;
  addItem: (p: Product, opts?: AddItemOptions) => void;
  removeItem: (id: number) => void;
  increment: (id: number) => void;
  decrement: (id: number) => void;
  setQuantity: (id: number, q: number) => void;
  clear: () => void;
  isOpen: boolean;
  openCart: () => void;
  closeCart: () => void;
  setOpen: (v: boolean) => void;
  // Sync
  linkedPhone: string | null;
  linkPhone: (phone: string) => Promise<void>;
  unlinkPhone: () => void;
  // Remote (Shoplanser guest API)
  guestId: number | null;
}

const CartContext = createContext<CartContextValue | undefined>(undefined);

const storageKeyFor = (slug: string) => `cart_${slug}_v1`;

interface CartProviderProps {
  children: ReactNode;
  /**
   * The current store slug. Each store has its own isolated cart in
   * localStorage and in the synced_carts table.
   */
  storeSlug: string;
}

export const CartProvider = ({ children, storeSlug }: CartProviderProps) => {
  const STORAGE_KEY = storageKeyFor(storeSlug);
  const { ctx } = useStore();

  const [items, setItems] = useState<CartItem[]>(() => {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      return raw ? (JSON.parse(raw) as CartItem[]) : [];
    } catch {
      return [];
    }
  });
  const [isOpen, setOpen] = useState(false);
  const [linkedPhone, setLinkedPhone] = useState<string | null>(() => getStoredPhone());
  const [guestId, setGuestIdState] = useState<number | null>(() => getGuestId());

  // When the slug changes (user navigates to another store), reload cart from
  // localStorage for that slug.
  useEffect(() => {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      setItems(raw ? (JSON.parse(raw) as CartItem[]) : []);
    } catch {
      setItems([]);
    }
    // hydration ref reset so we can pull remote for the new store
    hydratedRef.current = false;
    isInitialMount.current = true;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [storeSlug]);

  // Persist locally per-slug
  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(items));
    } catch {
      /* ignore */
    }
  }, [items, STORAGE_KEY]);

  // On first load (per slug): if phone is linked, pull this store's remote cart
  const hydratedRef = useRef(false);
  useEffect(() => {
    if (hydratedRef.current) return;
    hydratedRef.current = true;
    const phone = getStoredPhone();
    if (!phone) return;
    (async () => {
      const remote = await pullCart(phone, storeSlug);
      if (remote && remote.length > 0) {
        setItems(remote);
      } else if (remote === null) {
        if (items.length > 0) await pushCart(phone, storeSlug, items);
      }
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [storeSlug]);

  // Debounced push to remote (Supabase) when items change AND a phone is linked
  const pushTimer = useRef<number | null>(null);
  const isInitialMount = useRef(true);
  useEffect(() => {
    if (isInitialMount.current) {
      isInitialMount.current = false;
      return;
    }
    if (!linkedPhone) return;
    if (pushTimer.current) window.clearTimeout(pushTimer.current);
    pushTimer.current = window.setTimeout(() => {
      pushCart(linkedPhone, storeSlug, items).catch(() => undefined);
    }, 600);
    return () => {
      if (pushTimer.current) window.clearTimeout(pushTimer.current);
    };
  }, [items, linkedPhone, storeSlug]);

  // ----- Shoplanser guest cart sync -----
  // Once we know the store ctx, ensure a guest_id and pull the remote cart so
  // remoteCartId is hydrated (needed for /order/place).
  const remoteHydrated = useRef(false);
  useEffect(() => {
    if (!ctx || remoteHydrated.current) return;
    remoteHydrated.current = true;
    (async () => {
      try {
        const id = await ensureGuestId(ctx);
        setGuestIdState(id);
        const remote = await listRemoteCart(id, ctx);
        // Map remote rows by item_id so we can attach remoteCartId to local items.
        const byItem = new Map<number, number>();
        for (const r of remote) byItem.set(r.item_id, r.id);
        setItems((prev) =>
          prev.map((i) =>
            byItem.has(i.id) ? { ...i, remoteCartId: byItem.get(i.id) } : i,
          ),
        );
      } catch {
        /* non-blocking */
      }
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [ctx?.storeId]);

  // ----- Auth-driven cart replacement -----
  // When the user signs in/out, replace the local cart with the server cart
  // bound to that identity (token if signed-in, guest_id otherwise).
  const { isAuthenticated, loading: authLoading } = useShopAuth();
  const lastAuthRef = useRef<boolean | null>(null);
  useEffect(() => {
    if (authLoading || !ctx) return;
    if (lastAuthRef.current === isAuthenticated) return;
    const previous = lastAuthRef.current;
    lastAuthRef.current = isAuthenticated;
    // Skip the very first mount (already hydrated by remoteHydrated effect).
    if (previous === null) return;
    (async () => {
      try {
        if (isAuthenticated) {
          // Switched to logged-in: pull user's cart from API and REPLACE local.
          const remote = await listRemoteCart(null, ctx);
          const mapped: CartItem[] = remote.map((r) => ({
            id: r.item_id,
            name: r.item?.name ?? `#${r.item_id}`,
            image: r.item?.image_full_url ?? "",
            price: Number(r.price) || 0,
            originalPrice: Number(r.item?.price ?? r.price) || 0,
            quantity: Number(r.quantity) || 1,
            remoteCartId: r.id,
          }));
          setItems(mapped);
        } else {
          // Logged out: clear cart so we don't keep stale logged-in items.
          setItems([]);
        }
      } catch {
        /* non-blocking */
      }
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isAuthenticated, authLoading, ctx?.storeId]);

  // Cross-tab sync via storage event
  useEffect(() => {
    const onStorage = (e: StorageEvent) => {
      if (e.key === STORAGE_KEY && e.newValue) {
        try {
          setItems(JSON.parse(e.newValue));
        } catch {
          /* ignore */
        }
      }
      if (e.key === PHONE_KEY) {
        setLinkedPhone(e.newValue);
      }
    };
    window.addEventListener("storage", onStorage);
    return () => window.removeEventListener("storage", onStorage);
  }, [STORAGE_KEY]);

  // Helper: remote add (returns new cart_id) — fire-and-forget but updates state.
  const remoteAdd = async (item: { id: number; price: number; quantity: number }) => {
    try {
      const id = guestId ?? (ctx ? await ensureGuestId(ctx) : null);
      if (!id) return;
      if (!guestId) setGuestIdState(id);
      const row = await addRemoteCartItem(
        id,
        { item_id: item.id, price: item.price, quantity: item.quantity },
        ctx,
      );
      if (row?.id) {
        setItems((prev) =>
          prev.map((i) => (i.id === item.id ? { ...i, remoteCartId: row.id } : i)),
        );
      }
    } catch {
      /* non-blocking */
    }
  };

  const remoteUpdate = (cartId: number, price: number, quantity: number) => {
    if (!guestId) return;
    updateRemoteCartItem(guestId, { cart_id: cartId, price, quantity }, ctx).catch(
      () => undefined,
    );
  };

  const remoteRemove = (cartId: number) => {
    if (!guestId) return;
    removeRemoteCartItem(guestId, cartId, ctx).catch(() => undefined);
  };

  const addItem = (p: Product, opts?: AddItemOptions) => {
    const { final } = getDiscountedPrice(p);
    const initialQty = Math.max(1, Math.floor(opts?.quantity ?? 1));
    let isNew = false;
    let finalQty = initialQty;
    setItems((prev) => {
      const existing = prev.find((i) => i.id === p.id);
      if (existing) {
        // For attarah we replace quantity (it represents an absolute weight choice).
        // For piece/produce we increment.
        const nextQty =
          opts?.kind === "attarah" ? initialQty : existing.quantity + initialQty;
        finalQty = nextQty;
        if (existing.remoteCartId) remoteUpdate(existing.remoteCartId, existing.price, nextQty);
        return prev.map((i) =>
          i.id === p.id
            ? {
                ...i,
                quantity: nextQty,
                price: final,
                kind: opts?.kind ?? i.kind,
                referenceGramPrice:
                  opts?.referenceGramPrice ?? i.referenceGramPrice,
                minGrams: opts?.minGrams ?? i.minGrams,
                stock: opts?.stock ?? p.stock ?? i.stock,
              }
            : i,
        );
      }
      isNew = true;
      return [
        ...prev,
        {
          id: p.id,
          name: p.name,
          image: p.image_full_url,
          price: final,
          originalPrice: p.price,
          quantity: initialQty,
          kind: opts?.kind,
          referenceGramPrice: opts?.referenceGramPrice,
          minGrams: opts?.minGrams,
          stock: opts?.stock ?? p.stock,
        },
      ];
    });
    if (isNew) {
      void remoteAdd({ id: p.id, price: final, quantity: finalQty });
    }
  };

  const removeItem = (id: number) =>
    setItems((prev) => {
      const target = prev.find((i) => i.id === id);
      if (target?.remoteCartId) remoteRemove(target.remoteCartId);
      return prev.filter((i) => i.id !== id);
    });

  const increment = (id: number) =>
    setItems((prev) =>
      prev.map((i) => {
        if (i.id !== id) return i;
        const nextQty = i.quantity + 1;
        if (i.remoteCartId) remoteUpdate(i.remoteCartId, i.price, nextQty);
        return { ...i, quantity: nextQty };
      }),
    );

  const decrement = (id: number) =>
    setItems((prev) =>
      prev
        .map((i) => {
          if (i.id !== id) return i;
          const nextQty = i.quantity - 1;
          if (i.remoteCartId) {
            if (nextQty <= 0) remoteRemove(i.remoteCartId);
            else remoteUpdate(i.remoteCartId, i.price, nextQty);
          }
          return { ...i, quantity: nextQty };
        })
        .filter((i) => i.quantity > 0),
    );

  const setQuantity = (id: number, q: number) =>
    setItems((prev) =>
      prev
        .map((i) => {
          if (i.id !== id) return i;
          const nextQty = Math.max(0, Math.floor(q));
          if (i.remoteCartId) {
            if (nextQty <= 0) remoteRemove(i.remoteCartId);
            else remoteUpdate(i.remoteCartId, i.price, nextQty);
          }
          return { ...i, quantity: nextQty };
        })
        .filter((i) => i.quantity > 0),
    );

  const clear = () => {
    // Wipe remote rows for known items
    if (guestId) {
      for (const i of items) {
        if (i.remoteCartId) remoteRemove(i.remoteCartId);
      }
    }
    setItems([]);
  };

  const linkPhone = async (phone: string) => {
    setStoredPhone(phone);
    setLinkedPhone(phone);
    // Merge any existing per-phone snapshot with the current local cart.
    const merged = await mergeOnLink(phone, storeSlug, items);
    setItems(merged);
  };

  const unlinkPhone = () => {
    const prevPhone = linkedPhone;
    setStoredPhone(null);
    setLinkedPhone(null);
    // Wipe per-phone snapshots and the active local cart so no stale data remains.
    clearSnapshotsForPhone(prevPhone);
    clearLocalCart(storeSlug);
    setItems([]);
  };

  const { count, subtotal } = useMemo(() => {
    let c = 0;
    let s = 0;
    for (const i of items) {
      c += i.quantity;
      s += i.quantity * i.price;
    }
    return { count: c, subtotal: s };
  }, [items]);

  return (
    <CartContext.Provider
      value={{
        items,
        count,
        subtotal,
        addItem,
        removeItem,
        increment,
        decrement,
        setQuantity,
        clear,
        isOpen,
        openCart: () => setOpen(true),
        closeCart: () => setOpen(false),
        setOpen,
        linkedPhone,
        linkPhone,
        unlinkPhone,
        guestId,
      }}
    >
      {children}
    </CartContext.Provider>
  );
};

export const useCart = () => {
  const ctx = useContext(CartContext);
  if (!ctx) throw new Error("useCart must be used within CartProvider");
  return ctx;
};

