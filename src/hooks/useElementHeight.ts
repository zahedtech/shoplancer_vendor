import { useEffect, useState } from "react";

/**
 * Returns the live `offsetHeight` of the first element matching `selector`,
 * or 0 when no such element exists. Re-measures on:
 *  - element mount/unmount (MutationObserver on document.body)
 *  - element resize (ResizeObserver)
 *  - window resize / orientation change
 *
 * Useful for stacking floating UI above bottom bars whose presence/height
 * varies between routes and breakpoints.
 */
export function useElementHeight(selector: string, enabled: boolean = true): number {
  const [height, setHeight] = useState(0);

  useEffect(() => {
    if (typeof window === "undefined") return;
    if (!enabled) {
      setHeight((prev) => (prev === 0 ? prev : 0));
      return;
    }

    let target: Element | null = null;
    let ro: ResizeObserver | null = null;
    let rafId = 0;
    let attachScheduled = false;

    // Defer geometry reads to the next animation frame so they don't
    // force a synchronous layout right after DOM mutations.
    const measure = () => {
      if (rafId) return;
      rafId = window.requestAnimationFrame(() => {
        rafId = 0;
        const h = target ? (target as HTMLElement).offsetHeight || 0 : 0;
        setHeight((prev) => (prev === h ? prev : h));
      });
    };

    const attach = () => {
      attachScheduled = false;
      const next = document.querySelector(selector);
      if (next === target) {
        measure();
        return;
      }
      if (ro) {
        ro.disconnect();
        ro = null;
      }
      target = next;
      if (target && "ResizeObserver" in window) {
        ro = new ResizeObserver(() => measure());
        ro.observe(target);
      }
      measure();
    };

    attach();

    // Coalesce mutation bursts so we only re-query the DOM once per frame.
    const scheduleAttach = () => {
      if (attachScheduled) return;
      attachScheduled = true;
      window.requestAnimationFrame(attach);
    };

    const mo = new MutationObserver(scheduleAttach);
    mo.observe(document.body, { childList: true, subtree: true });

    const onResize = () => measure();
    window.addEventListener("resize", onResize);
    window.addEventListener("orientationchange", onResize);

    return () => {
      if (rafId) window.cancelAnimationFrame(rafId);
      mo.disconnect();
      if (ro) ro.disconnect();
      window.removeEventListener("resize", onResize);
      window.removeEventListener("orientationchange", onResize);
    };
  }, [selector, enabled]);

  return height;
}
