import { useContext, useEffect, useMemo, ReactNode } from "react";
import { useQuery } from "@tanstack/react-query";
import { useParams } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { fetchStore, buildStoreContext } from "@/lib/api";
import { StoreCtx, StoreContextValue } from "./storeContextValue";
import { useDynamicManifest } from "@/hooks/useDynamicManifest";

interface StoreProviderProps {
  children: ReactNode;
  slug: string;
}

/**
 * Loads the store identified by `slug` and exposes it via context.
 * Also applies the store's brand color as a CSS variable accent.
 */
export const StoreProvider = ({ children, slug }: StoreProviderProps) => {
  const { t, i18n } = useTranslation();
  const { data, isLoading, isError } = useQuery({
    queryKey: ["store", slug],
    queryFn: () => fetchStore(slug),
    staleTime: 10 * 60 * 1000,
    retry: 1,
  });

  const ctx = useMemo(() => (data ? buildStoreContext(data) : undefined), [data]);

  // Apply store's brand color (if available) as the page accent
  useEffect(() => {
    if (!data?.website_color) return;
    const hsl = hexToHsl(data.website_color);
    if (!hsl) return;
    const root = document.documentElement;
    const prevPrimary = root.style.getPropertyValue("--primary");
    root.style.setProperty("--primary", hsl);
    return () => {
      // Restore previous theme so leaving the store doesn't keep its color
      if (prevPrimary) root.style.setProperty("--primary", prevPrimary);
      else root.style.removeProperty("--primary");
    };
  }, [data?.website_color]);

  // Update document title + theme-color
  useEffect(() => {
    if (data?.name) {
      document.title = `${data.name} — ${t("home.titleSuffix")}`;
    }
    if (data?.website_color) {
      const meta = document.querySelector('meta[name="theme-color"]');
      if (meta) meta.setAttribute("content", data.website_color);
    }
  }, [data?.name, data?.website_color, t, i18n.language]);

  // Per-store PWA manifest so "Add to Home Screen" uses the store's name + logo.
  useDynamicManifest({
    name: data?.name,
    description: data?.address ? `${data.name} — ${data.address}` : data?.name,
    logoUrl: data?.logo_full_url,
    themeColor: data?.website_color,
  });

  const value = useMemo<StoreContextValue>(
    () => ({ slug, store: data, ctx, isLoading, isError }),
    [slug, data, ctx, isLoading, isError],
  );

  return <StoreCtx.Provider value={value}>{children}</StoreCtx.Provider>;
};

/** Hook to read the current store. Throws if not inside a StoreProvider. */
export const useStore = () => {
  const ctx = useContext(StoreCtx);
  if (!ctx) throw new Error("useStore must be used within StoreProvider");
  return ctx;
};

/** Convenience hook to get the current store slug from the URL. */
export const useStoreSlug = () => {
  const params = useParams<{ storeSlug: string }>();
  return params.storeSlug ?? "";
};

// Convert a hex color (#RRGGBB) to "H S% L%" suitable for `hsl(var(--primary))`.
function hexToHsl(hex: string): string | null {
  const m = hex.trim().match(/^#?([a-f\d]{6})$/i);
  if (!m) return null;
  const int = parseInt(m[1], 16);
  const r = ((int >> 16) & 255) / 255;
  const g = ((int >> 8) & 255) / 255;
  const b = (int & 255) / 255;
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  let h = 0;
  let s = 0;
  const l = (max + min) / 2;
  if (max !== min) {
    const d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    switch (max) {
      case r:
        h = (g - b) / d + (g < b ? 6 : 0);
        break;
      case g:
        h = (b - r) / d + 2;
        break;
      case b:
        h = (r - g) / d + 4;
        break;
    }
    h *= 60;
  }
  return `${Math.round(h)} ${Math.round(s * 100)}% ${Math.round(l * 100)}%`;
}
