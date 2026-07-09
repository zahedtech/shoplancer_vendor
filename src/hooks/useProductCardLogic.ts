import { useState } from "react";
import { useTranslation } from "react-i18next";
import { Product, getDiscountedPrice } from "@/lib/api";
import { useCart } from "@/context/CartContext";
import { useStoreSlug } from "@/context/StoreContext";
import { useUnitSizeOverrides } from "@/hooks/useUnitSizeOverrides";
import { useProductKind } from "@/hooks/useProductKind";
import {
  buildUnitChipDisplay,
  buildCartQtyDisplay,
  type ChipKind,
} from "@/lib/unitChip";

const resolveUnitLabel = (raw: string | null | undefined, fallback: string) => {
  const trimmed = raw?.trim();
  if (!trimmed) return { label: fallback, isFallback: true };
  return { label: trimmed, isFallback: false };
};

/**
 * Shared product card logic — used by ProductCard, HorizontalProductRail's
 * compact card, and RecommendedLatestTabs's compact card so all three apply
 * the same produce / attarah / piece behavior, the same Sheet, and the same
 * cart sync.
 */
export const useProductCardLogic = (product: Product) => {
  const { t } = useTranslation();
  const { final, hasDiscount, pct } = getDiscountedPrice(product);
  const { items, addItem, increment, decrement, setQuantity } = useCart();
  const inCart = items.find((i) => i.id === product.id);

  const slug = useStoreSlug();
  const sizeMap = useUnitSizeOverrides(slug);
  const kindInfo = useProductKind(slug, product);
  const { kind: rawKind, referenceGramPrice, minGrams } = kindInfo;

  const { label: resolvedLabel, isFallback } = resolveUnitLabel(
    product.unit_type,
    t("productCard.defaultUnit"),
  );

  const byWeight = rawKind === "produce";
  const isAttarah = rawKind === "attarah";
  const displayUnit = byWeight ? t("productCard.kilo") : resolvedLabel;
  const [attarahOpen, setAttarahOpen] = useState(false);
  const [alternativesOpen, setAlternativesOpen] = useState(false);

  const stock = product.stock ?? 0;
  const outOfStock = stock <= 0;

  const packageSize = sizeMap[product.id];

  const chipKind: ChipKind = isAttarah ? "attarah" : byWeight ? "produce" : "piece";
  const chipParams = {
    kind: chipKind,
    final,
    referenceGramPrice,
    displayUnit,
    isFallback,
    packageSize,
    cartQuantity: inCart?.quantity ?? 0,
  };

  const unitChipText = buildUnitChipDisplay(chipParams);
  const cartQtyDisplay = inCart
    ? buildCartQtyDisplay({ ...chipParams, cartQuantity: inCart.quantity })
    : null;

  const handleAdd = () => {
    // Out-of-stock → open alternatives instead of adding.
    if (outOfStock) {
      setAlternativesOpen(true);
      return;
    }
    if (isAttarah) {
      setAttarahOpen(true);
      return;
    }
    if (inCart) increment(product.id);
    else addItem(product, { kind: "produce_or_piece", stock });
  };

  const handleDecrement = () => {
    if (isAttarah) {
      setAttarahOpen(true);
      return;
    }
    decrement(product.id);
  };

  const handleAttarahConfirm = (units: number) => {
    if (units <= 0) {
      if (inCart) setQuantity(product.id, 0);
    } else {
      addItem(product, {
        quantity: units,
        kind: "attarah",
        referenceGramPrice,
        minGrams,
        stock,
      });
    }
    setAttarahOpen(false);
  };

  return {
    // pricing
    final,
    hasDiscount,
    pct,
    // kind
    kind: rawKind,
    isAttarah,
    byWeight,
    referenceGramPrice,
    minGrams,
    // stock
    stock,
    outOfStock,
    // display
    displayUnit,
    /** Final chip text — identical across ProductCard and compact cards. */
    unitChipText,
    cartQtyDisplay,
    // cart
    inCart,
    // actions
    handleAdd,
    handleDecrement,
    handleAttarahConfirm,
    // sheet state
    attarahOpen,
    setAttarahOpen,
    alternativesOpen,
    setAlternativesOpen,
  };
};
