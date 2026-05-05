// Persists the user's last-chosen payment method so the next checkout
// pre-selects it. Stored locally per-device (not synced across devices).
const KEY = "shoplanser_payment_prefs_v1";

export type PaymentMethod = "cod" | "offline";

export interface PaymentPrefs {
  method: PaymentMethod;
}

const DEFAULT: PaymentPrefs = { method: "cod" };

export function getPaymentPrefs(): PaymentPrefs {
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return DEFAULT;
    const parsed = JSON.parse(raw) as Partial<PaymentPrefs>;
    return {
      method: parsed.method === "offline" ? "offline" : "cod",
    };
  } catch {
    return DEFAULT;
  }
}

export function savePaymentPrefs(prefs: PaymentPrefs) {
  try {
    localStorage.setItem(KEY, JSON.stringify(prefs));
  } catch {
    /* ignore */
  }
}
