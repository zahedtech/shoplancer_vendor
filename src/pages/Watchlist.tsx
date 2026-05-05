import { useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { ArrowRight, Bookmark } from "lucide-react";
import { useStore } from "@/context/StoreContext";
import { useWatchlist } from "@/context/WatchlistContext";
import { usePriceOverrides } from "@/hooks/usePriceOverrides";
import { applyOverrides, Product } from "@/lib/api";
import { TopBar } from "@/components/TopBar";
import { ActiveOrderBar } from "@/components/order/ActiveOrderBar";
import { BottomNav } from "@/components/BottomNav";
import { CartSheet } from "@/components/CartSheet";
import { Footer } from "@/components/Footer";
import { OfflineBanner } from "@/components/OfflineBanner";
import { ProductGrid } from "@/components/ProductGrid";
import { EmptyState } from "@/components/EmptyState";
import { StoreSkeleton } from "@/components/StoreSkeleton";
import { StoreNotFound } from "@/components/StoreNotFound";
import { SEO } from "@/components/SEO";

/**
 * Watchlist page — shows products the user bookmarked. Replaces the old
 * Categories tab in the bottom nav. Filtering / category browsing has moved
 * into the Search page.
 */
const Watchlist = () => {
  const { slug, store, isLoading, isError } = useStore();
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { items } = useWatchlist();
  const overrides = usePriceOverrides(slug);

  const products = useMemo<Product[]>(() => {
    // Reconstruct minimal Product objects from snapshots so ProductCard renders.
    const reconstructed = items.map((it) => ({
      id: it.product_id,
      name: it.snapshot.name,
      image: it.snapshot.image,
      image_full_url: it.snapshot.image,
      images: [],
      images_full_url: [],
      price: it.snapshot.price,
      stock: 1,
      discount: 0,
      discount_type: "percent",
      tax: 0,
      tax_type: "percent",
      description: "",
      category_ids: [],
      category_id: 0,
      avg_rating: 0,
      rating_count: 0,
      unit_type: null,
    } as unknown as Product));
    return applyOverrides(reconstructed, overrides);
  }, [items, overrides]);

  if (isLoading) return <StoreSkeleton />;
  if (isError || !store) return <StoreNotFound slug={slug} />;

  return (
    <div className="min-h-screen flex flex-col bg-background">
      <SEO
        title={`${t("watchlist.pageTitle")} — ${store.name}`}
        description={t("watchlist.pageSubtitle")}
        noindex
      />
      <OfflineBanner />
      <TopBar store={store} />

      <header className="md:hidden sticky top-0 z-30 bg-background/95 backdrop-blur border-b border-border">
        <div className="container flex items-center gap-3 py-3">
          <button
            onClick={() => navigate(`/${slug}`)}
            className="h-9 w-9 inline-flex items-center justify-center rounded-full hover:bg-muted transition-smooth"
            aria-label={t("common.back")}
          >
            <ArrowRight className="h-5 w-5 ltr:rotate-180" />
          </button>
          <div className="flex-1">
            <h1 className="text-lg font-extrabold leading-tight">
              {t("watchlist.pageTitle")}
            </h1>
            <p className="text-[11px] text-muted-foreground">
              {t("watchlist.countLabel", { count: products.length })}
            </p>
          </div>
        </div>
      </header>

      <main className="flex-1 container py-4 pb-24 md:pb-8">
        <div className="hidden md:flex items-center gap-3 mb-6">
          <span className="h-7 w-1.5 rounded-full bg-primary" />
          <div>
            <h1 className="text-2xl md:text-3xl font-extrabold">
              {t("watchlist.pageTitle")}
            </h1>
            <p className="text-sm text-muted-foreground mt-0.5">
              {t("watchlist.countLabel", { count: products.length })}
            </p>
          </div>
        </div>

        <ProductGrid
          products={products}
          loading={false}
          total={products.length}
          hideHeader
          emptyState={
            <EmptyState
              icon={Bookmark}
              title={t("watchlist.emptyTitle")}
              description={t("watchlist.emptyDesc")}
              action={{
                label: t("watchlist.browse"),
                onClick: () => navigate(`/${slug}/search`),
              }}
            />
          }
        />
      </main>

      <Footer store={store} />
      <ActiveOrderBar />
      <BottomNav />
      <CartSheet />
    </div>
  );
};

export default Watchlist;
