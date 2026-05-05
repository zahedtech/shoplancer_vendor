import { useEffect, useState } from "react";
import { Activity, Trash2, X } from "lucide-react";
import {
  readVitalsSamples,
  clearVitalsSamples,
  ratingFor,
  VITALS_THRESHOLDS,
  type VitalsSample,
} from "@/lib/webVitals";

const METRIC_KEYS = ["LCP", "CLS", "INP", "FCP", "TTFB"] as const;
type MetricKey = (typeof METRIC_KEYS)[number];

const fmt = (k: MetricKey, v?: number) => {
  if (v == null) return "—";
  if (k === "CLS") return v.toFixed(3);
  return `${Math.round(v)} ms`;
};

const ratingClass = (r: string) =>
  r === "good"
    ? "bg-fresh/15 text-fresh border-fresh/40"
    : r === "needs-improvement"
      ? "bg-accent/15 text-accent border-accent/40"
      : "bg-discount/15 text-discount border-discount/40";

/**
 * Internal Web Vitals dashboard — visible only when the URL contains
 * `?vitals=1` (or in dev). Floats above the UI and shows the latest sample
 * + history so you can verify CLS/LCP/INP improvements after each deploy.
 */
export const WebVitalsDashboard = () => {
  const [open, setOpen] = useState(false);
  const [samples, setSamples] = useState<VitalsSample[]>([]);
  const [enabled, setEnabled] = useState(false);

  useEffect(() => {
    if (typeof window === "undefined") return;
    const params = new URLSearchParams(window.location.search);
    const flag =
      params.get("vitals") === "1" ||
      window.localStorage.getItem("lovable_vitals_dashboard") === "1";
    setEnabled(flag || import.meta.env.DEV);
    if (params.get("vitals") === "1") {
      window.localStorage.setItem("lovable_vitals_dashboard", "1");
    }
  }, []);

  useEffect(() => {
    if (!enabled) return;
    const refresh = () => setSamples(readVitalsSamples());
    refresh();
    const onVital = () => refresh();
    window.addEventListener("lovable:web-vital", onVital);
    const interval = window.setInterval(refresh, 2000);
    return () => {
      window.removeEventListener("lovable:web-vital", onVital);
      window.clearInterval(interval);
    };
  }, [enabled]);

  if (!enabled) return null;

  const latest = samples[samples.length - 1];
  const history = samples.slice(-10).reverse();

  return (
    <div className="fixed bottom-4 left-4 z-[60]" dir="ltr">
      {!open ? (
        <button
          onClick={() => setOpen(true)}
          className="h-10 px-3 rounded-full bg-primary text-primary-foreground inline-flex items-center gap-2 shadow-glow text-xs font-bold"
          aria-label="Open Web Vitals"
        >
          <Activity className="h-4 w-4" />
          Vitals
        </button>
      ) : (
        <div className="w-[340px] max-h-[80vh] overflow-auto bg-card border border-border rounded-2xl shadow-card p-3 text-xs">
          <div className="flex items-center justify-between mb-2">
            <div className="inline-flex items-center gap-2 font-extrabold">
              <Activity className="h-4 w-4 text-primary" />
              <span>Web Vitals</span>
            </div>
            <div className="flex items-center gap-1">
              <button
                onClick={() => {
                  clearVitalsSamples();
                  setSamples([]);
                }}
                aria-label="Clear samples"
                className="h-7 w-7 inline-flex items-center justify-center rounded-md hover:bg-muted"
              >
                <Trash2 className="h-3.5 w-3.5" />
              </button>
              <button
                onClick={() => setOpen(false)}
                aria-label="Close"
                className="h-7 w-7 inline-flex items-center justify-center rounded-md hover:bg-muted"
              >
                <X className="h-4 w-4" />
              </button>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-2 mb-3">
            {METRIC_KEYS.map((k) => {
              const v = latest?.metrics[k];
              const r = v != null ? ratingFor(k, v) : "good";
              return (
                <div
                  key={k}
                  className={`border rounded-xl p-2 ${ratingClass(v != null ? r : "")}`}
                >
                  <div className="text-[10px] font-bold opacity-70">{k}</div>
                  <div className="font-extrabold text-sm">{fmt(k, v)}</div>
                  <div className="text-[9px] opacity-70">
                    good ≤ {k === "CLS" ? VITALS_THRESHOLDS[k].good : `${VITALS_THRESHOLDS[k].good}ms`}
                  </div>
                </div>
              );
            })}
          </div>

          <div className="font-extrabold mb-1 text-[11px] text-muted-foreground">
            History (last {history.length})
          </div>
          <div className="space-y-1">
            {history.length === 0 && (
              <div className="text-muted-foreground">No samples yet…</div>
            )}
            {history.map((s, i) => (
              <div
                key={s.ts + "-" + i}
                className="flex items-center justify-between gap-2 border border-border/60 rounded-md px-2 py-1"
              >
                <div className="min-w-0">
                  <div className="font-bold truncate">{s.url}</div>
                  <div className="text-[9px] text-muted-foreground">
                    {new Date(s.ts).toLocaleTimeString()} · {s.buildId}
                  </div>
                </div>
                <div className="text-[10px] text-end shrink-0">
                  <div>LCP {fmt("LCP", s.metrics.LCP)}</div>
                  <div>CLS {fmt("CLS", s.metrics.CLS)}</div>
                  <div>INP {fmt("INP", s.metrics.INP)}</div>
                </div>
              </div>
            ))}
          </div>

          <div className="mt-3 text-[10px] text-muted-foreground">
            Tip: append <code>?vitals=1</code> to any URL to enable this panel.
          </div>
        </div>
      )}
    </div>
  );
};
