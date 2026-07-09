// Per-store search history persisted in localStorage.
const KEY = (slug: string) => `search_history_${slug}_v1`;
const MAX = 8;

export function getRecentSearches(slug: string): string[] {
  try {
    const raw = localStorage.getItem(KEY(slug));
    if (!raw) return [];
    const arr = JSON.parse(raw);
    return Array.isArray(arr) ? (arr as string[]).slice(0, MAX) : [];
  } catch {
    return [];
  }
}

export function pushRecentSearch(slug: string, query: string) {
  const q = (query || "").trim();
  if (!q) return;
  const current = getRecentSearches(slug).filter(
    (s) => s.toLowerCase() !== q.toLowerCase(),
  );
  const next = [q, ...current].slice(0, MAX);
  try {
    localStorage.setItem(KEY(slug), JSON.stringify(next));
  } catch {
    /* ignore */
  }
}

export function clearRecentSearches(slug: string) {
  try {
    localStorage.removeItem(KEY(slug));
  } catch {
    /* ignore */
  }
}
