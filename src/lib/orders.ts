import type { CartItem } from "@/context/CartContext";

export type OrderStage = "received" | "preparing" | "out_for_delivery" | "completed";

export interface DeliverySlot {
  day: "today" | "tomorrow" | "after_tomorrow";
  dayLabel: string;
  window: string;
}

export interface Order {
  id: string;
  storeSlug: string;
  storeName?: string;
  storeLogo?: string;
  createdAt: number;
  items: CartItem[];
  subtotal: number;
  customer: {
    name: string;
    phone: string;
    address: string;
    notes?: string;
  };
  slot: DeliverySlot;
  paymentMethod?: "cod" | "offline";
  stage: OrderStage;
  nextStageAt: number;
}

const STORAGE_KEY = "shoplanser_orders_v1";
const STAGE_INTERVAL_MS = 30_000;

export const STAGES: { key: OrderStage; label: string }[] = [
  { key: "received", label: "تم استلام الطلب" },
  { key: "preparing", label: "قيد التحضير" },
  { key: "out_for_delivery", label: "في الطريق إليك" },
  { key: "completed", label: "تم التسليم" },
];

export function loadOrders(storeSlug?: string): Order[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) {
      // Migrate legacy single-store orders if present
      const legacy = localStorage.getItem("hashem_orders_v1");
      if (legacy) {
        const parsed = JSON.parse(legacy) as Order[];
        const migrated = parsed.map((o) => ({ ...o, storeSlug: o.storeSlug ?? "hashem" }));
        localStorage.setItem(STORAGE_KEY, JSON.stringify(migrated));
        localStorage.removeItem("hashem_orders_v1");
        return storeSlug ? migrated.filter((o) => o.storeSlug === storeSlug) : migrated;
      }
      return [];
    }
    const all = JSON.parse(raw) as Order[];
    return storeSlug ? all.filter((o) => o.storeSlug === storeSlug) : all;
  } catch {
    return [];
  }
}

function saveAll(orders: Order[]) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(orders));
  } catch {
    /* ignore */
  }
}

export function addOrder(order: Order) {
  const all = loadOrders();
  all.unshift(order);
  saveAll(all.slice(0, 50));
}

export function getOrder(id: string): Order | undefined {
  return loadOrders().find((o) => o.id === id);
}

export function getLatestOrder(storeSlug?: string): Order | undefined {
  return loadOrders(storeSlug)[0];
}

export function updateOrder(id: string, patch: Partial<Order>) {
  const all = loadOrders();
  const idx = all.findIndex((o) => o.id === id);
  if (idx >= 0) {
    all[idx] = { ...all[idx], ...patch };
    saveAll(all);
  }
}

export function nextStage(stage: OrderStage): OrderStage {
  const i = STAGES.findIndex((s) => s.key === stage);
  if (i < 0 || i >= STAGES.length - 1) return "completed";
  return STAGES[i + 1].key;
}

export function stageIndex(stage: OrderStage): number {
  return STAGES.findIndex((s) => s.key === stage);
}

export function advanceStageIfDue(order: Order): Order {
  if (order.stage === "completed") return order;
  let updated = order;
  while (updated.stage !== "completed" && Date.now() >= updated.nextStageAt) {
    updated = {
      ...updated,
      stage: nextStage(updated.stage),
      nextStageAt: Date.now() + STAGE_INTERVAL_MS,
    };
  }
  return updated;
}

export function generateOrderId(storeSlug: string): string {
  const ts = Date.now().toString(36).toUpperCase();
  const rand = Math.random().toString(36).slice(2, 6).toUpperCase();
  const prefix = storeSlug.slice(0, 4).toUpperCase();
  return `${prefix}-${ts}-${rand}`;
}

export const STAGE_TICK_MS = STAGE_INTERVAL_MS;
