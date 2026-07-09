import { useState } from "react";
import { Link } from "react-router-dom";
import { ExternalLink, Plus, Store, Trash2, LayoutDashboard, Settings } from "lucide-react";
import { useStoresRegistry } from "@/hooks/useStoresRegistry";
import { storesRegistry, DEFAULT_SHOPLANSER_BASE } from "@/lib/storesRegistry";
import { fetchStore } from "@/lib/api";
import { toast } from "sonner";

export default function AdminStores() {
  const stores = useStoresRegistry();
  const [open, setOpen] = useState(false);
  const [slug, setSlug] = useState("");
  const [apiBase, setApiBase] = useState(DEFAULT_SHOPLANSER_BASE);
  const [loading, setLoading] = useState(false);

  const handleAdd = async (e: React.FormEvent) => {
    e.preventDefault();
    const cleaned = slug.trim().toLowerCase().replace(/^\/+/, "");
    if (!cleaned) {
      toast.error("أدخل slug للمتجر");
      return;
    }
    setLoading(true);
    try {
      const details = await fetchStore(cleaned);
      storesRegistry.upsert({
        slug: cleaned,
        apiBase: apiBase.trim() || DEFAULT_SHOPLANSER_BASE,
        displayName: details.name,
        cachedLogo: details.logo_full_url,
        cachedModuleId: details.module_id ?? details.module?.id,
      });
      toast.success(`تم ربط متجر ${details.name}`);
      setSlug("");
      setOpen(false);
    } catch (err) {
      toast.error("لم نعثر على هذا المتجر — تحقق من الـ slug");
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = (slug: string) => {
    if (!confirm(`حذف ${slug} من القائمة؟ (لن يتأثر المتجر على Shoplanser)`)) return;
    storesRegistry.remove(slug);
    toast.success("تم الحذف");
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-extrabold">المتاجر المرتبطة</h2>
          <p className="text-sm text-muted-foreground mt-1">
            كل متجر له صفحة عرض ولوحة تحكم خاصة.
          </p>
        </div>
        <button
          onClick={() => setOpen((o) => !o)}
          className="bg-primary text-primary-foreground px-4 py-2 rounded-xl font-bold inline-flex items-center gap-2 hover:bg-primary-glow transition-smooth"
        >
          <Plus className="h-4 w-4" />
          إضافة متجر
        </button>
      </div>

      {open && (
        <form
          onSubmit={handleAdd}
          className="bg-card rounded-2xl border border-border p-5 space-y-4"
        >
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-bold mb-1.5">Slug المتجر *</label>
              <input
                value={slug}
                onChange={(e) => setSlug(e.target.value)}
                placeholder="awaldrazq"
                className="w-full bg-background border border-input rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary"
                disabled={loading}
              />
              <p className="text-xs text-muted-foreground mt-1">
                مثال: <code className="bg-muted px-1 rounded">awaldrazq</code> →{" "}
                <code className="bg-muted px-1 rounded">/awaldrazq</code>
              </p>
            </div>
            <div>
              <label className="block text-sm font-bold mb-1.5">API Base</label>
              <input
                value={apiBase}
                onChange={(e) => setApiBase(e.target.value)}
                className="w-full bg-background border border-input rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary"
                disabled={loading}
              />
              <p className="text-xs text-muted-foreground mt-1">افتراضي: Shoplanser</p>
            </div>
          </div>
          <div className="flex gap-2">
            <button
              type="submit"
              disabled={loading}
              className="bg-primary text-primary-foreground px-4 py-2 rounded-xl font-bold hover:bg-primary-glow transition-smooth disabled:opacity-50"
            >
              {loading ? "جارٍ التحقق..." : "تحقّق وإضافة"}
            </button>
            <button
              type="button"
              onClick={() => setOpen(false)}
              className="px-4 py-2 rounded-xl font-bold border border-border hover:bg-muted"
            >
              إلغاء
            </button>
          </div>
        </form>
      )}

      <div className="bg-card rounded-2xl border border-border overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-muted/50 text-right">
            <tr>
              <th className="p-3 font-bold">المتجر</th>
              <th className="p-3 font-bold">Slug</th>
              <th className="p-3 font-bold">API</th>
              <th className="p-3 font-bold">إجراءات</th>
            </tr>
          </thead>
          <tbody>
            {stores.map((s) => (
              <tr key={s.slug} className="border-t border-border hover:bg-muted/30">
                <td className="p-3">
                  <div className="flex items-center gap-3">
                    <div className="h-10 w-10 rounded-lg bg-secondary inline-flex items-center justify-center overflow-hidden">
                      {s.cachedLogo ? (
                        <img src={s.cachedLogo} alt={s.slug} className="h-full w-full object-cover" />
                      ) : (
                        <Store className="h-4 w-4 text-muted-foreground" />
                      )}
                    </div>
                    <span className="font-bold">{s.displayName ?? s.slug}</span>
                  </div>
                </td>
                <td className="p-3 font-mono text-xs">/{s.slug}</td>
                <td className="p-3 text-xs text-muted-foreground truncate max-w-[200px]">
                  {s.apiBase.replace("https://", "")}
                </td>
                <td className="p-3">
                  <div className="flex items-center gap-1">
                    <Link
                      to={`/${s.slug}/dashboard`}
                      title="لوحة التاجر"
                      className="h-8 w-8 inline-flex items-center justify-center rounded-lg hover:bg-primary-soft text-primary"
                    >
                      <LayoutDashboard className="h-4 w-4" />
                    </Link>
                    <Link
                      to={`/${s.slug}`}
                      title="عرض المتجر"
                      className="h-8 w-8 inline-flex items-center justify-center rounded-lg hover:bg-muted"
                    >
                      <ExternalLink className="h-4 w-4" />
                    </Link>
                    <Link
                      to={`/admin/stores/${s.slug}/settings`}
                      title="الإعدادات"
                      className="h-8 w-8 inline-flex items-center justify-center rounded-lg hover:bg-muted"
                    >
                      <Settings className="h-4 w-4" />
                    </Link>
                    <button
                      onClick={() => handleDelete(s.slug)}
                      title="حذف"
                      className="h-8 w-8 inline-flex items-center justify-center rounded-lg hover:bg-destructive/10 text-destructive"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
            {stores.length === 0 && (
              <tr>
                <td colSpan={4} className="p-8 text-center text-muted-foreground">
                  لا توجد متاجر بعد. اضغط "إضافة متجر" لربط أول متجر.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
