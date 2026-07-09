import { useMemo, useState } from "react";
import { Ruler, X, Search, Trash2 } from "lucide-react";
import { Sheet, SheetContent, SheetHeader, SheetTitle } from "@/components/ui/sheet";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Product } from "@/lib/api";
import { useProductOverrides } from "@/hooks/useUnitSizeOverrides";
import { useStoreSettings } from "@/hooks/useStoreSettings";
import {
  setProductOverride,
  removeProductOverride,
  clearUnitSizes,
  UNIT_SIZE_PRESETS,
  ATTARAH_REFERENCE_PRESETS,
  ATTARAH_MIN_PRESETS,
  DEFAULT_ATTARAH_REFERENCE,
  DEFAULT_ATTARAH_MIN_GRAMS,
  type ProductOverride,
} from "@/lib/unitSizeOverrides";
import { cn } from "@/lib/utils";

interface Props {
  slug: string;
  /** All loaded products from the storefront — usually the merged rails + grid. */
  products: Product[];
}

/**
 * Floating editor for per-product overrides:
 *  - Package size label (any product) → "500 جم", "1 لتر"…
 *  - Attarah reference grams + min grams (when category marked as attarah)
 */
export const UnitSizeEditor = ({ slug, products }: Props) => {
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState("");
  const overrides = useProductOverrides(slug);
  const settings = useStoreSettings(slug);

  const unique = useMemo(() => {
    const seen = new Set<number>();
    return products.filter((p) => {
      if (seen.has(p.id)) return false;
      seen.add(p.id);
      return true;
    });
  }, [products]);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return unique;
    return unique.filter((p) => p.name.toLowerCase().includes(q));
  }, [unique, query]);

  const mappedCount = Object.keys(overrides).length;

  return (
    <>
      <button
        onClick={() => setOpen(true)}
        aria-label="تعيين أحجام العبوات"
        className="fixed bottom-40 left-3 z-40 h-11 w-11 rounded-full bg-primary text-primary-foreground inline-flex items-center justify-center shadow-card hover:bg-primary-glow transition-smooth"
      >
        <Ruler className="h-5 w-5" />
        {mappedCount > 0 && (
          <span className="absolute -top-1 -right-1 h-5 min-w-5 px-1 rounded-full bg-discount text-discount-foreground text-[10px] font-extrabold inline-flex items-center justify-center shadow-soft">
            {mappedCount}
          </span>
        )}
      </button>

      <Sheet open={open} onOpenChange={setOpen}>
        <SheetContent side="bottom" className="max-h-[90vh] overflow-y-auto" dir="rtl">
          <SheetHeader>
            <SheetTitle className="flex items-center justify-between gap-2">
              <span>أحجام وإعدادات المنتجات</span>
              {mappedCount > 0 && (
                <button
                  onClick={() => {
                    if (confirm("مسح كل إعدادات المنتجات لهذا المتجر؟")) {
                      clearUnitSizes(slug);
                    }
                  }}
                  className="inline-flex items-center gap-1 text-xs font-bold text-discount hover:underline"
                >
                  <Trash2 className="h-3.5 w-3.5" />
                  مسح الكل
                </button>
              )}
            </SheetTitle>
          </SheetHeader>

          <p className="text-[11px] text-muted-foreground mt-2 leading-relaxed">
            عيّن حجم العبوة لكل منتج. للمنتجات داخل فئات العطارة يظهر إعداد
            إضافي للمرجع (مثلاً السعر لكل 100 جم) والحد الأدنى للوزن.
          </p>

          <div className="relative mt-3">
            <Search className="absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="ابحث عن منتج…"
              className="pr-9"
            />
          </div>

          <div className="mt-3 space-y-2">
            {filtered.length === 0 ? (
              <p className="text-center text-sm text-muted-foreground py-8">
                لا توجد نتائج
              </p>
            ) : (
              filtered.map((p) => {
                const isAttarah = settings.attarahCategoryIds.includes(
                  Number(p.category_id),
                );
                return (
                  <ProductRow
                    key={p.id}
                    slug={slug}
                    product={p}
                    override={overrides[p.id]}
                    isAttarah={isAttarah}
                  />
                );
              })
            )}
          </div>
        </SheetContent>
      </Sheet>
    </>
  );
};

const ProductRow = ({
  slug,
  product,
  override,
  isAttarah,
}: {
  slug: string;
  product: Product;
  override?: ProductOverride;
  isAttarah: boolean;
}) => {
  const [custom, setCustom] = useState("");
  const [editing, setEditing] = useState(false);

  const apply = (size: string) => {
    setProductOverride(slug, product.id, { size });
    setCustom("");
    setEditing(false);
  };

  const currentSize = override?.size;
  const currentRef = override?.referenceGramPrice ?? DEFAULT_ATTARAH_REFERENCE;
  const currentMin = override?.minGrams ?? DEFAULT_ATTARAH_MIN_GRAMS;

  return (
    <div className="bg-card rounded-xl border border-border/60 p-2.5 shadow-soft">
      <div className="flex items-center gap-2.5">
        <div className="h-12 w-12 shrink-0 rounded-lg bg-white border border-border/60 overflow-hidden flex items-center justify-center p-1">
          {product.image_full_url ? (
            <img
              src={product.image_full_url}
              alt={product.name}
              loading="lazy"
              className="max-h-full max-w-full object-contain"
            />
          ) : (
            <div className="h-full w-full bg-muted rounded" />
          )}
        </div>
        <div className="flex-1 min-w-0">
          <h4 className="font-bold text-sm text-foreground line-clamp-1">
            {product.name}
            {isAttarah && (
              <span className="ms-1.5 text-[9px] font-extrabold px-1.5 py-0.5 rounded-full bg-accent text-accent-foreground">
                عطارة
              </span>
            )}
          </h4>
          <p className="text-[10px] text-muted-foreground">
            cat: {product.category_id} · unit: {product.unit_type ?? "—"} ·
            stock: {product.stock ?? 0}
          </p>
        </div>
        {override && (
          <button
            onClick={() => removeProductOverride(slug, product.id)}
            aria-label="مسح الإعدادات"
            className="h-7 w-7 rounded-full bg-muted text-muted-foreground inline-flex items-center justify-center hover:bg-discount hover:text-discount-foreground transition-smooth"
          >
            <X className="h-3.5 w-3.5" />
          </button>
        )}
      </div>

      {/* Size picker */}
      {currentSize && !editing ? (
        <div className="mt-2 flex items-center gap-2">
          <span className="inline-flex items-center px-2.5 py-1 rounded-full bg-primary text-primary-foreground text-xs font-extrabold">
            {currentSize}
          </span>
          <button
            onClick={() => setEditing(true)}
            className="text-[11px] font-bold text-primary hover:underline"
          >
            تغيير الحجم
          </button>
        </div>
      ) : (
        <div className="mt-2 space-y-2">
          <div className="flex flex-wrap gap-1">
            {UNIT_SIZE_PRESETS.map((preset) => (
              <button
                key={preset}
                onClick={() => apply(preset)}
                className={cn(
                  "text-[10px] font-bold px-2 py-1 rounded-full border transition-smooth",
                  currentSize === preset
                    ? "bg-primary text-primary-foreground border-transparent"
                    : "bg-secondary text-foreground border-border hover:bg-muted",
                )}
              >
                {preset}
              </button>
            ))}
          </div>
          <div className="flex items-center gap-2">
            <Input
              value={custom}
              onChange={(e) => setCustom(e.target.value)}
              placeholder="مخصص (مثل: 350 جم)"
              className="h-8 text-xs"
            />
            <Button
              size="sm"
              onClick={() => custom.trim() && apply(custom)}
              disabled={!custom.trim()}
              className="h-8 text-xs font-bold"
            >
              حفظ
            </Button>
          </div>
        </div>
      )}

      {/* Attarah-specific knobs */}
      {isAttarah && (
        <div className="mt-3 pt-3 border-t border-dashed border-border/70 space-y-2.5">
          <div>
            <p className="text-[10px] font-extrabold text-foreground mb-1">
              السعر لكل (مرجع الوزن):
            </p>
            <div className="flex flex-wrap gap-1">
              {ATTARAH_REFERENCE_PRESETS.map((g) => (
                <button
                  key={g}
                  onClick={() =>
                    setProductOverride(slug, product.id, { referenceGramPrice: g })
                  }
                  className={cn(
                    "text-[10px] font-bold px-2 py-1 rounded-full border transition-smooth",
                    currentRef === g
                      ? "bg-primary text-primary-foreground border-transparent"
                      : "bg-secondary text-foreground border-border hover:bg-muted",
                  )}
                >
                  {g >= 1000 ? `${g / 1000} كجم` : `${g} جم`}
                </button>
              ))}
            </div>
          </div>

          <div>
            <p className="text-[10px] font-extrabold text-foreground mb-1">
              الحد الأدنى للطلب:
            </p>
            <div className="flex flex-wrap gap-1">
              {ATTARAH_MIN_PRESETS.map((g) => (
                <button
                  key={g}
                  onClick={() =>
                    setProductOverride(slug, product.id, { minGrams: g })
                  }
                  className={cn(
                    "text-[10px] font-bold px-2 py-1 rounded-full border transition-smooth",
                    currentMin === g
                      ? "bg-fresh text-fresh-foreground border-transparent"
                      : "bg-secondary text-foreground border-border hover:bg-muted",
                  )}
                >
                  {g} جم
                </button>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
