import { useNavigate, useParams } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { ArrowRight, Check, Globe, Moon, Sun, ShoppingBasket } from "lucide-react";
import { toast } from "sonner";
import { useStore } from "@/context/StoreContext";
import { useDarkMode } from "@/hooks/useDarkMode";
import { useCartButtonPosition, type CartButtonPosition } from "@/hooks/useCartButtonPosition";
import { Switch } from "@/components/ui/switch";
import { StoreSkeleton } from "@/components/StoreSkeleton";
import { StoreNotFound } from "@/components/StoreNotFound";
import { BottomNav } from "@/components/BottomNav";
import { SEO } from "@/components/SEO";
import { SUPPORTED_LANGS, type SupportedLang } from "@/lib/i18n";
import { cn } from "@/lib/utils";

const LANG_LABELS: Record<SupportedLang, { nativeKey: string; key: string }> = {
  ar: { nativeKey: "settings.langArabic", key: "settings.langArabic" },
  en: { nativeKey: "settings.langEnglish", key: "settings.langEnglish" },
};

const Settings = () => {
  const { storeSlug = "" } = useParams<{ storeSlug: string }>();
  const navigate = useNavigate();
  const { slug, store, isLoading, isError } = useStore();
  const { t, i18n } = useTranslation();
  const [darkMode, setDarkMode] = useDarkMode();
  const [cartPos, setCartPos] = useCartButtonPosition();

  const cartPosOptions: { value: CartButtonPosition; labelKey: string; descKey: string }[] = [
    { value: "bottom-end", labelKey: "settings.cartPos.end", descKey: "settings.cartPos.endDesc" },
    { value: "bottom-start", labelKey: "settings.cartPos.start", descKey: "settings.cartPos.startDesc" },
  ];

  const pickCartPos = (p: CartButtonPosition) => {
    if (p === cartPos) return;
    setCartPos(p);
    toast.success(t("settings.saved"));
  };

  if (isLoading) return <StoreSkeleton />;
  if (isError || !store) return <StoreNotFound slug={storeSlug} />;

  const current = (SUPPORTED_LANGS as readonly string[]).includes(i18n.language)
    ? (i18n.language as SupportedLang)
    : "ar";

  const pickLang = (lang: SupportedLang) => {
    if (lang === current) return;
    i18n.changeLanguage(lang).then(() => {
      toast.success(t("settings.saved"));
    });
  };

  return (
    <div className="min-h-screen flex flex-col bg-background">
      <SEO title={`${t("settings.pageTitle")} — ${store.name}`} noindex />

      <header className="sticky top-0 z-30 bg-background/95 backdrop-blur border-b border-border">
        <div className="container py-3 flex items-center gap-2">
          <button
            type="button"
            onClick={() => navigate(`/${slug}/account`)}
            aria-label={t("common.back")}
            className="shrink-0 h-10 w-10 rounded-full bg-secondary inline-flex items-center justify-center text-muted-foreground hover:text-foreground transition-smooth"
          >
            <ArrowRight className="h-5 w-5 ltr:rotate-180" />
          </button>
          <h1 className="flex-1 text-center text-lg font-extrabold">
            {t("settings.pageTitle")}
          </h1>
          <span className="w-10" />
        </div>
      </header>

      <main className="flex-1 container py-5 pb-24 md:pb-8 max-w-2xl space-y-6">
        <p className="text-sm text-muted-foreground">{t("settings.pageSubtitle")}</p>

        {/* Language */}
        <section className="space-y-3">
          <div className="flex items-center gap-2 px-1">
            <Globe className="h-4 w-4 text-primary" />
            <h2 className="font-extrabold text-base">{t("settings.languageSection")}</h2>
          </div>
          <p className="text-xs text-muted-foreground px-1">
            {t("settings.languageDesc")}
          </p>
          <div className="rounded-2xl bg-card border border-border overflow-hidden divide-y divide-border">
            {SUPPORTED_LANGS.map((lang) => {
              const isActive = current === lang;
              return (
                <button
                  key={lang}
                  type="button"
                  onClick={() => pickLang(lang)}
                  className={cn(
                    "w-full flex items-center gap-3 p-4 text-start transition-smooth",
                    isActive ? "bg-primary-soft" : "hover:bg-secondary/40",
                  )}
                >
                  <span
                    className={cn(
                      "h-10 w-10 rounded-xl inline-flex items-center justify-center font-extrabold shrink-0 text-sm",
                      isActive
                        ? "bg-primary text-primary-foreground"
                        : "bg-secondary text-muted-foreground",
                    )}
                  >
                    {t(`settingsUi.langChip.${lang}`)}
                  </span>
                  <div className="flex-1 min-w-0">
                    <p className="font-bold text-sm">{t(LANG_LABELS[lang].nativeKey)}</p>
                    <p className="text-xs text-muted-foreground">
                      {t(LANG_LABELS[lang].key)}
                    </p>
                  </div>
                  {isActive && (
                    <span className="h-6 w-6 rounded-full bg-primary text-primary-foreground inline-flex items-center justify-center shrink-0">
                      <Check className="h-3.5 w-3.5" strokeWidth={3} />
                    </span>
                  )}
                </button>
              );
            })}
          </div>
        </section>

        {/* Appearance */}
        <section className="space-y-3">
          <div className="flex items-center gap-2 px-1">
            {darkMode ? (
              <Moon className="h-4 w-4 text-primary" />
            ) : (
              <Sun className="h-4 w-4 text-primary" />
            )}
            <h2 className="font-extrabold text-base">
              {t("settings.appearanceSection")}
            </h2>
          </div>
          <div className="rounded-2xl bg-card border border-border p-4 flex items-center gap-3">
            <span className="h-10 w-10 rounded-xl bg-accent/15 text-accent inline-flex items-center justify-center shrink-0">
              {darkMode ? <Moon className="h-4 w-4" /> : <Sun className="h-4 w-4" />}
            </span>
            <div className="flex-1 min-w-0">
              <p className="font-bold text-sm">{t("settings.darkMode")}</p>
              <p className="text-xs text-muted-foreground">
                {t("settings.darkModeDesc")}
              </p>
            </div>
            <Switch
              checked={darkMode}
              onCheckedChange={setDarkMode}
              aria-label={t("account.preferences.darkModeAria")}
            />
          </div>
        </section>

        {/* Cart button position */}
        <section className="space-y-3">
          <div className="flex items-center gap-2 px-1">
            <ShoppingBasket className="h-4 w-4 text-primary" />
            <h2 className="font-extrabold text-base">{t("settings.cartPos.title")}</h2>
          </div>
          <p className="text-xs text-muted-foreground px-1">
            {t("settings.cartPos.desc")}
          </p>
          <div className="rounded-2xl bg-card border border-border overflow-hidden divide-y divide-border">
            {cartPosOptions.map((opt) => {
              const isActive = cartPos === opt.value;
              return (
                <button
                  key={opt.value}
                  type="button"
                  onClick={() => pickCartPos(opt.value)}
                  className={cn(
                    "w-full flex items-center gap-3 p-4 text-start transition-smooth",
                    isActive ? "bg-primary-soft" : "hover:bg-secondary/40",
                  )}
                >
                  <span
                    className={cn(
                      "h-10 w-10 rounded-xl inline-flex items-center justify-center shrink-0",
                      isActive
                        ? "bg-primary text-primary-foreground"
                        : "bg-secondary text-muted-foreground",
                    )}
                  >
                    <ShoppingBasket className="h-4 w-4" />
                  </span>
                  <div className="flex-1 min-w-0">
                    <p className="font-bold text-sm">{t(opt.labelKey)}</p>
                    <p className="text-xs text-muted-foreground">{t(opt.descKey)}</p>
                  </div>
                  {isActive && (
                    <span className="h-6 w-6 rounded-full bg-primary text-primary-foreground inline-flex items-center justify-center shrink-0">
                      <Check className="h-3.5 w-3.5" strokeWidth={3} />
                    </span>
                  )}
                </button>
              );
            })}
          </div>
        </section>
      </main>

      <BottomNav />
    </div>
  );
};

export default Settings;
