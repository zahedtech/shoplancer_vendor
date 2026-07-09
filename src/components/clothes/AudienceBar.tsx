import { useSearchParams } from "react-router-dom";
import { User, UserRound, Baby, LayoutGrid } from "lucide-react";
import { cn } from "@/lib/utils";
import type { Audience } from "@/lib/audienceMapping";

const TABS: Array<{ key: Audience | "all"; label: string; Icon: typeof User }> = [
  { key: "all", label: "الكل", Icon: LayoutGrid },
  { key: "women", label: "نسائي", Icon: UserRound },
  { key: "men", label: "رجالي", Icon: User },
  { key: "kids", label: "أطفال", Icon: Baby },
];

interface Props {
  className?: string;
}

/**
 * Sticky audience filter chips for clothing storefronts.
 * State is mirrored to URL ?audience=... so it can be shared.
 */
export const AudienceBar = ({ className }: Props) => {
  const [params, setParams] = useSearchParams();
  const current = (params.get("audience") as Audience | null) ?? "all";

  const select = (key: Audience | "all") => {
    const next = new URLSearchParams(params);
    if (key === "all") next.delete("audience");
    else next.set("audience", key);
    setParams(next, { replace: true });
  };

  return (
    <div
      className={cn(
        "px-3 sm:px-4 md:container py-3 md:py-4 flex gap-2 overflow-x-auto no-scrollbar",
        className,
      )}
      dir="rtl"
    >
      {TABS.map(({ key, label, Icon }) => {
        const active = current === key;
        return (
          <button
            key={key}
            type="button"
            onClick={() => select(key)}
            className={cn(
              "shrink-0 inline-flex items-center gap-1.5 px-3.5 py-2 rounded-full text-xs font-extrabold border transition-smooth",
              active
                ? "bg-primary text-primary-foreground border-transparent shadow-soft"
                : "bg-card text-foreground border-border hover:bg-muted",
            )}
          >
            <Icon className="h-3.5 w-3.5" />
            {label}
          </button>
        );
      })}
    </div>
  );
};

/** Read the active audience from the URL (helper for consumers). */
export function useCurrentAudience(): Audience | null {
  const [params] = useSearchParams();
  const v = params.get("audience");
  if (v === "men" || v === "women" || v === "kids") return v;
  return null;
}
