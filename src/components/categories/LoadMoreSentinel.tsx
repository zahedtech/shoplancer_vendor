import { useEffect, useRef } from "react";

interface LoadMoreSentinelProps {
  onLoadMore: () => void;
  /** Disable the observer when there's nothing more to load or a fetch is in-flight. */
  disabled?: boolean;
  /** Pixels of pre-load buffer below the viewport. */
  rootMargin?: string;
}

/**
 * Invisible div that triggers `onLoadMore` whenever it scrolls into view.
 * Used by the Categories page to drive infinite scroll.
 */
export const LoadMoreSentinel = ({
  onLoadMore,
  disabled,
  rootMargin = "400px",
}: LoadMoreSentinelProps) => {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (disabled || !ref.current) return;
    const node = ref.current;
    const observer = new IntersectionObserver(
      (entries) => {
        if (entries.some((e) => e.isIntersecting)) onLoadMore();
      },
      { rootMargin },
    );
    observer.observe(node);
    return () => observer.disconnect();
  }, [onLoadMore, disabled, rootMargin]);

  return <div ref={ref} aria-hidden className="h-1 w-full" />;
};
