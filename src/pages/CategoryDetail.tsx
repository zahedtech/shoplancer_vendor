import { useEffect, useMemo, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { useQuery } from "@tanstack/react-query";
import { ArrowRight } from "lucide-react";
import { useStore } from "@/context/StoreContext";
import { usePriceOverrides } from "@/hooks/usePriceOverrides";
import { getSubCategories, getTopLevelCategories, type StoreCategory } from "@/lib/api";
import { fetchCategoryChildren } from "@/lib/shoplanserApi";
import { TopBar } from "@/components/TopBar";
import { CartSheet } from "@/components/CartSheet";
import { ActiveOrderBar } from "@/components/order/ActiveOrderBar";
import { BottomNav } from "@/components/BottomNav";
import { StoreSkeleton } from "@/components/StoreSkeleton";
import { StoreNotFound } from "@/components/StoreNotFound";
import { OfflineBanner } from "@/components/OfflineBanner";
import { Footer } from "@/components/Footer";
import { SEO } from "@/components/SEO";
import { CategoryProductsSection } from "@/components/home/CategoryProductsSection";

import { cn } from "@/lib/utils";

interface BannerSlide {
  id: string;
  image: string;
  title: string;
  subtitle?: string;
}

const CategoryDetail = () => {
  const { slug, store, ctx, isLoading, isError } = useStore();
  const { categoryId } = useParams<{ categoryId: string }>();
  const navigate = useNavigate();
  const { t } = useTranslation();

  const overrides = usePriceOverrides(slug);

  const cats = store?.category_details ?? [];
  const parentId = Number(categoryId);
  const parent = useMemo(
    () => cats.find((c) => Number(c.id) === parentId) ?? null,
    [cats, parentId],
  );
  const topCategories = useMemo(() => getTopLevelCategories(cats), [cats]);

  // Sub-categories may not be present in store.category_details (which often
  // only contains top-level entries). Fetch them on demand from the API.
  const localSubs = useMemo(
    () => (parent ? getSubCategories(cats, parent.id) : []),
    [cats, parent],
  );
  const childrenQuery = useQuery({
    queryKey: ["category-children", ctx?.slug ?? null, ctx?.zoneId ?? null, ctx?.moduleId ?? null, parentId],
    queryFn: () => fetchCategoryChildren(parentId, ctx!),
    enabled: !!ctx && !!parent && localSubs.length === 0,
    staleTime: 5 * 60 * 1000,
  });
  const subCategories: StoreCategory[] = localSubs.length > 0
    ? localSubs
    : (childrenQuery.data ?? []);


  // Build banner slides from the parent and its sub-categories' images
  const slides: BannerSlide[] = useMemo(() => {
    if (!parent) return [];
    const out: BannerSlide[] = [];
    if (parent.image_full_url) {
      out.push({
        id: `parent-${parent.id}`,
        image: parent.image_full_url,
        title: parent.name,
        subtitle: t("categories.exploreSubtitle", {
          defaultValue: "اكتشف مجموعتنا المختارة",
        }),
      });
    }
    subCategories.slice(0, 4).forEach((sc) => {
      if (sc.image_full_url) {
        out.push({ id: `sc-${sc.id}`, image: sc.image_full_url, title: sc.name });
      }
    });
    if (out.length === 0 && store?.cover_photo_full_url) {
      out.push({
        id: "cover",
        image: store.cover_photo_full_url,
        title: parent.name,
      });
    }
    return out;
  }, [parent, subCategories, store, t]);

  const [slideIdx, setSlideIdx] = useState(0);
  const [selectedSubId, setSelectedSubId] = useState<number | null>(null);
  useEffect(() => {
    setSelectedSubId(null);
  }, [parentId]);
  useEffect(() => {
    if (slides.length <= 1) return;
    const id = window.setInterval(() => {
      setSlideIdx((i) => (i + 1) % slides.length);
    }, 4500);
    return () => window.clearInterval(id);
  }, [slides.length]);

  if (isLoading) return <StoreSkeleton />;
  if (isError || !store) return <StoreNotFound slug={slug} />;
  if (!parent) {
    return (
      <div className="min-h-screen flex flex-col bg-background">
        <TopBar store={store} />
        <main className="flex-1 container py-12 text-center">
          <p className="text-muted-foreground">
            {t("categories.notFound", { defaultValue: "القسم غير موجود" })}
          </p>
          <button
            onClick={() => navigate(`/${slug}/categories`)}
            className="mt-4 text-primary font-bold hover:underline"
          >
            {t("categories.back")}
          </button>
        </main>
        <ActiveOrderBar />
      <BottomNav />
      </div>
    );
  }

  // Show ONLY sub-categories of this parent (not top-level/main categories).
  // If there are no sub-categories, fall back to showing all products of the parent.
  const hasSubs = subCategories.length > 0;

  return (
    <div className="min-h-screen flex flex-col bg-background overflow-x-clip">
      <SEO
        title={`${parent.name} — ${store.name}`}
        description={t("categories.seoDescription", {
          section: parent.name,
          store: store.name,
        })}
      />
      <OfflineBanner />
      <TopBar store={store} />

      {/* Mobile header */}
      <header className="md:hidden sticky top-0 z-30 bg-background/95 backdrop-blur border-b border-border">
        <div className="container flex items-center gap-3 py-3">
          <button
            onClick={() => navigate(`/${slug}/categories`)}
            className="h-9 w-9 inline-flex items-center justify-center rounded-full hover:bg-muted transition-smooth"
            aria-label={t("categories.back")}
          >
            <ArrowRight className="h-5 w-5 ltr:rotate-180" />
          </button>
          <div className="flex-1 min-w-0">
            <h1 className="text-lg font-extrabold leading-tight truncate">
              {parent.name}
            </h1>
          </div>
        </div>
      </header>

      {/* Banner slider */}
      {slides.length > 0 && (
        <section className="container pt-3 md:pt-6">
          <div className="relative w-full overflow-hidden rounded-2xl md:rounded-3xl aspect-[16/7] md:aspect-[21/7] bg-muted shadow-soft">
            {slides.map((s, i) => (
              <div
                key={s.id}
                className={cn(
                  "absolute inset-0 transition-opacity duration-700",
                  i === slideIdx ? "opacity-100" : "opacity-0 pointer-events-none",
                )}
                aria-hidden={i !== slideIdx}
              >
                <img
                  src={s.image}
                  alt={s.title}
                  className="h-full w-full object-cover"
                  loading={i === 0 ? "eager" : "lazy"}
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-black/20 to-transparent" />
                <div className="absolute bottom-0 inset-x-0 p-4 md:p-6 text-white">
                  <h2 className="text-lg md:text-2xl font-extrabold drop-shadow-sm">
                    {s.title}
                  </h2>
                  {s.subtitle && (
                    <p className="text-xs md:text-sm opacity-90 mt-1">
                      {s.subtitle}
                    </p>
                  )}
                </div>
              </div>
            ))}

            {slides.length > 1 && (
              <div className="absolute bottom-2 inset-x-0 flex items-center justify-center gap-1.5 z-10">
                {slides.map((_, i) => (
                  <button
                    key={i}
                    type="button"
                    onClick={() => setSlideIdx(i)}
                    aria-label={`Slide ${i + 1}`}
                    className={cn(
                      "h-1.5 rounded-full transition-all",
                      i === slideIdx ? "w-6 bg-white" : "w-1.5 bg-white/60",
                    )}
                  />
                ))}
              </div>
            )}
          </div>
        </section>
      )}

      {/* Filterable products grid (selection driven by the strip above) */}
      <main id="category-products" className="flex-1 pb-20 md:pb-0 scroll-mt-20">
        <div className="container">
          {hasSubs && (
            <div className="pt-3 pb-2">
              <div
                className="flex gap-2 overflow-x-auto no-scrollbar -mx-1 px-1 pb-1 snap-x"
                role="tablist"
                aria-label="الأصناف الفرعية"
              >
                <button
                  type="button"
                  onClick={() => setSelectedSubId(null)}
                  aria-pressed={selectedSubId === null}
                  className={cn(
                    "shrink-0 snap-start whitespace-nowrap px-4 py-2 rounded-full text-xs md:text-sm font-bold border transition-all",
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
                      onClick={() => setSelectedSubId(active ? null : sc.id)}
                      aria-pressed={active}
                      className={cn(
                        "shrink-0 snap-start whitespace-nowrap px-4 py-2 rounded-full text-xs md:text-sm font-bold border transition-all",
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
            </div>
          )}

          <CategoryProductsSection
            key={`${parent.id}-${hasSubs ? "with-subs" : "all"}`}
            slug={slug}
            ctx={ctx ?? null}
            categories={[]}
            overrides={overrides}
            hideCategoryBar
            selectedCategoryId={hasSubs ? (selectedSubId ?? parent.id) : parent.id}
            onSelectedCategoryChange={() => undefined}
            initialCategoryId={parent.id}
          />
        </div>
      </main>

      <Footer store={store} />
      <ActiveOrderBar />
      <BottomNav />
      <CartSheet />
    </div>
  );
};

export default CategoryDetail;
