import { useTranslation } from "react-i18next";
import { StoreCategory } from "@/lib/api";
import { cn } from "@/lib/utils";

interface CategoryShowcaseProps {
  categories: StoreCategory[];
  onSelect: (id: number) => void;
  /** Maximum number of categories to render. Extras are hidden. */
  limit?: number;
}

/**
 * "Shop by category" grid for the home page — mirrors the reference design:
 * pill-shaped card with a pastel-tinted circular icon and a centered name.
 * Backgrounds rotate through a small palette so the grid feels lively
 * without being garish.
 */
const TONES = [
  "bg-[hsl(0_70%_96%)] text-[hsl(0_60%_55%)]",
  "bg-[hsl(28_90%_94%)] text-[hsl(28_70%_50%)]",
  "bg-[hsl(45_90%_92%)] text-[hsl(35_70%_45%)]",
  "bg-[hsl(200_85%_94%)] text-[hsl(200_70%_50%)]",
  "bg-[hsl(140_55%_92%)] text-[hsl(140_50%_38%)]",
  "bg-[hsl(330_70%_95%)] text-[hsl(330_55%_55%)]",
];

export const CategoryShowcase = ({
  categories,
  onSelect,
  limit = 12,
}: CategoryShowcaseProps) => {
  const { t } = useTranslation();
  if (categories.length === 0) return null;
  const items = categories.slice(0, limit);

  return (
    <section className="container py-8 md:py-10">
      <div className="flex items-end justify-between mb-5 md:mb-6">
        <div>
          <h2 className="text-2xl md:text-3xl font-extrabold text-foreground">
            {t("categories.sectionTitle")}
          </h2>
          <p className="text-sm text-muted-foreground mt-1">
            {t("categories.sectionSubtitle")}
          </p>
        </div>
      </div>

      <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-6 gap-3 md:gap-4">
        {items.map((cat, i) => {
          const tone = TONES[i % TONES.length];
          return (
            <button
              key={cat.id}
              onClick={() => onSelect(cat.id)}
              className="group flex flex-col items-center gap-2 md:gap-3 p-3 md:p-4 rounded-2xl bg-card border border-border/60 shadow-soft hover:shadow-card hover:-translate-y-0.5 transition-smooth"
            >
              <div
                className={cn(
                  "h-14 w-14 md:h-16 md:w-16 rounded-2xl inline-flex items-center justify-center overflow-hidden transition-smooth",
                  tone,
                )}
              >
                <img
                  src={cat.image_full_url}
                  alt={cat.name}
                  loading="lazy"
                  className="h-9 w-9 md:h-10 md:w-10 object-contain group-hover:scale-110 transition-smooth"
                />
              </div>
              <span className="text-xs md:text-sm font-bold text-center leading-tight line-clamp-2 text-foreground">
                {cat.name}
              </span>
            </button>
          );
        })}
      </div>
    </section>
  );
};
