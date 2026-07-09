import { useEffect, useState } from "react";
import type { Session, User } from "@supabase/supabase-js";
import { supabase } from "@/integrations/supabase/client";

export type AppRole = "admin" | "vendor" | "user";

interface AuthState {
  session: Session | null;
  user: User | null;
  loading: boolean;
}

/**
 * Reactive Supabase auth state. Always sets up the listener BEFORE calling
 * getSession() so we don't miss the very first SIGNED_IN event.
 */
export function useAuth(): AuthState {
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const { data: sub } = supabase.auth.onAuthStateChange((_event, s) => {
      setSession(s);
      setLoading(false);
    });
    supabase.auth.getSession().then(({ data }) => {
      setSession(data.session);
      setLoading(false);
    });
    return () => sub.subscription.unsubscribe();
  }, []);

  return { session, user: session?.user ?? null, loading };
}

/** Roles for the current user — empty array while loading or signed out. */
export function useUserRoles(userId: string | null | undefined) {
  const [roles, setRoles] = useState<AppRole[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    if (!userId) {
      setRoles([]);
      setLoading(false);
      return;
    }
    setLoading(true);
    supabase
      .from("user_roles")
      .select("role")
      .eq("user_id", userId)
      .then(({ data, error }) => {
        if (cancelled) return;
        if (error) {
          console.warn("[useUserRoles] failed", error);
          setRoles([]);
        } else {
          setRoles((data ?? []).map((r) => r.role as AppRole));
        }
        setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [userId]);

  return { roles, loading };
}

/** Vendor → store_slug mapping for the current user. */
export function useVendorStores(userId: string | null | undefined) {
  const [slugs, setSlugs] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    if (!userId) {
      setSlugs([]);
      setLoading(false);
      return;
    }
    setLoading(true);
    supabase
      .from("vendor_stores")
      .select("store_slug")
      .eq("user_id", userId)
      .then(({ data, error }) => {
        if (cancelled) return;
        if (error) {
          console.warn("[useVendorStores] failed", error);
          setSlugs([]);
        } else {
          setSlugs((data ?? []).map((r) => r.store_slug));
        }
        setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [userId]);

  return { slugs, loading };
}
