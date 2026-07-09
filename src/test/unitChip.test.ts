import { describe, it, expect } from "vitest";
import {
  buildUnitChipDisplay,
  buildCartQtyDisplay,
  type ChipParams,
} from "@/lib/unitChip";

/**
 * Parity tests — ensure ProductCard, HorizontalProductRail's compact card,
 * and RecommendedLatestTabs's compact card render the EXACT same chip text
 * in every scenario, by asserting the single helper they all share.
 */

const base: ChipParams = {
  kind: "piece",
  final: 25,
  referenceGramPrice: 100,
  displayUnit: "علبة",
  isFallback: false,
};

describe("buildUnitChipDisplay (shared by ProductCard + Recommended + Latest + Deals)", () => {
  it("piece with explicit non-weight unit → null (chip hidden)", () => {
    expect(buildUnitChipDisplay(base)).toBeNull();
  });

  it("piece with fallback unit → null (chip hidden)", () => {
    expect(
      buildUnitChipDisplay({ ...base, displayUnit: "قطعة", isFallback: true }),
    ).toBeNull();
  });

  it("produce → '½ كجم'", () => {
    expect(buildUnitChipDisplay({ ...base, kind: "produce", displayUnit: "كجم" })).toBe(
      "½ كجم",
    );
  });

  it("attarah → '<price> / <reference grams>'", () => {
    const out = buildUnitChipDisplay({
      ...base,
      kind: "attarah",
      final: 50,
      referenceGramPrice: 100,
    });
    // formatPrice uses Arabic locale digits + " ج.م"; we just check the structure.
    expect(out).toMatch(/ج\.م \/ 100 جم$/);
  });

  it("attarah with kg-scale reference → uses كجم", () => {
    const out = buildUnitChipDisplay({
      ...base,
      kind: "attarah",
      final: 80,
      referenceGramPrice: 1000,
    });
    expect(out).toMatch(/ج\.م \/ 1 كجم$/);
  });

  it("packageSize override wins over piece default", () => {
    expect(buildUnitChipDisplay({ ...base, packageSize: "500 جم" })).toBe("500 جم");
  });

  it("packageSize multiplies with cartQuantity (100 جم × 2 → 200 جم)", () => {
    expect(
      buildUnitChipDisplay({ ...base, packageSize: "100 جم", cartQuantity: 2 }),
    ).toBe("200 جم");
  });

  it("packageSize auto-converts to كجم at ≥1000 جم", () => {
    expect(
      buildUnitChipDisplay({ ...base, packageSize: "100 جم", cartQuantity: 10 }),
    ).toBe("1 كجم");
    expect(
      buildUnitChipDisplay({ ...base, packageSize: "100 جم", cartQuantity: 15 }),
    ).toBe("1.5 كجم");
  });

  it("packageSize without cart shows raw value", () => {
    expect(
      buildUnitChipDisplay({ ...base, packageSize: "100 جم", cartQuantity: 0 }),
    ).toBe("100 جم");
  });

  it("packageSize override does NOT override attarah formatting", () => {
    const out = buildUnitChipDisplay({
      ...base,
      kind: "attarah",
      packageSize: "500 جم",
    });
    expect(out).toMatch(/ \/ /);
    expect(out).not.toBe("500 جم");
  });
});

describe("buildCartQtyDisplay parity", () => {
  it("attarah: cartQty * referenceGrams → grams string", () => {
    expect(
      buildCartQtyDisplay({
        ...base,
        kind: "attarah",
        cartQuantity: 3,
        referenceGramPrice: 100,
      }),
    ).toBe("300 جم");
  });

  it("produce: cartQty * 0.5 → kg label", () => {
    expect(
      buildCartQtyDisplay({
        ...base,
        kind: "produce",
        displayUnit: "كجم",
        cartQuantity: 3,
      }),
    ).toBe("1.5 كجم");
  });

  it("piece: just the integer", () => {
    expect(buildCartQtyDisplay({ ...base, cartQuantity: 4 })).toBe("4");
  });

  it("piece + packageSize: scales the package", () => {
    expect(
      buildCartQtyDisplay({ ...base, packageSize: "500 جم", cartQuantity: 3 }),
    ).toBe("1.5 كجم");
  });
});
