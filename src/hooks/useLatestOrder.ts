import { useCallback, useEffect, useRef, useState } from "react";
import { listUserOrders, type RemoteOrder } from "@/lib/shoplanserApi";
import { useStore } from "@/context/StoreContext";
import { useShopAuth } from "@/context/ShopAuthContext";

const POLL_MS = 30_000;

/**
 * Polls the latest user order every 30s while the tab is visible. Pauses when
 * hidden and refetches immediately on visibility change.
 */
export function useLatestOrder() {
  const { ctx } = useStore();
  const { isAuthenticated } = useShopAuth();
  const [order, setOrder] = useState<RemoteOrder | null>(null);
  const [loading, setLoading] = useState<boolean>(false);
  const timerRef = useRef<number | null>(null);

  const refresh = useCallback(async () => {
    if (!isAuthenticated) {
      setOrder(null);
      return;
    }
    setLoading(true);
    try {
      const { orders } = await listUserOrders(ctx ?? undefined, { limit: 1 });
      setOrder(orders[0] ?? null);
    } catch {
      // Keep last-known data on transient errors.
    } finally {
      setLoading(false);
    }
  }, [ctx, isAuthenticated]);

  useEffect(() => {
    void refresh();
    if (!isAuthenticated) return;

    const tick = () => {
      if (typeof document !== "undefined" && document.hidden) return;
      void refresh();
    };
    timerRef.current = window.setInterval(tick, POLL_MS);

    const onVis = () => {
      if (typeof document !== "undefined" && !document.hidden) void refresh();
    };
    document.addEventListener("visibilitychange", onVis);

    return () => {
      if (timerRef.current != null) window.clearInterval(timerRef.current);
      document.removeEventListener("visibilitychange", onVis);
    };
  }, [refresh, isAuthenticated]);

  return { order, loading, refresh };
}
