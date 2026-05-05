import { useEffect, useRef, useState } from "react";
import { Tag, ChevronLeft, ChevronRight } from "lucide-react";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import { StoreDetails } from "@/lib/api";
import { useStoreSlug } from "@/context/StoreContext";
import { useStoreSettings } from "@/hooks/useStoreSettings";
import { getHeroSlides, clothesHeroSlides, type HeroCtaAction, type HeroSlide } from "@/config/heroSlides";
import { cn } from "@/lib/utils";

interface HeroProps {
  store?: StoreDetails;
  hasOffers?: boolean;
  onShopOffers?: () => void;
  onBrowseCategories?: () => void;
  /** Storefront kind — switches copy/visuals (e.g. "clothes" for fashion). */
  kind?: "grocery" | "clothes" | "pharmacy" | "food" | "other";
}

const AUTO_ADVANCE_MS = 6000;

const PATTERN_CLASS: Record<string, string> = {
  stripe: "hero-pattern-stripe",
  flowers: "hero-pattern-flowers",
  denim: "hero-pattern-denim",
};

export const Hero = ({
  store,
  hasOffers = false,
  onShopOffers,
  onBrowseCategories,
  kind = "grocery",
}: HeroProps) => {
  const { t, i18n } = useTranslation();
  const slug = useStoreSlug();
  const navigate = useNavigate();
  const settings = useStoreSettings(slug);

  const slides = kind === "clothes" ? clothesHeroSlides : getHeroSlides(slug);
  const filteredSlides: HeroSlide[] = slides.map((s) => ({
    ...s,
    ctas: s.ctas.filter((c) => (c.action === "shopOffers" ? hasOffers : true)),
  }));

  const [index, setIndex] = useState(0);
  const [paused, setPaused] = useState(false);
  const [loadedImages, setLoadedImages] = useState<Set<string>>(new Set());
  const total = filteredSlides.length;
  const isRtl = i18n.language === "ar";

  const touchStartX = useRef<number | null>(null);
  const touchDeltaX = useRef(0);

  const goNext = () => setIndex((i) => (i + 1) % total);
  const goPrev = () => setIndex((i) => (i - 1 + total) % total);

  useEffect(() => {
    if (paused || total <= 1) return;
    const id = window.setInterval(goNext, AUTO_ADVANCE_MS);
    return () => window.clearInterval(id);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [paused, total]);

  // Prefetch the next slide's image (only the next one, not all).
  useEffect(() => {
    if (total <= 1) return;
    const nextSlide = filteredSlides[(index + 1) % total];
    if (nextSlide?.image && !loadedImages.has(nextSlide.image)) {
      const img = new Image();
      img.src = nextSlide.image;
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [index, total]);

  const handleCta = (action: HeroCtaAction) => {
    switch (action) {
      case "shopOffers":
        if (onShopOffers) onShopOffers();
        else document.getElementById("offers")?.scrollIntoView({ behavior: "smooth", block: "start" });
        break;
      case "browseCategories":
        if (onBrowseCategories) onBrowseCategories();
        else if (slug) navigate(`/${slug}/categories`);
        break;
      case "browseLatest":
        document.getElementById("latest")?.scrollIntoView({ behavior: "smooth", block: "start" });
        break;
      case "openSearch":
        if (slug) navigate(`/${slug}/search`);
        break;
    }
  };

  const onTouchStart = (e: React.TouchEvent) => {
    touchStartX.current = e.touches[0]?.clientX ?? null;
    touchDeltaX.current = 0;
  };
  const onTouchMove = (e: React.TouchEvent) => {
    if (touchStartX.current == null) return;
    touchDeltaX.current = (e.touches[0]?.clientX ?? 0) - touchStartX.current;
  };
  const onTouchEnd = () => {
    const dx = touchDeltaX.current;
    touchStartX.current = null;
    touchDeltaX.current = 0;
    if (Math.abs(dx) < 40) return;
    if (dx < 0) (isRtl ? goPrev : goNext)();
    else (isRtl ? goNext : goPrev)();
  };

  const deliveryTime = store?.delivery_time ?? t("hero.deliveryDefault");

  if (total === 0) return null;
  const slide = filteredSlides[Math.min(index, total - 1)];
  const isClothes = kind === "clothes";
  const patternClass = isClothes ? PATTERN_CLASS[settings.heroPattern] : undefined;
  const imgLoaded = slide.image ? loadedImages.has(slide.image) : true;

  const markLoaded = (src: string) =>
    setLoadedImages((s) => {
      if (s.has(src)) return s;
      const next = new Set(s);
      next.add(src);
      return next;
    });

  return (
    <section className="px-3 sm:px-4 md:container pt-3 md:pt-5 pb-2 md:pb-3">
      <div
        className={cn(
          "relative overflow-hidden rounded-2xl shadow-card",
          isClothes ? "gradient-hero-clothes" : "gradient-hero",
        )}
        onMouseEnter={() => setPaused(true)}
        onMouseLeave={() => setPaused(false)}
        onTouchStart={onTouchStart}
        onTouchMove={onTouchMove}
        onTouchEnd={onTouchEnd}
      >
        {/* Background slide images (lazy after the first). */}
        {filteredSlides.map((s, i) => {
          if (!s.image) return null;
          const active = i === index;
          return (
            <img
              key={`bg-${s.id}`}
              src={s.image}
              alt=""
              aria-hidden
              loading={i === 0 ? "eager" : "lazy"}
              decoding="async"
              // @ts-expect-error fetchpriority is valid HTML
              fetchpriority={i === 0 ? "high" : "auto"}
              onLoad={() => markLoaded(s.image!)}
              onError={() => markLoaded(s.image!)}
              className={cn(
                "absolute inset-0 w-full h-full object-cover transition-opacity duration-500",
                active && loadedImages.has(s.image) ? "opacity-40" : "opacity-0",
              )}
            />
          );
        })}

        {/* Pattern overlay (clothes only). */}
        {patternClass && (
          <div
            className={cn(
              "absolute inset-0 pointer-events-none mix-blend-overlay opacity-40",
              patternClass,
            )}
            aria-hidden
          />
        )}

        {/* Skeleton shimmer overlay while the active image loads. */}
        {slide.image && !imgLoaded && (
          <div
            className="absolute inset-0 bg-gradient-to-r from-primary-foreground/0 via-primary-foreground/10 to-primary-foreground/0 animate-pulse pointer-events-none"
            aria-hidden
          />
        )}

        <div className="absolute -top-16 -left-16 h-44 w-44 rounded-full bg-primary-foreground/10 blur-3xl pointer-events-none" />
        <div className="absolute -bottom-16 -right-8 h-56 w-56 rounded-full bg-primary-glow/30 blur-3xl pointer-events-none" />

        <div className="relative px-5 md:px-10 py-6 md:py-10 max-w-2xl text-start">
          <div className="inline-flex items-center gap-1.5 bg-primary-foreground/15 text-primary-foreground rounded-full px-3 py-1 text-xs backdrop-blur">
            <Tag className="h-3 w-3" />
            <span key={`eb-${slide.id}`} className="animate-fade-in">{slide.eyebrow}</span>
          </div>

          <h1
            key={`tt-${slide.id}`}
            className="mt-3 text-sm sm:text-base md:text-2xl font-extrabold text-primary-foreground leading-snug md:leading-tight animate-fade-in truncate whitespace-nowrap pb-0.5"
          >
            {slide.title}
          </h1>

          <p
            key={`st-${slide.id}`}
            className="mt-2 text-primary-foreground/90 text-xs sm:text-sm md:text-base max-w-md animate-fade-in"
          >
            {slide.subtitle}
          </p>

          {!isClothes && (
            <p className="mt-1.5 text-primary-foreground/80 text-[11px] sm:text-xs">
              {t("hero.deliveryIn", { time: deliveryTime })}
            </p>
          )}

          <div key={`ct-${slide.id}`} className="mt-4 flex flex-row flex-wrap gap-2 animate-fade-in">
            {slide.ctas.map((cta, i) => (
              <button
                key={`${slide.id}-cta-${i}`}
                type="button"
                onClick={() => handleCta(cta.action)}
                className={cn(
                  "inline-flex items-center font-bold px-4 sm:px-5 py-2 rounded-full transition-smooth text-xs sm:text-sm",
                  cta.variant === "ghost"
                    ? "text-primary-foreground border border-primary-foreground/40 hover:bg-primary-foreground/10"
                    : "bg-background text-primary shadow-soft hover:scale-105",
                )}
              >
                {cta.label}
              </button>
            ))}
          </div>
        </div>

        {total > 1 && (
          <>
            <div className="absolute bottom-3 left-0 right-0 flex items-center justify-center gap-1.5 z-10">
              {filteredSlides.map((s, i) => (
                <button
                  key={s.id}
                  type="button"
                  onClick={() => setIndex(i)}
                  aria-label={`Slide ${i + 1}`}
                  className={cn(
                    "h-1.5 rounded-full transition-all duration-300",
                    i === index
                      ? "w-6 bg-primary-foreground"
                      : "w-1.5 bg-primary-foreground/40 hover:bg-primary-foreground/70",
                  )}
                />
              ))}
            </div>

            <button
              type="button"
              onClick={goPrev}
              aria-label="Previous slide"
              className="hidden md:inline-flex absolute top-1/2 -translate-y-1/2 left-2 h-9 w-9 items-center justify-center rounded-full bg-background/20 text-primary-foreground hover:bg-background/35 backdrop-blur transition-smooth"
            >
              <ChevronLeft className="h-5 w-5" />
            </button>
            <button
              type="button"
              onClick={goNext}
              aria-label="Next slide"
              className="hidden md:inline-flex absolute top-1/2 -translate-y-1/2 right-2 h-9 w-9 items-center justify-center rounded-full bg-background/20 text-primary-foreground hover:bg-background/35 backdrop-blur transition-smooth"
            >
              <ChevronRight className="h-5 w-5" />
            </button>
          </>
        )}
      </div>
    </section>
  );
};
