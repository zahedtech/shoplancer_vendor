import { useCallback, useEffect, useState } from "react";
import { toast } from "sonner";
import {
  createAddress,
  editAddress,
  fetchAddresses,
  getDefaultAddressId,
  loadCachedAddresses,
  removeAddress,
  setDefaultAddressId,
  sortByDefault,
  type AddressInput,
  type RemoteAddress,
} from "@/lib/remoteAddresses";
import { useStore } from "@/context/StoreContext";
import { useShopAuth } from "@/context/ShopAuthContext";

export function useRemoteAddresses() {
  const { ctx } = useStore();
  const { isAuthenticated } = useShopAuth();
  const [addresses, setAddresses] = useState<RemoteAddress[]>(() =>
    sortByDefault(loadCachedAddresses()),
  );
  const [loading, setLoading] = useState<boolean>(false);
  const [defaultId, setDefId] = useState<number | null>(() => getDefaultAddressId());

  const refresh = useCallback(async () => {
    if (!isAuthenticated) {
      setAddresses([]);
      return;
    }
    setLoading(true);
    try {
      const list = await fetchAddresses(ctx ?? undefined);
      setAddresses(list);
      // If no default yet, pick the first item as a sensible default.
      if (getDefaultAddressId() == null && list[0]) {
        setDefaultAddressId(list[0].id);
        setDefId(list[0].id);
      }
    } catch (err) {
      toast.error("تعذر تحميل العناوين", {
        description: err instanceof Error ? err.message : undefined,
      });
    } finally {
      setLoading(false);
    }
  }, [ctx, isAuthenticated]);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  const add = useCallback(
    async (input: AddressInput) => {
      const list = await createAddress(input, ctx ?? undefined);
      setAddresses(list);
      if (getDefaultAddressId() == null && list[0]) {
        setDefaultAddressId(list[0].id);
        setDefId(list[0].id);
      }
      return list;
    },
    [ctx],
  );

  const update = useCallback(
    async (id: number, input: AddressInput) => {
      const list = await editAddress(id, input, ctx ?? undefined);
      setAddresses(list);
      return list;
    },
    [ctx],
  );

  const remove = useCallback(
    async (id: number) => {
      const list = await removeAddress(id, ctx ?? undefined);
      setAddresses(list);
      setDefId(getDefaultAddressId());
      return list;
    },
    [ctx],
  );

  const setDefault = useCallback((id: number) => {
    setDefaultAddressId(id);
    setDefId(id);
    setAddresses((prev) => sortByDefault(prev));
  }, []);

  const defaultAddress =
    addresses.find((a) => a.id === defaultId) ?? addresses[0] ?? null;

  return {
    addresses,
    loading,
    defaultAddress,
    defaultId,
    refresh,
    add,
    update,
    remove,
    setDefault,
  };
}
