/**
 * Web Vitals tracking — captures LCP, CLS, INP, FCP, TTFB across sessions
 * and stores rolling samples in localStorage so the in-app dashboard can
 * show trends after each deploy. Also forwards to console in dev and
 * dispatches a window event so any analytics integration can subscribe.
 */
import type { Metric } from "web-vitals";

const STORAGE_KEY = "lovable_web_vitals_v1";
const MAX_SAMPLES = 50;

export interface VitalsSample {
  ts: number;
  url: string;
  buildId: string;
  metrics: Partial<Record<"LCP" | "CLS" | "INP" | "FCP" | "TTFB", number>>;
}

interface CurrentSession {
  ts: number;
  url: string;
  buildId: string;
  metrics: VitalsSample["metrics"];
}

const session: CurrentSession = {
  ts: Date.now(),
  url: typeof window !== "undefined" ? window.location.pathname : "/",
  buildId:
    (typeof document !== "undefined" &&
      document
        .querySelector<HTMLMetaElement>('meta[name="build-id"]')
        ?.content) ||
    "dev",
  metrics: {},
};

const persist = () => {
  if (typeof window === "undefined") return;
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    const list: VitalsSample[] = raw ? JSON.parse(raw) : [];
    // Replace last sample if same session, otherwise append
    const last = list[list.length - 1];
    if (last && last.ts === session.ts) {
      list[list.length - 1] = { ...session };
    } else {
      list.push({ ...session });
    }
    while (list.length > MAX_SAMPLES) list.shift();
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(list));
  } catch {
    /* storage may be disabled */
  }
};

const handleMetric = (m: Metric) => {
  const key = m.name as keyof VitalsSample["metrics"];
  session.metrics[key] = Math.round(m.value * 1000) / 1000;
  persist();

  if (typeof window !== "undefined") {
    window.dispatchEvent(
      new CustomEvent("lovable:web-vital", { detail: { name: m.name, value: m.value, id: m.id } }),
    );
  }
  if (import.meta.env.DEV) {
    console.log(`[vitals] ${m.name}=${m.value.toFixed(3)} (${m.rating})`);
  }
};

let started = false;
export const initWebVitals = async () => {
  if (started || typeof window === "undefined") return;
  started = true;
  try {
    const { onLCP, onCLS, onINP, onFCP, onTTFB } = await import("web-vitals");
    onLCP(handleMetric);
    onCLS(handleMetric);
    onINP(handleMetric);
    onFCP(handleMetric);
    onTTFB(handleMetric);
  } catch {
    /* non-fatal */
  }
};

export const readVitalsSamples = (): VitalsSample[] => {
  if (typeof window === "undefined") return [];
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    return raw ? (JSON.parse(raw) as VitalsSample[]) : [];
  } catch {
    return [];
  }
};

export const clearVitalsSamples = () => {
  if (typeof window === "undefined") return;
  try {
    window.localStorage.removeItem(STORAGE_KEY);
  } catch {
    /* noop */
  }
};

export const VITALS_THRESHOLDS = {
  LCP: { good: 2500, poor: 4000 },
  CLS: { good: 0.1, poor: 0.25 },
  INP: { good: 200, poor: 500 },
  FCP: { good: 1800, poor: 3000 },
  TTFB: { good: 800, poor: 1800 },
} as const;

export const ratingFor = (
  name: keyof typeof VITALS_THRESHOLDS,
  value: number,
): "good" | "needs-improvement" | "poor" => {
  const t = VITALS_THRESHOLDS[name];
  if (value <= t.good) return "good";
  if (value <= t.poor) return "needs-improvement";
  return "poor";
};
