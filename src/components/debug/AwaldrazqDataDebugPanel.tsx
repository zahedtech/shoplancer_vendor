import { useState } from "react";
import { Bug, Copy, Check } from "lucide-react";
import { Sheet, SheetContent, SheetHeader, SheetTitle } from "@/components/ui/sheet";
import { Product, StoreContextData, StoreDetails } from "@/lib/api";

interface SectionData {
  products: Product[];
  loading: boolean;
}

interface Props {
  store: StoreDetails;
  ctx: StoreContextData | null;
  recommended: SectionData;
  offers: SectionData;
  latest: SectionData;
}

const pickFields = (p: Product) => ({
  id: p.id,
  name: p.name,
  price: p.price,
  discount: p.discount,
  stock: p.stock,
  unit_type: p.unit_type ?? null,
  category_id: p.category_id,
});

/**
 * Floating debug panel — only mounted on /awaldrazq. Lets us confirm what
 * the Shoplanser API actually returns for this tenant (especially the
 * unit_type / stock fields used to compute the unit-quantity badge).
 */
export const AwaldrazqDataDebugPanel = ({
  store,
  ctx,
  recommended,
  offers,
  latest,
}: Props) => {
  const [open, setOpen] = useState(false);
  const [copied, setCopied] = useState(false);

  const payload = {
    store: {
      id: store.id,
      slug: store.slug,
      name: store.name,
      total_items: store.total_items,
    },
    ctx,
    sections: {
      recommended: {
        loading: recommended.loading,
        count: recommended.products.length,
        sample: recommended.products.slice(0, 5).map(pickFields),
      },
      offers: {
        loading: offers.loading,
        count: offers.products.length,
        sample: offers.products.slice(0, 5).map(pickFields),
      },
      latest: {
        loading: latest.loading,
        count: latest.products.length,
        sample: latest.products.slice(0, 5).map(pickFields),
      },
    },
  };

  const copyAll = async () => {
    try {
      await navigator.clipboard.writeText(JSON.stringify(payload, null, 2));
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    } catch {
      /* ignore */
    }
  };

  return (
    <>
      <button
        onClick={() => setOpen(true)}
        aria-label="فتح لوحة التشخيص"
        className="fixed bottom-24 left-3 z-40 h-11 w-11 rounded-full bg-foreground text-background inline-flex items-center justify-center shadow-card hover:opacity-90 transition-smooth"
      >
        <Bug className="h-5 w-5" />
      </button>

      <Sheet open={open} onOpenChange={setOpen}>
        <SheetContent side="bottom" className="max-h-[85vh] overflow-y-auto" dir="rtl">
          <SheetHeader>
            <SheetTitle className="flex items-center justify-between gap-2">
              <span>لوحة بيانات /awaldrazq</span>
              <button
                onClick={copyAll}
                className="inline-flex items-center gap-1 text-xs font-bold bg-secondary px-3 py-1.5 rounded-full hover:bg-muted transition-smooth"
              >
                {copied ? <Check className="h-3.5 w-3.5" /> : <Copy className="h-3.5 w-3.5" />}
                {copied ? "تم النسخ" : "نسخ JSON"}
              </button>
            </SheetTitle>
          </SheetHeader>

          <div className="mt-4 space-y-4 text-xs">
            <DebugBlock title="معلومات المتجر">
              <KV k="id" v={store.id} />
              <KV k="slug" v={store.slug} />
              <KV k="name" v={store.name} />
              <KV k="storeId (ctx)" v={ctx?.storeId ?? "—"} />
              <KV k="zoneId" v={ctx?.zoneId ?? "—"} />
              <KV k="moduleId" v={ctx?.moduleId ?? "—"} />
            </DebugBlock>

            <SectionBlock label="موصى به لك" data={recommended} />
            <SectionBlock label="العروض" data={offers} />
            <SectionBlock label="الأحدث" data={latest} />

            <p className="text-[11px] text-muted-foreground leading-relaxed bg-muted/40 p-3 rounded-xl">
              ملاحظة: الـ API لا يُرجع حقل <code>unit_quantity</code> صريح
              (مثل 500 جم). الحقول المتوفرة:{" "}
              <code>unit_type</code> (نوع الوحدة) و <code>stock</code>{" "}
              (المخزون). شارة "كمية الوحدة" على البطاقة تستخدم هذين الحقلين.
            </p>
          </div>
        </SheetContent>
      </Sheet>
    </>
  );
};

const DebugBlock = ({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) => (
  <div className="bg-muted/30 rounded-xl p-3 border border-border/60">
    <h4 className="font-extrabold text-sm mb-2">{title}</h4>
    <div className="space-y-1">{children}</div>
  </div>
);

const KV = ({ k, v }: { k: string; v: React.ReactNode }) => (
  <div className="flex items-center justify-between gap-2 border-b border-border/40 last:border-0 py-1">
    <span className="text-muted-foreground font-medium">{k}</span>
    <span className="font-bold tabular-nums truncate max-w-[60%] text-left" dir="ltr">
      {String(v)}
    </span>
  </div>
);

const SectionBlock = ({
  label,
  data,
}: {
  label: string;
  data: SectionData;
}) => (
  <DebugBlock title={label}>
    <KV k="حالة التحميل" v={data.loading ? "⏳ جارٍ التحميل" : "✅ مكتمل"} />
    <KV k="عدد المنتجات" v={data.products.length} />
    {data.products.length > 0 && (
      <details className="mt-2">
        <summary className="cursor-pointer text-[11px] font-bold text-primary">
          عرض أول 5 منتجات (JSON)
        </summary>
        <pre
          dir="ltr"
          className="mt-2 text-[10px] bg-background border border-border/60 rounded-lg p-2 overflow-x-auto leading-relaxed"
        >
          {JSON.stringify(data.products.slice(0, 5).map(pickFields), null, 2)}
        </pre>
      </details>
    )}
  </DebugBlock>
);
