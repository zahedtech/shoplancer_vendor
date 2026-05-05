import { useEffect, useState } from "react";
import { useStore } from "@/context/StoreContext";
import { ShoppingBag, Clock, CheckCircle2, XCircle } from "lucide-react";
import { formatPrice } from "@/lib/api";

interface LocalOrder {
  id: string;
  store_slug: string;
  total: number;
  items_count: number;
  status: "pending" | "delivered" | "cancelled";
  created_at: string;
  customer_phone?: string;
}

// Read orders saved by the storefront's checkout flow (lib/orders.ts).
function readLocalOrders(slug: string): LocalOrder[] {
  if (typeof window === "undefined") return [];
  try {
    const raw = window.localStorage.getItem("orders_v1") || "[]";
    const all = JSON.parse(raw) as LocalOrder[];
    return all.filter((o) => o.store_slug === slug);
  } catch {
    return [];
  }
}

const statusMeta = {
  pending: { label: "قيد التنفيذ", color: "text-accent", bg: "bg-accent/10", icon: Clock },
  delivered: { label: "تم التوصيل", color: "text-fresh", bg: "bg-fresh/10", icon: CheckCircle2 },
  cancelled: { label: "ملغي", color: "text-destructive", bg: "bg-destructive/10", icon: XCircle },
};

export default function VendorOrders() {
  const { slug } = useStore();
  const [orders, setOrders] = useState<LocalOrder[]>([]);

  useEffect(() => {
    setOrders(readLocalOrders(slug));
    const handler = () => setOrders(readLocalOrders(slug));
    window.addEventListener("storage", handler);
    return () => window.removeEventListener("storage", handler);
  }, [slug]);

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-extrabold">الطلبات</h2>
        <p className="text-sm text-muted-foreground mt-1">
          جميع طلبات متجرك. عند ربط Vendor API ستُجلب من السيرفر مباشرة.
        </p>
      </div>

      {orders.length === 0 ? (
        <div className="bg-card rounded-2xl border border-border p-12 text-center">
          <ShoppingBag className="h-12 w-12 text-muted-foreground mx-auto mb-3" />
          <p className="text-muted-foreground">لا توجد طلبات بعد لمتجرك.</p>
          <p className="text-xs text-muted-foreground mt-2">
            الطلبات الجديدة من الواجهة ستظهر هنا.
          </p>
        </div>
      ) : (
        <div className="bg-card rounded-2xl border border-border overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-muted/50 text-right">
              <tr>
                <th className="p-3 font-bold">رقم الطلب</th>
                <th className="p-3 font-bold">العميل</th>
                <th className="p-3 font-bold">المنتجات</th>
                <th className="p-3 font-bold">الإجمالي</th>
                <th className="p-3 font-bold">الحالة</th>
                <th className="p-3 font-bold">التاريخ</th>
              </tr>
            </thead>
            <tbody>
              {orders.map((o) => {
                const meta = statusMeta[o.status] ?? statusMeta.pending;
                const Icon = meta.icon;
                return (
                  <tr key={o.id} className="border-t border-border hover:bg-muted/30">
                    <td className="p-3 font-mono text-xs">#{o.id.slice(0, 8)}</td>
                    <td className="p-3">{o.customer_phone ?? "—"}</td>
                    <td className="p-3">{o.items_count}</td>
                    <td className="p-3 font-extrabold text-primary">{formatPrice(o.total)}</td>
                    <td className="p-3">
                      <span
                        className={`inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-bold ${meta.bg} ${meta.color}`}
                      >
                        <Icon className="h-3 w-3" /> {meta.label}
                      </span>
                    </td>
                    <td className="p-3 text-xs text-muted-foreground">
                      {new Date(o.created_at).toLocaleString("ar-EG")}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
