import { useEffect, useState } from "react";

/**
 * Thin progress bar pinned to the top of the viewport that visualises how
 * far the user has scrolled between the "الجديد" and "العروض" sections.
 *
 * - 0% when the bottom of "الجديد" enters the viewport.
 * - 100% when the top of "العروض" reaches the top of the viewport.
 * - Hidden when the user is outside that range, so it doesn't distract on
 *   the rest of the page.
 */
export const SectionScrollProgress = ({
  fromId,
  toId,
}: {
  fromId: string;
  toId: string;
}) => {
  const [progress, setProgress] = useState(0);
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const compute = () => {
      const from = document.getElementById(fromId);
      const to = document.getElementById(toId);
      if (!from || !to) {
        setVisible(false);
        return;
      }
      const fromRect = from.getBoundingClientRect();
      const toRect = to.getBoundingClientRect();
      // Travel range: from the bottom of `from` reaching viewport top
      // until the top of `to` reaches viewport top.
      const start = window.scrollY + fromRect.bottom;
      const end = window.scrollY + toRect.top;
      const total = Math.max(end - start, 1);
      const current = window.scrollY - start;
      const pct = Math.min(Math.max(current / total, 0), 1);
      setProgress(pct);
      setVisible(window.scrollY >= start - 200 && window.scrollY <= end + 50);
    };
    compute();
    window.addEventListener("scroll", compute, { passive: true });
    window.addEventListener("resize", compute);
    return () => {
      window.removeEventListener("scroll", compute);
      window.removeEventListener("resize", compute);
    };
  }, [fromId, toId]);

  return (
    <div
      aria-hidden={!visible}
      className={`fixed top-0 inset-x-0 z-50 h-1 bg-transparent pointer-events-none transition-opacity duration-300 ${
        visible ? "opacity-100" : "opacity-0"
      }`}
    >
      <div
        className="h-full bg-primary shadow-glow transition-[width] duration-150 ease-out"
        style={{ width: `${progress * 100}%` }}
      />
    </div>
  );
};
