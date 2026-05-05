import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  ReactNode,
} from "react";
import {
  authLogin,
  authLogout,
  authSignUp,
  fetchCustomerInfo,
  getAuthToken,
  setAuthToken,
  type CustomerInfo,
} from "@/lib/shoplanserApi";
import { useStore } from "@/context/StoreContext";

interface ShopAuthValue {
  token: string | null;
  user: CustomerInfo | null;
  loading: boolean;
  isAuthenticated: boolean;
  signIn: (phone: string, password: string) => Promise<void>;
  signUp: (input: { name: string; phone: string; password: string; email?: string }) => Promise<void>;
  signOut: () => void;
  refresh: () => Promise<void>;
}

const ShopAuthContext = createContext<ShopAuthValue | undefined>(undefined);

export function ShopAuthProvider({ children }: { children: ReactNode }) {
  const { ctx } = useStore();
  const [token, setToken] = useState<string | null>(() => getAuthToken());
  const [user, setUser] = useState<CustomerInfo | null>(null);
  const [loading, setLoading] = useState<boolean>(!!token);

  const refresh = useCallback(async () => {
    if (!getAuthToken()) {
      setUser(null);
      setLoading(false);
      return;
    }
    setLoading(true);
    try {
      const info = await fetchCustomerInfo(ctx ?? undefined);
      setUser(info);
    } catch {
      // Token invalid → clear
      setAuthToken(null);
      setToken(null);
      setUser(null);
    } finally {
      setLoading(false);
    }
  }, [ctx]);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  const signIn = useCallback(
    async (phone: string, password: string) => {
      const res = await authLogin({ phone, password }, ctx ?? undefined);
      if (!res.token) throw new Error(res.message || "فشل تسجيل الدخول");
      setToken(res.token);
      await refresh();
    },
    [ctx, refresh],
  );

  const signUp = useCallback(
    async (input: { name: string; phone: string; password: string; email?: string }) => {
      const res = await authSignUp(input, ctx ?? undefined);
      if (res.token) {
        setToken(res.token);
        await refresh();
      }
    },
    [ctx, refresh],
  );

  const signOut = useCallback(() => {
    authLogout();
    setToken(null);
    setUser(null);
  }, []);

  const value = useMemo<ShopAuthValue>(
    () => ({
      token,
      user,
      loading,
      isAuthenticated: !!token,
      signIn,
      signUp,
      signOut,
      refresh,
    }),
    [token, user, loading, signIn, signUp, signOut, refresh],
  );

  return <ShopAuthContext.Provider value={value}>{children}</ShopAuthContext.Provider>;
}

export function useShopAuth(): ShopAuthValue {
  const v = useContext(ShopAuthContext);
  if (!v) throw new Error("useShopAuth must be used within ShopAuthProvider");
  return v;
}
