import { Sparkles } from "lucide-react";
import { useTranslation } from "react-i18next";
import { Product } from "@/lib/api";
import { ProductCard } from "@/components/ProductCard";

interface Props {
  products: Product[];
  loading?: boolean;
}

export const SuggestedProducts = ({ products, loading }: Props) => {
  const { t } = useTranslation();
  if (loading) {
    return (
      <section className="space-y-3">
        <h3 className="text-sm font-extrabold text-foreground flex items-center gap-2">
          <Sparkles className="h-4 w-4 text-primary" />
          {t("suggested.title")}
        </h3>
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3">
          {[...Array(6)].map((_, i) => (
            <div
              key={i}
              className="aspect-[3/4] rounded-2xl bg-muted animate-pulse"
            />
          ))}
        </div>
      </section>
    );
  }

  if (products.length === 0) return null;

  return (
    <section className="space-y-3">
      <h3 className="text-sm font-extrabold text-foreground flex items-center gap-2">
        <Sparkles className="h-4 w-4 text-primary" />
        {t("suggested.title")}
      </h3>
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3">
        {products.slice(0, 8).map((p) => (
          <ProductCard key={p.id} product={p} />
        ))}
      </div>
    </section>
  );
};
