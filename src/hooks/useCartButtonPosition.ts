import { useEffect, useState } from "react";

export type CartButtonPosition = "bottom-end" | "bottom-start";

const KEY = "ui.cartButtonPosition";
const EVENT = "cart-button-position-changed";
const DEFAULT: CartButtonPosition = "bottom-end";

function read(): CartButtonPosition {
  if (typeof window === "undefined") return DEFAULT;
  const v = window.localStorage.getItem(KEY);
  return v === "bottom-start" || v === "bottom-end" ? v : DEFAULT;
}

/**
 * User preference for the floating cart button's horizontal position.
 * Persists in localStorage and syncs across tabs/components.
 */
export function useCartButtonPosition(): [
  CartButtonPosition,
  (p: CartButtonPosition) => void,
] {
  const [pos, setPos] = useState<CartButtonPosition>(read);

  useEffect(() => {
    const onCustom = () => setPos(read());
    const onStorage = (e: StorageEvent) => {
      if (e.key === KEY) setPos(read());
    };
    window.addEventListener(EVENT, onCustom);
    window.addEventListener("storage", onStorage);
    return () => {
      window.removeEventListener(EVENT, onCustom);
      window.removeEventListener("storage", onStorage);
    };
  }, []);

  const update = (next: CartButtonPosition) => {
    window.localStorage.setItem(KEY, next);
    window.dispatchEvent(new CustomEvent(EVENT));
    setPos(next);
  };

  return [pos, update];
}
