import { ChevronLeft } from "lucide-react";
import { ReactNode } from "react";

interface Props {
  icon: ReactNode;
  label: string;
  trailing?: ReactNode;
  onClick?: () => void;
  iconBg?: "primary" | "info";
}

export const SettingsRow = ({
  icon,
  label,
  trailing,
  onClick,
  iconBg = "primary",
}: Props) => {
  const Comp = onClick ? "button" : "div";
  return (
    <Comp
      type={onClick ? "button" : undefined}
      onClick={onClick}
      className="w-full flex items-center gap-3 py-3 text-start hover:bg-secondary/40 px-1 rounded-xl transition-smooth"
    >
      <span
        className={
          "h-10 w-10 rounded-xl inline-flex items-center justify-center shrink-0 " +
          (iconBg === "info"
            ? "bg-accent/15 text-accent"
            : "bg-primary-soft text-primary")
        }
      >
        {icon}
      </span>
      <span className="flex-1 font-bold text-sm text-foreground text-start">
        {label}
      </span>
      {trailing ?? (
        onClick ? <ChevronLeft className="h-4 w-4 text-muted-foreground ltr:rotate-180" /> : null
      )}
    </Comp>
  );
};
