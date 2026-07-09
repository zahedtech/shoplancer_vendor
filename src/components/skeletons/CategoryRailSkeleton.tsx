import { Skeleton } from "@/components/ui/skeleton";

/** Mirrors the shape of <CategoryRail />. */
export const CategoryRailSkeleton = () => (
  <aside className="w-[88px] shrink-0 bg-card/40 rounded-2xl border border-border/60 overflow-hidden max-h-[calc(100vh-180px)] sticky top-[140px]">
    <div className="flex flex-col gap-1 p-2">
      {Array.from({ length: 8 }).map((_, i) => (
        <div key={i} className="flex flex-col items-center gap-1.5 p-2">
          <Skeleton className="h-12 w-12 rounded-xl" />
          <Skeleton className="h-3 w-12" />
        </div>
      ))}
    </div>
  </aside>
);
