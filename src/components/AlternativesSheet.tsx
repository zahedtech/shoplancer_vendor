import { useEffect, useState } from "react";
import { PackageX, ArrowLeftRight } from "lucide-react";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetDescription,
} from "@/components/ui/sheet";
import { Button } from "@/components/ui/button";
import type { Product } from "@/lib/api";
import { findAlternatives, subscribeProducts } from "@/lib/productAlternatives";
import { useCart } from "@/context/CartContext";
import { ProductCard } from "@/components/ProductCard";

interface AlternativesSheetProps {
  open: boolean;
  onOpenChange: (v: boolean) => void;
  /** The unavailable product whose alternatives we're suggesting. */
  product: Product;
  /** When true, also offer to remove the unavailable item from the cart. */
  showRemoveFromCart?: boolean;
}

/**
 * Bottom sheet that explains a product is out of stock and suggests
 * alternatives from the same category. Re-renders when the global
 * registry receives more products (e.g. another rail loads after).
 */
export function AlternativesSheet({
  open,
  onOpenChange,
  product,
  showRemoveFromCart,
}: AlternativesSheetProps) {
  const { items, removeItem } = useCart();
  const inCart = items.some((i) => i.id === product.id);
  const [, force] = useState(0);
  useEffect(() => subscribeProducts(() => force((n) => n + 1)), []);

  const alternatives = findAlternatives(product, 12);

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      
      <SheetContent
        side="bottom"
        className="max-h-[88vh] overflow-y-auto p-0"
      >
        <div className="p-4 border-b border-border bg-discount/5">
          <SheetHeader className="text-start space-y-2">
            <div className="inline-flex items-center gap-2">
              <span className="h-9 w-9 rounded-full bg-discount/15 text-discount inline-flex items-center justify-center shrink-0">
                <PackageX className="h-5 w-5" />
              </span>
              <SheetTitle className="text-base">
                المنتج غير متوفر حاليًا
              </SheetTitle>
            </div>
            <SheetDescription className="text-xs leading-relaxed">
              <span className="font-bold text-foreground">{product.name}</span>{" "}
              نفد من المخزون. اخترنا لك بدائل مشابهة من نفس الفئة.
            </SheetDescription>
          </SheetHeader>
        </div>

        <div className="p-3">
          {alternatives.length === 0 ? (
            <div className="flex flex-col items-center justify-center text-center gap-2 py-10">
              <ArrowLeftRight className="h-8 w-8 text-muted-foreground" />
              <p className="text-sm font-bold text-foreground">
                لا توجد بدائل متاحة حاليًا
              </p>
              <p className="text-xs text-muted-foreground max-w-xs">
                جرّب تصفّح الفئات لاكتشاف منتجات أخرى — أو عاود لاحقًا.
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-2 gap-3">
              {alternatives.map((alt) => (
                <ProductCard key={alt.id} product={alt} />
              ))}
            </div>
          )}
        </div>

        {(showRemoveFromCart && inCart) && (
          <div className="sticky bottom-0 inset-x-0 p-3 border-t border-border bg-background">
            <Button
              variant="outline"
              className="w-full font-extrabold"
              onClick={() => {
                removeItem(product.id);
                onOpenChange(false);
              }}
            >
              إزالة من السلة
            </Button>
          </div>
        )}
      </SheetContent>
    </Sheet>
  );
}

