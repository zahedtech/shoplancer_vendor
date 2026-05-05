// Edge function: serves pre-rendered HTML with proper Open Graph meta tags
// for social media crawlers (WhatsApp, Facebook, Twitter, Telegram, etc.)
// that don't execute JavaScript.
//
// Usage: This function is called via /functions/v1/store-meta?slug=<store-slug>&path=<original-path>
// It fetches store details from Shoplanser API and returns HTML with the
// store's name, logo, and description as meta tags. Real users get an
// immediate JS redirect to the SPA.

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "*",
};

const SHOPLANSER_API = "https://market.shoplanser.com/api/v1";
const APP_ORIGIN = "https://shoplansestore.lovable.app";

interface StoreDetails {
  name: string;
  logo_full_url?: string;
  cover_photo_full_url?: string;
  address?: string;
}

async function fetchStore(slug: string): Promise<StoreDetails | null> {
  try {
    const res = await fetch(`${SHOPLANSER_API}/stores/details/${slug}`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-localization": "ar",
        zoneId: "[1]",
        moduleId: "3",
        latitude: "29.92427564731563",
        longitude: "31.04896890845627",
      },
    });
    if (!res.ok) return null;
    return (await res.json()) as StoreDetails;
  } catch {
    return null;
  }
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function buildHtml(opts: {
  title: string;
  description: string;
  image: string;
  canonical: string;
  redirectTo: string;
}): string {
  const { title, description, image, canonical, redirectTo } = opts;
  const t = escapeHtml(title);
  const d = escapeHtml(description);
  const img = escapeHtml(image);
  const url = escapeHtml(canonical);
  const redir = escapeHtml(redirectTo);

  return `<!doctype html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>${t}</title>
  <meta name="description" content="${d}" />
  <link rel="canonical" href="${url}" />

  <meta property="og:type" content="website" />
  <meta property="og:site_name" content="${t}" />
  <meta property="og:title" content="${t}" />
  <meta property="og:description" content="${d}" />
  <meta property="og:image" content="${img}" />
  <meta property="og:image:secure_url" content="${img}" />
  <meta property="og:url" content="${url}" />

  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:title" content="${t}" />
  <meta name="twitter:description" content="${d}" />
  <meta name="twitter:image" content="${img}" />

  <meta http-equiv="refresh" content="0; url=${redir}" />
  <script>window.location.replace(${JSON.stringify(redirectTo)});</script>
</head>
<body>
  <p>Redirecting to <a href="${redir}">${t}</a>…</p>
</body>
</html>`;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  const url = new URL(req.url);
  const slug = url.searchParams.get("slug")?.trim();
  const rawPath = url.searchParams.get("path") ?? (slug ? `/store/${slug}` : "/");
  // Only accept relative paths (no scheme, no protocol-relative) to prevent
  // open-redirect via the `path` parameter.
  const path = /^\/(?!\/)/.test(rawPath) ? rawPath : (slug ? `/store/${slug}` : "/");
  // Always redirect to the trusted app origin — no caller-controlled base.
  const origin = APP_ORIGIN;

  if (!slug) {
    return new Response("Missing ?slug parameter", {
      status: 400,
      headers: corsHeaders,
    });
  }

  const store = await fetchStore(slug);
  const redirectTo = `${origin}${path.startsWith("/") ? path : `/${path}`}`;

  const title = store?.name
    ? `${store.name} — توصيل سريع`
    : "Shoplanser — توصيل سريع";
  const description = store?.address
    ? `${store.name} — ${store.address}. تسوق واحصل على توصيل سريع لباب منزلك.`
    : "تسوق من متاجرك المفضلة واحصل على توصيل سريع لباب منزلك عبر منصة Shoplanser.";
  const image =
    store?.cover_photo_full_url ||
    store?.logo_full_url ||
    "https://pub-bb2e103a32db4e198524a2e9ed8f35b4.r2.dev/dd789d78-c4c1-4c74-a52c-fa8a01fea07a/id-preview-7946de7b--7f0c4baa-daae-4e5b-bfd7-eafda875935e.lovable.app-1777205610759.png";

  const html = buildHtml({
    title,
    description,
    image,
    canonical: redirectTo,
    redirectTo,
  });

  return new Response(html, {
    status: 200,
    headers: {
      ...corsHeaders,
      "Content-Type": "text/html; charset=utf-8",
      "Cache-Control": "public, max-age=300, s-maxage=600",
    },
  });
});
