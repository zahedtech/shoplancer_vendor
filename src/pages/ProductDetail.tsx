import { useMemo, useState } from "react";
import { useParams, useNavigate, Link } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { ArrowRight, MessageCircle, Star, ShoppingBasket, Plus, Minus } from "lucide-react";
import { useStore } from "@/context/StoreContext";
import { fetchProductDetails, formatPrice, getDiscountedPrice } from "@/lib/api";
import { extractSizesFromProduct } from "@/lib/productSizes";
import { buildOrderBySizeMessage, buildWhatsAppUrl } from "@/lib/whatsapp";
import { getStoreKind } from "@/lib/storeKind";
import { useCart } from "@/context/CartContext";
import { TopBar } from "@/components/TopBar";
import { BottomNav } from "@/components/BottomNav";
import { CartSheet } from "@/components/CartSheet";
import { OfflineBanner } from "@/components/OfflineBanner";
import { Footer } from "@/components/Footer";
import { SEO } from "@/components/SEO";
import { StoreNotFound } from "@/components/StoreNotFound";
import { cn } from "@/lib/utils";

const ProductDetail = () => {
  const { productId } = useParams<{ productId: string }>();
  const { slug, store, ctx, isError } = useStore();
  const navigate = useNavigate();
  const { items, addItem, increment, decrement } = useCart();

  const { data: product, isLoading } = useQuery({
    queryKey: ["product", slug, productId],
    queryFn: () => fetchProductDetails(ctx!, productId!),
    enabled: !!ctx && !!productId,
    staleTime: 5 * 60 * 1000,
  });

  const sizes = useMemo(() => extractSizesFromProduct(product ?? null), [product]);
  const [selectedSize, setSelectedSize] = useState<string | null>(null);

  if (isError || !store) return <StoreNotFound slug={slug} />;

  const kind = getStoreKind(store);
  const isClothes = kind === "clothes";

  const inCart = product ? items.find((i) => i.id === product.id) : undefined;
  const priceInfo = product ? getDiscountedPrice(product) : null;

  const handleWhatsApp = () => {
    if (!product || !store.phone) return;
    const msg = buildOrderBySizeMessage({
      storeName: store.name,
      productName: product.name,
      size: selectedSize,
      price: priceInfo ? formatPrice(priceInfo.final) : undefined,
      url: typeof window !== "undefined" ? window.location.href : undefined,
    });
    window.open(buildWhatsAppUrl(store.phone, msg), "_blank", "noopener,noreferrer");
  };

  const sizeRequired = isClothes && sizes.length > 0;
  const waDisabled = sizeRequired && !selectedSize;

  return (
    <div className="min-h-screen flex flex-col bg-background overflow-x-clip">
      <SEO
        title={product ? `${product.name} — ${store.name}` : store.name}
        description={product?.description ?? store.name}
        image={product?.image_full_url || store.cover_photo_full_url}
      />
      <OfflineBanner />
      <TopBar store={store} />

      <header className="md:hidden sticky top-0 z-30 bg-background/95 backdrop-blur border-b border-border">
        <div className="container flex items-center gap-3 py-3">
          <button
            onClick={() => navigate(-1)}
            className="h-9 w-9 inline-flex items-center justify-center rounded-full hover:bg-muted transition-smooth"
            aria-label="رجوع"
          >
            <ArrowRight className="h-5 w-5 ltr:rotate-180" />
          </button>
          <h1 className="text-base font-extrabold line-clamp-1 flex-1">
            {product?.name ?? "تفاصيل المنتج"}
          </h1>
        </div>
      </header>

      <main className="flex-1 pb-28 md:pb-0">
        <div className="container py-4 md:py-6 grid md:grid-cols-2 gap-6 md:gap-10" dir="rtl">
          {/* Image */}
          <div className="bg-white rounded-2xl border border-border/60 shadow-soft overflow-hidden flex items-center justify-center aspect-square p-4">
            {isLoading ? (
              <div className="w-full h-full animate-pulse bg-muted rounded-xl" />
            ) : product?.image_full_url ? (
              <img
                src={product.image_full_url}
                alt={product.name}
                loading="eager"
                className="max-h-full max-w-full object-contain"
              />
            ) : (
              <div className="w-full h-full bg-muted rounded-xl" />
            )}
          </div>

          {/* Details */}
          <div className="space-y-4">
            {isLoading || !product ? (
              <>
                <div className="h-7 w-3/4 bg-muted animate-pulse rounded" />
                <div className="h-5 w-1/3 bg-muted animate-pulse rounded" />
                <div className="h-20 w-full bg-muted animate-pulse rounded" />
              </>
            ) : (
              <>
                <div>
                  <h2 className="text-xl md:text-2xl font-extrabold text-foreground leading-tight">
                    {product.name}
                  </h2>
                  {product.avg_rating > 0 && (
                    <div className="mt-1 inline-flex items-center gap-1 text-xs">
                      <Star className="h-3.5 w-3.5 fill-accent text-accent" />
                      <span className="font-bold">{product.avg_rating.toFixed(1)}</span>
                      <span className="text-muted-foreground">({product.rating_count})</span>
                    </div>
                  )}
                </div>

                <div className="flex items-baseline gap-3">
                  <span className="text-2xl md:text-3xl font-extrabold text-primary">
                    {formatPrice(priceInfo!.final)}
                  </span>
                  {priceInfo!.hasDiscount && (
                    <>
                      <span className="text-sm text-muted-foreground line-through">
                        {formatPrice(product.price)}
                      </span>
                      <span className="bg-discount text-discount-foreground text-[11px] font-extrabold px-2 py-0.5 rounded-full">
                        خصم {priceInfo!.pct}%
                      </span>
                    </>
                  )}
                </div>

                {product.description && (
                  <p className="text-sm text-muted-foreground leading-relaxed whitespace-pre-line">
                    {product.description}
                  </p>
                )}

                {/* Sizes */}
                {isClothes && sizes.length > 0 && (
                  <div>
                    <div className="flex items-center justify-between mb-2">
                      <h3 className="text-sm font-extrabold">المقاس</h3>
                      {selectedSize && (
                        <span className="text-xs font-bold text-primary">{selectedSize}</span>
                      )}
                    </div>
                    <div className="flex flex-wrap gap-2">
                      {sizes.map((s) => {
                        const active = selectedSize === s;
                        return (
                          <button
                            key={s}
                            type="button"
                            onClick={() => setSelectedSize(s)}
                            className={cn(
                              "min-w-[44px] h-10 px-3 rounded-xl border text-sm font-extrabold transition-smooth",
                              active
                                ? "bg-primary text-primary-foreground border-transparent"
                                : "bg-card text-foreground border-border hover:bg-muted",
                            )}
                          >
                            {s}
                          </button>
                        );
                      })}
                    </div>
                  </div>
                )}

                {/* Cart actions */}
                <div className="flex items-center gap-2 pt-2">
                  {inCart ? (
                    <div className="flex items-center gap-2 bg-card border border-border rounded-full p-1">
                      <button
                        onClick={() => decrement(product.id)}
                        aria-label="تقليل"
                        className="h-9 w-9 rounded-full bg-secondary inline-flex items-center justify-center"
                      >
                        <Minus className="h-4 w-4" />
                      </button>
                      <span className="px-2 text-sm font-extrabold tabular-nums min-w-[2ch] text-center">
                        {inCart.quantity}
                      </span>
                      <button
                        onClick={() => increment(product.id)}
                        aria-label="زيادة"
                        className="h-9 w-9 rounded-full bg-primary text-primary-foreground inline-flex items-center justify-center"
                      >
                        <Plus className="h-4 w-4" />
                      </button>
                    </div>
                  ) : (
                    <button
                      onClick={() => addItem(product)}
                      className="flex-1 h-12 rounded-full bg-primary text-primary-foreground font-extrabold inline-flex items-center justify-center gap-2 shadow-soft hover:bg-primary-glow transition-smooth"
                    >
                      <ShoppingBasket className="h-4 w-4" />
                      أضف للسلة
                    </button>
                  )}
                </div>

                {/* WhatsApp CTA */}
                {isClothes && store.phone && (
                  <button
                    onClick={handleWhatsApp}
                    disabled={waDisabled}
                    className={cn(
                      "w-full h-12 rounded-full font-extrabold inline-flex items-center justify-center gap-2 shadow-soft transition-smooth",
                      waDisabled
                        ? "bg-muted text-muted-foreground cursor-not-allowed"
                        : "bg-[hsl(142_70%_45%)] text-white hover:opacity-90",
                    )}
                  >
                    <MessageCircle className="h-4 w-4" />
                    {sizeRequired && !selectedSize
                      ? "اختر المقاس أولاً"
                      : sizes.length > 0
                        ? "اطلب بالمقاس عبر واتساب"
                        : "اطلب عبر واتساب"}
                  </button>
                )}

                <Link
                  to={`/${slug}/categories`}
                  className="block text-center text-xs text-muted-foreground hover:text-primary mt-3"
                >
                  ← متابعة التسوّق
                </Link>
              </>
            )}
          </div>
        </div>
      </main>

      <Footer store={store} />
      <BottomNav />
      <CartSheet />
    </div>
  );
};

export default ProductDetail;
