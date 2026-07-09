// Saved addresses, kept in localStorage. The first one is treated as default.
const KEY = "shoplanser_addresses_v1";

export interface Address {
  id: string;
  label?: string;       // e.g. البيت / الشغل
  address: string;      // the actual line
  notes?: string;       // landmark, floor…
}

export function loadAddresses(): Address[] {
  try {
    const raw = localStorage.getItem(KEY);
    return raw ? (JSON.parse(raw) as Address[]) : [];
  } catch {
    return [];
  }
}

function saveAll(list: Address[]) {
  try {
    localStorage.setItem(KEY, JSON.stringify(list));
  } catch {
    /* ignore */
  }
}

function genId() {
  return `addr_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 6)}`;
}

export function addAddress(input: Omit<Address, "id">): Address {
  const all = loadAddresses();
  const next: Address = { ...input, id: genId() };
  all.unshift(next);
  saveAll(all);
  return next;
}

export function updateAddress(id: string, patch: Partial<Address>) {
  const all = loadAddresses();
  const idx = all.findIndex((a) => a.id === id);
  if (idx >= 0) {
    all[idx] = { ...all[idx], ...patch, id };
    saveAll(all);
  }
}

export function deleteAddress(id: string) {
  saveAll(loadAddresses().filter((a) => a.id !== id));
}

export function setDefaultAddress(id: string) {
  const all = loadAddresses();
  const idx = all.findIndex((a) => a.id === id);
  if (idx <= 0) return;
  const [picked] = all.splice(idx, 1);
  all.unshift(picked);
  saveAll(all);
}

export function getDefaultAddress(): Address | undefined {
  return loadAddresses()[0];
}
