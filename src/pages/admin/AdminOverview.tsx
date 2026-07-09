import { Link } from "react-router-dom";
import { Store, ShoppingBag, TrendingUp, Plus } from "lucide-react";
import { useStoresRegistry } from "@/hooks/useStoresRegistry";

const StatCard = ({
  icon: Icon,
  label,
  value,
  hint,
}: {
  icon: typeof Store;
  label: string;
  value: string | number;
  hint?: string;
}) => (
  <div className="bg-card rounded-2xl border border-border p-5 shadow-soft">
    <div className="flex items-center justify-between mb-3">
      <span className="text-sm text-muted-foreground">{label}</span>
      <div className="h-9 w-9 rounded-xl bg-primary-soft text-primary inline-flex items-center justify-center">
        <Icon className="h-4 w-4" />
      </div>
    </div>
    <div className="text-3xl font-extrabold text-foreground">{value}</div>
    {hint && <div className="text-xs text-muted-foreground mt-1">{hint}</div>}
  </div>
);

export default function AdminOverview() {
  const stores = useStoresRegistry();
  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-extrabold">مرحباً بك 👋</h2>
        <p className="text-sm text-muted-foreground mt-1">
          إدارة جميع متاجرك من مكان واحد. اختر متجراً لإدارة منتجاته وطلباته.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <StatCard icon={Store} label="عدد المتاجر" value={stores.length} hint="متاجر مسجّلة" />
        <StatCard icon={ShoppingBag} label="المنتجات" value="—" hint="من API لكل متجر" />
        <StatCard icon={TrendingUp} label="الطلبات اليوم" value="—" hint="قريباً" />
      </div>

      <div className="bg-card rounded-2xl border border-border p-5">
        <div className="flex items-center justify-between mb-4">
          <h3 className="font-extrabold text-lg">المتاجر السريعة</h3>
          <Link
            to="/admin/stores"
            className="text-sm text-primary font-bold inline-flex items-center gap-1 hover:underline"
          >
            <Plus className="h-4 w-4" /> إضافة متجر
          </Link>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
          {stores.map((s) => (
            <Link
              key={s.slug}
              to={`/${s.slug}/dashboard`}
              className="group flex items-center gap-3 p-3 rounded-xl border border-border hover:border-primary hover:bg-primary-soft/40 transition-smooth"
            >
              <div className="h-12 w-12 rounded-xl bg-secondary inline-flex items-center justify-center overflow-hidden">
                {s.cachedLogo ? (
                  <img src={s.cachedLogo} alt={s.slug} className="h-full w-full object-cover" />
                ) : (
                  <Store className="h-5 w-5 text-muted-foreground" />
                )}
              </div>
              <div className="flex-1 min-w-0">
                <div className="font-bold truncate">{s.displayName ?? s.slug}</div>
                <div className="text-xs text-muted-foreground truncate">/{s.slug}</div>
              </div>
            </Link>
          ))}
        </div>
      </div>
    </div>
  );
}
