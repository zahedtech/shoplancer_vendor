import { StoreCategory } from "@/lib/api";
import { cn } from "@/lib/utils";

interface Props {
  categories: StoreCategory[];
  selected: number | null;
  onSelect: (id: number | null) => void;
  parentName?: string;
}

/**
 * Name-only sub-categories strip rendered under the banner on the Category
 * Detail page. Renders pills/chips with the category name, no images.
 */
export const SubCategoriesStrip = ({
  categories,
  selected,
  onSelect,
  parentName,
}: Props) => {
  if (categories.length === 0) return null;

  return (
    <section className="container pt-5 pb-6 md:pb-8">
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2.5">
          <span className="h-5 w-1 rounded-full bg-primary" aria-hidden />
          <h2 className="text-base md:text-lg font-extrabold tracking-tight">
            الأصناف الفرعية
            {parentName ? (
              <span className="text-muted-foreground font-bold mx-1">
                — {parentName}
              </span>
            ) : null}
          </h2>
        </div>
        {selected !== null && (
          <button
            type="button"
            onClick={() => onSelect(null)}
            className="text-xs font-extrabold text-primary hover:underline"
          >
            عرض الكل
          </button>
        )}
      </div>

      <div
        className="flex gap-2 overflow-x-auto no-scrollbar -mx-4 px-4 snap-x snap-mandatory pb-1"
        role="tablist"
        aria-label="الأصناف الفرعية"
      >
        {categories.map((cat) => {
          const active = selected === cat.id;
          return (
            <button
              key={cat.id}
              type="button"
              role="tab"
              onClick={() => onSelect(active ? null : cat.id)}
              title={cat.name}
              aria-pressed={active}
              aria-selected={active}
              className={cn(
                "shrink-0 snap-start whitespace-nowrap px-4 py-2 rounded-full text-xs md:text-sm font-bold border transition-all duration-200 focus:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 focus-visible:ring-offset-background",
                active
                  ? "bg-primary text-primary-foreground border-primary shadow-soft scale-[1.02]"
                  : "bg-card/80 backdrop-blur text-foreground border-border hover:bg-muted hover:border-primary/40 hover:-translate-y-0.5",
              )}
            >
              {cat.name}
            </button>
          );
        })}
      </div>
    </section>
  );
};


