import { useState, useMemo } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { Search, Edit, Save, X, RotateCcw, RefreshCw, History } from "lucide-react";
import { useStore } from "@/context/StoreContext";
import { fetchProducts, formatPrice, getDiscountedPrice, Product } from "@/lib/api";
import { usePriceOverrides } from "@/hooks/usePriceOverrides";
import {
  setOverride,
  removeOverride,
  getHistory,
  getHistoryFor,
  clearHistory,
  PriceHistoryEntry,
} from "@/lib/priceOverrides";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import { toast } from "sonner";

function formatDateTime(iso: string): string {
  try {
    return new Date(iso).toLocaleString("ar-EG", {
      dateStyle: "medium",
      timeStyle: "short",
    });
  } catch {
    return iso;
  }
}

export default function VendorProducts() {
  const { ctx, slug } = useStore();
  const queryClient = useQueryClient();
  const [search, setSearch] = useState("");
  const [editingId, setEditingId] = useState<number | null>(null);
  const [editValue, setEditValue] = useState("");
  const overrides = usePriceOverrides(slug);
  const [historyOpen, setHistoryOpen] = useState(false);
  // null = show full store-wide history; otherwise show one product's history
  const [historyProduct, setHistoryProduct] = useState<Product | null>(null);

  const { data, isLoading, isFetching } = useQuery({
    queryKey: ["vendor-all-products", slug],
    queryFn: () => fetchProducts(ctx!, { limit: 200 }),
    enabled: !!ctx,
  });

  const products = useMemo(() => {
    const all = data?.products ?? [];
    if (!search.trim()) return all;
    const q = search.trim().toLowerCase();
    return all.filter((p) => p.name.toLowerCase().includes(q));
  }, [data, search]);

  // Recompute history when overrides change (usePriceOverrides also fires on history writes)
  const allHistory: PriceHistoryEntry[] = useMemo(() => {
    void overrides;
    return getHistory(slug);
  }, [slug, overrides]);

  const visibleHistory: PriceHistoryEntry[] = useMemo(() => {
    if (historyProduct) return getHistoryFor(slug, historyProduct.id);
    return allHistory;
  }, [historyProduct, allHistory, slug, overrides]);

  const startEdit = (p: Product) => {
    setEditingId(p.id);
    setEditValue(String(overrides[p.id] ?? p.price));
  };
  const cancelEdit = () => {
    setEditingId(null);
    setEditValue("");
  };
  const saveEdit = (p: Product) => {
    const num = Number(editValue);
    if (!Number.isFinite(num) || num < 0) {
      toast.error("سعر غير صالح");
      return;
    }
    setOverride(slug, p.id, num, {
      originalPrice: p.price,
      productName: p.name,
    });
    toast.success("تم تحديث السعر — ظهر فوراً في المتجر");
    cancelEdit();
  };
  const resetPrice = (p: Product) => {
    removeOverride(slug, p.id, {
      originalPrice: p.price,
      productName: p.name,
    });
    toast.success("تم إرجاع السعر الأصلي");
  };
  const refreshFromShoplanser = () => {
    queryClient.invalidateQueries({ queryKey: ["vendor-all-products", slug] });
    queryClient.invalidateQueries({ queryKey: ["products", slug] });
    toast.success("جارٍ تحديث المنتجات من Shoplanser...");
  };

  const openProductHistory = (p: Product) => {
    setHistoryProduct(p);
    setHistoryOpen(true);
  };
  const openFullHistory = () => {
    setHistoryProduct(null);
    setHistoryOpen(true);
  };
  const handleClearHistory = () => {
    if (!confirm("هل تريد فعلاً مسح كل سجل تغييرات الأسعار؟")) return;
    clearHistory(slug);
    toast.success("تم مسح السجل");
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3">
        <div>
          <h2 className="text-2xl font-extrabold">المنتجات والأسعار</h2>
          <p className="text-sm text-muted-foreground mt-1">
            عدّل سعر أي منتج — التغيير يظهر فوراً في صفحة متجرك العامة.
          </p>
        </div>
        <div className="flex items-center gap-2 w-full md:w-auto">
          <div className="relative flex-1 md:w-72">
            <Search className="absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="ابحث عن منتج..."
              className="w-full bg-card border border-input rounded-xl pr-9 pl-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>
          <button
            onClick={openFullHistory}
            className="h-10 px-3 inline-flex items-center gap-2 rounded-xl bg-card border border-input hover:bg-muted text-sm font-bold"
            title="سجل تغييرات الأسعار"
          >
            <History className="h-4 w-4" />
            <span className="hidden sm:inline">السجل</span>
            {allHistory.length > 0 && (
              <span className="text-[10px] bg-primary text-primary-foreground rounded-full px-1.5 py-0.5">
                {allHistory.length}
              </span>
            )}
          </button>
          <button
            onClick={refreshFromShoplanser}
            disabled={isFetching}
            className="h-10 w-10 inline-flex items-center justify-center rounded-xl bg-card border border-input hover:bg-muted disabled:opacity-50"
            title="تحديث من Shoplanser"
          >
            <RefreshCw className={`h-4 w-4 ${isFetching ? "animate-spin" : ""}`} />
          </button>
        </div>
      </div>

      <div className="bg-card rounded-2xl border border-border overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-muted/50 text-right">
              <tr>
                <th className="p-3 font-bold">المنتج</th>
                <th className="p-3 font-bold">الفئة</th>
                <th className="p-3 font-bold">السعر</th>
                <th className="p-3 font-bold">الخصم</th>
                <th className="p-3 font-bold">المخزون</th>
                <th className="p-3 font-bold">إجراءات</th>
              </tr>
            </thead>
            <tbody>
              {isLoading &&
                Array.from({ length: 6 }).map((_, i) => (
                  <tr key={i} className="border-t border-border">
                    <td colSpan={6} className="p-4">
                      <div className="h-8 bg-muted rounded animate-pulse" />
                    </td>
                  </tr>
                ))}
              {products.map((p) => {
                const override = overrides[p.id];
                const hasOverride = override !== undefined && override !== p.price;
                const effectivePrice = override ?? p.price;
                const { hasDiscount, pct } = getDiscountedPrice({
                  ...p,
                  price: effectivePrice,
                });
                const isEditing = editingId === p.id;
                const productHistoryCount = allHistory.filter(
                  (h) => h.productId === p.id,
                ).length;
                return (
                  <tr key={p.id} className="border-t border-border hover:bg-muted/30">
                    <td className="p-3">
                      <div className="flex items-center gap-3 min-w-0">
                        <div className="h-12 w-12 rounded-lg bg-white border border-border inline-flex items-center justify-center overflow-hidden shrink-0">
                          {p.image_full_url && (
                            <img
                              src={p.image_full_url}
                              alt={p.name}
                              loading="lazy"
                              className="max-h-full max-w-full object-contain"
                            />
                          )}
                        </div>
                        <span className="font-bold truncate max-w-[220px]">{p.name}</span>
                      </div>
                    </td>
                    <td className="p-3 text-xs text-muted-foreground">
                      {p.category_ids?.[0]?.name ?? "—"}
                    </td>
                    <td className="p-3">
                      {isEditing ? (
                        <input
                          type="number"
                          step="0.01"
                          value={editValue}
                          onChange={(e) => setEditValue(e.target.value)}
                          className="w-24 bg-background border border-input rounded-lg px-2 py-1 text-sm focus:outline-none focus:ring-2 focus:ring-primary"
                          autoFocus
                        />
                      ) : (
                        <div className="flex flex-col">
                          <span className="font-extrabold text-primary">
                            {formatPrice(effectivePrice)}
                          </span>
                          {hasOverride && (
                            <span className="text-[10px] text-muted-foreground line-through">
                              {formatPrice(p.price)}
                            </span>
                          )}
                        </div>
                      )}
                    </td>
                    <td className="p-3">
                      {hasDiscount ? (
                        <span className="bg-discount/10 text-discount text-xs font-bold px-2 py-1 rounded-full">
                          {pct}%
                        </span>
                      ) : (
                        <span className="text-xs text-muted-foreground">—</span>
                      )}
                    </td>
                    <td className="p-3">
                      <span
                        className={`text-xs font-bold ${
                          p.stock > 10
                            ? "text-fresh"
                            : p.stock > 0
                            ? "text-accent"
                            : "text-destructive"
                        }`}
                      >
                        {p.stock}
                      </span>
                    </td>
                    <td className="p-3">
                      {isEditing ? (
                        <div className="flex items-center gap-1">
                          <button
                            onClick={() => saveEdit(p)}
                            className="h-8 w-8 inline-flex items-center justify-center rounded-lg bg-primary text-primary-foreground hover:bg-primary-glow"
                            title="حفظ"
                          >
                            <Save className="h-4 w-4" />
                          </button>
                          <button
                            onClick={cancelEdit}
                            className="h-8 w-8 inline-flex items-center justify-center rounded-lg hover:bg-muted"
                            title="إلغاء"
                          >
                            <X className="h-4 w-4" />
                          </button>
                        </div>
                      ) : (
                        <div className="flex items-center gap-1">
                          <button
                            onClick={() => startEdit(p)}
                            className="h-8 w-8 inline-flex items-center justify-center rounded-lg hover:bg-primary-soft text-primary"
                            title="تعديل السعر"
                          >
                            <Edit className="h-4 w-4" />
                          </button>
                          {hasOverride && (
                            <button
                              onClick={() => resetPrice(p)}
                              className="h-8 w-8 inline-flex items-center justify-center rounded-lg hover:bg-muted text-muted-foreground"
                              title="إرجاع السعر الأصلي"
                            >
                              <RotateCcw className="h-4 w-4" />
                            </button>
                          )}
                          <button
                            onClick={() => openProductHistory(p)}
                            className="h-8 w-8 relative inline-flex items-center justify-center rounded-lg hover:bg-muted text-muted-foreground"
                            title="سجل التغييرات"
                          >
                            <History className="h-4 w-4" />
                            {productHistoryCount > 0 && (
                              <span className="absolute -top-1 -right-1 h-4 min-w-4 px-1 rounded-full bg-primary text-primary-foreground text-[9px] font-bold inline-flex items-center justify-center">
                                {productHistoryCount}
                              </span>
                            )}
                          </button>
                        </div>
                      )}
                    </td>
                  </tr>
                );
              })}
              {!isLoading && products.length === 0 && (
                <tr>
                  <td colSpan={6} className="p-8 text-center text-muted-foreground">
                    لا توجد منتجات مطابقة
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      <p className="text-xs text-muted-foreground">
        💡 الأسعار المعدّلة تُحفظ لكل متجر على حدة وتظهر فوراً للزبائن. عند توصيل Vendor API ستُرسل تلقائياً للسيرفر.
      </p>

      {/* Audit log dialog */}
      <Dialog open={historyOpen} onOpenChange={setHistoryOpen}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle className="text-right">
              {historyProduct
                ? `سجل أسعار: ${historyProduct.name}`
                : "سجل تغييرات الأسعار"}
            </DialogTitle>
            <DialogDescription className="text-right">
              يعرض من غيّر السعر، متى، والقيمة القديمة مقابل الجديدة.
            </DialogDescription>
          </DialogHeader>

          <div className="flex items-center justify-between gap-2 pb-2">
            <div className="text-xs text-muted-foreground">
              {visibleHistory.length} عملية
              {historyProduct && allHistory.length > visibleHistory.length && (
                <button
                  onClick={() => setHistoryProduct(null)}
                  className="mr-2 text-primary hover:underline"
                >
                  عرض كل المنتجات
                </button>
              )}
            </div>
            {visibleHistory.length > 0 && !historyProduct && (
              <button
                onClick={handleClearHistory}
                className="text-xs text-destructive hover:underline"
              >
                مسح السجل
              </button>
            )}
          </div>

          <div className="max-h-[60vh] overflow-y-auto border border-border rounded-xl">
            {visibleHistory.length === 0 ? (
              <div className="p-8 text-center text-sm text-muted-foreground">
                لا توجد تغييرات بعد
              </div>
            ) : (
              <table className="w-full text-sm">
                <thead className="bg-muted/50 text-right sticky top-0">
                  <tr>
                    {!historyProduct && <th className="p-2 font-bold">المنتج</th>}
                    <th className="p-2 font-bold">من</th>
                    <th className="p-2 font-bold">إلى</th>
                    <th className="p-2 font-bold">بواسطة</th>
                    <th className="p-2 font-bold">التاريخ</th>
                  </tr>
                </thead>
                <tbody>
                  {visibleHistory.map((h) => {
                    const diff = h.newPrice - h.oldPrice;
                    const diffColor =
                      diff > 0
                        ? "text-destructive"
                        : diff < 0
                        ? "text-fresh"
                        : "text-muted-foreground";
                    return (
                      <tr key={h.id} className="border-t border-border hover:bg-muted/30">
                        {!historyProduct && (
                          <td className="p-2 font-bold truncate max-w-[180px]">
                            {h.productName}
                          </td>
                        )}
                        <td className="p-2 text-muted-foreground line-through">
                          {formatPrice(h.oldPrice)}
                        </td>
                        <td className="p-2">
                          <div className="flex flex-col">
                            <span className="font-extrabold text-primary">
                              {formatPrice(h.newPrice)}
                            </span>
                            <span className={`text-[10px] ${diffColor}`}>
                              {h.action === "reset"
                                ? "إرجاع للأصلي"
                                : `${diff > 0 ? "+" : ""}${formatPrice(diff)}`}
                            </span>
                          </div>
                        </td>
                        <td className="p-2 text-xs">{h.actor}</td>
                        <td className="p-2 text-xs text-muted-foreground whitespace-nowrap">
                          {formatDateTime(h.timestamp)}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            )}
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
