import type { Product } from "@/lib/api";

/**
 * Extract size options from a product's variations / attributes.
 * Shoplanser commonly uses one of: `variations`, `attributes`, `choice_options`.
 * We match attribute names containing "size" or "مقاس", and fall back to
 * pattern-matching common size tokens (S/M/L/XL/numeric).
 */
const SIZE_TOKEN_RE = /^(XXS|XS|S|M|L|XL|XXL|XXXL|3XL|4XL|5XL|\d{2,3})$/i;
const SIZE_NAME_RE = /size|مقاس|sizes|مقاسات|talla/i;

export function extractSizesFromProduct(product: Product | null | undefined): string[] {
  if (!product) return [];
  const raw = product as unknown as Record<string, unknown>;
  const out = new Set<string>();

  const pushVal = (v: unknown) => {
    if (typeof v === "string" || typeof v === "number") {
      const s = String(v).trim();
      if (s) out.add(s);
    }
  };

  // 1) choice_options: [{ name, title, options: [...] }]
  const choice = raw.choice_options as Array<Record<string, unknown>> | undefined;
  if (Array.isArray(choice)) {
    for (const c of choice) {
      const name = String(c?.name ?? c?.title ?? "");
      if (SIZE_NAME_RE.test(name)) {
        const opts = (c.options ?? c.values) as unknown;
        if (Array.isArray(opts)) opts.forEach(pushVal);
      }
    }
  }

  // 2) attributes: [{ name, values | options }]
  const attrs = raw.attributes as Array<Record<string, unknown>> | undefined;
  if (Array.isArray(attrs)) {
    for (const a of attrs) {
      const name = String(a?.name ?? a?.title ?? "");
      if (SIZE_NAME_RE.test(name)) {
        const opts = (a.values ?? a.options) as unknown;
        if (Array.isArray(opts)) {
          opts.forEach((v) => {
            if (typeof v === "object" && v !== null) {
              pushVal((v as Record<string, unknown>).name ?? (v as Record<string, unknown>).value);
            } else {
              pushVal(v);
            }
          });
        }
      }
    }
  }

  // 3) variations: [{ type, ... }] — extract values whose label looks like a size
  const vars = raw.variations as Array<Record<string, unknown>> | undefined;
  if (Array.isArray(vars)) {
    for (const v of vars) {
      const type = String(v?.type ?? v?.name ?? "");
      if (type && SIZE_TOKEN_RE.test(type)) out.add(type);
      // Some Shoplanser tenants nest values
      const values = (v as Record<string, unknown>).values;
      if (Array.isArray(values)) {
        values.forEach((x) => {
          if (typeof x === "string" && SIZE_TOKEN_RE.test(x)) out.add(x);
        });
      }
    }
  }

  // Sort: keep size order S<M<L<XL... then numeric
  const order = ["XXS", "XS", "S", "M", "L", "XL", "XXL", "XXXL", "3XL", "4XL", "5XL"];
  return Array.from(out).sort((a, b) => {
    const ia = order.indexOf(a.toUpperCase());
    const ib = order.indexOf(b.toUpperCase());
    if (ia !== -1 && ib !== -1) return ia - ib;
    if (ia !== -1) return -1;
    if (ib !== -1) return 1;
    const na = Number(a);
    const nb = Number(b);
    if (Number.isFinite(na) && Number.isFinite(nb)) return na - nb;
    return a.localeCompare(b);
  });
}
