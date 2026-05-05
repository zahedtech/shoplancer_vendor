import { useState } from "react";
import { MapPin, Plus, Pencil, Trash2, Star, StarOff } from "lucide-react";
import { toast } from "sonner";
import {
  Address,
  addAddress,
  deleteAddress,
  loadAddresses,
  setDefaultAddress,
  updateAddress,
} from "@/lib/addresses";
import { AddressFormSheet } from "./AddressFormSheet";
import { cn } from "@/lib/utils";

export const AddressesList = () => {
  const [items, setItems] = useState<Address[]>(() => loadAddresses());
  const [editing, setEditing] = useState<Address | null>(null);
  const [open, setOpen] = useState(false);

  const refresh = () => setItems(loadAddresses());

  const handleSave = (data: Omit<Address, "id">) => {
    if (editing) {
      updateAddress(editing.id, data);
      toast.success("تم تحديث العنوان");
    } else {
      addAddress(data);
      toast.success("تم حفظ العنوان");
    }
    refresh();
    setEditing(null);
  };

  return (
    <>
      <div className="rounded-2xl bg-card border border-border overflow-hidden">
        {items.length === 0 ? (
          <div className="px-4 py-6 text-center space-y-2">
            <p className="text-sm text-muted-foreground">لا توجد عناوين محفوظة بعد.</p>
          </div>
        ) : (
          <ul className="divide-y divide-border">
            {items.map((a, idx) => {
              const isDefault = idx === 0;
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
                        {a.label || "عنوان"}
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
                    {a.notes && (
                      <p className="text-[11px] text-muted-foreground/80 mt-0.5">
                        {a.notes}
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
                          setDefaultAddress(a.id);
                          refresh();
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
                      onClick={() => {
                        deleteAddress(a.id);
                        refresh();
                        toast.success("تم حذف العنوان");
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

      <AddressFormSheet
        open={open}
        onOpenChange={(v) => {
          setOpen(v);
          if (!v) setEditing(null);
        }}
        initial={editing}
        onSave={handleSave}
      />
    </>
  );
};
