import { useMemo, useState } from "react";
import { Settings2 } from "lucide-react";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import { Slider } from "@/components/ui/slider";
import { Button } from "@/components/ui/button";
import { useStoreSettings } from "@/hooks/useStoreSettings";
import { setStoreSettings, DEFAULT_SETTINGS, type HeroPattern } from "@/lib/storeSettings";
import { StoreCategory, getTopLevelCategories, getSubCategories } from "@/lib/api";
import { cn } from "@/lib/utils";

interface Props {
  slug: string;
  /** All categories from the loaded store (used to pick produce / attarah). */
  categories?: StoreCategory[];
  /** When true, show clothes-specific sections (hero pattern + audience map). */
  showClothes?: boolean;
}

type ColumnKey = "produceCategoryIds" | "attarahCategoryIds";

/**
 * Floating settings panel for store-level UI tunables.
 * Now also lets the vendor mark categories as produce (½ kg steps) or
 * attarah (sold by weight or amount).
 */
export const StoreSettingsPanel = ({ slug, categories = [], showClothes = false }: Props) => {
  const [open, setOpen] = useState(false);
  const settings = useStoreSettings(slug);

  // Build a flat list of all categories (parents + children) for selection.
  const flatCategories = useMemo(() => {
    if (!categories.length) return [] as StoreCategory[];
    const tops = getTopLevelCategories(categories);
    const out: StoreCategory[] = [];
    for (const top of tops) {
      out.push(top);
      const subs = getSubCategories(categories, top.id);
      for (const s of subs) out.push(s);
    }
    return out;
  }, [categories]);

  const toggleCategory = (col: ColumnKey, id: number) => {
    const current = settings[col] ?? [];
    const next = current.includes(id)
      ? current.filter((x) => x !== id)
      : [...current, id];
    // Keep the two columns mutually exclusive: a category can only belong to one bucket.
    const other: ColumnKey =
      col === "produceCategoryIds" ? "attarahCategoryIds" : "produceCategoryIds";
    const otherList = (settings[other] ?? []).filter((x) => x !== id);
    setStoreSettings(slug, { [col]: next, [other]: otherList } as Partial<typeof settings>);
  };

  return (
    <>
      <button
        onClick={() => setOpen(true)}
        aria-label="إعدادات المتجر"
        className="fixed bottom-56 left-3 z-40 h-11 w-11 rounded-full bg-secondary text-foreground border border-border inline-flex items-center justify-center shadow-card hover:bg-muted transition-smooth"
      >
        <Settings2 className="h-5 w-5" />
      </button>

      <Sheet open={open} onOpenChange={setOpen}>
        <SheetContent side="bottom" className="max-h-[85vh] overflow-y-auto" dir="rtl">
          <SheetHeader>
            <SheetTitle>إعدادات العرض</SheetTitle>
          </SheetHeader>

          <div className="mt-5 space-y-7">
            {/* Low-stock threshold */}
            <div className="space-y-3">
              <div className="flex items-center justify-between gap-2">
                <div>
                  <h4 className="font-extrabold text-sm">حد المخزون المنخفض</h4>
                  <p className="text-[11px] text-muted-foreground mt-0.5 leading-relaxed">
                    شارة "متوفر: N" تظهر فقط عند بلوغ المخزون هذا الحد أو أقل.
                  </p>
                </div>
                <span className="shrink-0 inline-flex items-center justify-center min-w-[52px] h-9 px-3 rounded-full bg-primary text-primary-foreground text-sm font-extrabold tabular-nums">
                  {settings.lowStockThreshold}
                </span>
              </div>

              <Slider
                value={[settings.lowStockThreshold]}
                min={0}
                max={100}
                step={1}
                onValueChange={(v) =>
                  setStoreSettings(slug, { lowStockThreshold: v[0] })
                }
              />

              <div className="flex flex-wrap gap-1.5 pt-1">
                {[0, 5, 10, 20, 50, 100].map((preset) => (
                  <button
                    key={preset}
                    onClick={() =>
                      setStoreSettings(slug, { lowStockThreshold: preset })
                    }
                    className={`text-[11px] font-bold px-2.5 py-1 rounded-full border transition-smooth ${
                      settings.lowStockThreshold === preset
                        ? "bg-primary text-primary-foreground border-transparent"
                        : "bg-secondary text-foreground border-border hover:bg-muted"
                    }`}
                  >
                    {preset === 0 ? "إيقاف" : `≤ ${preset}`}
                  </button>
                ))}
              </div>
            </div>

            {/* Category typing */}
            <div className="space-y-3">
              <div>
                <h4 className="font-extrabold text-sm">نوع البيع لكل فئة</h4>
                <p className="text-[11px] text-muted-foreground mt-0.5 leading-relaxed">
                  حدد الفئات التي تُباع بالخضار/الفواكه (نصف كيلو) أو فئات
                  العطارة (وزن أو مبلغ). الباقي يُعرض كقطعة.
                </p>
              </div>

              {flatCategories.length === 0 ? (
                <p className="text-xs text-muted-foreground py-4 text-center">
                  لا توجد فئات محمَّلة.
                </p>
              ) : (
                <div className="space-y-1.5 max-h-72 overflow-y-auto pr-1">
                  {flatCategories.map((c) => {
                    const isProduce = settings.produceCategoryIds.includes(c.id);
                    const isAttarah = settings.attarahCategoryIds.includes(c.id);
                    const isChild = !!c.parent_id;
                    return (
                      <div
                        key={c.id}
                        className={cn(
                          "flex items-center gap-2 p-2 rounded-lg border bg-card",
                          isChild && "mr-4 border-dashed",
                        )}
                      >
                        <span className="flex-1 text-xs font-bold text-foreground truncate">
                          {c.name}
                          <span className="text-[10px] text-muted-foreground font-normal ms-1">
                            #{c.id}
                          </span>
                        </span>
                        <button
                          onClick={() => toggleCategory("produceCategoryIds", c.id)}
                          className={cn(
                            "text-[10px] font-extrabold px-2 py-1 rounded-full border transition-smooth",
                            isProduce
                              ? "bg-fresh text-fresh-foreground border-transparent"
                              : "bg-secondary text-foreground border-border hover:bg-muted",
                          )}
                        >
                          خضار
                        </button>
                        <button
                          onClick={() => toggleCategory("attarahCategoryIds", c.id)}
                          className={cn(
                            "text-[10px] font-extrabold px-2 py-1 rounded-full border transition-smooth",
                            isAttarah
                              ? "bg-accent text-accent-foreground border-transparent"
                              : "bg-secondary text-foreground border-border hover:bg-muted",
                          )}
                        >
                          عطارة
                        </button>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>

            {/* Clothes-only sections */}
            {showClothes && (
              <>
                {/* Hero pattern */}
                <div className="space-y-3">
                  <div>
                    <h4 className="font-extrabold text-sm">نمط خلفية الهيرو</h4>
                    <p className="text-[11px] text-muted-foreground mt-0.5 leading-relaxed">
                      اختر نمطاً يناسب هوية متجر الملابس.
                    </p>
                  </div>
                  <div className="grid grid-cols-4 gap-2">
                    {(["none", "stripe", "flowers", "denim"] as HeroPattern[]).map((p) => {
                      const active = settings.heroPattern === p;
                      const previewClass =
                        p === "none"
                          ? "gradient-hero-clothes"
                          : `gradient-hero-clothes ${
                              p === "stripe"
                                ? "hero-pattern-stripe"
                                : p === "flowers"
                                  ? "hero-pattern-flowers"
                                  : "hero-pattern-denim"
                            }`;
                      const label =
                        p === "none" ? "بدون" : p === "stripe" ? "خطوط" : p === "flowers" ? "زهور" : "جينز";
                      return (
                        <button
                          key={p}
                          onClick={() => setStoreSettings(slug, { heroPattern: p })}
                          className={cn(
                            "rounded-xl overflow-hidden border-2 transition-smooth",
                            active ? "border-primary" : "border-border hover:border-muted-foreground",
                          )}
                        >
                          <div className={cn("h-12", previewClass)} />
                          <div className="text-[10px] font-extrabold py-1 bg-card">{label}</div>
                        </button>
                      );
                    })}
                  </div>
                </div>

                {/* Audience mapping */}
                <div className="space-y-3">
                  <div>
                    <h4 className="font-extrabold text-sm">تصنيف الفئات (رجالي/نسائي/أطفال)</h4>
                    <p className="text-[11px] text-muted-foreground mt-0.5 leading-relaxed">
                      الفئات بدون اختيار يدوي يتم تصنيفها تلقائياً من اسمها.
                    </p>
                  </div>

                  {flatCategories.length === 0 ? (
                    <p className="text-xs text-muted-foreground py-4 text-center">
                      لا توجد فئات محمَّلة.
                    </p>
                  ) : (
                    <div className="space-y-1.5 max-h-72 overflow-y-auto pr-1">
                      {flatCategories.map((c) => {
                        const isMen = settings.audienceMap.men.includes(c.id);
                        const isWomen = settings.audienceMap.women.includes(c.id);
                        const isKids = settings.audienceMap.kids.includes(c.id);
                        const isChild = !!c.parent_id;
                        const setAudience = (key: "men" | "women" | "kids") => {
                          const map = settings.audienceMap;
                          const isActive = map[key].includes(c.id);
                          const next = {
                            men: map.men.filter((x) => x !== c.id),
                            women: map.women.filter((x) => x !== c.id),
                            kids: map.kids.filter((x) => x !== c.id),
                          };
                          if (!isActive) next[key] = [...next[key], c.id];
                          setStoreSettings(slug, { audienceMap: next });
                        };
                        return (
                          <div
                            key={c.id}
                            className={cn(
                              "flex items-center gap-1 p-2 rounded-lg border bg-card",
                              isChild && "mr-4 border-dashed",
                            )}
                          >
                            <span className="flex-1 text-xs font-bold text-foreground truncate">
                              {c.name}
                            </span>
                            {(["men", "women", "kids"] as const).map((key) => {
                              const isActive =
                                key === "men" ? isMen : key === "women" ? isWomen : isKids;
                              const label = key === "men" ? "ر" : key === "women" ? "ن" : "أ";
                              return (
                                <button
                                  key={key}
                                  onClick={() => setAudience(key)}
                                  className={cn(
                                    "h-7 w-7 rounded-full text-[11px] font-extrabold border transition-smooth",
                                    isActive
                                      ? "bg-primary text-primary-foreground border-transparent"
                                      : "bg-secondary text-foreground border-border hover:bg-muted",
                                  )}
                                >
                                  {label}
                                </button>
                              );
                            })}
                          </div>
                        );
                      })}
                    </div>
                  )}
                </div>
              </>
            )}
            <div className="pt-2 border-t border-border/60">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setStoreSettings(slug, DEFAULT_SETTINGS)}
                className="text-xs font-bold w-full"
              >
                إعادة الإعدادات الافتراضية
              </Button>
            </div>
          </div>
        </SheetContent>
      </Sheet>
    </>
  );
};
