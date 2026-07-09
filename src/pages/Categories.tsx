import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { ArrowRight, ChevronLeft } from "lucide-react";
import { useStore } from "@/context/StoreContext";
import { getTopLevelCategories } from "@/lib/api";
import { TopBar } from "@/components/TopBar";
import { CartSheet } from "@/components/CartSheet";
import { ActiveOrderBar } from "@/components/order/ActiveOrderBar";
import { BottomNav } from "@/components/BottomNav";
import { StoreSkeleton } from "@/components/StoreSkeleton";
import { StoreNotFound } from "@/components/StoreNotFound";
import { OfflineBanner } from "@/components/OfflineBanner";
import { Footer } from "@/components/Footer";
import { SEO } from "@/components/SEO";
import { getStoreKind } from "@/lib/storeKind";
import { AudienceBar, useCurrentAudience } from "@/components/clothes/AudienceBar";
import { filterCategoriesByAudience } from "@/lib/audienceMapping";
import { useStoreSettings } from "@/hooks/useStoreSettings";

const Categories = () => {
  const { slug, store, isLoading, isError } = useStore();
  const navigate = useNavigate();
  const { t } = useTranslation();
  const settings = useStoreSettings(slug);
  const audience = useCurrentAudience();

  if (isLoading) return <StoreSkeleton />;
  if (isError || !store) return <StoreNotFound slug={slug} />;

  const allTop = getTopLevelCategories(store.category_details ?? []);
  const isClothes = getStoreKind(store) === "clothes";
  const topCategories = isClothes
    ? filterCategoriesByAudience(allTop, audience, settings.audienceMap)
    : allTop;

  return (
    <div className="min-h-screen flex flex-col bg-background overflow-x-clip">
      <SEO
        title={`${t("categories.pageTitle")} — ${store.name}`}
        description={t("categories.seoDescription", {
          section: t("categories.allProducts"),
          store: store.name,
        })}
        canonical={
          typeof window !== "undefined"
            ? window.location.href.split("?")[0]
            : undefined
        }
      />
      <OfflineBanner />
      <TopBar store={store} />

      <header className="md:hidden sticky top-0 z-30 bg-background/95 backdrop-blur border-b border-border">
        <div className="container flex items-center gap-3 py-3">
          <button
            onClick={() => navigate(`/${slug}`)}
            className="h-9 w-9 inline-flex items-center justify-center rounded-full hover:bg-muted transition-smooth"
            aria-label={t("categories.back")}
          >
            <ArrowRight className="h-5 w-5 ltr:rotate-180" />
          </button>
          <div className="flex-1">
            <h1 className="text-lg font-extrabold leading-tight">
              {t("categories.pageTitle")}
            </h1>
            <p className="text-[11px] text-muted-foreground">
              {t("categories.pageSubtitle")}
            </p>
          </div>
        </div>
      </header>

      <div className="hidden md:block container pt-6">
        <div className="flex items-center gap-3">
          <span className="h-7 w-1.5 rounded-full bg-primary" />
          <div>
            <h1 className="text-2xl md:text-3xl font-extrabold">
              {t("categories.pageTitle")}
            </h1>
            <p className="text-sm text-muted-foreground mt-0.5">
              {t("categories.pageSubtitle")}
            </p>
          </div>
        </div>
      </div>

      <main className="flex-1 pb-20 md:pb-0">
        {isClothes && <AudienceBar />}
        <div className="container py-4">
          {topCategories.length === 0 ? (
            <p className="text-center text-sm text-muted-foreground py-12">
              {t("categories.empty", { defaultValue: "لا توجد أقسام بعد" })}
            </p>
          ) : (
            <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3 md:gap-4">
              {topCategories.map((cat) => (
                <button
                  key={cat.id}
                  type="button"
                  onClick={() => navigate(`/${slug}/categories/${cat.id}`)}
                  className="group relative flex flex-col items-stretch overflow-hidden rounded-2xl border border-border bg-card text-start shadow-soft hover:shadow-md hover:-translate-y-0.5 transition-all"
                >
                  <div className="aspect-[4/3] w-full overflow-hidden bg-muted">
                    {cat.image_full_url ? (
                      <img
                        src={cat.image_full_url}
                        alt={cat.name}
                        loading="lazy"
                        className="h-full w-full object-cover group-hover:scale-105 transition-transform duration-500"
                      />
                    ) : (
                      <div className="h-full w-full bg-gradient-to-br from-primary/20 to-primary/5" />
                    )}
                  </div>
                  <div className="flex items-center justify-between gap-2 p-3">
                    <span className="font-bold text-sm md:text-base line-clamp-2 flex-1">
                      {cat.name}
                    </span>
                    <ChevronLeft className="h-4 w-4 text-muted-foreground shrink-0 ltr:rotate-180" />
                  </div>
                </button>
              ))}
            </div>
          )}
        </div>
      </main>

      <Footer store={store} />
      <ActiveOrderBar />
      <BottomNav />
      <CartSheet />
    </div>
  );
};

export default Categories;
