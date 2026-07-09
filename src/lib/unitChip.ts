/**
 * Pure helpers that compute the unit-chip display string and the in-cart
 * quantity display string. Centralizing them here means ProductCard and the
 * compact cards (HorizontalProductRail / RecommendedLatestTabs) all show the
 * exact same text in every scenario (attarah, half-kilo produce, fallback,
 * package-size override). Pure ⇒ easy to unit-test.
 */
import { formatPrice } from "@/lib/api";
import { formatGrams } from "@/components/AttarahPickerSheet";

export type ChipKind = "attarah" | "produce" | "piece";

export interface ChipParams {
  kind: ChipKind;
  /** Final (discounted) price per reference unit / per piece. */
  final: number;
  /** For attarah: grams represented by `final`. */
  referenceGramPrice: number;
  /** Resolved unit label ("كجم" for produce, raw unit_type otherwise). */
  displayUnit: string;
  /** True when no unit_type was provided and we fell back to the default. */
  isFallback: boolean;
  /** Optional admin-set "package size" override (e.g. "500 جم"). */
  packageSize?: string;
  /**
   * Optional in-cart quantity. When provided AND `packageSize` is a numeric
   * weight/volume (e.g. "100 جم"), the chip multiplies it by the cart qty
   * (100 → 200 → 300 جم, auto-converts to كجم at ≥1000).
   */
  cartQuantity?: number;
}

const formatAmount = (n: number) =>
  n % 1 === 0 ? n.toString() : n.toFixed(2).replace(/\.?0+$/, "");

const formatHalfKiloQty = (qty: number) => {
  const kg = qty * 0.5;
  return kg % 1 === 0 ? kg.toString() : kg.toFixed(1);
};

const parsePackageSize = (
  raw?: string,
): { amount: number; unit: string } | null => {
  if (!raw) return null;
  const m = raw.trim().match(/^([\d.,]+)\s*(.+)$/);
  if (!m) return null;
  const amount = parseFloat(m[1].replace(",", "."));
  if (!Number.isFinite(amount) || amount <= 0) return null;
  return { amount, unit: m[2].trim() };
};

const multiplyPackageSize = (
  pkg: { amount: number; unit: string },
  qty: number,
): string => {
  let amount = pkg.amount * qty;
  let unit = pkg.unit;
  const u = unit.toLowerCase();
  if (
    (u === "جم" || u.includes("غرام") || u.includes("جرام") || u === "g") &&
    amount >= 1000
  ) {
    amount = amount / 1000;
    unit = "كجم";
  } else if ((u === "مل" || u.includes("ميلي") || u === "ml") && amount >= 1000) {
    amount = amount / 1000;
    unit = "لتر";
  }
  return `${formatAmount(amount)} ${unit}`;
};

/**
 * Returns true when the package-size override expresses a weight or volume
 * unit we want to surface (grams, kilos, ml, liters). Anything else (قطعة،
 * علبة، حبة...) is treated as non-measurable and the chip is hidden.
 */
const isWeightOrVolumeUnit = (rawUnit: string): boolean => {
  const u = rawUnit.trim().toLowerCase();
  return (
    u === "جم" ||
    u === "غ" ||
    u === "g" ||
    u === "كجم" ||
    u === "كغ" ||
    u === "kg" ||
    u === "مل" ||
    u === "ml" ||
    u === "لتر" ||
    u === "l" ||
    u.includes("غرام") ||
    u.includes("جرام") ||
    u.includes("كيلو") ||
    u.includes("ميلي")
  );
};

/**
 * Returns the chip text shown at the bottom-left of the product image,
 * or null when the product is not measured in grams/kilos (or ml/liters)
 * — in that case the chip is hidden across the whole app.
 *
 * Rules (kept identical across every card):
 * - attarah → "<price> / <reference grams>"
 * - produce (sold by ½ kg) → "½ كجم"
 * - package-size override with a weight/volume unit → that string
 *   (multiplied by cartQty when present)
 * - everything else (piece / package-size with non-weight unit) → null
 */
export const buildUnitChipDisplay = (p: ChipParams): string | null => {
  if (p.kind === "attarah") {
    return `${formatPrice(p.final)} / ${formatGrams(p.referenceGramPrice)}`;
  }
  if (p.packageSize) {
    const parsed = parsePackageSize(p.packageSize);
    if (parsed && isWeightOrVolumeUnit(parsed.unit)) {
      if (p.cartQuantity && p.cartQuantity > 0) {
        return multiplyPackageSize(parsed, p.cartQuantity);
      }
      return p.packageSize;
    }
    // Package size present but not a weight/volume unit → hide chip.
    return null;
  }
  if (p.kind === "produce") return `½ ${p.displayUnit}`;
  // Piece without a weight/volume package size → hide chip.
  return null;
};

export interface CartQtyParams extends ChipParams {
  cartQuantity: number;
}

/** Returns the in-cart quantity chip text, or null when not in cart. */
export const buildCartQtyDisplay = (p: CartQtyParams): string => {
  if (p.kind === "attarah") {
    return formatGrams(p.cartQuantity * p.referenceGramPrice);
  }
  const parsed = parsePackageSize(p.packageSize);
  if (parsed) return multiplyPackageSize(parsed, p.cartQuantity);
  if (p.kind === "produce")
    return `${formatHalfKiloQty(p.cartQuantity)} ${p.displayUnit}`;
  return `${p.cartQuantity}`;
};
