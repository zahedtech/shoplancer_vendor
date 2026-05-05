// Shoplanser API client — multi-tenant
// All calls take a slug + storeId so the same code works for any vendor on Shoplanser.
const BASE_URL = "https://shoplanser.com/api/v1";

// Default geo (Cairo / 6th of October). Used when the browser hasn't given us
// a location yet. Shoplanser still needs lat/lng headers on most endpoints.
const DEFAULT_LAT = "29.92427564731563";
const DEFAULT_LNG = "31.04896890845627";

export interface StoreCategory {
  id: number;
  name: string;
  image_full_url: string;
  slug: string;
  priority?: number;
  parent_id?: number;
}

export interface StoreDetails {
  id: number;
  name: string;
  slug: string;
  logo_full_url: string;
  cover_photo_full_url: string;
  delivery_time: string;
  minimum_order: number;
  avg_rating: number;
  rating_count: number;
  total_items: number;
  address: string;
  phone: string;
  email?: string;
  category_details: StoreCategory[];
  website_color: string;
  free_delivery: boolean;
  total_order?: number;
  order_count?: number;
  zone_id?: number | number[];
  module_id?: number;
  module?: { id: number; module_name?: string; module_type?: string; slug?: string };
  zone?: { id: number };
  latitude?: string | number;
  longitude?: string | number;
}

export interface Product {
  id: number;
  name: string;
  description: string;
  image_full_url: string;
  price: number;
  discount: number;
  discount_type: "percent" | "amount";
  store_discount?: number;
  category_id: number;
  category_ids: { id: string; name: string; position: number }[];
  avg_rating: number;
  rating_count: number;
  stock: number;
  unit_type?: string | null;
  recommended?: number;
  organic?: number;
  store_id?: number;
}

export interface ProductsResponse {
  total_size: number;
  limit: string;
  offset: string;
  products: Product[];
}

export interface StoreContextData {
  slug: string;
  storeId: number;
  zoneId: number;
  moduleId: number;
  latitude: string;
  longitude: string;
}

function buildHeaders(ctx?: Partial<StoreContextData>): HeadersInit {
  // moduleId 1 is the universal grocery module — used for store-details lookup
  // before we know the store's actual module. Once we have the store, we use its module.
  const moduleId = ctx?.moduleId ?? 1;
  const zoneId = ctx?.zoneId ?? 1;
  return {
    "X-localization": "ar",
    zoneId: `[${zoneId}]`,
    moduleId: String(moduleId),
    latitude: String(ctx?.latitude ?? DEFAULT_LAT),
    longitude: String(ctx?.longitude ?? DEFAULT_LNG),
  };
}

/** Fetch store details by slug. Used to bootstrap a tenant. */
export async function fetchStore(slug: string): Promise<StoreDetails> {
  const res = await fetch(`${BASE_URL}/stores/details/${slug}`, {
    method: "POST",
    headers: { ...buildHeaders(), "Content-Type": "application/json" },
  });
  if (!res.ok) throw new Error(`Store "${slug}" not found`);
  const data = (await res.json()) as StoreDetails;
  // Normalize slug back onto the object so consumers can rely on it
  return { ...data, slug };
}

export async function fetchProducts(
  ctx: StoreContextData,
  opts: {
    categoryId?: number;
    offset?: number;
    limit?: number;
    type?: "all" | "veg" | "non_veg";
  } = {},
): Promise<ProductsResponse> {
  const { categoryId = 0, offset = 1, limit = 50, type = "all" } = opts;
  const url = `${BASE_URL}/items/latest?store_id=${ctx.storeId}&category_id=${categoryId}&offset=${offset}&limit=${limit}&type=${type}`;
  const res = await fetch(url, { headers: buildHeaders(ctx) });
  if (!res.ok) throw new Error("Failed to load products");
  return res.json();
}

/** Normalize Shoplanser responses that sometimes use `items` instead of `products`. */
function normalizeProductsResponse(raw: unknown): ProductsResponse {
  const r = raw as {
    total_size?: unknown;
    limit?: unknown;
    offset?: unknown;
    products?: unknown;
    items?: unknown;
  };
  const products = r.products ?? r.items;
  return {
    total_size: Number(r.total_size ?? 0),
    limit: String(r.limit ?? "0"),
    offset: String(r.offset ?? "1"),
    products: Array.isArray(products) ? (products as Product[]) : [],
  };
}

export async function fetchRecommended(
  ctx: StoreContextData,
): Promise<ProductsResponse> {
  const url = `${BASE_URL}/items/recommended?store_id=${ctx.storeId}&offset=1&limit=20`;
  const res = await fetch(url, { headers: buildHeaders(ctx) });
  if (!res.ok) throw new Error("Failed to load recommended");
  return normalizeProductsResponse(await res.json());
}

/** Items currently on discount. Used by the "Offers" rail. */
export async function fetchDiscounted(
  ctx: StoreContextData,
): Promise<ProductsResponse> {
  const url = `${BASE_URL}/items/discounted?store_id=${ctx.storeId}&offset=1&limit=20`;
  const res = await fetch(url, { headers: buildHeaders(ctx) });
  if (!res.ok) throw new Error("Failed to load discounted");
  return normalizeProductsResponse(await res.json());
}

/** Popular / new arrivals. Used by the "Latest" rail. */
export async function fetchPopular(
  ctx: StoreContextData,
): Promise<ProductsResponse> {
  const url = `${BASE_URL}/items/popular?store_id=${ctx.storeId}&offset=1&limit=20`;
  const res = await fetch(url, { headers: buildHeaders(ctx) });
  if (!res.ok) throw new Error("Failed to load popular");
  return normalizeProductsResponse(await res.json());
}

/** Fetch full product details (incl. variations/attributes) by item ID. */
export async function fetchProductDetails(
  ctx: StoreContextData,
  productId: number | string,
): Promise<Product & Record<string, unknown>> {
  const url = `${BASE_URL}/items/details/${productId}`;
  const res = await fetch(url, { headers: buildHeaders(ctx) });
  if (!res.ok) throw new Error("Failed to load product");
  return res.json();
}

/** Top-level categories only (parent_id falsy or 0). */
export function getTopLevelCategories(cats: StoreCategory[]): StoreCategory[] {
  return cats.filter((c) => !c.parent_id);
}

/** Direct children of a given category. */
export function getSubCategories(
  cats: StoreCategory[],
  parentId: number,
): StoreCategory[] {
  return cats.filter((c) => Number(c.parent_id) === Number(parentId));
}

export function getDiscountedPrice(p: Product): {
  final: number;
  hasDiscount: boolean;
  pct: number;
} {
  const productDiscount =
    p.discount_type === "percent" ? (p.price * p.discount) / 100 : p.discount;
  const final = Math.max(0, p.price - productDiscount);
  const pct =
    p.price > 0 ? Math.round(((p.price - final) / p.price) * 100) : 0;
  return { final, hasDiscount: productDiscount > 0, pct };
}

export function formatPrice(value: number): string {
  return `${Number(value).toLocaleString("ar-EG", { maximumFractionDigits: 2 })} ج.م`;
}

/**
 * Apply per-store price overrides to a product list. Returns a new array with
 * the `price` field replaced by the vendor-defined price when present. The
 * original price is preserved on `__originalPrice` for UIs that want to show
 * a strike-through. Discount calculations continue to work because they use
 * the (now-overridden) `price` field.
 */
export function applyOverrides<T extends Product>(
  products: T[],
  overrides: Record<number, number>,
): (T & { __originalPrice?: number })[] {
  if (!overrides || Object.keys(overrides).length === 0) return products;
  return products.map((p) => {
    const override = overrides[p.id];
    if (override === undefined || override === p.price) return p;
    return { ...p, price: override, __originalPrice: p.price };
  });
}

/** Extract a usable StoreContextData from a fetched StoreDetails. */
export function buildStoreContext(store: StoreDetails): StoreContextData {
  const zoneRaw = store.zone_id ?? store.zone?.id ?? 1;
  const zoneId = Array.isArray(zoneRaw) ? Number(zoneRaw[0]) : Number(zoneRaw);
  const moduleId = Number(store.module_id ?? store.module?.id ?? 1);
  return {
    slug: store.slug,
    storeId: store.id,
    zoneId: Number.isFinite(zoneId) ? zoneId : 1,
    moduleId: Number.isFinite(moduleId) ? moduleId : 1,
    latitude: String(store.latitude ?? DEFAULT_LAT),
    longitude: String(store.longitude ?? DEFAULT_LNG),
  };
}
