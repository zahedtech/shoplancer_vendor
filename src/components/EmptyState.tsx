import { LucideIcon, PackageSearch } from "lucide-react";
import { cn } from "@/lib/utils";

interface EmptyStateProps {
  icon?: LucideIcon;
  title: string;
  description?: string;
  action?: {
    label: string;
    onClick: () => void;
  };
  secondaryAction?: {
    label: string;
    onClick: () => void;
  };
  className?: string;
}

/**
 * Friendly empty state used across the app. Keeps copy and visual rhythm
 * consistent so users always know what to do next.
 */
export const EmptyState = ({
  icon: Icon = PackageSearch,
  title,
  description,
  action,
  secondaryAction,
  className,
}: EmptyStateProps) => {
  return (
    <div
      className={cn(
        "text-center py-12 px-6 bg-card rounded-2xl border border-border/60 shadow-soft",
        className,
      )}
    >
      <div className="mx-auto h-14 w-14 rounded-2xl bg-primary-soft text-primary inline-flex items-center justify-center mb-4">
        <Icon className="h-7 w-7" />
      </div>
      <h3 className="text-base font-extrabold text-foreground">{title}</h3>
      {description && (
        <p className="text-sm text-muted-foreground mt-1.5 max-w-sm mx-auto">
          {description}
        </p>
      )}
      {(action || secondaryAction) && (
        <div className="mt-4 flex items-center justify-center gap-2 flex-wrap">
          {action && (
            <button
              onClick={action.onClick}
              className="inline-flex items-center justify-center h-10 px-5 rounded-full bg-primary text-primary-foreground text-sm font-bold shadow-soft hover:bg-primary-glow hover:shadow-glow transition-smooth"
            >
              {action.label}
            </button>
          )}
          {secondaryAction && (
            <button
              onClick={secondaryAction.onClick}
              className="inline-flex items-center justify-center h-10 px-5 rounded-full bg-secondary text-foreground text-sm font-bold border border-border hover:bg-muted transition-smooth"
            >
              {secondaryAction.label}
            </button>
          )}
        </div>
      )}
    </div>
  );
};

