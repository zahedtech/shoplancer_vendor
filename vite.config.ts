import { defineConfig } from "vite";
import react from "@vitejs/plugin-react-swc";
import path from "path";
import { componentTagger } from "lovable-tagger";
import { VitePWA } from "vite-plugin-pwa";

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => ({
  base: "/store/",
  server: {
    host: "::",
    port: 8080,
    hmr: {
      overlay: false,
    },
  },
  plugins: [
    react(),
    mode === "development" && componentTagger(),
    VitePWA({
      registerType: "autoUpdate",
      // Critical: never run the SW in dev/preview — the Lovable iframe will
      // otherwise serve stale builds and break navigation.
      devOptions: { enabled: false },
      filename: "sw.js",
      includeAssets: ["favicon.png", "icon-192.png", "icon-512.png"],
      manifest: false, // we ship our own at public/manifest.webmanifest
      workbox: {
        navigateFallback: "/store/index.html",
        navigateFallbackDenylist: [/^\/~oauth/, /^\/api\//],
        globPatterns: ["**/*.{js,css,html,svg,png,webp,woff2}"],
        runtimeCaching: [
          {
            // Google Fonts
            urlPattern: ({ url }) =>
              url.origin === "https://fonts.googleapis.com" ||
              url.origin === "https://fonts.gstatic.com",
            handler: "CacheFirst",
            options: {
              cacheName: "google-fonts",
              expiration: { maxEntries: 30, maxAgeSeconds: 60 * 60 * 24 * 365 },
            },
          },
          {
            // Shoplanser API → freshness-first, but offline-friendly
            urlPattern: ({ url }) => url.origin === "https://market.shoplanser.com",
            handler: "NetworkFirst",
            options: {
              cacheName: "shoplanser-api",
              networkTimeoutSeconds: 6,
              expiration: { maxEntries: 100, maxAgeSeconds: 60 * 60 * 24 },
            },
          },
          {
            // Product imagery & remote media
            urlPattern: ({ request }) => request.destination === "image",
            handler: "CacheFirst",
            options: {
              cacheName: "images",
              expiration: { maxEntries: 200, maxAgeSeconds: 60 * 60 * 24 * 30 },
            },
          },
        ],
      },
    }),
  ].filter(Boolean),
  build: {
    target: "es2020",
    cssCodeSplit: true,
    /**
     * Vite warns when any chunk > 500 kB. Aggressive manualChunks previously caused
     * vendor ↔ react-vendor circular imports (runtime: React/useState undefined).
     * We only split deps that do not pull React into a separate graph edge from React.
     */
    chunkSizeWarningLimit: 1100,
    rollupOptions: {
      output: {
        manualChunks(id) {
          if (!id.includes("node_modules")) return undefined;
          if (id.includes("@supabase")) return "supabase-vendor";
          if (id.includes("@tanstack")) return "query-vendor";
          if (id.includes("/zod/") || id.includes(`${path.sep}zod${path.sep}`))
            return "zod-vendor";
          return undefined;
        },
      },
    },
  },
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
    dedupe: ["react", "react-dom", "react/jsx-runtime", "react/jsx-dev-runtime", "@tanstack/react-query", "@tanstack/query-core"],
  },
}));
