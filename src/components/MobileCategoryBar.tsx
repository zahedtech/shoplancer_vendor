import { useTranslation } from "react-i18next";
import { StoreCategory } from "@/lib/api";
import { cn } from "@/lib/utils";

interface MobileCategoryBarProps {
  categories: StoreCategory[];
  selected: number | null;
  onSelect: (id: number | null) => void;
}

/**
 * Sticky horizontal categories bar shown on mobile.
 * Always visible — does NOT hide on scroll so the navigation feels stable.
 */
export const MobileCategoryBar = ({
  categories,
  selected,
  onSelect,
}: MobileCategoryBarProps) => {
  const { t } = useTranslation();

  if (categories.length === 0) return null;

  return (
    <div
      className={cn(
        "md:hidden sticky top-[68px] z-20 bg-background/95 backdrop-blur border-b border-border",
      )}
    >
      <div className="overflow-x-auto no-scrollbar">
        <div className="flex items-center gap-2 px-3 py-2 w-max">
          <button
            onClick={() => onSelect(null)}
            className={cn(
              "shrink-0 flex flex-col items-center gap-1 px-2 py-1 rounded-xl transition-smooth",
              selected === null ? "text-primary" : "text-muted-foreground",
            )}
          >
            <div
              className={cn(
                "h-12 w-12 rounded-full flex items-center justify-center text-[10px] font-extrabold border-2 transition-smooth",
                selected === null
                  ? "border-primary bg-primary-soft text-primary"
                  : "border-border bg-card",
              )}
            >
              {t("categories.allShort")}
            </div>
            <span className="text-[10px] font-bold">{t("categories.all")}</span>
          </button>

          {categories.map((cat) => {
            const active = selected === cat.id;
            return (
              <button
                key={cat.id}
                onClick={() => onSelect(active ? null : cat.id)}
                className={cn(
                  "shrink-0 flex flex-col items-center gap-1 px-1 py-1 rounded-xl transition-smooth max-w-[72px]",
                )}
              >
                <div
                  className={cn(
                    "h-12 w-12 rounded-full overflow-hidden border-2 transition-smooth",
                    active
                      ? "border-primary ring-2 ring-primary/20"
                      : "border-border bg-card",
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
                    "text-[10px] font-bold leading-tight text-center line-clamp-1",
                    active ? "text-primary" : "text-foreground",
                  )}
                >
                  {cat.name}
                </span>
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
};
