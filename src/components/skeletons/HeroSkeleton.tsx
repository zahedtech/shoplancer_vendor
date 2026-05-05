import { cn } from "@/lib/utils";

interface Props {
  /** Use the clothes-style boutique gradient when true. */
  clothes?: boolean;
}

/**
 * Lightweight Hero skeleton — same height as the real Hero to prevent layout shift.
 */
export const HeroSkeleton = ({ clothes = false }: Props) => {
  return (
    <section className="px-3 sm:px-4 md:container py-3 md:py-5">
      <div
        className={cn(
          "relative overflow-hidden rounded-2xl shadow-card animate-pulse",
          clothes ? "gradient-hero-clothes" : "gradient-hero",
        )}
      >
        <div className="px-5 md:px-10 py-6 md:py-10 max-w-2xl">
          <div className="h-5 w-24 rounded-full bg-primary-foreground/20" />
          <div className="mt-3 h-7 md:h-9 w-3/4 rounded-lg bg-primary-foreground/25" />
          <div className="mt-2 h-4 w-2/3 rounded bg-primary-foreground/15" />
          <div className="mt-1.5 h-3 w-1/3 rounded bg-primary-foreground/10" />
          <div className="mt-4 flex gap-2">
            <div className="h-9 w-28 rounded-full bg-primary-foreground/25" />
            <div className="h-9 w-24 rounded-full bg-primary-foreground/15" />
          </div>
        </div>
      </div>
    </section>
  );
};
