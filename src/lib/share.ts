// Build a shareable URL for a store/page that returns proper Open Graph
// meta tags to social media crawlers (WhatsApp, Facebook, Telegram, etc.)
// and redirects real users to the SPA route.
//
// The link points at our `store-meta` edge function. Crawlers stop at the
// HTML and pick up the OG tags; humans get a sub-100ms JS redirect to the
// real app URL.

// Public marketing/sharing domain. Shared links use the canonical URL:
// https://market.shoplanser.com/store/{slug}
const PUBLIC_SHARE_BASE = "https://market.shoplanser.com";

/**
 * Build the canonical public URL for a store, used for sharing/links.
 */
export function buildPublicStoreUrl(slug: string, extraPath = ""): string {
  const suffix = extraPath && !extraPath.startsWith("/") ? `/${extraPath}` : extraPath;
  return `${PUBLIC_SHARE_BASE}/store/${slug}${suffix}`;
}

/**
 * Build the shareable public URL for a store. Always returns the canonical
 * marketing URL: https://market.shoplanser.com/store/{slug}
 *
 * @param slug  Store slug (required).
 * @param path  Optional path override (defaults to `/store/${slug}`).
 */
export function buildShareUrl(slug: string, path?: string): string {
  const target = path ?? `/store/${slug}`;
  const suffix = target.startsWith("/") ? target : `/${target}`;
  return `${PUBLIC_SHARE_BASE}${suffix}`;
}

/**
 * Fire the native Web Share sheet (or copy to clipboard as a fallback)
 * with a link that produces correct social previews.
 */
export async function shareStoreLink(opts: {
  slug: string;
  path?: string;
  title: string;
  text?: string;
}): Promise<"shared" | "copied" | "failed"> {
  const url = buildShareUrl(opts.slug, opts.path);
  const data = { title: opts.title, text: opts.text ?? opts.title, url };
  try {
    const nav = typeof navigator !== "undefined" ? (navigator as Navigator) : null;
    if (nav && "share" in nav) {
      await nav.share(data);
      return "shared";
    }
    if (nav && nav.clipboard) {
      await nav.clipboard.writeText(url);
      return "copied";
    }
    return "failed";
  } catch {
    return "failed";
  }
}
