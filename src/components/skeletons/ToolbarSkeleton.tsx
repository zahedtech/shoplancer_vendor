import { Skeleton } from "@/components/ui/skeleton";

/** Mirrors <CategoryToolbar /> while the first page is loading. */
export const ToolbarSkeleton = () => (
  <div className="flex items-center justify-between gap-2 mb-3 md:mb-5">
    <Skeleton className="h-4 w-20" />
    <div className="flex items-center gap-2">
      <Skeleton className="h-9 w-[140px]" />
      <Skeleton className="h-9 w-24" />
    </div>
  </div>
);
