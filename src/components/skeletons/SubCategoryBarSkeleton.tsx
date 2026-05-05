import { Skeleton } from "@/components/ui/skeleton";

/** Mirrors the shape of <SubCategoryBar /> while children are loading. */
export const SubCategoryBarSkeleton = ({ count = 6 }: { count?: number }) => (
  <div className="overflow-hidden -mx-1" aria-hidden="true">
    <div className="flex items-center gap-2 px-1 py-2 w-max">
      {Array.from({ length: count }).map((_, i) => (
        <Skeleton
          key={i}
          className="h-7 rounded-full"
          style={{ width: `${56 + ((i * 13) % 40)}px` }}
        />
      ))}
    </div>
  </div>
);
