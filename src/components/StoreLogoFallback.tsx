import { cn } from "@/lib/utils";

interface StoreLogoFallbackProps {
  name?: string;
  color?: string;
  className?: string;
}

/** Compute the text shown inside the auto-generated logo. */
function getLogoText(name?: string): string {
  const raw = (name ?? "").trim();
  if (!raw) return "?";
  // Strip whitespace for length check
  const compact = raw.replace(/\s+/g, "");
  if (compact.length <= 5) return raw;
  const words = raw.split(/\s+/).filter(Boolean);
  if (words.length >= 2) {
    // First letter of first two words
    return (words[0][0] ?? "") + (words[1][0] ?? "");
  }
  // Single long word → first two chars
  return compact.slice(0, 2);
}

/** Pick an adaptive font-size class based on text length. */
function getTextSizeClass(text: string): string {
  const len = text.length;
  if (len <= 2) return "text-base md:text-lg";
  if (len <= 3) return "text-sm md:text-base";
  if (len <= 4) return "text-[11px] md:text-sm";
  return "text-[10px] md:text-xs";
}

export const StoreLogoFallback = ({
  name,
  color,
  className,
}: StoreLogoFallbackProps) => {
  const text = getLogoText(name);
  const sizeClass = getTextSizeClass(text);

  // Subtle gradient using the store color for a more polished, "logo-like" look.
  const background = color
    ? `linear-gradient(135deg, ${color} 0%, ${color}dd 60%, ${color}b3 100%)`
    : undefined;

  return (
    <div
      className={cn(
        "rounded-2xl inline-flex items-center justify-center shadow-soft shrink-0 overflow-hidden",
        !color && "bg-primary",
        className,
      )}
      style={background ? { background } : undefined}
      aria-label={name}
    >
      <span
        className={cn(
          "font-extrabold text-white leading-none px-1 text-center truncate max-w-full",
          sizeClass,
        )}
        style={{
          textShadow: "0 1px 2px rgba(0,0,0,0.18)",
          fontFamily:
            "'Tajawal', 'Cairo', system-ui, -apple-system, sans-serif",
        }}
      >
        {text}
      </span>
    </div>
  );
};
