import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useNavigate, useParams, useSearchParams } from "react-router-dom";
import { useTranslation } from "react-i18next";
import {
  ArrowRight,
  PackageSearch,
  AlertTriangle,
  SearchX,
  Search as SearchIcon,
  Sparkles,
} from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";
import { useDebouncedValue } from "@/hooks/useDebouncedValue";
import {
  applyOverrides,
  getDiscountedPrice,
  Product,
} from "@/lib/api";
import { useStore } from "@/context/StoreContext";
import { usePriceOverrides } from "@/hooks/usePriceOverrides";
import { useCategoriesUrlState } from "@/hooks/useCategoriesUrlState";
import { useBrandsQuery } from "@/hooks/catalog/useBrandsQuery";
import { useInfiniteCategoryItems } from "@/hooks/catalog/useInfiniteCategoryItems";
import { useVoiceRecorder } from "@/hooks/useVoiceRecorder";
import { ShoplanserApiError } from "@/lib/shoplanserErrors";
import {
  clearRecentSearches,
  getRecentSearches,
  pushRecentSearch,
} from "@/lib/searchHistory";
import {
  cleanTranscript,
  clearVoiceHistory,
  getCleanOptions,
  getVoiceDialect,
  getVoiceHistory,
  getVoiceListenOptions,
  pushVoiceHistory,
  setVoiceDialect,
  VoiceHistoryEntry,
  VoiceLangCode,
  type VoiceListenOptions,
} from "@/lib/voiceSearchHistory";
import {
  formatResetIn,
  getQuota,
  MAX_PER_HOUR,
  recordVoiceUse,
} from "@/lib/voiceQuota";

import { TopBar } from "@/components/TopBar";
import { ProductGrid } from "@/components/ProductGrid";
import { CartSheet } from "@/components/CartSheet";
import { ActiveOrderBar } from "@/components/order/ActiveOrderBar";
import { BottomNav } from "@/components/BottomNav";
import { StoreSkeleton } from "@/components/StoreSkeleton";
import { StoreNotFound } from "@/components/StoreNotFound";
import { OfflineBanner } from "@/components/OfflineBanner";
import { Footer } from "@/components/Footer";
import { EmptyState } from "@/components/EmptyState";
import { CategoryToolbar } from "@/components/categories/CategoryToolbar";
import { LoadMoreSentinel } from "@/components/categories/LoadMoreSentinel";
import { Button } from "@/components/ui/button";
import { VoiceMicButton } from "@/components/search/VoiceMicButton";
import { BigVoiceMicButton } from "@/components/search/BigVoiceMicButton";
import { RecentSearches } from "@/components/search/RecentSearches";
import { VoiceHistoryList } from "@/components/search/VoiceHistoryList";
import { VoiceLangPicker } from "@/components/search/VoiceLangPicker";
import {
  VoiceMatch,
  VoiceResultPanel,
} from "@/components/search/VoiceResultPanel";
import { SEO } from "@/components/SEO";
import { VoiceSettingsButton } from "@/components/search/VoiceSettingsButton";

/**
 * Search page — search bar + voice + recent searches + suggested/all products.
 * No category tree here (categories live on the dedicated Categories page).
 * Only price/stock/brand/sort filters apply.
 */
const SearchPage = () => {
  const { storeSlug = "" } = useParams<{ storeSlug: string }>();
  const { slug, store, ctx, isLoading, isError } = useStore();
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  const { t, i18n } = useTranslation();
  const { state, update, resetFilters } = useCategoriesUrlState();
  const { sort, min, max, inStockOnly, q, brand } = state;

  const brandsQuery = useBrandsQuery(ctx ?? null);

  const debouncedQ = useDebouncedValue(q, 120);

  const itemsQuery = useInfiniteCategoryItems({
    ctx: ctx ?? null,
    categoryId: 0,
    search: debouncedQ,
    brandId: brand,
  });

  const {
    data,
    isLoading: productsLoading,
    isFetchingNextPage,
    hasNextPage,
    fetchNextPage,
    isError: itemsError,
    error: itemsErrorObj,
    retryFromStart: refetchItems,
  } = itemsQuery;

  const overrides = usePriceOverrides(slug);

  const loadedProducts = useMemo(() => {
    const flat: Product[] = [];
    data?.pages.forEach((p) => flat.push(...(p.products ?? [])));
    return applyOverrides(flat, overrides);
  }, [data, overrides]);

  const priceBounds = useMemo(() => {
    if (loadedProducts.length === 0) return { min: 0, max: 1000 };
    const finals = loadedProducts.map((p) => getDiscountedPrice(p).final);
    return {
      min: Math.floor(Math.min(...finals)),
      max: Math.ceil(Math.max(...finals)),
    };
  }, [loadedProducts]);

  const visibleProducts = useMemo(() => {
    let list = loadedProducts;
    if (inStockOnly) list = list.filter((p) => (p.stock ?? 0) > 0);
    if (min !== null || max !== null) {
      const lo = min ?? -Infinity;
      const hi = max ?? Infinity;
      list = list.filter((p) => {
        const f = getDiscountedPrice(p).final;
        return f >= lo && f <= hi;
      });
    }
    if (sort !== "default") {
      list = [...list].sort((a, b) => {
        const fa = getDiscountedPrice(a).final;
        const fb = getDiscountedPrice(b).final;
        if (sort === "price-asc") return fa - fb;
        if (sort === "price-desc") return fb - fa;
        const ratingDiff = (b.avg_rating ?? 0) - (a.avg_rating ?? 0);
        if (ratingDiff !== 0) return ratingDiff;
        return (b.rating_count ?? 0) - (a.rating_count ?? 0);
      });
    }
    return list;
  }, [loadedProducts, inStockOnly, min, max, sort]);

  const isSearching = q.trim().length >= 1;
  const sectionTitle = isSearching
    ? t("search.resultsFor", { q, defaultValue: `نتائج البحث: ${q}` })
    : t("suggested.title", { defaultValue: "المنتجات المقترحة" });

  const activeFiltersCount =
    (min !== null ? 1 : 0) +
    (max !== null ? 1 : 0) +
    (inStockOnly ? 1 : 0) +
    (brand !== null ? 1 : 0);

  const handleLoadMore = useCallback(() => {
    if (hasNextPage && !isFetchingNextPage) fetchNextPage();
  }, [hasNextPage, isFetchingNextPage, fetchNextPage]);

  // ---- Voice search --------------------------------------------------
  const [recents, setRecents] = useState<string[]>([]);
  const [voiceHistory, setVoiceHistory] = useState<VoiceHistoryEntry[]>([]);
  const [voiceProcessing, setVoiceProcessing] = useState(false);
  const [voiceTranscript, setVoiceTranscript] = useState("");
  const [voiceMatches, setVoiceMatches] = useState<VoiceMatch[] | null>(null);
  const [voiceLang, setVoiceLangState] = useState<VoiceLangCode>(() =>
    getVoiceDialect(i18n.language === "en" ? "en-US" : "ar-JO"),
  );
  const [quota, setQuota] = useState(() => getQuota());
  const [listenOpts, setListenOpts] = useState<VoiceListenOptions>(() =>
    getVoiceListenOptions(),
  );
  

  const refreshQuota = () => setQuota(getQuota());

  const changeVoiceLang = (v: VoiceLangCode) => {
    setVoiceLangState(v);
    setVoiceDialect(v);
  };

  useEffect(() => {
    setRecents(getRecentSearches(slug));
    setVoiceHistory(getVoiceHistory(slug));
    refreshQuota();
  }, [slug]);

  // Refresh quota every 60s while page is open so the badge stays accurate.
  useEffect(() => {
    const id = window.setInterval(refreshQuota, 60_000);
    return () => window.clearInterval(id);
  }, []);

  const productsById = useMemo(() => {
    const m = new Map<number, Product>();
    loadedProducts.forEach((p) => m.set(p.id, p));
    return m;
  }, [loadedProducts]);

  const runVoiceSearch = async (rawTranscript: string) => {
    const cleaned = cleanTranscript(rawTranscript, getCleanOptions());
    if (!cleaned) return;

    // Client-side quota guard before hitting the AI.
    const q = getQuota();
    if (q.blocked) {
      const wait = formatResetIn(q.resetInMs, i18n.language);
      toast.error(
        i18n.language === "en"
          ? `Voice search limit reached. Try again in ${wait}.`
          : `تجاوزت حد البحث الصوتي. حاول بعد ${wait}.`,
      );
      setQuota(q);
      return;
    }

    setVoiceProcessing(true);
    setVoiceMatches(null);
    setVoiceTranscript(cleaned);
    recordVoiceUse();
    refreshQuota();
    // Drive the normal text search so results appear in the grid below.
    pushRecentSearch(slug, cleaned);
    setRecents(getRecentSearches(slug));
    update({ q: cleaned });
    try {
      const productsPayload = loadedProducts.map((p) => ({
        id: p.id,
        name: p.name,
        unit: p.unit_type ?? null,
        price: p.price,
        available: (p.stock ?? 1) > 0,
      }));
      const { data, error } = await supabase.functions.invoke("voice-search", {
        body: { transcript: cleaned, products: productsPayload },
      });
      if (error) throw error;
      if (data?.error) {
        toast.error(data.error);
        return;
      }
      const matches = (data?.items ?? []) as VoiceMatch[];
      if (matches.length === 0) toast.info(t("search.noVoiceMatch"));
      setVoiceMatches(matches);
      const matchedCount = matches.filter(
        (m) => m.productId && productsById.get(m.productId),
      ).length;
      pushVoiceHistory(slug, {
        transcript: cleaned,
        at: Date.now(),
        matched: matchedCount,
        total: matches.length,
      });
      setVoiceHistory(getVoiceHistory(slug));
    } catch (e) {
      console.error(e);
      toast.error(t("search.voiceFailed"));
    } finally {
      setVoiceProcessing(false);
    }
  };

  // Auto-run when navigated with ?voice=<transcript> (e.g. from BottomNav mic
  // or Account page). Track the last transcript we ran so re-navigating with
  // a NEW voice query (while already on this page) still triggers a search.
  const lastVoiceRanRef = useRef<string | null>(null);
  useEffect(() => {
    const v = searchParams.get("voice");
    if (!v) return;
    if (lastVoiceRanRef.current === v) return;
    if (loadedProducts.length === 0 && productsLoading) return;
    lastVoiceRanRef.current = v;
    // Strip from URL to avoid re-running on back/forward.
    const next = new URLSearchParams(searchParams);
    next.delete("voice");
    setSearchParams(next, { replace: true });
    runVoiceSearch(v);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [searchParams, loadedProducts.length, productsLoading]);

  const [voiceError, setVoiceError] = useState<string | null>(null);
  const [voiceHintQuery, setVoiceHintQuery] = useState<string | null>(null);
  const searchInputRef = useRef<HTMLInputElement | null>(null);

  // Hide the voice hint as soon as the user edits the query manually.
  useEffect(() => {
    if (voiceHintQuery !== null && q !== voiceHintQuery) {
      setVoiceHintQuery(null);
    }
  }, [q, voiceHintQuery]);

  const recorder = useVoiceRecorder({
    lang: voiceLang.startsWith("en") ? "en" : "ar",
    onResult: (text) => {
      setVoiceError(null);
      const cleaned = cleanTranscript(text, getCleanOptions());
      if (cleaned) setVoiceHintQuery(cleaned);
      runVoiceSearch(text);
    },
    onError: (code) => {
      const map: Record<string, string> = {
        unsupported: t("voice.unsupported"),
        micDenied: t("voice.micDenied"),
        noSpeech: t("voice.noSpeech"),
        startFailed: t("voice.startFailed"),
      };
      const msg = map[code] ?? t("voice.genericError");
      toast.error(msg);
      setVoiceError(msg);
    },
  });


  // ---- Render --------------------------------------------------------
  if (isLoading) return <StoreSkeleton />;
  if (isError || !store) return <StoreNotFound slug={storeSlug} />;

  const totalLoaded = visibleProducts.length;
  const totalApi = data?.pages?.[0]?.total_size ?? loadedProducts.length;

  const filtersHidEverything =
    !productsLoading && loadedProducts.length > 0 && visibleProducts.length === 0;
  const searchReturnedNothing =
    !productsLoading && isSearching && loadedProducts.length === 0;

  const errorCopy = itemsError
    ? itemsErrorObj instanceof ShoplanserApiError
      ? itemsErrorObj.userMessage(t)
      : {
          title: t("categories.errors.generic.title"),
          description: t("categories.errors.generic.description"),
        }
    : null;

  const emptyState = errorCopy ? (
    <EmptyState
      icon={AlertTriangle}
      title={errorCopy.title}
      description={errorCopy.description}
      action={{
        label: t("categories.errors.retry"),
        onClick: () => refetchItems(),
      }}
    />
  ) : searchReturnedNothing ? (
    <EmptyState
      icon={SearchX}
      title={t("categories.emptySearch.title")}
      description={t("categories.emptySearch.description")}
      action={{
        label: t("categories.emptySearch.action"),
        onClick: () => update({ q: "" }),
      }}
    />
  ) : filtersHidEverything ? (
    <EmptyState
      icon={PackageSearch}
      title={t("categories.emptyFiltered.title")}
      description={t("categories.emptyFiltered.description")}
      action={{
        label: t("categories.emptyFiltered.action"),
        onClick: resetFilters,
      }}
    />
  ) : (
    <EmptyState
      icon={PackageSearch}
      title={t("categories.emptySection.title")}
      description={t("categories.emptySection.description")}
    />
  );

  const toolbar = (
    <CategoryToolbar
      total={totalLoaded}
      sort={sort}
      onSortChange={(s) => update({ sort: s })}
      filters={{ min, max, inStockOnly, brand }}
      onFiltersChange={(v) =>
        update({
          min: v.min,
          max: v.max,
          inStockOnly: v.inStockOnly,
          brand: v.brand,
        })
      }
      priceBounds={priceBounds}
      activeFiltersCount={activeFiltersCount}
      brands={brandsQuery.data}
      brandsLoading={brandsQuery.isLoading}
    />
  );

  return (
    <div className="min-h-screen flex flex-col bg-background">
      <SEO
        title={
          q
            ? t("search.seoSearch", { q, store: store.name })
            : t("search.seoTitle", { store: store.name })
        }
        description={t("search.seoDesc", { store: store.name })}
        noindex
      />
      <OfflineBanner />
      <TopBar store={store} />

      {/* Sticky search header */}
      <header className="sticky top-0 z-30 bg-background/95 backdrop-blur border-b border-border">
        <div className="container py-3 flex items-center gap-2">
          <button
            type="button"
            onClick={() => navigate(`/${slug}`)}
            aria-label={t("common.back")}
            className="md:hidden shrink-0 h-10 w-10 rounded-full bg-secondary inline-flex items-center justify-center text-muted-foreground hover:text-foreground transition-smooth"
          >
            <ArrowRight className="h-5 w-5 ltr:rotate-180" />
          </button>

          <div className="flex-1 relative">
            <SearchIcon className="absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground rtl:right-3 ltr:left-3 ltr:right-auto" />
            <input
              ref={searchInputRef}
              type="search"
              dir={i18n.language === "en" ? "ltr" : "rtl"}
              value={q}
              onChange={(e) => update({ q: e.target.value })}
              onKeyDown={(e) => {
                if (e.key === "Enter" && q.trim()) {
                  pushRecentSearch(slug, q);
                  setRecents(getRecentSearches(slug));
                }
              }}
              placeholder={t("search.placeholder")}
              className="w-full h-11 rounded-full bg-secondary ps-10 pe-12 text-sm border border-transparent focus:outline-none focus:bg-background focus:border-border placeholder:text-muted-foreground"
            />
            <div className="absolute left-1.5 top-1/2 -translate-y-1/2 rtl:left-1.5 ltr:right-1.5 ltr:left-auto">
              {recorder.isSupported && (
                <VoiceMicButton
                  isListening={recorder.isRecording}
                  onStart={recorder.start}
                  onStop={recorder.stop}
                  size="sm"
                  disabled={recorder.isProcessing || voiceProcessing}
                />
              )}
            </div>
          </div>

          {recorder.isSupported && (
            <VoiceSettingsButton value={listenOpts} onChange={setListenOpts} />
          )}
        </div>

        {q.trim() && !recorder.isRecording && !recorder.isProcessing && !voiceProcessing && (
          <div className="container pb-3">
            <Button
              size="sm"
              className="w-full h-9 text-xs font-extrabold"
              onClick={() => {
                pushRecentSearch(slug, q);
                setRecents(getRecentSearches(slug));
                searchInputRef.current?.blur();
              }}
            >
              <SearchIcon className="h-3.5 w-3.5 me-1" /> ابحث الآن
            </Button>
          </div>
        )}

        {(voiceProcessing || recorder.isProcessing) && (
          <div className="container pb-3">
            <div className="rounded-xl bg-secondary text-muted-foreground px-3 py-2 text-xs font-bold flex items-center gap-2">
              <span className="relative flex h-2 w-2">
                <span className="absolute inline-flex h-full w-full rounded-full bg-primary opacity-75 animate-ping" />
                <span className="relative inline-flex rounded-full h-2 w-2 bg-primary" />
              </span>
              {recorder.isProcessing
                ? (i18n.language === "en" ? "Processing voice..." : "جاري معالجة الصوت...")
                : t("search.analyzing")}
            </div>
          </div>
        )}

        {voiceHintQuery && voiceHintQuery === q && !voiceProcessing && !recorder.isProcessing && !recorder.isRecording && (
          <div className="container pb-3">
            <div className="rounded-xl bg-primary/10 text-primary px-3 py-2 text-xs font-bold flex items-center gap-2">
              <Sparkles className="h-3.5 w-3.5 shrink-0" />
              <span>
                {i18n.language === "en"
                  ? `Converted your speech to text: "${voiceHintQuery}" — showing results below.`
                  : `تم تحويل كلامك إلى نص: "${voiceHintQuery}" — وتظهر النتائج بالأسفل.`}
              </span>
            </div>
          </div>
        )}

      </header>

      <main className="flex-1 pb-20 md:pb-0">
        <section className="container py-4">
          {/* Big push-to-talk mic moved to BottomNav */}


          {/* Voice transcript + AI matches panel */}
          {(voiceTranscript || (voiceMatches && voiceMatches.length > 0)) && (
            <div className="mb-4">
              <VoiceResultPanel
                transcript={voiceTranscript}
                matches={voiceMatches ?? []}
                productsById={productsById}
                onClose={() => {
                  setVoiceTranscript("");
                  setVoiceMatches(null);
                }}
              />
            </div>
          )}

          {/* Recent searches — only when no query yet */}
          {!q.trim() && recents.length > 0 && (
            <div className="mb-4">
              <RecentSearches
                items={recents}
                onPick={(query) => update({ q: query })}
                onClear={() => {
                  clearRecentSearches(slug);
                  setRecents([]);
                }}
              />
            </div>
          )}

          {/* Voice search history hidden — voice queries are not shown */}


          <div className="min-w-0">
            <h2 className="text-lg font-extrabold mb-2 flex items-center gap-2">
              {!isSearching && <Sparkles className="h-4 w-4 text-primary" />}
              {sectionTitle}
            </h2>
            {isSearching && toolbar}
            <ProductGrid
              products={isSearching ? visibleProducts : visibleProducts.slice(0, 8)}
              loading={productsLoading}
              total={isSearching ? totalApi : Math.min(8, visibleProducts.length)}
              title={sectionTitle}
              compact
              fetchingMore={isSearching && isFetchingNextPage}
              emptyState={emptyState}
              hideHeader
            />
            {isSearching && !productsLoading && visibleProducts.length > 0 && (
              <LoadMoreFooter
                hasNextPage={!!hasNextPage}
                isFetching={isFetchingNextPage}
                onLoadMore={handleLoadMore}
              />
            )}
          </div>
        </section>
      </main>

      <Footer store={store} />
      <ActiveOrderBar />
      <BottomNav />
      <CartSheet />
    </div>
  );
};

const LoadMoreFooter = ({
  hasNextPage,
  isFetching,
  onLoadMore,
}: {
  hasNextPage: boolean;
  isFetching: boolean;
  onLoadMore: () => void;
}) => {
  const { t } = useTranslation();
  if (!hasNextPage) {
    return (
      <p className="text-center text-xs text-muted-foreground py-6">
        {t("categories.endOfResults")}
      </p>
    );
  }
  return (
    <div className="py-6 flex flex-col items-center gap-2">
      <LoadMoreSentinel onLoadMore={onLoadMore} disabled={isFetching} />
      <Button
        variant="outline"
        size="sm"
        onClick={onLoadMore}
        disabled={isFetching}
        className="text-xs font-bold"
      >
        {isFetching ? t("categories.loading") : t("categories.loadMore")}
      </Button>
    </div>
  );
};

export default SearchPage;
