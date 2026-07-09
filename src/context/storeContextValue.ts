import { createContext } from "react";
import type { StoreDetails, StoreContextData } from "@/lib/api";

export interface StoreContextValue {
  slug: string;
  store: StoreDetails | undefined;
  ctx: StoreContextData | undefined;
  isLoading: boolean;
  isError: boolean;
}

// Kept in a non-component module so Fast Refresh doesn't recreate the context
// identity when StoreContext.tsx is hot-reloaded.
export const StoreCtx = createContext<StoreContextValue | undefined>(undefined);
