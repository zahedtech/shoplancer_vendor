import { useQuery } from "@tanstack/react-query";
import { Package, ShoppingBag, Star, Truck, Store as StoreIcon } from "lucide-react";
import { useStore } from "@/context/StoreContext";
import { fetchProducts } from "@/lib/api";

const Stat = ({
  icon: Icon,
  label,
  value,
  hint,
}: {
  icon: typeof Package;
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

export default function VendorOverview() {
  const { store, ctx } = useStore();
  const { data: products } = useQuery({
    queryKey: ["vendor-products-count", ctx?.slug],
    queryFn: () => fetchProducts(ctx!, { limit: 1 }),
    enabled: !!ctx,
  });

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-extrabold">مرحباً، {store?.name} 👋</h2>
        <p className="text-sm text-muted-foreground mt-1">
          نظرة سريعة على متجرك. الأرقام مباشرة من Shoplanser.
        </p>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <Stat
          icon={Package}
          label="المنتجات"
          value={products?.total_size ?? store?.total_items ?? "—"}
          hint="إجمالي"
        />
        <Stat
          icon={ShoppingBag}
          label="الطلبات الإجمالية"
          value={store?.total_order ?? "—"}
        />
        <Stat
          icon={Star}
          label="التقييم"
          value={store?.avg_rating?.toFixed(1) ?? "—"}
          hint={`${store?.rating_count ?? 0} مراجعة`}
        />
        <Stat
          icon={Truck}
          label="وقت التوصيل"
          value={store?.delivery_time ?? "—"}
        />
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="bg-card rounded-2xl border border-border p-5">
          <h3 className="font-extrabold mb-3 flex items-center gap-2">
            <StoreIcon className="h-4 w-4 text-primary" /> معلومات المتجر
          </h3>
          <dl className="space-y-2 text-sm">
            <Row label="الاسم" value={store?.name} />
            <Row label="الهاتف" value={store?.phone} />
            <Row label="العنوان" value={store?.address} />
            <Row label="الحد الأدنى للطلب" value={`${store?.minimum_order ?? 0} ج.م`} />
          </dl>
        </div>

        <div className="bg-card rounded-2xl border border-border p-5">
          <h3 className="font-extrabold mb-3">الفئات النشطة</h3>
          <div className="flex flex-wrap gap-2">
            {store?.category_details?.map((c) => (
              <span
                key={c.id}
                className="px-3 py-1.5 rounded-full bg-primary-soft text-primary text-sm font-bold"
              >
                {c.name}
              </span>
            ))}
            {!store?.category_details?.length && (
              <span className="text-sm text-muted-foreground">لا توجد فئات</span>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

const Row = ({ label, value }: { label: string; value?: string | number }) => (
  <div className="flex justify-between gap-4 border-b border-border last:border-0 pb-2 last:pb-0">
    <dt className="text-muted-foreground">{label}</dt>
    <dd className="font-bold text-left truncate">{value ?? "—"}</dd>
  </div>
);
