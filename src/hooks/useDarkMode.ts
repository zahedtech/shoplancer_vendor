import { useEffect, useState } from "react";

const KEY = "shoplanser_dark_mode_v1";

function readPref(): boolean {
  try {
    const raw = localStorage.getItem(KEY);
    if (raw === "1") return true;
    if (raw === "0") return false;
  } catch {
    /* ignore */
  }
  if (typeof window !== "undefined" && window.matchMedia) {
    return window.matchMedia("(prefers-color-scheme: dark)").matches;
  }
  return false;
}

function applyClass(enabled: boolean) {
  if (typeof document === "undefined") return;
  document.documentElement.classList.toggle("dark", enabled);
}

export function useDarkMode(): [boolean, (v: boolean) => void] {
  const [enabled, setEnabled] = useState<boolean>(() => readPref());

  useEffect(() => {
    applyClass(enabled);
    try {
      localStorage.setItem(KEY, enabled ? "1" : "0");
    } catch {
      /* ignore */
    }
  }, [enabled]);

  return [enabled, setEnabled];
}
