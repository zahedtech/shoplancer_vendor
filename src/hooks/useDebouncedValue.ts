import { useEffect, useState } from "react";

/**
 * Returns `value` after it has been stable for `delay` ms.
 * Useful for collapsing rapid user input (e.g. fast pill switching) into a
 * single downstream effect / network request.
 */
export function useDebouncedValue<T>(value: T, delay = 150): T {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const id = window.setTimeout(() => setDebounced(value), delay);
    return () => window.clearTimeout(id);
  }, [value, delay]);
  return debounced;
}
