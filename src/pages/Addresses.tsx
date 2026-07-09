import { useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { ArrowRight, MapPin, Plus, Pencil, Trash2, Star, Loader2 } from "lucide-react";
import { toast } from "sonner";
import { useRemoteAddresses } from "@/hooks/useRemoteAddresses";
import { useStore } from "@/context/StoreContext";
import { AddressFormSheet, type ExtendedAddressData } from "@/components/account/AddressFormSheet";
import { BottomNav } from "@/components/BottomNav";
import { SEO } from "@/components/SEO";
import { cn } from "@/lib/utils";
import type { RemoteAddress } from "@/lib/remoteAddresses";

const Addresses = () => {
  const { storeSlug = "" } = useParams<{ storeSlug: string }>();
  const navigate = useNavigate();
  const { ctx } = useStore();
  const { addresses, loading, defaultId, add, update, remove, setDefault } =
    useRemoteAddresses();

  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<RemoteAddress | null>(null);

  const handleSave = async (data: ExtendedAddressData) => {
    const payload = {
      contact_person_name: data.contact_person_name ?? "",
      contact_person_number: data.contact_person_number ?? "",
      address_type: data.address_type ?? "home",
      address: data.address,
      latitude: String(ctx?.latitude ?? "0"),
      longitude: String(ctx?.longitude ?? "0"),
    };
    try {
      if (editing) {
        await update(editing.id, payload);
        toast.success("تم تحديث العنوان");
      } else {
        await add(payload);
        toast.success("تم حفظ العنوان");
      }
      setEditing(null);
    } catch (err) {
      toast.error("فشل الحفظ", {
        description: err instanceof Error ? err.message : undefined,
      });
      throw err;
    }
  };

  return (
    <div className="min-h-screen flex flex-col bg-background">
      <SEO title="عناويني" noindex />
      <header className="sticky top-0 z-30 bg-background/95 backdrop-blur border-b border-border">
        <div className="container py-3 flex items-center gap-2">
          <button
            type="button"
            onClick={() => navigate(`/${storeSlug}/account`)}
            aria-label="رجوع"
            className="shrink-0 h-10 w-10 rounded-full bg-secondary inline-flex items-center justify-center text-muted-foreground hover:text-foreground transition-smooth"
          >
            <ArrowRight className="h-5 w-5 ltr:rotate-180" />
          </button>
          <h1 className="flex-1 text-center text-lg font-extrabold">عناويني</h1>
          <span className="w-10" />
        </div>
      </header>

      <main className="flex-1 container py-4 pb-24 md:pb-8">
        <div className="rounded-2xl bg-card border border-border overflow-hidden">
          {loading && addresses.length === 0 ? (
            <div className="px-4 py-10 text-center">
              <Loader2 className="h-6 w-6 mx-auto animate-spin text-primary" />
            </div>
          ) : addresses.length === 0 ? (
            <div className="px-4 py-8 text-center space-y-2">
              <MapPin className="h-8 w-8 mx-auto text-muted-foreground/50" />
              <p className="text-sm text-muted-foreground">
                لا توجد عناوين محفوظة بعد.
              </p>
            </div>
          ) : (
            <ul className="divide-y divide-border">
              {addresses.map((a) => {
                const isDefault = a.id === defaultId;
                return (
                  <li key={a.id} className="px-4 py-3 flex items-start gap-3">
                    <span
                      className={cn(
                        "h-9 w-9 rounded-xl inline-flex items-center justify-center shrink-0",
                        isDefault
                          ? "bg-primary text-primary-foreground"
                          : "bg-primary-soft text-primary",
                      )}
                    >
                      <MapPin className="h-4 w-4" />
                    </span>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <p className="font-bold text-sm truncate">
                          {a.address_type === "workplace"
                            ? "العمل"
                            : a.address_type === "other"
                              ? "أخرى"
                              : "المنزل"}
                        </p>
                        {isDefault && (
                          <span className="text-[10px] font-extrabold text-primary bg-primary-soft px-1.5 py-0.5 rounded-full">
                            افتراضي
                          </span>
                        )}
                      </div>
                      <p className="text-xs text-muted-foreground mt-0.5 line-clamp-2">
                        {a.address}
                      </p>
                      {a.contact_person_name && (
                        <p className="text-[11px] text-muted-foreground/80 mt-0.5">
                          {a.contact_person_name}
                          {a.contact_person_number ? (
                            <>
                              {" "}
                              • <span dir="ltr">{a.contact_person_number}</span>
                            </>
                          ) : null}
                        </p>
                      )}
                    </div>
                    <div className="flex items-center gap-1 shrink-0">
                      {!isDefault && (
                        <button
                          type="button"
                          aria-label="تعيين كافتراضي"
                          className="h-8 w-8 rounded-full hover:bg-secondary inline-flex items-center justify-center text-muted-foreground hover:text-primary transition-smooth"
                          onClick={() => {
                            setDefault(a.id);
                            toast.success("تم تعيين العنوان الافتراضي");
                          }}
                        >
                          <Star className="h-4 w-4" />
                        </button>
                      )}
                      <button
                        type="button"
                        aria-label="تعديل"
                        className="h-8 w-8 rounded-full hover:bg-secondary inline-flex items-center justify-center text-muted-foreground hover:text-foreground transition-smooth"
                        onClick={() => {
                          setEditing(a);
                          setOpen(true);
                        }}
                      >
                        <Pencil className="h-4 w-4" />
                      </button>
                      <button
                        type="button"
                        aria-label="حذف"
                        className="h-8 w-8 rounded-full hover:bg-destructive/10 inline-flex items-center justify-center text-muted-foreground hover:text-destructive transition-smooth"
                        onClick={async () => {
                          try {
                            await remove(a.id);
                            toast.success("تم حذف العنوان");
                          } catch (err) {
                            toast.error("تعذّر الحذف", {
                              description: err instanceof Error ? err.message : undefined,
                            });
                          }
                        }}
                      >
                        <Trash2 className="h-4 w-4" />
                      </button>
                    </div>
                  </li>
                );
              })}
            </ul>
          )}
          <button
            type="button"
            onClick={() => {
              setEditing(null);
              setOpen(true);
            }}
            className="w-full flex items-center justify-center gap-2 py-3 border-t border-border text-primary font-bold text-sm hover:bg-primary-soft/40 transition-smooth"
          >
            <Plus className="h-4 w-4" />
            إضافة عنوان جديد
          </button>
        </div>
      </main>

      <AddressFormSheet
        open={open}
        onOpenChange={(v) => {
          setOpen(v);
          if (!v) setEditing(null);
        }}
        initial={
          editing
            ? {
                address: editing.address,
                contact_person_name: editing.contact_person_name,
                contact_person_number: editing.contact_person_number,
                address_type: editing.address_type,
              }
            : null
        }
        onSave={handleSave}
        extended
      />

      <BottomNav />
    </div>
  );
};

export default Addresses;
