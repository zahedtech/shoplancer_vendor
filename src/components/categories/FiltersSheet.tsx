import { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetFooter,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import { Slider } from "@/components/ui/slider";
import { Switch } from "@/components/ui/switch";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { formatPrice } from "@/lib/api";
import type { Brand } from "@/lib/shoplanserApi";

export interface FiltersValue {
  /** null means "no lower bound active" */
  min: number | null;
  max: number | null;
  inStockOnly: boolean;
  brand: number | null;
}

interface FiltersSheetProps {
  open: boolean;
  onOpenChange: (v: boolean) => void;
  value: FiltersValue;
  onChange: (v: FiltersValue) => void;
  priceBounds: { min: number; max: number };
  brands?: Brand[];
  brandsLoading?: boolean;
}

/**
 * Drawer of filters for the Categories grid. Local state mirrors the props
 * so the user can fiddle without committing — changes apply on "تطبيق".
 */
export const FiltersSheet = ({
  open,
  onOpenChange,
  value,
  onChange,
  priceBounds,
  brands,
  brandsLoading,
}: FiltersSheetProps) => {
  const [draft, setDraft] = useState<FiltersValue>(value);
  const { t } = useTranslation();

  // Keep local draft synced when the parent value changes (e.g. URL reset).
  useEffect(() => {
    if (open) setDraft(value);
  }, [open, value]);

  const min = priceBounds.min;
  const max = Math.max(priceBounds.max, priceBounds.min + 1);
  const currentRange: [number, number] = [
    draft.min ?? min,
    draft.max ?? max,
  ];

  const apply = () => {
    // Strip bounds that match the full range so the URL stays clean.
    const next: FiltersValue = {
      min: draft.min !== null && draft.min > min ? draft.min : null,
      max: draft.max !== null && draft.max < max ? draft.max : null,
      inStockOnly: draft.inStockOnly,
      brand: draft.brand ?? null,
    };
    onChange(next);
    onOpenChange(false);
  };

  const reset = () => {
    const cleared: FiltersValue = { min: null, max: null, inStockOnly: false, brand: null };
    setDraft(cleared);
    onChange(cleared);
    onOpenChange(false);
  };

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent side="right" className="w-full sm:max-w-md">
        <SheetHeader className="text-start">
          <SheetTitle>{t("filters.title")}</SheetTitle>
          <SheetDescription>{t("filters.description")}</SheetDescription>
        </SheetHeader>

        <div className="py-6 space-y-8">
          {/* Price */}
          <section className="space-y-3">
            <div className="flex items-center justify-between">
              <Label className="text-sm font-bold">{t("filters.priceRange")}</Label>
              <span className="text-xs text-muted-foreground font-bold">
                {formatPrice(currentRange[0])} – {formatPrice(currentRange[1])}
              </span>
            </div>
            <Slider
              min={min}
              max={max}
              step={Math.max(1, Math.round((max - min) / 100))}
              value={currentRange}
              onValueChange={(v) =>
                setDraft((d) => ({ ...d, min: v[0], max: v[1] }))
              }
              className="py-2"
            />
            <div className="flex items-center justify-between text-[11px] text-muted-foreground">
              <span>{formatPrice(min)}</span>
              <span>{formatPrice(max)}</span>
            </div>
          </section>

          {/* Availability */}
          <section className="flex items-center justify-between bg-secondary/50 rounded-xl p-3">
            <div>
              <Label className="text-sm font-bold">{t("filters.inStockOnly")}</Label>
              <p className="text-[11px] text-muted-foreground mt-0.5">
                {t("filters.inStockHint")}
              </p>
            </div>
            <Switch
              checked={draft.inStockOnly}
              onCheckedChange={(v) =>
                setDraft((d) => ({ ...d, inStockOnly: !!v }))
              }
            />
          </section>

          {/* Brand */}
          {(brands && brands.length > 0) || brandsLoading ? (
            <section className="space-y-2">
              <Label className="text-sm font-bold">{t("filters.brand")}</Label>
              <Select
                value={draft.brand == null ? "all" : String(draft.brand)}
                onValueChange={(v) =>
                  setDraft((d) => ({ ...d, brand: v === "all" ? null : Number(v) }))
                }
                disabled={brandsLoading}
              >
                <SelectTrigger className="w-full">
                  <SelectValue placeholder={t("filters.brandPlaceholder")} />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">{t("filters.brandAll")}</SelectItem>
                  {(brands ?? []).map((b) => (
                    <SelectItem key={b.id} value={String(b.id)}>
                      {b.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </section>
          ) : null}
        </div>

        <SheetFooter className="flex-row gap-2 sm:flex-row sm:justify-between sm:space-x-0">
          <Button
            type="button"
            variant="outline"
            onClick={reset}
            className="flex-1"
          >
            {t("filters.reset")}
          </Button>
          <Button type="button" onClick={apply} className="flex-1">
            {t("filters.apply")}
          </Button>
        </SheetFooter>
      </SheetContent>
    </Sheet>
  );
};
