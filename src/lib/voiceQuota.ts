// Client-side throttle for voice search to protect the workspace AI quota.
// Stores timestamps of recent uses in localStorage and exposes helpers to
// know how many attempts the user has left in the current hour/day.

const KEY = "voice_quota_uses_v1";
export const MAX_PER_HOUR = 20;
export const MAX_PER_DAY = 60;

const HOUR_MS = 60 * 60 * 1000;
const DAY_MS = 24 * HOUR_MS;

function readAll(): number[] {
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return [];
    const arr = JSON.parse(raw);
    if (!Array.isArray(arr)) return [];
    const cutoff = Date.now() - DAY_MS;
    return (arr as number[]).filter((n) => typeof n === "number" && n >= cutoff);
  } catch {
    return [];
  }
}

function writeAll(list: number[]) {
  try {
    localStorage.setItem(KEY, JSON.stringify(list));
  } catch {
    /* ignore */
  }
}

export interface QuotaInfo {
  remainingHour: number;
  remainingDay: number;
  resetInMs: number; // ms until the most relevant cap frees a slot
  blocked: boolean;
}

export function getQuota(): QuotaInfo {
  const now = Date.now();
  const all = readAll();
  const hourUses = all.filter((t) => t >= now - HOUR_MS);
  const remainingHour = Math.max(0, MAX_PER_HOUR - hourUses.length);
  const remainingDay = Math.max(0, MAX_PER_DAY - all.length);
  const blocked = remainingHour === 0 || remainingDay === 0;

  let resetInMs = 0;
  if (remainingHour === 0 && hourUses.length > 0) {
    resetInMs = Math.max(0, hourUses[0] + HOUR_MS - now);
  } else if (remainingDay === 0 && all.length > 0) {
    resetInMs = Math.max(0, all[0] + DAY_MS - now);
  }
  return { remainingHour, remainingDay, resetInMs, blocked };
}

export function recordVoiceUse() {
  const all = readAll();
  all.push(Date.now());
  writeAll(all);
}

export function formatResetIn(ms: number, locale: string): string {
  if (ms <= 0) return "";
  const min = Math.ceil(ms / 60000);
  if (min < 60) return locale === "en" ? `${min}m` : `${min} د`;
  const h = Math.ceil(min / 60);
  return locale === "en" ? `${h}h` : `${h} س`;
}
