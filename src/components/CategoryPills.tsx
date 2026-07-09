import { useEffect, useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import { StoreCategory } from "@/lib/api";
import { cn } from "@/lib/utils";

interface CategoryPillsProps {
  categories: StoreCategory[];
  selected: number | null;
  onSelect: (id: number | null) => void;
  /** ID of the products section so the bar can sticky once scrolled past it. */
  anchorRef?: React.RefObject<HTMLElement | null>;
  /**
   * `default` — sticks to the top of the viewport once scrolled past.
   * `inline-only` — renders inline only, no sticky overlay (for in-page use).
   */
  variant?: "default" | "inline-only";
}

/**
 * Horizontal pill list of categories — replaces the large
 * "Shop by category" grid on the home page.
 *
 * - Always visible inline at the top of the categories section.
 * - Becomes sticky once the user scrolls past the inline position
 *   (only when variant is `default`).
 */
export const CategoryPills = ({
  categories,
  selected,
  onSelect,
  variant = "default",
}: CategoryPillsProps) => {
  const inlineRef = useRef<HTMLDivElement | null>(null);
  const lastY = useRef(0);
  const [isStuck, setIsStuck] = useState(false);
  const [visible, setVisible] = useState(true);
  const { t } = useTranslation();

  useEffect(() => {
    if (variant === "inline-only") return;
    lastY.current = window.scrollY;
    const handleScroll = () => {
      const y = window.scrollY;
      const inlineEl = inlineRef.current;
      if (inlineEl) {
        const rect = inlineEl.getBoundingClientRect();
        setIsStuck(rect.top <= 64);
      }
      const diff = y - lastY.current;
      if (diff < -6) setVisible(true);
      else if (diff > 6 && y > 200) setVisible(false);
      lastY.current = y;
    };
    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, [variant]);

  if (categories.length === 0) return null;

  const inline = variant === "inline-only";
  const renderPills = () => (
    <div className="overflow-x-auto no-scrollbar">
      <div className={cn("flex items-center gap-2 py-2.5 w-max", inline ? "ps-1.5 md:ps-3 pe-0" : "px-3 md:px-6")}>
        <button
          onClick={() => onSelect(null)}
          className={cn(
            "shrink-0 px-4 py-2 rounded-full text-sm font-bold transition-smooth border",
            selected === null
              ? "bg-primary text-primary-foreground border-primary shadow-soft"
              : "bg-card text-foreground border-border hover:border-primary/40",
          )}
        >
          {t("categories.all")}
        </button>
        {categories.map((cat) => {
          const active = selected === cat.id;
          return (
            <button
              key={cat.id}
              onClick={() => onSelect(active ? null : cat.id)}
              className={cn(
                "shrink-0 px-4 py-2 rounded-full text-sm font-bold transition-smooth border whitespace-nowrap",
                active
                  ? "bg-primary text-primary-foreground border-primary shadow-soft"
                  : "bg-card text-foreground border-border hover:border-primary/40",
              )}
            >
              {cat.name}
            </button>
          );
        })}
      </div>
    </div>
  );

  if (inline) {
    return renderPills();
  }

  return (
    <>
      {/* Inline pills — placeholder spot at the top of the categories section */}
      <div ref={inlineRef} className="container py-2">
        <div className="rounded-2xl bg-card/60 border border-border/60 shadow-soft">
          {renderPills()}
        </div>
      </div>

      {/* Sticky overlay — only mounted when the user has scrolled past the inline bar */}
      <div
        className={cn(
          "fixed left-0 right-0 top-[68px] z-30 bg-background/95 backdrop-blur border-b border-border transition-all duration-300",
          isStuck && visible
            ? "translate-y-0 opacity-100 pointer-events-auto"
            : "-translate-y-full opacity-0 pointer-events-none",
        )}
      >
        {renderPills()}
      </div>
    </>
  );
};
