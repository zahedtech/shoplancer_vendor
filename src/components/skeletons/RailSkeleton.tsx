/**
 * Horizontal skeleton row matching the CompactProductCard layout.
 * Dimensions are pinned to the real card so swapping skeleton → cards
 * produces zero layout shift (CLS).
 */
export const RailSkeleton = ({ count = 6 }: { count?: number }) => {
  return (
    <div className="overflow-x-auto no-scrollbar -mx-4 px-4 h-[230px]">
      <div className="flex gap-3 snap-x snap-mandatory pb-2 h-full">
        {Array.from({ length: count }).map((_, i) => (
          <div
            key={i}
            className="shrink-0 w-[130px] sm:w-[140px] snap-start bg-card rounded-2xl border border-border/60 overflow-hidden shadow-soft"
          >
            <div className="aspect-[4/3] bg-muted animate-pulse" />
            <div className="p-2.5 space-y-1.5">
              <div className="h-3.5 bg-muted animate-pulse rounded w-4/5" />
              <div className="h-3 bg-muted animate-pulse rounded w-2/5" />
              <div className="flex items-end justify-between pt-1">
                <div className="h-8 w-8 rounded-full bg-muted animate-pulse" />
                <div className="h-4 w-12 bg-muted animate-pulse rounded" />
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};
