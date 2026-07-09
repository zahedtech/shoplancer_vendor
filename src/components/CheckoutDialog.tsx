import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { useEffect, useMemo, useState } from "react";
import { z } from "zod";
import { useTranslation } from "react-i18next";
import { useCart } from "@/context/CartContext";
import { useStore } from "@/context/StoreContext";
import { formatPrice } from "@/lib/api";
import { toast } from "sonner";
import { useNavigate } from "react-router-dom";
import { addOrder, generateOrderId, STAGE_TICK_MS } from "@/lib/orders";
import { getProfile, saveProfile } from "@/lib/profile";
import { addAddress, getDefaultAddress, loadAddresses } from "@/lib/addresses";
import { ensureGuestId, placeRemoteOrder } from "@/lib/shoplanserApi";
import { getPaymentPrefs, savePaymentPrefs, type PaymentMethod } from "@/lib/paymentPrefs";
import { Banknote, Wallet, Check, MapPin, Plus } from "lucide-react";
import { cn } from "@/lib/utils";
import { useShopAuth } from "@/context/ShopAuthContext";
import { useRemoteAddresses } from "@/hooks/useRemoteAddresses";
import { AddressFormSheet, type ExtendedAddressData } from "@/components/account/AddressFormSheet";

interface Props {
  open: boolean;
  onOpenChange: (v: boolean) => void;
  onConfirmed: () => void;
}

export const CheckoutDialog = ({ open, onOpenChange, onConfirmed }: Props) => {
  const { items, subtotal, clear, linkPhone, linkedPhone, guestId } = useCart();
  const { slug, store, ctx } = useStore();
  const navigate = useNavigate();
  const { t } = useTranslation();

  const schema = useMemo(
    () =>
      z.object({
        name: z.string().trim().min(2, t("checkout.errors.nameShort")).max(80),
        phone: z
          .string()
          .trim()
          .regex(/^[0-9+\-\s]{7,20}$/, t("checkout.errors.phoneInvalid")),
        address: z.string().trim().min(5, t("checkout.errors.addressShort")).max(300),
        notes: z.string().max(300).optional(),
      }),
    [t],
  );
  const [form, setForm] = useState({ name: "", phone: "", address: "", notes: "" });
  const [paymentMethod, setPaymentMethod] = useState<PaymentMethod>("cod");
  const [paymentRef, setPaymentRef] = useState("");
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [submitting, setSubmitting] = useState(false);
  const { isAuthenticated, user } = useShopAuth();
  const { addresses, defaultAddress, defaultId, setDefault, add: addRemoteAddress } =
    useRemoteAddresses();
  const [selectedAddressId, setSelectedAddressId] = useState<number | null>(null);
  const [addrSheetOpen, setAddrSheetOpen] = useState(false);

  useEffect(() => {
    if (!open) return;
    const profile = getProfile();
    const def = getDefaultAddress();
    const prefs = getPaymentPrefs();
    setPaymentMethod(prefs.method);

    if (isAuthenticated && defaultAddress) {
      setSelectedAddressId(defaultAddress.id);
      setForm({
        name: defaultAddress.contact_person_name || user?.name || user?.f_name || profile.name || "",
        phone: defaultAddress.contact_person_number || user?.phone || linkedPhone || "",
        address: defaultAddress.address,
        notes: profile.notes || "",
      });
    } else {
      setForm((prev) => ({
        name: prev.name || user?.name || user?.f_name || profile.name || "",
        phone: prev.phone || user?.phone || linkedPhone || "",
        address: prev.address || def?.address || "",
        notes: prev.notes || profile.notes || "",
      }));
    }
  }, [open, linkedPhone, isAuthenticated, defaultAddress, user]);

  // When user picks a different saved address, sync the form fields.
  const handlePickAddress = (id: number) => {
    const a = addresses.find((x) => x.id === id);
    if (!a) return;
    setSelectedAddressId(id);
    setForm((prev) => ({
      ...prev,
      address: a.address,
      name: a.contact_person_name || prev.name,
      phone: a.contact_person_number || prev.phone,
    }));
  };

  const handleSaveNewAddress = async (data: ExtendedAddressData) => {
    const list = await addRemoteAddress({
      contact_person_name: data.contact_person_name ?? form.name ?? "",
      contact_person_number: data.contact_person_number ?? form.phone ?? "",
      address_type: data.address_type ?? "home",
      address: data.address,
      latitude: String(ctx?.latitude ?? "0"),
      longitude: String(ctx?.longitude ?? "0"),
    });
    // Newly created address is at the front of the returned list.
    const fresh = list[0];
    if (fresh) {
      setDefault(fresh.id);
      handlePickAddress(fresh.id);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    // Stock guard — block if any item is unavailable or quantity exceeds stock.
    const blocked = items.some((i) => {
      const s = i.stock;
      if (s === undefined || s === null) return false;
      if (s <= 0) return true;
      if (i.kind !== "attarah" && i.quantity > s) return true;
      return false;
    });
    if (blocked) {
      toast.error("لا يمكن إتمام الطلب", {
        description: "بعض المنتجات غير متوفرة أو الكمية أكبر من المخزون. راجع السلة لاختيار بدائل.",
      });
      return;
    }
    const result = schema.safeParse(form);
    const errs: Record<string, string> = {};
    if (!result.success) {
      for (const issue of result.error.issues) {
        errs[String(issue.path[0])] = issue.message;
      }
    }
    // Extra validation: offline payment requires a reference / transfer note
    const trimmedRef = paymentRef.trim();
    if (paymentMethod === "offline") {
      if (trimmedRef.length < 3) {
        errs.paymentRef = t("checkout.errors.paymentRefShort");
      } else if (trimmedRef.length > 200) {
        errs.paymentRef = t("checkout.errors.paymentRefLong");
      }
    }
    if (Object.keys(errs).length > 0) {
      setErrors(errs);
      return;
    }
    setErrors({});
    setSubmitting(true);

    // Compose the note we send to the backend so the merchant sees the
    // payment reference alongside any customer instructions.
    const baseNote = form.notes?.trim() ?? "";
    const composedNote =
      paymentMethod === "offline"
        ? [baseNote, t("voice.paymentRefNote", { ref: trimmedRef })].filter(Boolean).join("\n")
        : baseNote;

    let remoteOrderId: number | undefined;
    try {
      const gid = guestId ?? (ctx ? await ensureGuestId(ctx) : null);
      if (gid && ctx && store) {
        const cartPayload = items
          .filter((i) => i.remoteCartId)
          .map((i) => ({
            cart_id: i.remoteCartId as number,
            item_id: i.id,
            price: i.price,
            quantity: i.quantity,
          }));
        if (cartPayload.length > 0) {
          const res = await placeRemoteOrder(
            gid,
            {
              storeId: store.id,
              cart: cartPayload,
              orderAmount: subtotal,
              customer: { name: form.name.trim(), phone: form.phone.trim() },
              address: form.address.trim(),
              notes: composedNote || undefined,
              latitude: ctx.latitude,
              longitude: ctx.longitude,
              paymentMethod,
              addressId: isAuthenticated ? selectedAddressId ?? undefined : undefined,
            },
            ctx,
          );
          if (res.ok) {
            remoteOrderId = res.order_id;
          } else {
            toast.error(t("checkout.remoteFailed"), { description: res.message });
            setSubmitting(false);
            return;
          }
        }
      }
    } catch (err) {
      console.warn("[checkout] remote order failed", err);
    }

    const orderId = remoteOrderId ? `SL-${remoteOrderId}` : generateOrderId(slug);
    const order = {
      id: orderId,
      storeSlug: slug,
      storeName: store?.name,
      storeLogo: store?.logo_full_url,
      createdAt: Date.now(),
      items: [...items],
      subtotal,
      customer: {
        name: form.name.trim(),
        phone: form.phone.trim(),
        address: form.address.trim(),
        notes: composedNote || undefined,
      },
      slot: { day: "today" as const, dayLabel: "—", window: "—" },
      paymentMethod,
      stage: "received" as const,
      nextStageAt: Date.now() + STAGE_TICK_MS,
    };
    addOrder(order);

    // Persist payment method as the new default for next time.
    savePaymentPrefs({ method: paymentMethod });

    saveProfile({
      name: form.name.trim(),
      email: getProfile().email,
      notes: form.notes?.trim() || undefined,
    });
    const trimmedAddr = form.address.trim();
    const known = loadAddresses().some(
      (a) => a.address.trim().toLowerCase() === trimmedAddr.toLowerCase(),
    );
    if (trimmedAddr && !known) {
      addAddress({ address: trimmedAddr });
    }

    if (!linkedPhone) {
      try {
        await linkPhone(form.phone.trim());
      } catch {
        /* non-blocking */
      }
    }

    setSubmitting(false);
    toast.success(t("checkout.successTitle"), {
      description:
        paymentMethod === "offline"
          ? t("checkout.successOffline")
          : t("checkout.successCod"),
    });

    clear();
    setForm({ name: "", phone: "", address: "", notes: "" });
    setPaymentRef("");
    onConfirmed();
    navigate(`/${slug}/orders/${orderId}`);
  };

  const PaymentOption = ({
    value,
    icon: Icon,
    title,
    desc,
  }: {
    value: PaymentMethod;
    icon: typeof Banknote;
    title: string;
    desc: string;
  }) => {
    const active = paymentMethod === value;
    return (
      <button
        type="button"
        onClick={() => setPaymentMethod(value)}
        className={cn(
          "w-full flex items-start gap-3 p-3 rounded-xl border-2 text-start transition-all",
          active
            ? "border-primary bg-primary/5"
            : "border-border hover:border-primary/40 bg-background",
        )}
      >
        <div
          className={cn(
            "h-10 w-10 rounded-lg flex items-center justify-center shrink-0",
            active ? "bg-primary text-primary-foreground" : "bg-secondary text-foreground",
          )}
        >
          <Icon className="h-5 w-5" />
        </div>
        <div className="flex-1 min-w-0">
          <p className="font-bold text-sm">{title}</p>
          <p className="text-xs text-muted-foreground mt-0.5">{desc}</p>
        </div>
        {active && (
          <div className="h-5 w-5 rounded-full bg-primary text-primary-foreground flex items-center justify-center shrink-0">
            <Check className="h-3 w-3" strokeWidth={3} />
          </div>
        )}
      </button>
    );
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-md max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>{t("checkout.title")}</DialogTitle>
          <DialogDescription>
            {t("checkout.description", { count: items.length })}
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-1.5">
            <Label htmlFor="name">{t("checkout.fullName")}</Label>
            <Input
              id="name"
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
              placeholder={t("checkout.fullNamePlaceholder")}
              maxLength={80}
            />
            {errors.name && <p className="text-xs text-destructive">{errors.name}</p>}
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="phone">{t("checkout.phone")}</Label>
            <Input
              id="phone"
              type="tel"
              dir="ltr"
              value={form.phone}
              onChange={(e) => setForm({ ...form, phone: e.target.value })}
              placeholder={t("checkout.phonePlaceholder")}
              maxLength={20}
            />
            {errors.phone && <p className="text-xs text-destructive">{errors.phone}</p>}
          </div>

          {isAuthenticated && addresses.length > 0 ? (
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <Label>عنوان التوصيل</Label>
                <button
                  type="button"
                  onClick={() => setAddrSheetOpen(true)}
                  className="inline-flex items-center gap-1 text-xs font-bold text-primary hover:underline"
                >
                  <Plus className="h-3.5 w-3.5" />
                  جديد
                </button>
              </div>
              <div className="space-y-2 max-h-56 overflow-y-auto pe-1">
                {addresses.map((a) => {
                  const active = selectedAddressId === a.id;
                  return (
                    <button
                      key={a.id}
                      type="button"
                      onClick={() => handlePickAddress(a.id)}
                      className={cn(
                        "w-full flex items-start gap-2 p-3 rounded-xl border-2 text-start transition-all",
                        active
                          ? "border-primary bg-primary/5"
                          : "border-border hover:border-primary/40 bg-background",
                      )}
                    >
                      <span
                        className={cn(
                          "h-8 w-8 rounded-lg inline-flex items-center justify-center shrink-0",
                          active
                            ? "bg-primary text-primary-foreground"
                            : "bg-secondary text-foreground",
                        )}
                      >
                        <MapPin className="h-4 w-4" />
                      </span>
                      <div className="flex-1 min-w-0">
                        <p className="font-bold text-sm truncate">
                          {a.address_type === "workplace"
                            ? "العمل"
                            : a.address_type === "other"
                              ? "أخرى"
                              : "المنزل"}
                          {defaultId === a.id ? " • افتراضي" : ""}
                        </p>
                        <p className="text-xs text-muted-foreground line-clamp-2">
                          {a.address}
                        </p>
                      </div>
                      {active && (
                        <Check className="h-4 w-4 text-primary shrink-0" strokeWidth={3} />
                      )}
                    </button>
                  );
                })}
              </div>
              {errors.address && <p className="text-xs text-destructive">{errors.address}</p>}
            </div>
          ) : (
            <div className="space-y-1.5">
              <div className="flex items-center justify-between">
                <Label htmlFor="address">{t("checkout.address")}</Label>
                {isAuthenticated && (
                  <button
                    type="button"
                    onClick={() => setAddrSheetOpen(true)}
                    className="inline-flex items-center gap-1 text-xs font-bold text-primary hover:underline"
                  >
                    <Plus className="h-3.5 w-3.5" />
                    حفظ عنوان جديد
                  </button>
                )}
              </div>
              <Textarea
                id="address"
                value={form.address}
                onChange={(e) => setForm({ ...form, address: e.target.value })}
                placeholder={t("checkout.addressPlaceholder")}
                rows={3}
                maxLength={300}
              />
              {errors.address && <p className="text-xs text-destructive">{errors.address}</p>}
            </div>
          )}

          <div className="space-y-1.5">
            <Label htmlFor="notes">{t("checkout.notes")}</Label>
            <Textarea
              id="notes"
              value={form.notes}
              onChange={(e) => setForm({ ...form, notes: e.target.value })}
              placeholder={t("checkout.notesPlaceholder")}
              rows={2}
              maxLength={300}
            />
          </div>

          <div className="space-y-2">
            <Label>{t("checkout.paymentMethod")}</Label>
            <div className="space-y-2">
              <PaymentOption
                value="cod"
                icon={Banknote}
                title={t("checkout.cod")}
                desc={t("checkout.codDesc")}
              />
              <PaymentOption
                value="offline"
                icon={Wallet}
                title={t("checkout.offline")}
                desc={t("checkout.offlineDesc")}
              />
            </div>

            {paymentMethod === "offline" && (
              <div className="space-y-1.5 pt-1">
                <Label htmlFor="paymentRef">
                  {t("checkout.paymentRefLabel")} <span className="text-destructive">*</span>
                </Label>
                <Textarea
                  id="paymentRef"
                  value={paymentRef}
                  onChange={(e) => setPaymentRef(e.target.value)}
                  placeholder={t("checkout.paymentRefPlaceholder")}
                  rows={2}
                  maxLength={200}
                />
                <p className="text-[11px] text-muted-foreground">
                  {t("checkout.paymentRefHint")}
                </p>
                {errors.paymentRef && (
                  <p className="text-xs text-destructive">{errors.paymentRef}</p>
                )}
              </div>
            )}
          </div>

          <div className="bg-secondary rounded-xl p-3 space-y-1 text-sm">
            <div className="flex justify-between">
              <span className="text-muted-foreground">{t("checkout.products")}</span>
              <span>
                {t("checkout.pieces", { count: items.reduce((s, i) => s + i.quantity, 0) })}
              </span>
            </div>
            <div className="flex justify-between font-bold text-base pt-1 border-t border-border">
              <span>{t("checkout.total")}</span>
              <span className="text-primary">{formatPrice(subtotal)}</span>
            </div>
          </div>

          <Button
            type="submit"
            disabled={submitting || items.length === 0}
            className="w-full h-12 rounded-full text-base font-bold"
          >
            {submitting ? t("checkout.submitting") : t("checkout.submit")}
          </Button>
        </form>
      </DialogContent>
      <AddressFormSheet
        open={addrSheetOpen}
        onOpenChange={setAddrSheetOpen}
        initial={{
          address: form.address,
          contact_person_name: form.name,
          contact_person_number: form.phone,
        }}
        onSave={handleSaveNewAddress}
        extended
      />
    </Dialog>
  );
};
