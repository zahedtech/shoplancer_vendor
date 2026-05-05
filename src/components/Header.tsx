import { useEffect, useState } from "react";
import { Bookmark, Download, Mic, Search, Share, X } from "lucide-react";
import { StoreLogoFallback } from "@/components/StoreLogoFallback";
import { Link, useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Input } from "@/components/ui/input";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import { StoreDetails } from "@/lib/api";
import { useStore } from "@/context/StoreContext";
import { useWatchlist } from "@/context/WatchlistContext";
import { useInstallPrompt } from "@/hooks/useInstallPrompt";
import { useIsMobile } from "@/hooks/use-mobile";
import { cn } from "@/lib/utils";

interface HeaderProps {
  store?: StoreDetails;
  search: string;
  onSearchChange: (v: string) => void;
}

export const Header = ({ store, search, onSearchChange }: HeaderProps) => {
  const { slug } = useStore();
  const { items: watchedItems } = useWatchlist();
  const watchedCount = watchedItems.length;
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [scrolled, setScrolled] = useState(false);
  const isMobile = useIsMobile();
  const {
    canInstall,
    isIOS,
    isStandalone,
    isInstallable,
    promptInstall,
    dismiss,
  } = useInstallPrompt();
  const [installOpen, setInstallOpen] = useState(false);
  const showInstallButton = isMobile && !isStandalone && isInstallable;

  // Auto-open the popover once on first eligibility so users notice the
  // install affordance — but only if it isn't already open.
  useEffect(() => {
    if (showInstallButton) {
      const t = window.setTimeout(() => setInstallOpen(true), 600);
      return () => window.clearTimeout(t);
    }
    setInstallOpen(false);
  }, [showInstallButton]);

  // Smoothly shrink the header once the user scrolls past a small threshold
  // so that there's no jump after we tightened vertical padding.
  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 8);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  const goSearch = () => navigate(`/${slug}/search`);

  return (
    <header
      className={cn(
        "sticky top-0 z-30 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/80 border-b",
        scrolled
          ? "border-border shadow-soft"
          : "border-transparent shadow-none",
      )}
    >
      <div
        className={cn(
          "container flex items-center gap-2.5 sm:gap-4 md:gap-6 py-2 md:py-2.5",
        )}
      >
        {/* Logo + Brand — RTL: logo on the right, name beside it */}
        <Link
          to={`/${slug}`}
          className="flex items-center gap-2 sm:gap-2.5 shrink-0 min-w-0"
        >
          {store?.logo_full_url ? (
            <img
              src={store.logo_full_url}
              alt={store.name}
              className={cn(
                "rounded-2xl object-cover shadow-soft shrink-0 h-10 w-10 md:h-12 md:w-12",
              )}
            />
          ) : (
            <StoreLogoFallback
              name={store?.name}
              color={store?.website_color}
              className={cn(
                "transition-all duration-300 ease-out",
                scrolled ? "h-9 w-9 md:h-10 md:w-10" : "h-10 w-10 md:h-12 md:w-12",
              )}
            />
          )}
          <div className="hidden xs:flex flex-col leading-tight text-start min-w-0">
            <span className="font-extrabold text-sm sm:text-base md:text-lg text-foreground truncate">
              {store?.name ?? t("header.brandFallback")}
            </span>
            <span className="text-[9px] sm:text-[10px] md:text-[11px] text-muted-foreground font-bold tracking-[0.18em] sm:tracking-[0.2em]">
              FRESH MARKET
            </span>
          </div>
        </Link>

        {/* Search */}
        <div className="flex-1 relative">
          <Search className="absolute start-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground pointer-events-none" />
          <Input
            type="search"
            placeholder={t("header.searchPlaceholder")}
            value={search}
            onChange={(e) => onSearchChange(e.target.value)}
            onFocus={(e) => {
              // On mobile, route to the dedicated search screen with voice + suggestions
              if (window.matchMedia("(max-width: 768px)").matches) {
                e.currentTarget.blur();
                goSearch();
              }
            }}
            className="ps-10 pe-12 bg-secondary border-transparent focus-visible:bg-background h-11 rounded-full text-start"
          />
          <button
            type="button"
            onClick={goSearch}
            aria-label={t("header.voiceSearchAria")}
            className="absolute end-1.5 top-1/2 -translate-y-1/2 h-8 w-8 rounded-full bg-primary text-primary-foreground inline-flex items-center justify-center hover:shadow-glow transition-smooth"
          >
            <Mic className="h-4 w-4" />
          </button>
        </div>

        {/* Watchlist quick-access button */}
        <button
          type="button"
          onClick={() => navigate(`/${slug}/watchlist`)}
          aria-label={t("nav.watchlist")}
          title={t("nav.watchlist")}
          className="shrink-0 relative h-10 w-10 sm:h-11 sm:w-11 rounded-full bg-secondary text-foreground inline-flex items-center justify-center hover:bg-primary-soft hover:text-primary transition-smooth"
        >
          <Bookmark className="h-4 w-4" />
          {watchedCount > 0 && (
            <span className="absolute -top-1 -end-1 bg-accent text-accent-foreground text-[10px] font-bold h-4 min-w-4 px-1 rounded-full inline-flex items-center justify-center leading-none ring-2 ring-background tabular-nums">
              {watchedCount > 99 ? "99+" : watchedCount}
            </span>
          )}
        </button>

        {showInstallButton && (
          <Popover open={installOpen} onOpenChange={setInstallOpen}>
            <PopoverTrigger asChild>
              <button
                type="button"
                aria-label={t("header.installAppAria")}
                title={t("header.installApp")}
                className="shrink-0 h-10 w-10 sm:h-11 sm:w-11 rounded-full bg-primary-soft text-primary inline-flex items-center justify-center hover:shadow-glow transition-smooth relative"
              >
                <Download className="h-4 w-4" />
                <span className="absolute -top-0.5 -end-0.5 h-2.5 w-2.5 rounded-full bg-primary ring-2 ring-background" aria-hidden="true" />
              </button>
            </PopoverTrigger>
            <PopoverContent
              align="end"
              sideOffset={8}
              className="w-[min(20rem,calc(100vw-1.5rem))] p-3"
            >
              <div className="flex items-start gap-2">
                <div className="h-9 w-9 shrink-0 rounded-full bg-primary-soft text-primary inline-flex items-center justify-center">
                  <Download className="h-4 w-4" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-extrabold text-foreground leading-tight">
                    {t("header.installApp")}
                  </p>
                  <p className="mt-1 text-xs text-muted-foreground leading-snug">
                    {isIOS && !canInstall ? (
                      <span className="inline-flex items-center gap-1 flex-wrap">
                        {t("installPrompt.iosHint")}
                        <Share className="h-3.5 w-3.5 inline shrink-0" aria-hidden="true" />
                      </span>
                    ) : (
                      t("installPrompt.message")
                    )}
                  </p>
                  <div className="mt-3 flex items-center justify-end gap-2">
                    <button
                      type="button"
                      onClick={() => {
                        dismiss();
                        setInstallOpen(false);
                      }}
                      className="h-8 px-3 rounded-full text-xs font-bold text-muted-foreground hover:bg-muted transition-smooth"
                    >
                      {t("installPrompt.dismiss")}
                    </button>
                    {canInstall && (
                      <button
                        type="button"
                        onClick={async () => {
                          await promptInstall();
                          setInstallOpen(false);
                        }}
                        className="h-8 px-4 rounded-full bg-primary text-primary-foreground text-xs font-extrabold hover:shadow-glow transition-smooth"
                      >
                        {t("installPrompt.install")}
                      </button>
                    )}
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => setInstallOpen(false)}
                  aria-label={t("installPrompt.dismiss")}
                  className="h-7 w-7 shrink-0 inline-flex items-center justify-center rounded-full text-muted-foreground hover:bg-muted transition-smooth"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>
            </PopoverContent>
          </Popover>
        )}
      </div>
    </header>
  );
};
