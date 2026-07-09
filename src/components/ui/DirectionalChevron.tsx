import { ChevronLeft, type LucideProps } from "lucide-react";
import { cn } from "@/lib/utils";

/**
 * Forward-pointing chevron that respects document direction.
 *
 * In RTL (Arabic), reading flows right→left, so "next/forward" should point left.
 * In LTR, "next/forward" should point right.
 *
 * Implementation: render `ChevronLeft` (points left by default → correct for RTL)
 * and rotate 180° when the document is LTR.
 */
export const DirectionalChevron = ({
  className,
  ...props
}: LucideProps) => {
  return (
    <ChevronLeft
      {...props}
      className={cn("ltr:rotate-180", className)}
    />
  );
};

export default DirectionalChevron;
