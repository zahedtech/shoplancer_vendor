import { PackageSearch } from "lucide-react";

interface EmptyRailProps {
  title: string;
  description?: string;
  actionLabel?: string;
  onAction?: () => void;
}

/**
 * Friendly fallback shown inside a horizontal rail/section when the API
 * returned zero products. Keeps the same vertical rhythm as a populated
 * rail so the layout doesn't jump.
 */
export const EmptyRail = ({
  title,
  description,
  actionLabel,
  onAction,
}: EmptyRailProps) => {
  return (
    <div
      dir="rtl"
      className="rounded-2xl border border-dashed border-border bg-card/60 p-6 flex flex-col items-center justify-center text-center gap-2 min-h-[160px]"
    >
      <div className="h-10 w-10 rounded-full bg-muted flex items-center justify-center text-muted-foreground">
        <PackageSearch className="h-5 w-5" />
      </div>
      <h3 className="text-sm font-extrabold text-foreground">{title}</h3>
      {description && (
        <p className="text-xs text-muted-foreground max-w-[260px]">
          {description}
        </p>
      )}
      {actionLabel && onAction && (
        <button
          onClick={onAction}
          className="mt-1 text-xs font-bold text-primary hover:underline"
        >
          {actionLabel}
        </button>
      )}
    </div>
  );
};
