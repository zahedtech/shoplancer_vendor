import { useEffect, useState } from "react";
import { ArrowUp, ArrowDown } from "lucide-react";
import { useTranslation } from "react-i18next";
import { cn } from "@/lib/utils";

/**
 * Floating scroll helper — always pinned to the screen.
 *
 * - At the top of the page: shows a down arrow that scrolls to the bottom.
 * - After scrolling down: shows an up arrow that scrolls back to the top.
 *
 * Sits above the bottom nav on mobile.
 */
export const ScrollToTop = () => {
  const [scrolled, setScrolled] = useState(false);
  const { t } = useTranslation();

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 200);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  const handleClick = () => {
    if (scrolled) {
      window.scrollTo({ top: 0, behavior: "smooth" });
    } else {
      window.scrollTo({
        top: document.documentElement.scrollHeight,
        behavior: "smooth",
      });
    }
  };

  return (
    <button
      type="button"
      aria-label={scrolled ? t("scrollToTop.up") : t("scrollToTop.down")}
      onClick={handleClick}
      className={cn(
        "fixed left-4 z-40 h-11 w-11 rounded-full bg-primary text-primary-foreground shadow-glow inline-flex items-center justify-center transition-all duration-300",
        "bottom-24 md:bottom-6",
      )}
    >
      {scrolled ? (
        <ArrowUp className="h-5 w-5" strokeWidth={2.5} />
      ) : (
        <ArrowDown className="h-5 w-5" strokeWidth={2.5} />
      )}
    </button>
  );
};
