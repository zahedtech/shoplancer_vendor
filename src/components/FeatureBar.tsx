import { Truck, ShieldCheck, Tag, Clock, Sparkles, Leaf, Headphones, BadgePercent } from "lucide-react";
import { useTranslation } from "react-i18next";
import { useMemo } from "react";

export const FeatureBar = () => {
  const { t, i18n } = useTranslation();

  const features = useMemo(
    () => [
      { icon: Truck, title: t("features.fastDelivery"), subtitle: t("features.fastDeliverySub") },
      { icon: ShieldCheck, title: t("features.qualityGuaranteed"), subtitle: t("features.qualityGuaranteedSub") },
      { icon: Tag, title: t("features.bestPrices"), subtitle: t("features.bestPricesSub") },
      { icon: Clock, title: t("features.service247"), subtitle: t("features.service247Sub") },
      { icon: Sparkles, title: t("features.curated"), subtitle: t("features.curatedSub") },
      { icon: Leaf, title: t("features.produce"), subtitle: t("features.produceSub") },
      { icon: Headphones, title: t("features.support"), subtitle: t("features.supportSub") },
      { icon: BadgePercent, title: t("features.exclusiveDeals"), subtitle: t("features.exclusiveDealsSub") },
    ],
    [t, i18n.language],
  );

  // Duplicate the list once so the loop is seamless.
  const track = [...features, ...features];
  const innerDir = i18n.language === "ar" ? "rtl" : "ltr";

  return (
    <section className="px-2 py-3 md:py-4">
      <div
        dir="ltr"
        className="relative bg-card rounded-2xl border border-border/60 shadow-soft overflow-hidden [--marquee-duration:50s] sm:[--marquee-duration:40s] md:[--marquee-duration:30s] lg:[--marquee-duration:22s]"
      >
        <div className="pointer-events-none absolute inset-y-0 left-0 w-8 bg-gradient-to-r from-card to-transparent z-10" />
        <div className="pointer-events-none absolute inset-y-0 right-0 w-8 bg-gradient-to-l from-card to-transparent z-10" />

        <div className="flex w-max animate-marquee-rtl hover:[animation-play-state:paused] motion-reduce:animate-none py-3">
          {track.map(({ icon: Icon, title, subtitle }, i) => (
            <div
              key={`${title}-${i}`}
              className="flex items-center gap-3 px-5 shrink-0"
              dir={innerDir}
            >
              <div className="h-10 w-10 rounded-xl bg-primary-soft text-primary inline-flex items-center justify-center shrink-0">
                <Icon className="h-5 w-5" />
              </div>
              <div className="leading-tight whitespace-nowrap">
                <div className="font-bold text-sm text-foreground">{title}</div>
                <div className="text-xs text-muted-foreground">{subtitle}</div>
              </div>
              <span className="mx-3 h-6 w-px bg-border/60" aria-hidden />
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};
