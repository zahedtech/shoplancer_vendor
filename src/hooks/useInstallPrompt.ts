import { useEffect, useState, useCallback } from "react";

interface BeforeInstallPromptEvent extends Event {
  prompt: () => Promise<void>;
  userChoice: Promise<{ outcome: "accepted" | "dismissed" }>;
}

const DISMISS_KEY = "installPrompt:dismissedAt";
const DISMISS_TTL_MS = 1000 * 60 * 60 * 24 * 7; // 7 days

/**
 * Tracks the browser's `beforeinstallprompt` event so the UI can offer an
 * "Install app" affordance. Also detects iOS Safari (which doesn't fire the
 * event) and standalone mode so we can hide the prompt once installed.
 */
export const useInstallPrompt = () => {
  const [deferred, setDeferred] = useState<BeforeInstallPromptEvent | null>(null);
  const [isStandalone, setIsStandalone] = useState(false);
  const [isIOS, setIsIOS] = useState(false);
  const [dismissed, setDismissed] = useState(false);

  useEffect(() => {
    // Detect already-installed standalone mode
    const mql = window.matchMedia?.("(display-mode: standalone)");
    const standalone =
      mql?.matches ||
      // iOS Safari
      (window.navigator as unknown as { standalone?: boolean }).standalone === true;
    setIsStandalone(!!standalone);

    // React to runtime changes (e.g. user just installed and the OS opens
    // the PWA in a standalone window) without needing a page refresh.
    const onDisplayModeChange = (e: MediaQueryListEvent) => {
      if (e.matches) {
        setIsStandalone(true);
        setDeferred(null);
      }
    };
    mql?.addEventListener?.("change", onDisplayModeChange);

    // Detect iOS (Safari install path is manual via Share menu)
    const ua = window.navigator.userAgent;
    setIsIOS(/iPad|iPhone|iPod/.test(ua) && !/CriOS|FxiOS/.test(ua));

    // Restore dismissal
    try {
      const raw = localStorage.getItem(DISMISS_KEY);
      if (raw) {
        const ts = Number(raw);
        if (Number.isFinite(ts) && Date.now() - ts < DISMISS_TTL_MS) {
          setDismissed(true);
        }
      }
    } catch {
      /* ignore */
    }

    const onBeforeInstall = (e: Event) => {
      e.preventDefault();
      setDeferred(e as BeforeInstallPromptEvent);
    };
    const onInstalled = () => {
      setDeferred(null);
      setIsStandalone(true);
    };

    window.addEventListener("beforeinstallprompt", onBeforeInstall);
    window.addEventListener("appinstalled", onInstalled);
    return () => {
      window.removeEventListener("beforeinstallprompt", onBeforeInstall);
      window.removeEventListener("appinstalled", onInstalled);
      mql?.removeEventListener?.("change", onDisplayModeChange);
    };
  }, []);

  const promptInstall = useCallback(async () => {
    if (!deferred) return false;
    await deferred.prompt();
    const choice = await deferred.userChoice;
    setDeferred(null);
    if (choice.outcome === "dismissed") {
      try {
        localStorage.setItem(DISMISS_KEY, String(Date.now()));
      } catch {
        /* ignore */
      }
      setDismissed(true);
    }
    return choice.outcome === "accepted";
  }, [deferred]);

  const dismiss = useCallback(() => {
    try {
      localStorage.setItem(DISMISS_KEY, String(Date.now()));
    } catch {
      /* ignore */
    }
    setDismissed(true);
  }, []);

  // Can install via native prompt
  const canInstall = !!deferred && !isStandalone;
  // Should we show the iOS hint? iOS, not standalone, not dismissed
  const shouldShowIOSHint = isIOS && !isStandalone && !dismissed;
  // Whether to show ANY install affordance
  const isInstallable = (canInstall || shouldShowIOSHint) && !dismissed;

  return {
    canInstall,
    isIOS,
    isStandalone,
    isInstallable,
    shouldShowIOSHint,
    promptInstall,
    dismiss,
  };
};
