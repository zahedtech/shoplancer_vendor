import { useSyncExternalStore } from "react";
import { storesRegistry, StoreRegistryEntry } from "@/lib/storesRegistry";

// Cache the snapshot reference so React doesn't see a new array each render.
let cachedSnapshot: StoreRegistryEntry[] = storesRegistry.list();
let cachedKey = JSON.stringify(cachedSnapshot);

function getSnapshot(): StoreRegistryEntry[] {
  const fresh = storesRegistry.list();
  const key = JSON.stringify(fresh);
  if (key !== cachedKey) {
    cachedKey = key;
    cachedSnapshot = fresh;
  }
  return cachedSnapshot;
}

/** Reactive hook for the local store registry. */
export function useStoresRegistry(): StoreRegistryEntry[] {
  return useSyncExternalStore(storesRegistry.subscribe, getSnapshot, getSnapshot);
}
