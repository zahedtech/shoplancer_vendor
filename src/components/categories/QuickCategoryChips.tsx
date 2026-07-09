import { useMemo, useState } from "react";
import { ChevronDown, ChevronUp } from "lucide-react";
import { useTranslation } from "react-i18next";
import { StoreCategory } from "@/lib/api";
import { cn } from "@/lib/utils";

interface QuickCategoryChipsProps {
  categories: StoreCategory[];
  selected: number | null;
  onSelect: (id: number | null) => void;
  /** How many chips to show before requiring "show all". Default: 12. */
  collapsedCount?: number;
}

/**
 * Wrap-style quick category chips for the Categories page.
 * - No horizontal scroll: chips wrap onto multiple lines.
 * - Collapsible to keep the section compact on mobile.
 */
export const QuickCategoryChips = ({
  categories,
  selected,
  onSelect,
  collapsedCount = 12,
}: QuickCategoryChipsProps) => {
  const { t } = useTranslation();
  const [expanded, setExpanded] = useState(false);

  const total = categories.length;
  const showToggle = total > collapsedCount;

  const visible = useMemo(
    () => (expanded || !showToggle ? categories : categories.slice(0, collapsedCount)),
    [categories, expanded, showToggle, collapsedCount],
  );

  if (total === 0) return null;

  return (
    <div className="rounded-2xl bg-card/60 border border-border/60 shadow-soft p-2.5 md:p-3">
      <div className="flex flex-wrap gap-2">
        <button
          onClick={() => onSelect(null)}
          className={cn(
            "inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs md:text-sm font-bold border transition-smooth",
            selected === null
              ? "bg-primary text-primary-foreground border-primary shadow-soft"
              : "bg-background text-foreground border-border hover:border-primary/40",
          )}
        >
          {t("categories.all")}
        </button>

        {visible.map((cat) => {
          const active = selected === cat.id;
          return (
            <button
              key={cat.id}
              onClick={() => onSelect(active ? null : cat.id)}
              className={cn(
                "inline-flex items-center gap-1.5 ps-1 pe-3 py-1 rounded-full text-xs md:text-sm font-bold border transition-smooth max-w-full",
                active
                  ? "bg-primary text-primary-foreground border-primary shadow-soft"
                  : "bg-background text-foreground border-border hover:border-primary/40",
              )}
              title={cat.name}
            >
              {cat.image_full_url ? (
                <span
                  className={cn(
                    "h-6 w-6 rounded-full overflow-hidden bg-white border shrink-0",
                    active ? "border-primary-foreground/40" : "border-border",
                  )}
                >
                  <img
                    src={cat.image_full_url}
                    alt=""
                    loading="lazy"
                    className="h-full w-full object-cover"
                  />
                </span>
              ) : (
                <span className="h-6 w-6 rounded-full bg-muted shrink-0" />
              )}
              <span className="truncate max-w-[140px]">{cat.name}</span>
            </button>
          );
        })}
      </div>

      {showToggle && (
        <div className="flex justify-center pt-2">
          <button
            onClick={() => setExpanded((v) => !v)}
            className="inline-flex items-center gap-1 text-xs font-bold text-primary hover:underline"
          >
            {expanded ? t("categories.showLess") : t("categories.showAll")}
            {expanded ? (
              <ChevronUp className="h-3.5 w-3.5" />
            ) : (
              <ChevronDown className="h-3.5 w-3.5" />
            )}
          </button>
        </div>
      )}
    </div>
  );
};
