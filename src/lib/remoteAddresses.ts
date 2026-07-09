// Remote (API-backed) addresses for authenticated users.
// Wraps shoplanserApi address endpoints + a small localStorage cache so the
// list paints instantly while the network request is in flight, and tracks
// a "default address id" (the API itself doesn't expose a default flag).
import {
  listAddresses as apiListAddresses,
  addAddress as apiAddAddress,
  updateAddress as apiUpdateAddress,
  deleteAddress as apiDeleteAddress,
  type AddressInput,
  type RemoteAddress,
} from "@/lib/shoplanserApi";
import type { StoreContextData } from "@/lib/api";

const CACHE_KEY = "shoplanser_remote_addresses_v1";
const DEFAULT_KEY = "shoplanser_remote_default_address_v1";

export type { RemoteAddress, AddressInput };

export function loadCachedAddresses(): RemoteAddress[] {
  try {
    const raw = localStorage.getItem(CACHE_KEY);
    return raw ? (JSON.parse(raw) as RemoteAddress[]) : [];
  } catch {
    return [];
  }
}

function saveCache(list: RemoteAddress[]) {
  try {
    localStorage.setItem(CACHE_KEY, JSON.stringify(list));
  } catch {
    /* ignore quota errors */
  }
}

export function getDefaultAddressId(): number | null {
  try {
    const raw = localStorage.getItem(DEFAULT_KEY);
    if (!raw) return null;
    const n = Number(raw);
    return Number.isFinite(n) ? n : null;
  } catch {
    return null;
  }
}

export function setDefaultAddressId(id: number | null) {
  try {
    if (id == null) localStorage.removeItem(DEFAULT_KEY);
    else localStorage.setItem(DEFAULT_KEY, String(id));
  } catch {
    /* ignore */
  }
}

/** Sort so the default address is first. */
export function sortByDefault(list: RemoteAddress[]): RemoteAddress[] {
  const def = getDefaultAddressId();
  if (def == null) return list;
  const idx = list.findIndex((a) => a.id === def);
  if (idx <= 0) return list;
  const next = list.slice();
  const [picked] = next.splice(idx, 1);
  next.unshift(picked);
  return next;
}

export async function fetchAddresses(
  ctx?: Partial<StoreContextData>,
): Promise<RemoteAddress[]> {
  const list = await apiListAddresses(ctx);
  const sorted = sortByDefault(list);
  saveCache(sorted);
  return sorted;
}

export async function createAddress(
  input: AddressInput,
  ctx?: Partial<StoreContextData>,
): Promise<RemoteAddress[]> {
  await apiAddAddress(input, ctx);
  return fetchAddresses(ctx);
}

export async function editAddress(
  id: number,
  input: AddressInput,
  ctx?: Partial<StoreContextData>,
): Promise<RemoteAddress[]> {
  await apiUpdateAddress(id, input, ctx);
  return fetchAddresses(ctx);
}

export async function removeAddress(
  id: number,
  ctx?: Partial<StoreContextData>,
): Promise<RemoteAddress[]> {
  await apiDeleteAddress(id, ctx);
  if (getDefaultAddressId() === id) setDefaultAddressId(null);
  return fetchAddresses(ctx);
}
