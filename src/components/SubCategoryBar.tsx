import { useTranslation } from "react-i18next";
import { StoreCategory } from "@/lib/api";
import { cn } from "@/lib/utils";

interface SubCategoryBarProps {
  subCategories: StoreCategory[];
  selected: number | null;
  onSelect: (id: number | null) => void;
}

/**
 * Pill-style horizontal bar shown under a main category title when that
 * category has children. The "الكل" pill clears the sub-filter.
 */
export const SubCategoryBar = ({
  subCategories,
  selected,
  onSelect,
}: SubCategoryBarProps) => {
  const { t } = useTranslation();
  if (subCategories.length === 0) return null;

  return (
    <div className="overflow-x-auto no-scrollbar -mx-1">
      <div className="flex items-center gap-2 px-1 py-2 w-max">
        <button
          onClick={() => onSelect(null)}
          className={cn(
            "shrink-0 px-3 py-1.5 rounded-full text-xs font-bold border transition-smooth",
            selected === null
              ? "bg-primary text-primary-foreground border-primary shadow-soft"
              : "bg-card text-muted-foreground border-border hover:border-primary/50",
          )}
        >
          {t("categories.allShort")}
        </button>
        {subCategories.map((sub) => {
          const active = selected === sub.id;
          return (
            <button
              key={sub.id}
              onClick={() => onSelect(active ? null : sub.id)}
              className={cn(
                "shrink-0 px-3 py-1.5 rounded-full text-xs font-bold border transition-smooth",
                active
                  ? "bg-primary text-primary-foreground border-primary shadow-soft"
                  : "bg-card text-foreground border-border hover:border-primary/50",
              )}
            >
              {sub.name}
            </button>
          );
        })}
      </div>
    </div>
  );
};
