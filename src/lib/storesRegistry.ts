// Local registry of tenant stores. Persisted in localStorage so the user can
// add/edit stores from the /admin UI without a backend.
//
// Each entry stores the *minimum* needed to bootstrap a tenant: the URL slug
// and the Shoplanser API base. Everything else (name, logo, module_id, zone)
// is fetched live from Shoplanser when the storefront/dashboard loads.

export interface StoreRegistryEntry {
  slug: string;
  /** Friendly display name (cached from Shoplanser). */
  displayName?: string;
  /** API base URL — defaults to Shoplanser. Per-tenant override supported. */
  apiBase: string;
  /** Optional cached metadata to avoid an extra API call on the admin list. */
  cachedModuleId?: number;
  cachedLogo?: string;
  /** ISO timestamp the entry was created. */
  createdAt: string;
}

const STORAGE_KEY = "stores_registry_v1";
const DEFAULT_API_BASE = "https://shoplanser.com/api/v1";

/** Default seed so a fresh user immediately sees their primary store. */
const SEED: StoreRegistryEntry[] = [
  {
    slug: "awaldrazq",
    displayName: "أولاد الرزق",
    apiBase: DEFAULT_API_BASE,
    createdAt: new Date().toISOString(),
  },
];

function read(): StoreRegistryEntry[] {
  if (typeof window === "undefined") return SEED;
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (!raw) {
      window.localStorage.setItem(STORAGE_KEY, JSON.stringify(SEED));
      return SEED;
    }
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) && parsed.length ? parsed : SEED;
  } catch {
    return SEED;
  }
}

function write(entries: StoreRegistryEntry[]) {
  if (typeof window === "undefined") return;
  window.localStorage.setItem(STORAGE_KEY, JSON.stringify(entries));
  // Notify other tabs/components
  window.dispatchEvent(new CustomEvent("stores-registry-changed"));
}

export const storesRegistry = {
  list: read,
  get(slug: string): StoreRegistryEntry | undefined {
    return read().find((s) => s.slug === slug);
  },
  upsert(entry: Partial<StoreRegistryEntry> & { slug: string }) {
    const all = read();
    const idx = all.findIndex((s) => s.slug === entry.slug);
    const merged: StoreRegistryEntry = {
      apiBase: DEFAULT_API_BASE,
      createdAt: new Date().toISOString(),
      ...all[idx],
      ...entry,
    };
    if (idx >= 0) all[idx] = merged;
    else all.push(merged);
    write(all);
    return merged;
  },
  remove(slug: string) {
    write(read().filter((s) => s.slug !== slug));
  },
  /** Subscribe to changes (cross-component reactivity without a global store). */
  subscribe(cb: () => void): () => void {
    if (typeof window === "undefined") return () => {};
    const handler = () => cb();
    window.addEventListener("stores-registry-changed", handler);
    window.addEventListener("storage", handler);
    return () => {
      window.removeEventListener("stores-registry-changed", handler);
      window.removeEventListener("storage", handler);
    };
  },
};

export const DEFAULT_SHOPLANSER_BASE = DEFAULT_API_BASE;
