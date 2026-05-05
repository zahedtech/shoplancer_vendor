import { useRef } from "react";
import { useTranslation } from "react-i18next";
import { StoreCategory } from "@/lib/api";
import { cn } from "@/lib/utils";

interface CategoryRailProps {
  categories: StoreCategory[];
  selected: number | null;
  onSelect: (id: number | null) => void;
}

/**
 * Vertical scrollable rail of categories shown on the right side, paired
 * with a product list to its left (matches the mobile-app pattern in the
 * provided design). On desktop we don't render this — the existing grid
 * remains the source of truth there.
 */
export const CategoryRail = ({
  categories,
  selected,
  onSelect,
}: CategoryRailProps) => {
  const railRef = useRef<HTMLDivElement>(null);
  const { t } = useTranslation();

  return (
    <aside
      ref={railRef}
      className="w-[88px] shrink-0 bg-card/40 rounded-2xl border border-border/60 overflow-y-auto no-scrollbar max-h-[calc(100vh-180px)] sticky top-[140px]"
      aria-label={t("categories.railLabel")}
    >
      <div className="flex flex-col">
        <button
          onClick={() => onSelect(null)}
          className={cn(
            "flex flex-col items-center gap-1.5 p-3 transition-smooth border-e-2",
            selected === null
              ? "bg-primary-soft border-primary text-primary"
              : "border-transparent text-foreground hover:bg-muted/50",
          )}
        >
          <div
            className={cn(
              "h-12 w-12 rounded-xl inline-flex items-center justify-center text-[11px] font-extrabold border",
              selected === null
                ? "border-primary bg-background"
                : "border-border bg-card",
            )}
          >
            {t("categories.allShort")}
          </div>
          <span className="text-[11px] font-bold leading-tight text-center">
            {t("categories.all")}
          </span>
        </button>

        {categories.map((cat) => {
          const active = selected === cat.id;
          return (
            <button
              key={cat.id}
              onClick={() => onSelect(active ? null : cat.id)}
              className={cn(
                "flex flex-col items-center gap-1.5 p-3 transition-smooth border-e-2",
                active
                  ? "bg-primary-soft border-primary"
                  : "border-transparent hover:bg-muted/50",
              )}
            >
              <div
                className={cn(
                  "h-12 w-12 rounded-xl overflow-hidden border bg-white shrink-0",
                  active ? "border-primary" : "border-border",
                )}
              >
                <img
                  src={cat.image_full_url}
                  alt={cat.name}
                  loading="lazy"
                  className="h-full w-full object-cover"
                />
              </div>
              <span
                className={cn(
                  "text-[11px] font-bold leading-tight text-center line-clamp-2 min-h-[1.6rem]",
                  active ? "text-primary" : "text-foreground",
                )}
              >
                {cat.name}
              </span>
            </button>
          );
        })}
      </div>
    </aside>
  );
};
