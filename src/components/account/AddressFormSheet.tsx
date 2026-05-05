import { useEffect, useState } from "react";
import { Sheet, SheetContent, SheetHeader, SheetTitle } from "@/components/ui/sheet";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { Address } from "@/lib/addresses";
import { cn } from "@/lib/utils";
import { InstallGate } from "@/components/install/InstallGate";

export interface ExtendedAddressInitial {
  label?: string;
  address: string;
  notes?: string;
  contact_person_name?: string;
  contact_person_number?: string;
  address_type?: string;
}

export interface ExtendedAddressData extends Omit<Address, "id"> {
  contact_person_name?: string;
  contact_person_number?: string;
  address_type?: string;
}

interface Props {
  open: boolean;
  onOpenChange: (v: boolean) => void;
  initial?: ExtendedAddressInitial | null;
  onSave: (data: ExtendedAddressData) => void | Promise<void>;
  /** Show contact + address-type fields (used for API-backed addresses). */
  extended?: boolean;
}

const TYPES: Array<{ key: string; label: string }> = [
  { key: "home", label: "المنزل" },
  { key: "workplace", label: "العمل" },
  { key: "other", label: "أخرى" },
];

export const AddressFormSheet = ({
  open,
  onOpenChange,
  initial,
  onSave,
  extended = false,
}: Props) => {
  const [label, setLabel] = useState("");
  const [address, setAddress] = useState("");
  const [notes, setNotes] = useState("");
  const [contactName, setContactName] = useState("");
  const [contactPhone, setContactPhone] = useState("");
  const [addressType, setAddressType] = useState<string>("home");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (open) {
      setLabel(initial?.label ?? "");
      setAddress(initial?.address ?? "");
      setNotes(initial?.notes ?? "");
      setContactName(initial?.contact_person_name ?? "");
      setContactPhone(initial?.contact_person_number ?? "");
      setAddressType(initial?.address_type ?? "home");
      setError(null);
    }
  }, [open, initial]);

  const submit = async () => {
    const a = address.trim();
    if (a.length < 5) {
      setError("الرجاء كتابة عنوان واضح (5 أحرف على الأقل).");
      return;
    }
    if (extended) {
      if (contactName.trim().length < 2) {
        setError("اكتب اسم المستلم.");
        return;
      }
      if (!/^[0-9+\-\s]{7,20}$/.test(contactPhone.trim())) {
        setError("رقم الهاتف غير صالح.");
        return;
      }
    }
    setBusy(true);
    try {
      await onSave({
        label: label.trim() || undefined,
        address: a,
        notes: notes.trim() || undefined,
        contact_person_name: contactName.trim() || undefined,
        contact_person_number: contactPhone.trim() || undefined,
        address_type: addressType,
      });
      onOpenChange(false);
    } catch (err) {
      setError(err instanceof Error ? err.message : "تعذّر الحفظ");
    } finally {
      setBusy(false);
    }
  };

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent side="bottom" className="rounded-t-3xl max-h-[90vh] overflow-y-auto">
        <SheetHeader>
          <SheetTitle>{initial?.address ? "تعديل العنوان" : "إضافة عنوان"}</SheetTitle>
        </SheetHeader>
        <div className="space-y-3 py-4">
          {extended && (
            <div className="space-y-1.5">
              <Label>نوع العنوان</Label>
              <div className="grid grid-cols-3 gap-2">
                {TYPES.map((t) => {
                  const active = addressType === t.key;
                  return (
                    <button
                      key={t.key}
                      type="button"
                      onClick={() => setAddressType(t.key)}
                      className={cn(
                        "h-10 rounded-xl border-2 text-sm font-bold transition-smooth",
                        active
                          ? "border-primary bg-primary/5 text-primary"
                          : "border-border hover:border-primary/40 text-foreground",
                      )}
                    >
                      {t.label}
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          <div className="space-y-1.5">
            <Label htmlFor="addr-label">التسمية (اختياري)</Label>
            <Input
              id="addr-label"
              placeholder="البيت، الشغل، بيت الأهل…"
              value={label}
              onChange={(e) => setLabel(e.target.value)}
            />
          </div>

          {extended && (
            <>
              <div className="space-y-1.5">
                <Label htmlFor="contact-name">اسم المستلم</Label>
                <Input
                  id="contact-name"
                  value={contactName}
                  onChange={(e) => setContactName(e.target.value)}
                  autoComplete="name"
                />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="contact-phone">رقم المستلم</Label>
                <Input
                  id="contact-phone"
                  type="tel"
                  inputMode="tel"
                  dir="ltr"
                  value={contactPhone}
                  onChange={(e) => setContactPhone(e.target.value)}
                  autoComplete="tel"
                />
              </div>
            </>
          )}

          <div className="space-y-1.5">
            <Label htmlFor="addr">العنوان</Label>
            <Textarea
              id="addr"
              placeholder="الحي، الشارع، رقم البناية، الطابق…"
              rows={3}
              value={address}
              onChange={(e) => setAddress(e.target.value)}
            />
            {error && <p className="text-xs text-destructive">{error}</p>}
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="addr-notes">ملاحظات للسائق (اختياري)</Label>
            <Input
              id="addr-notes"
              placeholder="بجانب الصيدلية…"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
            />
          </div>

          <InstallGate
            reason="ثبّت التطبيق ليبقى عنوانك جاهزاً لكل طلب قادم."
            onProceed={submit}
          >
            <Button
              type="button"
              disabled={busy}
              className="w-full h-11 rounded-full font-bold"
            >
              {busy ? "جارٍ الحفظ…" : "حفظ"}
            </Button>
          </InstallGate>
        </div>
      </SheetContent>
    </Sheet>
  );
};
