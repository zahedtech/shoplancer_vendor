import { useState } from "react";
import { useParams, useNavigate, Link } from "react-router-dom";
import { ArrowRight, Save, RefreshCw } from "lucide-react";
import { storesRegistry, DEFAULT_SHOPLANSER_BASE } from "@/lib/storesRegistry";
import { useStoresRegistry } from "@/hooks/useStoresRegistry";
import { fetchStore } from "@/lib/api";
import { toast } from "sonner";

export default function AdminStoreSettings() {
  const { slug = "" } = useParams<{ slug: string }>();
  const stores = useStoresRegistry();
  const entry = stores.find((s) => s.slug === slug);
  const navigate = useNavigate();

  const [apiBase, setApiBase] = useState(entry?.apiBase ?? DEFAULT_SHOPLANSER_BASE);
  const [displayName, setDisplayName] = useState(entry?.displayName ?? "");
  const [refreshing, setRefreshing] = useState(false);

  if (!entry) {
    return (
      <div className="text-center py-16">
        <p className="text-muted-foreground">المتجر غير موجود.</p>
        <Link to="/admin/stores" className="text-primary font-bold mt-4 inline-block">
          العودة للمتاجر
        </Link>
      </div>
    );
  }

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    storesRegistry.upsert({
      slug,
      apiBase: apiBase.trim() || DEFAULT_SHOPLANSER_BASE,
      displayName: displayName.trim() || undefined,
    });
    toast.success("تم الحفظ");
  };

  const handleRefresh = async () => {
    setRefreshing(true);
    try {
      const d = await fetchStore(slug);
      storesRegistry.upsert({
        slug,
        displayName: d.name,
        cachedLogo: d.logo_full_url,
        cachedModuleId: d.module_id ?? d.module?.id,
      });
      setDisplayName(d.name);
      toast.success("تم تحديث البيانات من Shoplanser");
    } catch {
      toast.error("فشل التحديث");
    } finally {
      setRefreshing(false);
    }
  };

  return (
    <div className="max-w-3xl space-y-6">
      <div className="flex items-center gap-2">
        <button
          onClick={() => navigate("/admin/stores")}
          className="h-9 w-9 inline-flex items-center justify-center rounded-lg hover:bg-muted"
        >
          <ArrowRight className="h-4 w-4 ltr:rotate-180" />
        </button>
        <div>
          <h2 className="text-2xl font-extrabold">إعدادات: {entry.displayName ?? slug}</h2>
          <p className="text-sm text-muted-foreground">
            تعديل ربط المتجر بمصدر البيانات.
          </p>
        </div>
      </div>

      <form onSubmit={handleSave} className="bg-card rounded-2xl border border-border p-5 space-y-4">
        <div>
          <label className="block text-sm font-bold mb-1.5">Slug</label>
          <input
            value={slug}
            disabled
            className="w-full bg-muted border border-input rounded-xl px-3 py-2 text-sm font-mono"
          />
          <p className="text-xs text-muted-foreground mt-1">لا يمكن تغيير الـ slug — احذف المتجر وأضفه بـ slug جديد.</p>
        </div>

        <div>
          <label className="block text-sm font-bold mb-1.5">اسم العرض</label>
          <input
            value={displayName}
            onChange={(e) => setDisplayName(e.target.value)}
            placeholder="هاشم"
            className="w-full bg-background border border-input rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary"
          />
        </div>

        <div>
          <label className="block text-sm font-bold mb-1.5">API Base URL</label>
          <input
            value={apiBase}
            onChange={(e) => setApiBase(e.target.value)}
            className="w-full bg-background border border-input rounded-xl px-3 py-2 text-sm font-mono focus:outline-none focus:ring-2 focus:ring-primary"
          />
          <p className="text-xs text-muted-foreground mt-1">
            افتراضي: <code>{DEFAULT_SHOPLANSER_BASE}</code>
          </p>
        </div>

        <div className="grid grid-cols-2 gap-4 pt-2 border-t border-border">
          <div>
            <span className="text-xs text-muted-foreground">Module ID</span>
            <div className="font-bold">{entry.cachedModuleId ?? "—"}</div>
          </div>
          <div>
            <span className="text-xs text-muted-foreground">تمت الإضافة</span>
            <div className="font-bold text-xs">{new Date(entry.createdAt).toLocaleDateString("ar-EG")}</div>
          </div>
        </div>

        <div className="flex gap-2 pt-2">
          <button
            type="submit"
            className="bg-primary text-primary-foreground px-4 py-2 rounded-xl font-bold inline-flex items-center gap-2 hover:bg-primary-glow"
          >
            <Save className="h-4 w-4" /> حفظ
          </button>
          <button
            type="button"
            onClick={handleRefresh}
            disabled={refreshing}
            className="px-4 py-2 rounded-xl font-bold border border-border hover:bg-muted inline-flex items-center gap-2 disabled:opacity-50"
          >
            <RefreshCw className={`h-4 w-4 ${refreshing ? "animate-spin" : ""}`} /> تحديث من API
          </button>
        </div>
      </form>
    </div>
  );
}
