import { useEffect, useMemo, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { useTranslation } from "react-i18next";
import {
  ArrowRight,
  ChevronLeft,
  Globe,
  HelpCircle,
  Info,
  Moon,
  Phone,
  Scale,
  Settings as SettingsIcon,
  ShieldCheck,
  Sun,
  Mail,
  Facebook,
  Instagram,
  Youtube,
  MessageCircle,
} from "lucide-react";
import { useStore } from "@/context/StoreContext";
import { useDarkMode } from "@/hooks/useDarkMode";
import { Switch } from "@/components/ui/switch";
import { StoreSkeleton } from "@/components/StoreSkeleton";
import { StoreNotFound } from "@/components/StoreNotFound";
import { AccountHero } from "@/components/account/AccountHero";
import { OrdersList } from "@/components/account/OrdersList";
import { AddressesList } from "@/components/account/AddressesList";
import { LatestOrderCard } from "@/components/account/LatestOrderCard";
import { ProfileForm } from "@/components/account/ProfileForm";
import { SettingsRow } from "@/components/account/SettingsRow";
import { loadOrders, type Order } from "@/lib/orders";
import { getProfile } from "@/lib/profile";
import { BottomNav } from "@/components/BottomNav";
import { listRemoteOrders, listUserOrders, getGuestId } from "@/lib/shoplanserApi";
import { useShopAuth } from "@/context/ShopAuthContext";
import { Button } from "@/components/ui/button";
import { LogIn, LogOut, UserPlus, Download, X, Share2, Copy } from "lucide-react";
import { SEO } from "@/components/SEO";
import { useStore as useStoreCtx } from "@/context/StoreContext";
import { InstallGate } from "@/components/install/InstallGate";
import { useInstallPrompt } from "@/hooks/useInstallPrompt";
import { toast } from "@/hooks/use-toast";
import { VoiceHistoryList } from "@/components/search/VoiceHistoryList";
import { VoiceSettingsCard } from "@/components/account/VoiceSettingsCard";
import { buildShareUrl, shareStoreLink } from "@/lib/share";
import {
  clearVoiceHistory,
  getVoiceHistory,
  type VoiceHistoryEntry,
} from "@/lib/voiceSearchHistory";

const SectionHeading = ({ children }: { children: React.ReactNode }) => (
  <h2 className="text-sm font-extrabold text-primary mt-6 mb-2 px-1">{children}</h2>
);

const Account = () => {
  const { storeSlug = "" } = useParams<{ storeSlug: string }>();
  const navigate = useNavigate();
  const { t, i18n } = useTranslation();
  const { slug, store, isLoading, isError } = useStore();
  const [darkMode, setDarkMode] = useDarkMode();
  const [orders, setOrders] = useState<Order[]>([]);
  const [profileName, setProfileName] = useState<string>("");
  const [voiceHistory, setVoiceHistory] = useState<VoiceHistoryEntry[]>([]);
  const INSTALL_TIP_KEY = "account:installTipDismissed";
  const [showInstallTip, setShowInstallTip] = useState<boolean>(() => {
    if (typeof window === "undefined") return true;
    try {
      return localStorage.getItem(INSTALL_TIP_KEY) !== "1";
    } catch {
      return true;
    }
  });
  const dismissInstallTip = () => {
    setShowInstallTip(false);
    try {
      localStorage.setItem(INSTALL_TIP_KEY, "1");
    } catch {
      /* ignore */
    }
  };

  const { ctx } = useStoreCtx();
  const { isAuthenticated, user, signOut } = useShopAuth();
  const { canInstall, isIOS, isStandalone, isInstallable, promptInstall } = useInstallPrompt();
  const showInstallLater = !isStandalone && (canInstall || isIOS || isInstallable);

  const handleInstallLater = async () => {
    if (canInstall) {
      const accepted = await promptInstall();
      if (!accepted) {
        toast({
          title: "تم تأجيل التثبيت",
          description: "يمكنك تثبيت التطبيق لاحقاً من هذا الزر في أي وقت.",
        });
      }
      return;
    }
    if (isIOS) {
      toast({
        title: "تثبيت على iPhone",
        description: "اضغط زر المشاركة في Safari ثم اختر «إضافة إلى الشاشة الرئيسية».",
      });
      return;
    }
    toast({
      title: "التثبيت غير متاح الآن",
      description: "افتح المتجر في متصفح الجوال لتفعيل خيار التثبيت.",
    });
  };

  useEffect(() => {
    setVoiceHistory(getVoiceHistory(slug));
  }, [slug]);

  useEffect(() => {
    const local = loadOrders(slug);
    setOrders(local);
    setProfileName(user?.name || user?.f_name || getProfile().name);
    // Use authenticated orders endpoint when signed-in; otherwise fall back to guest.
    const fetcher = isAuthenticated
      ? listUserOrders(ctx ?? undefined, { limit: 20 })
      : (() => {
          const gid = getGuestId();
          return gid && ctx
            ? listRemoteOrders(gid, ctx, { limit: 20 })
            : Promise.resolve({ total_size: 0, orders: [] });
        })();
    fetcher
      .then(({ orders: remote }) => {
        if (!remote.length) return;
        const localIds = new Set(local.map((o) => o.id));
        const mapped: Order[] = remote
          .map((r) => {
            const id = `SL-${r.id}`;
            if (localIds.has(id)) return null;
            const stage =
              r.order_status === "delivered"
                ? "completed"
                : r.order_status === "out_for_delivery"
                  ? "out_for_delivery"
                  : r.order_status === "processing" || r.order_status === "confirmed"
                    ? "preparing"
                    : "received";
            return {
              id,
              storeSlug: slug,
              storeName: store?.name,
              storeLogo: store?.logo_full_url,
              createdAt: new Date(r.created_at).getTime() || Date.now(),
              items: (r.details ?? []).map((d) => ({
                id: d.id,
                name: d.item_details?.name ?? "",
                image: d.item_details?.image_full_url ?? "",
                price: Number(d.price ?? 0),
                originalPrice: Number(d.price ?? 0),
                quantity: Number(d.quantity ?? 1),
              })),
              subtotal: Number(r.order_amount ?? 0),
              customer: {
                name: r.delivery_address?.contact_person_name ?? "",
                phone: "",
                address: r.delivery_address?.address ?? "",
              },
              slot: { day: "today" as const, dayLabel: "—", window: "—" },
              stage: stage as Order["stage"],
              nextStageAt: Date.now(),
            } satisfies Order;
          })
          .filter((o): o is NonNullable<typeof o> => o !== null);
        if (mapped.length) {
          setOrders((prev) =>
            [...mapped, ...prev].sort((a, b) => b.createdAt - a.createdAt),
          );
        }
      })
      .catch(() => undefined);
  }, [slug, ctx, store?.name, store?.logo_full_url, isAuthenticated, user]);

  const supportHref = useMemo(() => {
    if (store?.phone) return `tel:${store.phone}`;
    if (store?.email) return `mailto:${store.email}`;
    return undefined;
  }, [store]);

  if (isLoading) return <StoreSkeleton />;
  if (isError || !store) return <StoreNotFound slug={storeSlug} />;

  const langLabel =
    i18n.language === "en"
      ? t("account.preferences.languageEnglish")
      : t("account.preferences.languageArabic");

  return (
    <div className="min-h-screen flex flex-col bg-background">
      <SEO title={`${t("account.pageTitle")} — ${store.name}`} noindex />
      <header className="sticky top-0 z-30 bg-background/95 backdrop-blur border-b border-border">
        <div className="container py-3 flex items-center gap-2">
          <button
            type="button"
            onClick={() => navigate(`/${slug}`)}
            aria-label={t("common.back")}
            className="shrink-0 h-10 w-10 rounded-full bg-secondary inline-flex items-center justify-center text-muted-foreground hover:text-foreground transition-smooth"
          >
            <ArrowRight className="h-5 w-5 ltr:rotate-180" />
          </button>
          <h1 className="flex-1 text-center text-lg font-extrabold">
            {t("account.pageTitle")}
          </h1>
          <span className="w-10" />
        </div>
      </header>

      <main className="flex-1 container py-4 pb-24 md:pb-8 space-y-1">
        <AccountHero userName={profileName} />

        {/* Auth card */}
        {isAuthenticated ? (
          <div className="rounded-2xl bg-card border border-border p-3 flex items-center gap-3 mt-2">
            <div className="flex-1 min-w-0">
              <div className="text-sm font-extrabold truncate">
                {user?.name || user?.f_name || profileName || user?.phone || "—"}
              </div>
              {user?.phone ? (
                <div className="text-xs text-muted-foreground" dir="ltr">{user.phone}</div>
              ) : null}
            </div>
            <Button variant="outline" size="sm" onClick={signOut}>
              <LogOut className="me-1 h-4 w-4" /> خروج
            </Button>
          </div>
        ) : (
          <div className="rounded-2xl bg-card border border-border p-3 mt-2 space-y-2">
            <div className="flex items-center gap-2">
              <div className="flex-1 text-sm text-muted-foreground">
                سجّل دخولك للوصول إلى طلباتك وعناوينك من أي جهاز.
              </div>
              <Button
                size="sm"
                onClick={() =>
                  navigate(
                    `/${slug}/login?redirect=${encodeURIComponent(`/${slug}/account`)}`,
                  )
                }
              >
                <LogIn className="me-1 h-4 w-4" /> دخول
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={() =>
                  navigate(
                    `/${slug}/register?redirect=${encodeURIComponent(`/${slug}/account`)}`,
                  )
                }
              >
                <UserPlus className="me-1 h-4 w-4" /> تسجيل
              </Button>
            </div>
            {showInstallTip && (
              <div className="relative flex items-start gap-2 rounded-xl bg-secondary/50 p-2 pe-7 text-xs text-muted-foreground">
                <Info className="h-4 w-4 mt-0.5 shrink-0 text-primary" />
                <span>
                  التثبيت اختياري — يمكنك تسجيل الدخول الآن مباشرة. بعض الميزات
                  مثل تنبيهات الطلبات تعمل بشكل أفضل بعد التثبيت.
                </span>
                <button
                  type="button"
                  onClick={dismissInstallTip}
                  aria-label="إغلاق"
                  className="absolute top-1 end-1 h-5 w-5 inline-flex items-center justify-center rounded-full text-muted-foreground hover:text-foreground hover:bg-background/60"
                >
                  <X className="h-3.5 w-3.5" />
                </button>
              </div>
            )}
            {showInstallLater && (
              <Button
                variant="outline"
                size="sm"
                onClick={handleInstallLater}
                className="w-full font-bold"
              >
                <Download className="me-1 h-4 w-4" /> فعّل التثبيت لاحقاً
              </Button>
            )}
          </div>
        )}

        {isAuthenticated && <LatestOrderCard />}

        <div className="flex items-center justify-between mt-6 mb-2 px-1">
          <h2 className="text-sm font-extrabold text-primary">
            {t("account.sections.orders")}
          </h2>
          <button
            type="button"
            onClick={() => navigate(`/${slug}/orders`)}
            className="text-xs font-extrabold text-primary hover:underline inline-flex items-center gap-0.5"
          >
            عرض الكل
            <ChevronLeft className="h-3.5 w-3.5 ltr:rotate-180" />
          </button>
        </div>
        <OrdersList slug={slug} orders={orders.slice(0, 5)} />

        <SectionHeading>{t("account.sections.addresses")}</SectionHeading>
        {isAuthenticated ? (
          <button
            type="button"
            onClick={() => navigate(`/${slug}/addresses`)}
            className="w-full rounded-2xl bg-card border border-border p-4 flex items-center justify-between hover:bg-secondary/40 transition-smooth"
          >
            <span className="font-bold text-sm">إدارة عناويني</span>
            <ChevronLeft className="h-4 w-4 ltr:rotate-180 text-muted-foreground" />
          </button>
        ) : (
          <AddressesList />
        )}



        <SectionHeading>
          {t("account.sections.voiceSettings", {
            defaultValue: "إعدادات البحث الصوتي",
          })}
        </SectionHeading>
        <VoiceSettingsCard />

        <SectionHeading>{t("account.sections.support")}</SectionHeading>
        <div className="rounded-2xl bg-card border border-border p-1.5 divide-y divide-border">
          {store.phone ? (
            <a href={`tel:${store.phone}`} className="block">
              <SettingsRow
                icon={<Phone className="h-4 w-4" />}
                label="تواصل معنا"
                trailing={
                  <span className="text-xs text-muted-foreground font-bold" dir="ltr">
                    {store.phone}
                  </span>
                }
              />
            </a>
          ) : null}
          {store.email ? (
            <a href={`mailto:${store.email}`} className="block">
              <SettingsRow
                icon={<Mail className="h-4 w-4" />}
                label="البريد الإلكتروني"
                trailing={
                  <span className="text-xs text-muted-foreground font-bold truncate max-w-[160px]" dir="ltr">
                    {store.email}
                  </span>
                }
              />
            </a>
          ) : null}
          <Link to={`/${slug}#about`} className="block">
            <SettingsRow
              icon={<Info className="h-4 w-4" />}
              label="معلومات عنا"
              trailing={
                <span className="inline-flex items-center gap-1 text-xs text-muted-foreground font-bold truncate max-w-[180px]">
                  {store.name}
                  <ChevronLeft className="h-4 w-4 ltr:rotate-180 shrink-0" />
                </span>
              }
            />
          </Link>
        </div>

        {/* Share store */}
        <SectionHeading>شارك المتجر</SectionHeading>
        <div className="rounded-2xl bg-card border border-border p-4 flex items-center gap-3">
          {store.logo_full_url ? (
            <img
              src={store.logo_full_url}
              alt={store.name}
              className="h-14 w-14 rounded-xl object-cover border border-border shrink-0"
              loading="lazy"
            />
          ) : (
            <div className="h-14 w-14 rounded-xl bg-secondary shrink-0" />
          )}
          <div className="flex-1 min-w-0">
            <div className="font-extrabold text-sm truncate">{store.name}</div>
            <div className="text-xs text-muted-foreground truncate" dir="ltr">
              {buildShareUrl(slug).replace(/^https?:\/\//, "")}
            </div>
          </div>
          <Button
            size="sm"
            variant="outline"
            onClick={async () => {
              const url = buildShareUrl(slug);
              try {
                await navigator.clipboard.writeText(url);
                toast({ title: "تم نسخ الرابط" });
              } catch {
                toast({ title: "تعذّر النسخ", variant: "destructive" });
              }
            }}
            aria-label="نسخ الرابط"
            className="shrink-0"
          >
            <Copy className="h-4 w-4" />
          </Button>
        </div>
        <div className="grid grid-cols-2 gap-2 mt-2">
          <a
            href={`https://wa.me/?text=${encodeURIComponent(`${store.name}\n${buildShareUrl(slug)}`)}`}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center justify-center gap-2 rounded-xl bg-[#25D366] text-white font-extrabold text-sm py-2.5 hover:opacity-90 transition-smooth"
          >
            <MessageCircle className="h-4 w-4" />
            مشاركة على واتساب
          </a>
          <button
            type="button"
            onClick={async () => {
              const result = await shareStoreLink({
                slug,
                title: store.name,
                text: store.address
                  ? `${store.name} — ${store.address}`
                  : store.name,
              });
              if (result === "copied") toast({ title: "تم نسخ الرابط" });
              else if (result === "failed")
                toast({ title: "تعذّرت المشاركة", variant: "destructive" });
            }}
            className="inline-flex items-center justify-center gap-2 rounded-xl bg-primary text-primary-foreground font-extrabold text-sm py-2.5 hover:opacity-90 transition-smooth"
          >
            <Share2 className="h-4 w-4" />
            مشاركة...
          </button>
        </div>

        {/* Social media */}
        <div className="pt-6">
          <div className="flex items-center justify-center gap-3">
            {store.phone && (
              <a
                href={`https://wa.me/${store.phone.replace(/[^0-9]/g, "")}`}
                target="_blank"
                rel="noopener noreferrer"
                aria-label="WhatsApp"
                className="h-11 w-11 inline-flex items-center justify-center rounded-full bg-card border border-border text-foreground hover:bg-primary hover:text-primary-foreground hover:border-primary transition-smooth"
              >
                <MessageCircle className="h-5 w-5" />
              </a>
            )}
            <a
              href="https://facebook.com"
              target="_blank"
              rel="noopener noreferrer"
              aria-label="Facebook"
              className="h-11 w-11 inline-flex items-center justify-center rounded-full bg-card border border-border text-foreground hover:bg-primary hover:text-primary-foreground hover:border-primary transition-smooth"
            >
              <Facebook className="h-5 w-5" />
            </a>
            <a
              href="https://instagram.com"
              target="_blank"
              rel="noopener noreferrer"
              aria-label="Instagram"
              className="h-11 w-11 inline-flex items-center justify-center rounded-full bg-card border border-border text-foreground hover:bg-primary hover:text-primary-foreground hover:border-primary transition-smooth"
            >
              <Instagram className="h-5 w-5" />
            </a>
            <a
              href="https://youtube.com"
              target="_blank"
              rel="noopener noreferrer"
              aria-label="YouTube"
              className="h-11 w-11 inline-flex items-center justify-center rounded-full bg-card border border-border text-foreground hover:bg-primary hover:text-primary-foreground hover:border-primary transition-smooth"
            >
              <Youtube className="h-5 w-5" />
            </a>
          </div>
        </div>

        <p className="text-center text-xs text-muted-foreground pt-6">
          Powered by{" "}
          <span className="font-bold">
            <span className="text-foreground">Shop</span>
            <span style={{ color: "hsl(220, 90%, 35%)" }}>lanser</span>
          </span>
        </p>
      </main>

      <BottomNav />
    </div>
  );
};

export default Account;
