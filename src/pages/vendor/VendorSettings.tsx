import { Link } from "react-router-dom";
import { useStore } from "@/context/StoreContext";
import { ArrowLeft } from "lucide-react";

export default function VendorSettings() {
  const { slug, store } = useStore();
  return (
    <div className="max-w-3xl space-y-6">
      <div>
        <h2 className="text-2xl font-extrabold">إعدادات المتجر</h2>
        <p className="text-sm text-muted-foreground mt-1">
          الإعدادات الأساسية. التعديل المتقدم يتطلب Vendor API.
        </p>
      </div>

      <div className="bg-card rounded-2xl border border-border p-5 space-y-4">
        <h3 className="font-bold">معلومات المتجر</h3>
        <dl className="space-y-3 text-sm">
          <Row label="الاسم" value={store?.name} />
          <Row label="Slug" value={`/${slug}`} mono />
          <Row label="الهاتف" value={store?.phone} />
          <Row label="البريد" value={store?.email as string} />
          <Row label="العنوان" value={store?.address} />
          <Row label="الحد الأدنى للطلب" value={`${store?.minimum_order ?? 0} ج.م`} />
          <Row label="وقت التوصيل" value={store?.delivery_time} />
        </dl>
      </div>

      <div className="bg-card rounded-2xl border border-border p-5">
        <h3 className="font-bold mb-2">إعدادات API</h3>
        <p className="text-sm text-muted-foreground mb-3">
          إعدادات ربط API (Slug، Module ID، API Base) تُدار من اللوحة العامة.
        </p>
        <Link
          to={`/admin/stores/${slug}/settings`}
          className="inline-flex items-center gap-2 text-primary font-bold text-sm hover:underline"
        >
          <ArrowLeft className="h-4 w-4 ltr:rotate-180" /> فتح إعدادات API
        </Link>
      </div>
    </div>
  );
}

const Row = ({ label, value, mono }: { label: string; value?: string | number; mono?: boolean }) => (
  <div className="flex justify-between gap-4 border-b border-border last:border-0 pb-3 last:pb-0">
    <dt className="text-muted-foreground">{label}</dt>
    <dd className={`font-bold text-left ${mono ? "font-mono text-xs" : ""}`}>{value ?? "—"}</dd>
  </div>
);
