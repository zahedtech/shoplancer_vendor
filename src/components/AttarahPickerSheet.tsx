import { useEffect, useMemo, useState } from "react";
import { Scale, Wallet, AlertCircle } from "lucide-react";
import { Product, formatPrice } from "@/lib/api";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

/** Format grams as "750 جم" or "1.5 كجم". */
export const formatGrams = (g: number): string => {
  if (g >= 1000) {
    const kg = g / 1000;
    return `${kg % 1 === 0 ? kg : kg.toFixed(2).replace(/\.?0+$/, "")} كجم`;
  }
  return `${Math.round(g)} جم`;
};

interface AttarahPickerProps {
  open: boolean;
  onOpenChange: (v: boolean) => void;
  product: Product;
  unitPrice: number;
  referenceGramPrice: number;
  minGrams: number;
  currentUnits: number;
  onConfirm: (units: number) => void;
}

export const AttarahPickerSheet = ({
  open,
  onOpenChange,
  product,
  unitPrice,
  referenceGramPrice,
  minGrams,
  currentUnits,
  onConfirm,
}: AttarahPickerProps) => {
  const [mode, setMode] = useState<"weight" | "amount">("weight");

  const weightPresets = useMemo(() => {
    const base = [50, 100, 250, 500, 1000];
    return base.filter((g) => g >= minGrams);
  }, [minGrams]);

  const initialGrams = () =>
    Math.max(currentUnits * referenceGramPrice, minGrams);

  const [grams, setGrams] = useState<number>(initialGrams);
  const [amount, setAmount] = useState<number>(
    () => (initialGrams() / referenceGramPrice) * unitPrice,
  );
  const [touched, setTouched] = useState(false);

  // Re-sync each time the sheet opens.
  useEffect(() => {
    if (open) {
      const g = initialGrams();
      setGrams(g);
      setAmount((g / referenceGramPrice) * unitPrice);
      setTouched(false);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open]);

  const updateGrams = (g: number) => {
    setTouched(true);
    setGrams(g);
    setAmount((g / referenceGramPrice) * unitPrice);
  };

  const updateAmount = (a: number) => {
    setTouched(true);
    setAmount(a);
    setGrams((a / unitPrice) * referenceGramPrice);
  };

  // Snap to nearest reference-unit block.
  const units = Math.max(0, Math.round(grams / referenceGramPrice));
  const finalGrams = units * referenceGramPrice;
  const finalPrice = units * unitPrice;

  // ---- Validation in Arabic (precise + shows expected values) ----
  let errorMsg: string | null = null;
  let errorHint: string | null = null;
  if (unitPrice <= 0) {
    errorMsg = "السعر غير متاح حاليًا، حاول لاحقًا.";
  } else if (referenceGramPrice <= 0) {
    errorMsg = "إعدادات وحدة المنتج غير صحيحة.";
    errorHint = "تواصل مع المتجر — قيمة \"السعر لكل ١٠٠ جم\" غير مضبوطة.";
  } else if (mode === "amount" && amount > 0 && amount < unitPrice) {
    // amount entered is below the price of one reference block
    errorMsg = `المبلغ أقل من سعر أصغر كمية متاحة (${formatPrice(unitPrice)} لكل ${formatGrams(referenceGramPrice)}).`;
    errorHint = `جرّب مبلغًا ${formatPrice(unitPrice)} أو أكثر.`;
  } else if (units <= 0) {
    const minBlock = Math.max(minGrams, referenceGramPrice);
    errorMsg = `أدخل وزنًا أو مبلغًا صالحًا.`;
    errorHint = `الحد الأدنى ${formatGrams(minBlock)} (≈ ${formatPrice((minBlock / referenceGramPrice) * unitPrice)}).`;
  } else if (finalGrams < minGrams) {
    errorMsg = `الحد الأدنى للطلب ${formatGrams(minGrams)}.`;
    errorHint = `الكمية الحالية ${formatGrams(finalGrams)} — زِدها لتصل إلى ${formatGrams(minGrams)} على الأقل.`;
  }

  const valid = errorMsg === null;
  const showError = touched && !valid;

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent side="bottom" className="max-h-[85vh] overflow-y-auto" dir="rtl">
        <SheetHeader>
          <SheetTitle className="text-right">{product.name}</SheetTitle>
        </SheetHeader>

        {/* Reference info card */}
        <div className="mt-2 p-3 rounded-xl bg-muted/40 border border-border/60 space-y-1 text-[12px]">
          <div className="flex items-center justify-between">
            <span className="text-muted-foreground font-bold">السعر المرجعي</span>
            <span className="font-extrabold text-foreground">
              {formatPrice(unitPrice)} / {formatGrams(referenceGramPrice)}
            </span>
          </div>
          <div className="flex items-center justify-between">
            <span className="text-muted-foreground font-bold">الحد الأدنى للطلب</span>
            <span className="font-extrabold text-foreground">{formatGrams(minGrams)}</span>
          </div>
          <div className="flex items-center justify-between">
            <span className="text-muted-foreground font-bold">يُقرَّب لأقرب</span>
            <span className="font-extrabold text-foreground">{formatGrams(referenceGramPrice)}</span>
          </div>
        </div>

        {/* Mode toggle */}
        <div className="mt-4 grid grid-cols-2 gap-1 bg-muted rounded-full p-1">
          <button
            onClick={() => setMode("weight")}
            className={`h-9 rounded-full text-xs font-extrabold inline-flex items-center justify-center gap-1.5 transition-smooth ${
              mode === "weight"
                ? "bg-background text-foreground shadow-soft"
                : "text-muted-foreground"
            }`}
          >
            <Scale className="h-3.5 w-3.5" />
            بالوزن
          </button>
          <button
            onClick={() => setMode("amount")}
            className={`h-9 rounded-full text-xs font-extrabold inline-flex items-center justify-center gap-1.5 transition-smooth ${
              mode === "amount"
                ? "bg-background text-foreground shadow-soft"
                : "text-muted-foreground"
            }`}
          >
            <Wallet className="h-3.5 w-3.5" />
            بالمبلغ
          </button>
        </div>

        {mode === "weight" ? (
          <div className="mt-4 space-y-3">
            <div className="flex items-center gap-2">
              <Input
                type="number"
                inputMode="numeric"
                min={minGrams}
                step={referenceGramPrice}
                value={Math.round(grams)}
                onChange={(e) => updateGrams(Math.max(0, Number(e.target.value) || 0))}
                className="text-base font-extrabold"
              />
              <span className="text-sm font-bold text-muted-foreground shrink-0">جم</span>
            </div>
            <div className="flex flex-wrap gap-1.5">
              {weightPresets.map((g) => (
                <button
                  key={g}
                  onClick={() => updateGrams(g)}
                  className={`text-[11px] font-bold px-3 py-1.5 rounded-full border transition-smooth ${
                    Math.round(grams) === g
                      ? "bg-primary text-primary-foreground border-transparent"
                      : "bg-secondary text-foreground border-border hover:bg-muted"
                  }`}
                >
                  {formatGrams(g)}
                </button>
              ))}
            </div>
          </div>
        ) : (
          <div className="mt-4 space-y-3">
            <div className="flex items-center gap-2">
              <Input
                type="number"
                inputMode="decimal"
                min={0}
                step={1}
                value={amount ? Number(amount.toFixed(2)) : ""}
                onChange={(e) => updateAmount(Math.max(0, Number(e.target.value) || 0))}
                className="text-base font-extrabold"
              />
              <span className="text-sm font-bold text-muted-foreground shrink-0">ج.م</span>
            </div>
            <div className="flex flex-wrap gap-1.5">
              {[10, 20, 50, 100, 200].map((a) => (
                <button
                  key={a}
                  onClick={() => updateAmount(a)}
                  className="text-[11px] font-bold px-3 py-1.5 rounded-full border bg-secondary text-foreground border-border hover:bg-muted transition-smooth"
                >
                  {a} ج.م
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Live result */}
        <div className="mt-5 p-3 rounded-xl bg-primary-soft/40 border border-primary/15 space-y-1">
          <div className="flex items-center justify-between text-xs font-bold text-muted-foreground">
            <span>الوزن النهائي</span>
            <span className="font-extrabold text-foreground">{formatGrams(finalGrams)}</span>
          </div>
          <div className="flex items-center justify-between text-xs font-bold text-muted-foreground">
            <span>الإجمالي</span>
            <span className="font-extrabold text-primary text-base">{formatPrice(finalPrice)}</span>
          </div>
        </div>

        {/* Validation */}
        {showError && (
          <div
            role="alert"
            aria-live="polite"
            className="mt-3 flex items-start gap-2 p-2.5 rounded-lg bg-discount/10 border border-discount/30"
          >
            <AlertCircle className="h-4 w-4 text-discount shrink-0 mt-0.5" />
            <div className="space-y-0.5">
              <p className="text-[11px] font-extrabold text-discount leading-relaxed">{errorMsg}</p>
              {errorHint && (
                <p className="text-[10px] font-bold text-discount/80 leading-relaxed">{errorHint}</p>
              )}
            </div>
          </div>
        )}

        <div className="mt-4 grid grid-cols-2 gap-2">
          {currentUnits > 0 && (
            <Button
              variant="outline"
              onClick={() => onConfirm(0)}
              className="font-extrabold"
            >
              إزالة من السلة
            </Button>
          )}
          <Button
            onClick={() => {
              setTouched(true);
              if (valid) onConfirm(units);
            }}
            disabled={!valid}
            className={`font-extrabold ${currentUnits > 0 ? "" : "col-span-2"}`}
          >
            {currentUnits > 0 ? "تحديث" : "أضف للسلة"}
          </Button>
        </div>
      </SheetContent>
    </Sheet>
  );
};
