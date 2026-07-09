import { lazy, Suspense, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useStore } from "@/context/StoreContext";
import { usePriceOverrides } from "@/hooks/usePriceOverrides";
import { useStoreSections } from "@/hooks/useStoreSections";
import { applyOverrides, getSubCategories, getTopLevelCategories, type StoreCategory } from "@/lib/api";
import { fetchCategoryChildren } from "@/lib/shoplanserApi";
import { cn } from "@/lib/utils";
import { TopBar } from "@/components/TopBar";
import { Header } from "@/components/Header";
import { Hero } from "@/components/Hero";
import { FeatureBar } from "@/components/FeatureBar";
import { ClothesFeatureBar } from "@/components/ClothesFeatureBar";
import { RecommendedLatestTabs } from "@/components/home/RecommendedLatestTabs";
import { ProductGrid } from "@/components/ProductGrid";
import { ErrorBoundary } from "@/components/ErrorBoundary";
import { SEO } from "@/components/SEO";
import { Footer } from "@/components/Footer";
import { CartSheet } from "@/components/CartSheet";
import { BottomNav } from "@/components/BottomNav";
import { OfflineBanner } from "@/components/OfflineBanner";
import { StoreNotFound } from "@/components/StoreNotFound";
import { StoreSplash } from "@/components/StoreSplash";
import { ScrollToTop } from "@/components/ScrollToTop";
import { ActiveOrderBar } from "@/components/order/ActiveOrderBar";
import { ReorderLastOrderCard } from "@/components/home/ReorderLastOrderCard";
import { WhatsAppPopup } from "@/components/WhatsAppPopup";
import { getStoreKind } from "@/lib/storeKind";
import { AudienceBar, useCurrentAudience } from "@/components/clothes/AudienceBar";
import { filterCategoriesByAudience } from "@/lib/audienceMapping";
import { useStoreSettings } from "@/hooks/useStoreSettings";

// Lazy-load below-the-fold heavy section to keep initial JS bundle smaller.
const CategoryProductsSection = lazy(() =>
  import("@/components/home/CategoryProductsSection").then((m) => ({
    default: m.CategoryProductsSection,
  })),
);

/**
 * Home tab — app-style landing. Shows hero + curated horizontal rails
 * (recommended / offers / new arrivals). The full category browser and
 * product grid live on the dedicated /:slug/categories page.
 */
const Storefront = () => {
  const { slug, store, ctx, isLoading, isError } = useStore();
  const { t, i18n } = useTranslation();
  const queryClient = useQueryClient();
  const [search, setSearch] = useState("");
  const navigate = useNavigate();

  const refetchSection = (key: string) =>
    queryClient.invalidateQueries({ queryKey: [key, slug] });
  const refetchHomeFeed = () =>
    Promise.all([
      refetchSection("section-recommended"),
      refetchSection("section-discounted"),
      refetchSection("section-popular"),
    ]);

  const overrides = usePriceOverrides(slug);
  const sections = useStoreSections(slug, ctx ?? null, []);

  // Apply per-store price overrides to the rail products as well.
  const recommended = useMemo(
    () => applyOverrides(sections.recommended.products, overrides),
    [sections.recommended.products, overrides],
  );
  const offers = useMemo(
    () => applyOverrides(sections.offers.products, overrides),
    [sections.offers.products, overrides],
  );
  const latest = useMemo(
    () => applyOverrides(sections.latest.products, overrides),
    [sections.latest.products, overrides],
  );

  const settings = useStoreSettings(slug);
  const audience = useCurrentAudience();

  // Inline parent → sub-category selection (HOME ONLY).
  // IMPORTANT: keep all hooks above any early returns to satisfy Rules of Hooks.
  const [selectedParentId, setSelectedParentId] = useState<number | null>(null);
  const [selectedSubId, setSelectedSubId] = useState<number | null>(null);
  const cats = store?.category_details ?? [];
  const localSubs = useMemo(
    () => (selectedParentId ? getSubCategories(cats, selectedParentId) : []),
    [cats, selectedParentId],
  );
  const childrenQuery = useQuery({
    queryKey: [
      "category-children",
      ctx?.slug ?? null,
      ctx?.zoneId ?? null,
      ctx?.moduleId ?? null,
      selectedParentId,
    ],
    queryFn: () => fetchCategoryChildren(selectedParentId!, ctx!),
    enabled: !!ctx && !!selectedParentId && localSubs.length === 0,
    staleTime: 5 * 60 * 1000,
  });
  const subCategories: StoreCategory[] =
    localSubs.length > 0 ? localSubs : (childrenQuery.data ?? []);

  if (isLoading) return <StoreSplash />;
  if (isError || !store) return <StoreNotFound slug={slug} />;

  const goCategories = () => navigate(`/${slug}/categories`);

  const topCategories = getTopLevelCategories(store.category_details ?? []);
  const hasOffers = offers.length > 0;
  const scrollToOffers = () => {
    const el = document.getElementById("offers");
    if (el) el.scrollIntoView({ behavior: "smooth", block: "start" });
  };

  const seoTitle = t("home.seoTitle", { store: store.name });
  const seoDesc = store.address
    ? t("home.seoDescWithAddress", { store: store.name, address: store.address })
    : t("home.seoDesc", { store: store.name });
  const canonical = typeof window !== "undefined"
    ? `${window.location.origin}/${slug}`
    : undefined;

  const storeKind = getStoreKind(store);
  const filteredTopCategories =
    storeKind === "clothes"
      ? filterCategoriesByAudience(topCategories, audience, settings.audienceMap)
      : topCategories;

  return (
    <div className="min-h-screen flex flex-col bg-background overflow-x-clip">
      <SEO
        title={seoTitle}
        description={seoDesc}
        image={store.cover_photo_full_url || store.logo_full_url}
        canonical={canonical}
      />
      <OfflineBanner />
      <TopBar store={store} />
      <Header
        store={store}
        search={search}
        onSearchChange={(v) => {
          setSearch(v);
          if (v.trim()) navigate(`/${slug}/search`);
        }}
      />

      <main className="flex-1 pb-20 md:pb-0 space-y-2 md:space-y-3">
        <ReorderLastOrderCard />
        {storeKind === "clothes" && <AudienceBar />}

        <Hero
          store={store}
          hasOffers={hasOffers}
          onShopOffers={scrollToOffers}
          onBrowseCategories={goCategories}
          kind={storeKind}
        />

        {storeKind === "clothes" ? <ClothesFeatureBar /> : <FeatureBar />}
        <div id="latest" className="scroll-mt-24">
          <ErrorBoundary
            section="home/recommended-latest"
            slug={slug}
            context={{
              recommendedCount: recommended.length,
              latestCount: latest.length,
            }}
            onReset={() =>
              Promise.all([
                refetchSection("section-recommended"),
                refetchSection("section-popular"),
              ])
            }
          >
            <RecommendedLatestTabs
              slug={slug}
              recommended={{
                products: recommended,
                loading: sections.recommended.loading,
              }}
              latest={{
                products: latest,
                loading: sections.latest.loading,
              }}
              onViewAll={goCategories}
            />
          </ErrorBoundary>
        </div>

        {hasOffers && (
          <section
            id="offers"
            className="scroll-mt-24 bg-primary-soft/30 py-3 md:py-4 px-1.5 md:px-3 border-y border-primary/10"
            dir={i18n.language === "ar" ? "rtl" : "ltr"}
          >
            <div className="flex items-center justify-between mb-3 px-1">
              <div className="flex items-center gap-2">
                <h2 className="text-lg md:text-xl font-extrabold text-foreground">
                  {t("home.offersHeading")}
                </h2>
                <span className="inline-flex items-center text-[10px] font-extrabold bg-discount text-discount-foreground rounded-full px-2 py-0.5">
                  {t("home.discountsBadge")}
                </span>
                {!sections.offers.loading && offers.length > 0 && (
                  <span className="text-[11px] font-bold text-muted-foreground">
                    {t("home.offersCount", { count: offers.length })}
                  </span>
                )}
              </div>
              <button
                onClick={goCategories}
                className="text-xs font-bold text-primary hover:underline shrink-0"
              >
                {t("home.viewAll")}
              </button>
            </div>
            <ErrorBoundary
              section="home/offers"
              slug={slug}
              context={{ offersCount: offers.length }}
              onReset={() => refetchSection("section-discounted")}
            >
              <ProductGrid
                products={offers}
                loading={sections.offers.loading}
                hideHeader
              />
            </ErrorBoundary>
          </section>
        )}

        <ErrorBoundary
          section="home/category-products"
          slug={slug}
          context={{
            categoriesCount: filteredTopCategories.length,
            audience,
            storeKind,
          }}
          onReset={() =>
            queryClient.invalidateQueries({
              predicate: (q) =>
                Array.isArray(q.queryKey) &&
                (q.queryKey[0] === "products-infinite" ||
                  q.queryKey[0] === "catalog"),
            })
          }
        >
          <Suspense fallback={<div className="min-h-[120px]" aria-hidden />}>
            <CategoryProductsSection
              slug={slug}
              ctx={ctx ?? null}
              categories={filteredTopCategories}
              overrides={overrides}
              selectedCategoryId={selectedSubId ?? selectedParentId ?? null}
              onSelectedCategoryChange={(id) => {
                // Clicking a parent pill: toggle parent and reset sub.
                setSelectedParentId(id);
                setSelectedSubId(null);
              }}
              subCategoriesSlot={
                selectedParentId && subCategories.length > 0 ? (
                  <div
                    className="flex gap-2 overflow-x-auto no-scrollbar -mx-1 px-1 pb-2 pt-1 snap-x"
                    role="tablist"
                    aria-label="الأصناف الفرعية"
                  >
                    <button
                      type="button"
                      onClick={() => setSelectedSubId(null)}
                      aria-pressed={selectedSubId === null}
                      className={cn(
                        "shrink-0 snap-start whitespace-nowrap px-3.5 py-1.5 rounded-full text-xs font-bold border transition-all",
                        selectedSubId === null
                          ? "bg-primary text-primary-foreground border-primary shadow-soft"
                          : "bg-card text-foreground border-border hover:bg-muted",
                      )}
                    >
                      الكل
                    </button>
                    {subCategories.map((sc) => {
                      const active = selectedSubId === sc.id;
                      return (
                        <button
                          key={sc.id}
                          type="button"
                          onClick={() =>
                            setSelectedSubId(active ? null : sc.id)
                          }
                          aria-pressed={active}
                          className={cn(
                            "shrink-0 snap-start whitespace-nowrap px-3.5 py-1.5 rounded-full text-xs font-bold border transition-all",
                            active
                              ? "bg-primary text-primary-foreground border-primary shadow-soft"
                              : "bg-card text-foreground border-border hover:bg-muted hover:border-primary/40",
                          )}
                        >
                          {sc.name}
                        </button>
                      );
                    })}
                  </div>
                ) : null
              }
            />
          </Suspense>

        </ErrorBoundary>
      </main>

      <Footer store={store} />
      <BottomNav />
      <ActiveOrderBar />
      <CartSheet />
      <ScrollToTop />
      {storeKind === "clothes" && (
        <WhatsAppPopup phone={store.phone} storeName={store.name} />
      )}
    </div>
  );
};

export default Storefront;
