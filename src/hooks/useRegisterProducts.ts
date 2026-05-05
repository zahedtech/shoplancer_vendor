import { useEffect } from "react";
import type { Product } from "@/lib/api";
import { registerProducts } from "@/lib/productAlternatives";

/**
 * Register a product list with the alternatives registry whenever it changes.
 * Used by every list/rail so we have a corpus to suggest from when an item
 * runs out of stock.
 */
export const useRegisterProducts = (products: Product[] | undefined) => {
  useEffect(() => {
    registerProducts(products ?? []);
  }, [products]);
};
