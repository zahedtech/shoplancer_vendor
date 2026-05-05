import { useTranslation } from "react-i18next";
import { StoreCategory } from "@/lib/api";
import { cn } from "@/lib/utils";

interface CategoryGridProps {
  categories: StoreCategory[];
  selected: number | null;
  onSelect: (id: number | null) => void;
  loading?: boolean;
}

export const CategoryGrid = ({
  categories,
  selected,
  onSelect,
  loading,
}: CategoryGridProps) => {
  const { t } = useTranslation();
  return (
    <section id="categories" className="container py-8 md:py-10">
      <div className="flex items-end justify-between mb-6">
        <div>
          <h2 className="text-2xl md:text-3xl font-extrabold text-foreground">
            {t("categories.sectionTitle")}
          </h2>
          <p className="text-sm text-muted-foreground mt-1">
            {t("categories.sectionSubtitle")}
          </p>
        </div>
        {selected !== null && (
          <button
            onClick={() => onSelect(null)}
            className="text-sm text-primary font-bold hover:underline"
          >
            {t("categories.viewAll")}
          </button>
        )}
      </div>

      <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-6 gap-3 md:gap-4">
        {loading
          ? Array.from({ length: 6 }).map((_, i) => (
              <div
                key={i}
                className="aspect-square rounded-2xl bg-muted animate-pulse"
              />
            ))
          : categories.map((cat) => {
              const active = selected === cat.id;
              return (
                <button
                  key={cat.id}
                  onClick={() => onSelect(active ? null : cat.id)}
                  className={cn(
                    "group flex flex-col items-center gap-2 p-3 md:p-4 rounded-2xl border bg-card transition-smooth shadow-soft hover:shadow-card hover:-translate-y-0.5",
                    active
                      ? "border-primary ring-2 ring-primary/20 bg-primary-soft"
                      : "border-border/60"
                  )}
                >
                  <div
                    className={cn(
                      "h-14 w-14 md:h-16 md:w-16 rounded-2xl flex items-center justify-center overflow-hidden transition-smooth",
                      active ? "bg-background" : "bg-primary-soft"
                    )}
                  >
                    <img
                      src={cat.image_full_url}
                      alt={cat.name}
                      loading="lazy"
                      className="h-full w-full object-cover group-hover:scale-110 transition-smooth"
                    />
                  </div>
                  <span
                    className={cn(
                      "text-xs md:text-sm font-bold text-center leading-tight",
                      active ? "text-primary" : "text-foreground"
                    )}
                  >
                    {cat.name}
                  </span>
                </button>
              );
            })}
      </div>
    </section>
  );
};
