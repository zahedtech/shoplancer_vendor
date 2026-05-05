import { useStore } from "@/context/StoreContext";

/**
 * Splash screen shown while the store data is loading. Displays the store logo
 * (or a graceful fallback) and a "Powered by Shoplanser" wordmark on the same
 * vertical stack as the title — kept compact to feel instant.
 */
export function StoreSplash() {
  const { store } = useStore();
  const logo = store?.logo_full_url;
  const name = store?.name;

  return (
    <div
      className="min-h-screen flex flex-col items-center justify-center bg-background px-6 py-10"
      role="status"
      aria-live="polite"
      aria-label={name ? `جارٍ تحميل ${name}` : "جارٍ التحميل"}
    >
      <div className="flex flex-col items-center gap-4 animate-in fade-in zoom-in-95 duration-300">
        <div className="h-28 w-28 md:h-32 md:w-32 rounded-3xl bg-card shadow-lg ring-1 ring-border overflow-hidden flex items-center justify-center">
          {logo ? (
            <img
              src={logo}
              alt={name ?? ""}
              className="h-full w-full object-contain p-3"
              loading="eager"
              fetchPriority="high"
            />
          ) : (
            <div className="h-full w-full bg-muted animate-pulse" />
          )}
        </div>

        {name ? (
          <h1 className="text-lg md:text-xl font-extrabold text-foreground text-center leading-tight">
            {name}
          </h1>
        ) : (
          <div className="h-5 w-32 rounded bg-muted animate-pulse" />
        )}

        {/* Powered-by sits right under the title with a matching font size */}
        <p className="text-lg md:text-xl text-muted-foreground text-center leading-tight">
          Powered by{" "}
          <span className="font-extrabold">
            <span className="text-foreground">Shop</span>
            <span style={{ color: "hsl(220, 90%, 35%)" }}>lanser</span>
          </span>
        </p>

        {/* Subtle loading indicator */}
        <div className="mt-2 h-1 w-20 overflow-hidden rounded-full bg-muted">
          <div className="h-full w-1/2 bg-primary animate-[loading_1s_ease-in-out_infinite]" />
        </div>
      </div>

      <style>{`
        @keyframes loading {
          0% { transform: translateX(-100%); }
          100% { transform: translateX(200%); }
        }
      `}</style>
    </div>
  );
}

