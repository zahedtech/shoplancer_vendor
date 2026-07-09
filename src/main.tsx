import { createRoot } from "react-dom/client";
import { HelmetProvider } from "react-helmet-async";
import App from "./App.tsx";
import "./index.css";
import "./lib/i18n";
import { initWebVitals } from "./lib/webVitals";

void initWebVitals();

// PWA: only register the service worker on the published/standalone site.
// Inside the Lovable preview iframe (or other embeds) we proactively unregister
// any existing SW to prevent stale-cache headaches in the editor.
const isInIframe = (() => {
  try {
    return window.self !== window.top;
  } catch {
    return true;
  }
})();
const isPreviewHost =
  typeof window !== "undefined" &&
  (window.location.hostname.includes("id-preview--") ||
    window.location.hostname.includes("lovableproject.com"));

if (typeof window !== "undefined" && "serviceWorker" in navigator) {
  if (isInIframe || isPreviewHost) {
    navigator.serviceWorker
      .getRegistrations()
      .then((regs) => regs.forEach((r) => r.unregister()))
      .catch(() => {
        /* non-fatal */
      });
  } else {
    // Lazy-load workbox-window so the preview build never pulls it.
    import("workbox-window")
      .then(({ Workbox }) => {
        const wb = new Workbox("/sw.js");
        wb.register().catch(() => {
          /* non-fatal */
        });
      })
      .catch(() => {
        /* non-fatal — PWA simply won't activate */
      });
  }
}

createRoot(document.getElementById("root")!).render(
  <HelmetProvider>
    <App />
  </HelmetProvider>,
);
