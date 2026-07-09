import { useEffect } from "react";

interface UseDynamicManifestOptions {
  name?: string;
  shortName?: string;
  description?: string;
  logoUrl?: string;
  themeColor?: string;
}

/**
 * Generates a per-store PWA manifest at runtime and swaps the document's
 * <link rel="manifest"> to point at it. This way, when a user installs the
 * app from a specific store URL (e.g. /nsaem), their home-screen icon shows
 * the **store's** name instead of the generic platform name.
 *
 * Also keeps `apple-mobile-web-app-title` in sync so iOS "Add to Home Screen"
 * shows the correct label.
 */
export const useDynamicManifest = ({
  name,
  shortName,
  description,
  logoUrl,
  themeColor,
}: UseDynamicManifestOptions) => {
  useEffect(() => {
    if (!name) return;
    if (typeof window === "undefined") return;

    const icons = logoUrl
      ? [
          // Use the store logo as the install icon when available.
          { src: logoUrl, sizes: "192x192", type: "image/png", purpose: "any" },
          { src: logoUrl, sizes: "512x512", type: "image/png", purpose: "any" },
        ]
      : [
          { src: "/icon-192.png", sizes: "192x192", type: "image/png", purpose: "any" },
          { src: "/icon-512.png", sizes: "512x512", type: "image/png", purpose: "any" },
        ];

    const manifest = {
      name,
      short_name: (shortName ?? name).slice(0, 12),
      description: description ?? name,
      lang: "ar",
      dir: "rtl",
      start_url: window.location.pathname,
      scope: window.location.pathname,
      display: "standalone",
      orientation: "portrait",
      background_color: "#fafaf3",
      theme_color: themeColor ?? "#466600",
      icons,
    };

    const blob = new Blob([JSON.stringify(manifest)], {
      type: "application/manifest+json",
    });
    const url = URL.createObjectURL(blob);

    // Swap the manifest <link> to our dynamic one.
    let link = document.querySelector<HTMLLinkElement>('link[rel="manifest"]');
    const previousHref = link?.getAttribute("href") ?? null;
    if (!link) {
      link = document.createElement("link");
      link.rel = "manifest";
      document.head.appendChild(link);
    }
    link.href = url;

    // Update iOS title shown under the home-screen icon.
    let appleTitle = document.querySelector<HTMLMetaElement>(
      'meta[name="apple-mobile-web-app-title"]',
    );
    const previousAppleTitle = appleTitle?.getAttribute("content") ?? null;
    if (!appleTitle) {
      appleTitle = document.createElement("meta");
      appleTitle.name = "apple-mobile-web-app-title";
      document.head.appendChild(appleTitle);
    }
    appleTitle.content = name;

    // Swap favicon + apple-touch-icon to the store logo so the browser tab
    // and iOS home-screen icon match the store identity.
    const previousIcons: Array<{ el: HTMLLinkElement; href: string }> = [];
    if (logoUrl) {
      const iconSelectors = [
        'link[rel="icon"]',
        'link[rel="shortcut icon"]',
        'link[rel="apple-touch-icon"]',
      ];
      iconSelectors.forEach((sel) => {
        document.querySelectorAll<HTMLLinkElement>(sel).forEach((el) => {
          previousIcons.push({ el, href: el.href });
          el.href = logoUrl;
        });
      });
    }

    // Update Open Graph / Twitter meta so in-app share previews (where
    // available) show the store's name + logo.
    const metaUpdates: Array<{ el: HTMLMetaElement; attr: string; prev: string }> = [];
    const setMeta = (selector: string, attr: "content", value: string) => {
      const el = document.querySelector<HTMLMetaElement>(selector);
      if (!el) return;
      metaUpdates.push({ el, attr, prev: el.getAttribute(attr) ?? "" });
      el.setAttribute(attr, value);
    };
    setMeta('meta[property="og:title"]', "content", name);
    setMeta('meta[name="twitter:title"]', "content", name);
    if (description) {
      setMeta('meta[property="og:description"]', "content", description);
      setMeta('meta[name="twitter:description"]', "content", description);
    }
    if (logoUrl) {
      setMeta('meta[property="og:image"]', "content", logoUrl);
      setMeta('meta[name="twitter:image"]', "content", logoUrl);
    }

    return () => {
      URL.revokeObjectURL(url);
      // Restore previous manifest so leaving the store doesn't pin its name.
      if (link && previousHref) link.href = previousHref;
      if (appleTitle && previousAppleTitle) appleTitle.content = previousAppleTitle;
      previousIcons.forEach(({ el, href }) => {
        el.href = href;
      });
      metaUpdates.forEach(({ el, attr, prev }) => {
        if (prev) el.setAttribute(attr, prev);
      });
    };
  }, [name, shortName, description, logoUrl, themeColor]);
};
