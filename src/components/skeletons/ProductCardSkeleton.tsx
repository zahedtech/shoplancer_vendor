import { cn } from "@/lib/utils";

interface ProductCardSkeletonProps {
  /** Compact variant matches the smaller cards used in horizontal rails. */
  compact?: boolean;
}

/**
 * Skeleton that matches the real <ProductCard /> layout (image, title,
 * price, action button) so the swap-in feels seamless.
 */
export const ProductCardSkeleton = ({ compact }: ProductCardSkeletonProps) => {
  return (
    <div
      className={cn(
        "relative bg-card rounded-2xl overflow-hidden border border-border/60 shadow-soft",
        compact ? "w-full" : "",
      )}
    >
      <div className={cn("bg-muted animate-pulse", compact ? "aspect-square" : "aspect-square")} />
      <div className="p-2.5 md:p-3 space-y-2">
        <div className="h-3.5 bg-muted animate-pulse rounded w-4/5" />
        <div className="h-3 bg-muted animate-pulse rounded w-2/5" />
        <div className="flex items-center justify-between pt-2">
          <div className="h-9 w-9 rounded-xl bg-muted animate-pulse" />
          <div className="h-4 w-14 bg-muted animate-pulse rounded" />
        </div>
      </div>
    </div>
  );
};
