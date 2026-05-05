// Shoplanser API client — typed access to the ShopLancer backend.
// - Guest identity (per-browser localStorage `guest_id`) for cart/orders.
// - Catalog reads (categories, brands, items, search) for browsing.
// All endpoints automatically inject zoneId/moduleId/X-localization/lat/lng
// via the shared `request()` core and `buildHeaders()`.

import i18n from "@/lib/i18n";
import type { Product, ProductsResponse, StoreCategory, StoreContextData } from "./api";
import { ShoplanserApiError, type ShoplanserErrorItem } from "./shoplanserErrors";

const ENV_BASE = (import.meta.env.VITE_API_BASE_URL as string | undefined)?.trim();
const BASE_URL = ENV_BASE && ENV_BASE.length > 0
  ? ENV_BASE.replace(/\/+$/, "")
  : "https://market.shoplanser.com/api/v1";
const GUEST_KEY = "shoplanser_guest_id_v1";
const AUTH_KEY = "shoplanser_auth_token";

// ---------- Auth token storage ----------

export function getAuthToken(): string | null {
  try { return localStorage.getItem(AUTH_KEY); } catch { return null; }
}
export function setAuthToken(token: string | null) {
  try {
    if (token) localStorage.setItem(AUTH_KEY, token);
    else localStorage.removeItem(AUTH_KEY);
  } catch { /* ignore */ }
}

const DEFAULT_LAT = "29.92427564731563";
const DEFAULT_LNG = "31.04896890845627";

function currentLang(): string {
  const raw = (i18n.language ?? "ar").toString();
  // Strip region (e.g. "en-US" → "en") and normalize.
  return raw.split("-")[0] || "ar";
}

function buildHeaders(ctx?: Partial<StoreContextData>, withJson = false): HeadersInit {
  // moduleId 3 is the historical default for grocery; ctx wins when provided.
  const moduleId = ctx?.moduleId ?? 3;
  const zoneId = ctx?.zoneId ?? 1;
  const headers: Record<string, string> = {
    "X-localization": currentLang(),
    zoneId: `[${zoneId}]`,
    moduleId: String(moduleId),
    latitude: String(ctx?.latitude ?? DEFAULT_LAT),
    longitude: String(ctx?.longitude ?? DEFAULT_LNG),
  };
  if (withJson) headers["Content-Type"] = "application/json";
  try {
    const token = localStorage.getItem(AUTH_KEY);
    if (token) headers.Authorization = `Bearer ${token}`;
  } catch {
    /* ignore — SSR/private mode */
  }
  return headers;
}

// ---------- Core request wrapper ----------

type QueryValue = string | number | boolean | null | undefined;

interface RequestOptions {
  method?: "GET" | "POST" | "PUT" | "DELETE";
  query?: Record<string, QueryValue>;
  body?: unknown;
  ctx?: Partial<StoreContextData>;
  /** Include Content-Type: application/json (auto-on for body). */
  json?: boolean;
  /** Optional AbortSignal — typically forwarded from React Query's queryFn. */
  signal?: AbortSignal;
}

function buildQuery(query?: Record<string, QueryValue>): string {
  if (!query) return "";
  const params = new URLSearchParams();
  for (const [k, v] of Object.entries(query)) {
    if (v === null || v === undefined || v === "") continue;
    params.set(k, String(v));
  }
  const s = params.toString();
  return s ? `?${s}` : "";
}

/**
 * Core fetch wrapper. Throws `ShoplanserApiError` on non-2xx or network failures
 * so React Query surfaces them as `isError` with a typed `error` object.
 */
export async function request<T>(path: string, opts: RequestOptions = {}): Promise<T> {
  const { method = "GET", query, body, ctx, json, signal } = opts;
  const url = `${BASE_URL}${path}${buildQuery(query)}`;
  const wantsJson = json ?? body !== undefined;

  let res: Response;
  try {
    res = await fetch(url, {
      method,
      headers: buildHeaders(ctx, wantsJson),
      body: body !== undefined ? JSON.stringify(body) : undefined,
      signal,
    });
  } catch (e) {
    // Re-throw aborts as-is so React Query can recognize cancellation.
    if (e instanceof DOMException && e.name === "AbortError") throw e;
    throw new ShoplanserApiError({
      status: 0,
      message: e instanceof Error ? e.message : "Network error",
      path,
    });
  }

  // Try to parse JSON regardless of ok — error bodies carry `errors[]`.
  let data: unknown = null;
  const text = await res.text();
  if (text) {
    try {
      data = JSON.parse(text);
    } catch {
      data = text;
    }
  }

  if (!res.ok) {
    const errors: ShoplanserErrorItem[] = Array.isArray(
      (data as { errors?: ShoplanserErrorItem[] })?.errors,
    )
      ? (data as { errors: ShoplanserErrorItem[] }).errors
      : [];
    throw new ShoplanserApiError({
      status: res.status,
      message:
        errors[0]?.message ??
        (data as { message?: string })?.message ??
        `HTTP ${res.status}`,
      errors,
      path,
    });
  }

  return data as T;
}

// ---------- Guest identity ----------

export function getGuestId(): number | null {
  try {
    const raw = localStorage.getItem(GUEST_KEY);
    return raw ? Number(raw) || null : null;
  } catch {
    return null;
  }
}

export function setGuestId(id: number | null) {
  try {
    if (id == null) localStorage.removeItem(GUEST_KEY);
    else localStorage.setItem(GUEST_KEY, String(id));
  } catch {
    /* ignore */
  }
}

/** Ensure we have a guest_id. Hits /auth/guest/request once and caches it. */
export async function ensureGuestId(ctx?: Partial<StoreContextData>): Promise<number> {
  const existing = getGuestId();
  if (existing) return existing;
  const res = await fetch(`${BASE_URL}/auth/guest/request`, {
    method: "POST",
    headers: buildHeaders(ctx, true),
    body: JSON.stringify({ fcm_token: "@" }),
  });
  if (!res.ok) throw new Error("Guest auth failed");
  const data = (await res.json()) as { guest_id?: number };
  if (!data.guest_id) throw new Error("Guest auth: missing guest_id");
  setGuestId(data.guest_id);
  return data.guest_id;
}

// ---------- Cart ----------

export interface RemoteCartItem {
  id: number; // cart row id
  user_id: number;
  item_id: number;
  price: number;
  quantity: number;
  variation: unknown[];
  add_on_ids: number[];
  add_on_qtys: number[];
  item?: {
    id: number;
    name: string;
    image_full_url?: string;
    price?: number;
  };
}

/**
 * Cart list — when authenticated, omit `guest_id` and rely on Bearer token.
 */
export async function listRemoteCart(
  guestId: number | null,
  ctx?: Partial<StoreContextData>,
): Promise<RemoteCartItem[]> {
  const useToken = !!getAuthToken();
  const url = useToken
    ? `${BASE_URL}/customer/cart/list`
    : `${BASE_URL}/customer/cart/list?guest_id=${guestId}`;
  const res = await fetch(url, { headers: buildHeaders(ctx) });
  if (!res.ok) throw new Error("Cart list failed");
  const data = await res.json();
  return Array.isArray(data) ? (data as RemoteCartItem[]) : [];
}

export async function addRemoteCartItem(
  guestId: number | null,
  payload: { item_id: number; price: number; quantity: number },
  ctx?: Partial<StoreContextData>,
): Promise<RemoteCartItem | null> {
  const useToken = !!getAuthToken();
  const body: Record<string, unknown> = {
    item_id: payload.item_id,
    model: "Item",
    price: payload.price,
    quantity: payload.quantity,
    variation: [],
    add_on_ids: [],
    add_on_qtys: [],
  };
  if (!useToken && guestId != null) body.guest_id = guestId;
  const res = await fetch(`${BASE_URL}/customer/cart/add`, {
    method: "POST",
    headers: buildHeaders(ctx, true),
    body: JSON.stringify(body),
  });
  if (!res.ok) return null;
  const data = await res.json();
  return Array.isArray(data) && data.length > 0 ? (data[0] as RemoteCartItem) : null;
}

export async function updateRemoteCartItem(
  guestId: number | null,
  payload: { cart_id: number; price: number; quantity: number },
  ctx?: Partial<StoreContextData>,
): Promise<void> {
  const useToken = !!getAuthToken();
  const body: Record<string, unknown> = {
    cart_id: payload.cart_id,
    price: payload.price,
    quantity: payload.quantity,
    variations: [],
  };
  if (!useToken && guestId != null) body.guest_id = guestId;
  await fetch(`${BASE_URL}/customer/cart/update`, {
    method: "POST",
    headers: buildHeaders(ctx, true),
    body: JSON.stringify(body),
  });
}

export async function removeRemoteCartItem(
  guestId: number | null,
  cartId: number,
  ctx?: Partial<StoreContextData>,
): Promise<void> {
  const useToken = !!getAuthToken();
  const url = useToken
    ? `${BASE_URL}/customer/cart/remove?cart_id=${cartId}`
    : `${BASE_URL}/customer/cart/remove?guest_id=${guestId}&cart_id=${cartId}`;
  await fetch(url, { method: "DELETE", headers: buildHeaders(ctx) });
}

// ---------- Orders ----------

export interface RemoteOrder {
  id: number;
  order_amount: number;
  order_status: string;
  payment_status?: string;
  created_at: string;
  delivery_address?: { address?: string; contact_person_name?: string } | null;
  details_count?: number;
  details?: Array<{
    id: number;
    item_details?: { name?: string; image_full_url?: string };
    quantity?: number;
    price?: number;
  }>;
}

export async function listRemoteOrders(
  guestId: number,
  ctx?: Partial<StoreContextData>,
  opts: { offset?: number; limit?: number } = {},
): Promise<{ total_size: number; orders: RemoteOrder[] }> {
  const offset = opts.offset ?? 1;
  const limit = opts.limit ?? 20;
  const res = await fetch(
    `${BASE_URL}/customer/order/list?guest_id=${guestId}&offset=${offset}&limit=${limit}`,
    { headers: buildHeaders(ctx) },
  );
  if (!res.ok) return { total_size: 0, orders: [] };
  const data = await res.json();
  return {
    total_size: data?.total_size ?? 0,
    orders: Array.isArray(data?.orders) ? data.orders : [],
  };
}

export interface PlaceOrderInput {
  storeId: number;
  cart: Array<{ cart_id: number; item_id: number; price: number; quantity: number }>;
  orderAmount: number;
  customer: { name: string; phone: string; email?: string };
  address: string;
  notes?: string;
  latitude?: string;
  longitude?: string;
  paymentMethod?: "cod" | "offline";
  /** Saved address id (for authenticated users). When set, takes precedence over `address`. */
  addressId?: number;
}

export interface PlaceOrderResult {
  ok: boolean;
  order_id?: number;
  message?: string;
  raw?: unknown;
}

export async function placeRemoteOrder(
  guestId: number,
  input: PlaceOrderInput,
  ctx?: Partial<StoreContextData>,
): Promise<PlaceOrderResult> {
  const lat = String(input.latitude ?? ctx?.latitude ?? DEFAULT_LAT);
  const lng = String(input.longitude ?? ctx?.longitude ?? DEFAULT_LNG);
  const body = {
    guest_id: guestId,
    cart: input.cart.map((c) => ({
      cart_id: c.cart_id,
      item_id: c.item_id,
      item_campaign_id: null,
      price: c.price,
      quantity: c.quantity,
      variations: [],
      add_on_ids: [],
      add_ons: [],
      add_on_qtys: [],
    })),
    order_amount: input.orderAmount,
    order_type: "delivery",
    payment_method: input.paymentMethod === "offline" ? "offline_payment" : "cash_on_delivery",
    order_note: input.notes ?? "",
    address: input.address,
    latitude: lat,
    longitude: lng,
    contact_person_name: input.customer.name,
    contact_person_number: input.customer.phone,
    contact_person_email: input.customer.email || `guest_${guestId}@shoplanser.local`,
    address_type: "home",
    road: "",
    house: "",
    floor: "",
    distance: 1,
    schedule_at: null,
    is_buy_now: 0,
    order_status: "pending",
    delivery_charge: 0,
    coupon_code: null,
    coupon_discount_amount: 0,
    store_discount_amount: 0,
    total_tax_amount: 0,
    store_id: input.storeId,
    is_partial: 0,
    unavailable_item_note: "",
    delivery_instruction: "",
    order_attachment: [],
    dm_tips: 0,
    discount_amount: 0,
    is_cutlery_required: 0,
    cutlery: 0,
    create_new_user: 0,
    password: null,
    guest_address: [],
    ...(input.addressId ? { address_id: input.addressId } : {}),
  };

  const res = await fetch(`${BASE_URL}/customer/order/place`, {
    method: "POST",
    headers: buildHeaders(ctx, true),
    body: JSON.stringify(body),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    const message =
      Array.isArray((data as { errors?: Array<{ message?: string }> })?.errors)
        ? (data as { errors: Array<{ message?: string }> }).errors
            .map((e) => e.message)
            .filter(Boolean)
            .join(" — ")
        : (data as { message?: string })?.message ?? "Order failed";
    return { ok: false, message, raw: data };
  }
  const orderId =
    (data as { order_id?: number })?.order_id ??
    (data as { id?: number })?.id ??
    undefined;
  return { ok: true, order_id: orderId, raw: data };
}

// ---------- Catalog ----------

export interface Brand {
  id: number;
  name: string;
  image_full_url?: string;
  items_count?: number;
}

interface BrandsListResponse {
  total_size?: number;
  brands?: Brand[];
}

/** Normalize the various list shapes the API returns (`products`/`items`/`data`). */
function normalizeProducts(raw: unknown): ProductsResponse {
  const r = (raw ?? {}) as Record<string, unknown>;
  const list =
    (r.products as Product[]) ??
    (r.items as Product[]) ??
    (r.data as Product[]) ??
    (Array.isArray(raw) ? (raw as Product[]) : []);
  return {
    total_size: Number(r.total_size ?? list.length ?? 0),
    limit: String(r.limit ?? list.length ?? 0),
    offset: String(r.offset ?? "1"),
    products: list,
  };
}

/** Top-level categories for the current zone/module. */
export function fetchCategoriesTopLevel(
  ctx?: Partial<StoreContextData>,
): Promise<StoreCategory[]> {
  return request<StoreCategory[]>("/categories", { ctx });
}

/** Direct children of `parentId`. */
export function fetchCategoryChildren(
  parentId: number,
  ctx?: Partial<StoreContextData>,
): Promise<StoreCategory[]> {
  return request<StoreCategory[]>(`/categories/childes/${parentId}`, { ctx });
}

/** Items inside a category. Pagination is 1-based. */
export async function fetchCategoryItems(
  params: {
    categoryId: number;
    offset?: number;
    limit?: number;
    type?: "all" | "veg" | "non_veg";
    signal?: AbortSignal;
  },
  ctx?: Partial<StoreContextData>,
): Promise<ProductsResponse> {
  const { categoryId, offset = 1, limit = 20, type = "all", signal } = params;
  const raw = await request<unknown>(`/categories/items/${categoryId}`, {
    ctx,
    query: { limit, offset, type },
    signal,
  });
  return normalizeProducts(raw);
}

/** Brands list (filterable in `FiltersSheet`). */
export async function fetchBrands(
  ctx?: Partial<StoreContextData>,
): Promise<Brand[]> {
  const raw = await request<Brand[] | BrandsListResponse>("/brand", { ctx });
  if (Array.isArray(raw)) return raw;
  return raw.brands ?? [];
}

/** Items inside a brand. */
export async function fetchBrandItems(
  params: { brandId: number; offset?: number; limit?: number; signal?: AbortSignal },
  ctx?: Partial<StoreContextData>,
): Promise<ProductsResponse> {
  const { brandId, offset = 1, limit = 20, signal } = params;
  const raw = await request<unknown>(`/brand/items/${brandId}`, {
    ctx,
    query: { offset, limit },
    signal,
  });
  return normalizeProducts(raw);
}

/** Backend item search. */
export async function searchItems(
  params: {
    name: string;
    storeId?: number;
    categoryId?: number;
    offset?: number;
    limit?: number;
    signal?: AbortSignal;
  },
  ctx?: Partial<StoreContextData>,
): Promise<ProductsResponse> {
  const { name, storeId, categoryId, offset = 1, limit = 20, signal } = params;
  const raw = await request<unknown>("/items/search", {
    ctx,
    query: {
      name,
      store_id: storeId,
      category_id: categoryId,
      offset,
      limit,
    },
    signal,
  });
  return normalizeProducts(raw);
}

/** Combined item-or-store search. Useful when you want broader matches. */
export async function searchItemsOrStores(
  params: {
    name: string;
    categoryId?: number;
    type?: "all" | "veg" | "non_veg";
    offset?: number;
    limit?: number;
  },
  ctx?: Partial<StoreContextData>,
): Promise<ProductsResponse> {
  const { name, categoryId, type = "all", offset = 1, limit = 20 } = params;
  const raw = await request<unknown>("/items/item-or-store-search", {
    ctx,
    query: {
      name,
      category_id: categoryId,
      type,
      offset,
      limit,
    },
  });
  return normalizeProducts(raw);
}

// ---------- Auth (registered users) ----------

export interface AuthSignUpInput {
  name: string;
  phone: string;
  password: string;
  email?: string;
}

export interface AuthLoginResult {
  token?: string;
  is_phone_verified?: number | boolean;
  user_id?: number;
  message?: string;
  raw?: unknown;
}

/** POST /auth/sign-up */
export async function authSignUp(
  input: AuthSignUpInput,
  ctx?: Partial<StoreContextData>,
): Promise<AuthLoginResult> {
  const data = await request<Record<string, unknown>>("/auth/sign-up", {
    method: "POST",
    body: input,
    ctx,
  });
  const token = (data.token as string) ?? undefined;
  if (token) setAuthToken(token);
  return { token, raw: data, ...data };
}

/** POST /auth/login (phone + password) */
export async function authLogin(
  input: { phone: string; password: string },
  ctx?: Partial<StoreContextData>,
): Promise<AuthLoginResult> {
  const data = await request<Record<string, unknown>>("/auth/login", {
    method: "POST",
    body: { ...input, login_type: "manual" },
    ctx,
  });
  const token = (data.token as string) ?? undefined;
  if (token) setAuthToken(token);
  return { token, raw: data, ...data };
}

export function authLogout() {
  setAuthToken(null);
}

export interface CustomerInfo {
  id: number;
  f_name?: string;
  l_name?: string;
  name?: string;
  phone?: string;
  email?: string;
  image_full_url?: string;
  loyalty_point?: number;
  wallet_balance?: number;
}

/** GET /customer/info — requires Bearer token. */
export async function fetchCustomerInfo(
  ctx?: Partial<StoreContextData>,
): Promise<CustomerInfo | null> {
  if (!getAuthToken()) return null;
  return request<CustomerInfo>("/customer/info", { ctx });
}

/** POST /customer/update-profile */
export async function updateCustomerProfile(
  input: { name?: string; image?: string },
  ctx?: Partial<StoreContextData>,
): Promise<unknown> {
  return request("/customer/update-profile", {
    method: "POST",
    body: input,
    ctx,
  });
}

// ---------- Addresses (registered users) ----------

export interface RemoteAddress {
  id: number;
  contact_person_name: string;
  contact_person_number: string;
  address_type: string;
  address: string;
  latitude: string;
  longitude: string;
}

export interface AddressInput {
  contact_person_name: string;
  contact_person_number: string;
  address_type: string;
  address: string;
  latitude: string;
  longitude: string;
}

export async function listAddresses(
  ctx?: Partial<StoreContextData>,
): Promise<RemoteAddress[]> {
  if (!getAuthToken()) return [];
  const data = await request<{ addresses?: RemoteAddress[] } | RemoteAddress[]>(
    "/customer/address/list",
    { ctx },
  );
  if (Array.isArray(data)) return data;
  return data.addresses ?? [];
}

export async function addAddress(
  input: AddressInput,
  ctx?: Partial<StoreContextData>,
): Promise<unknown> {
  return request("/customer/address/add", {
    method: "POST",
    body: input,
    ctx,
  });
}

export async function updateAddress(
  id: number,
  input: AddressInput,
  ctx?: Partial<StoreContextData>,
): Promise<unknown> {
  return request(`/customer/address/update/${id}`, {
    method: "PUT",
    body: input,
    ctx,
  });
}

export async function deleteAddress(
  id: number,
  ctx?: Partial<StoreContextData>,
): Promise<unknown> {
  return request("/customer/address/delete", {
    method: "DELETE",
    body: { address_id: id },
    ctx,
  });
}

// ---------- Orders for registered users ----------

/** GET /customer/order/list (token-based; falls back to guest_id when no auth). */
export async function listUserOrders(
  ctx?: Partial<StoreContextData>,
  opts: { offset?: number; limit?: number } = {},
): Promise<{ total_size: number; orders: RemoteOrder[] }> {
  if (!getAuthToken()) return { total_size: 0, orders: [] };
  const offset = opts.offset ?? 1;
  const limit = opts.limit ?? 20;
  const res = await fetch(
    `${BASE_URL}/customer/order/list?offset=${offset}&limit=${limit}`,
    { headers: buildHeaders(ctx) },
  );
  if (!res.ok) return { total_size: 0, orders: [] };
  const data = await res.json();
  return {
    total_size: data?.total_size ?? 0,
    orders: Array.isArray(data?.orders) ? data.orders : [],
  };
}

/** PUT /customer/order/cancel */
export async function cancelOrder(
  orderId: number,
  ctx?: Partial<StoreContextData>,
): Promise<unknown> {
  return request("/customer/order/cancel", {
    method: "PUT",
    body: { order_id: orderId },
    ctx,
  });
}

/** GET /customer/order/details?order_id=... */
export async function fetchOrderDetails(
  orderId: number,
  ctx?: Partial<StoreContextData>,
): Promise<unknown> {
  return request("/customer/order/details", {
    query: { order_id: orderId },
    ctx,
  });
}

export { ShoplanserApiError } from "./shoplanserErrors";

