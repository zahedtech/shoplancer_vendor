/**
 * Per-store Hero slides — editable from this single file.
 *
 * Each store maps to an ordered list of slides. The Hero component on the
 * home page rotates through them automatically (and supports swipe / dot
 * navigation on mobile).
 *
 * Slides are intentionally kept short and supermarket-friendly: a tag
 * eyebrow, a strong headline, a one-line subtitle, and one or two CTAs.
 *
 * To add a new store, just add an entry here keyed by the store slug.
 * `default` is used as a fallback when the active store has no entry.
 */

export type HeroCtaAction =
  | "shopOffers"        // Smooth-scroll to #offers section
  | "browseCategories"  // Navigate to /:slug/categories
  | "browseLatest"      // Smooth-scroll to #latest section
  | "openSearch";       // Navigate to /:slug/search

export interface HeroCta {
  label: string;
  action: HeroCtaAction;
  /** "primary" = filled background, "ghost" = outlined */
  variant?: "primary" | "ghost";
}

export interface HeroSlide {
  /** Stable id, used as React key. */
  id: string;
  /** Small pill above the headline. */
  eyebrow: string;
  /** Main headline (kept under ~36 Arabic characters for mobile). */
  title: string;
  /** One-line supporting copy. */
  subtitle: string;
  /** Up to two CTAs. */
  ctas: HeroCta[];
  /** Optional background image for visual impact (lazy-loaded). */
  image?: string;
}

const defaultSlides: HeroSlide[] = [
  {
    id: "offers",
    eyebrow: "عروض الأسبوع",
    title: "وفّر على فاتورتك مع عروض السوبر ماركت",
    subtitle: "خصومات يومية على أساسيات البيت — منتجات أصلية وأسعار أقل.",
    ctas: [
      { label: "تسوّق العروض", action: "shopOffers", variant: "primary" },
      { label: "تصفح الأصناف", action: "browseCategories", variant: "ghost" },
    ],
  },
  {
    id: "delivery",
    eyebrow: "توصيل سريع",
    title: "اطلب الآن، يوصلك في نفس اليوم",
    subtitle: "كل احتياجاتك من البقالة والمنظفات والمعلّبات لباب البيت.",
    ctas: [
      { label: "تصفّح المنتجات", action: "browseCategories", variant: "primary" },
      { label: "ابحث عن منتج", action: "openSearch", variant: "ghost" },
    ],
  },
  {
    id: "fresh",
    eyebrow: "طازج كل يوم",
    title: "خضار وفواكه ولحوم بأعلى جودة",
    subtitle: "نختار لك الأطزج يومياً — جودة مضمونة أو استرداد كامل.",
    ctas: [
      { label: "تسوّق الجديد", action: "browseLatest", variant: "primary" },
      { label: "كل الأصناف", action: "browseCategories", variant: "ghost" },
    ],
  },
];

/**
 * Slide overrides per store slug. Add or edit any store's slides here.
 * The `default` key is used when the slug isn't listed.
 */
const slidesByStore: Record<string, HeroSlide[]> = {
  default: defaultSlides,
  // Example: customize Awaldrazq's hero copy (kept similar to default for now).
  awaldrazq: [
    {
      id: "awaldrazq-offers",
      eyebrow: "عروض الأسبوع",
      title: "أسعار سوبر ماركت أقل، وجودة أعلى",
      subtitle: "عروض جديدة كل أسبوع على البقالة والمنظفات والمشروبات.",
      ctas: [
        { label: "تسوّق العروض", action: "shopOffers", variant: "primary" },
        { label: "تصفح الأصناف", action: "browseCategories", variant: "ghost" },
      ],
    },
    {
      id: "awaldrazq-delivery",
      eyebrow: "توصيل لباب البيت",
      title: "اطلب احتياجاتك ووصلك بسرعة",
      subtitle: "غطّينا كل احتياجات البيت — من الرز والزيت حتى المنظفات.",
      ctas: [
        { label: "ابدأ التسوّق", action: "browseCategories", variant: "primary" },
        { label: "ابحث عن منتج", action: "openSearch", variant: "ghost" },
      ],
    },
    {
      id: "awaldrazq-fresh",
      eyebrow: "طازج يومياً",
      title: "خضار وفواكه طازجة كل صباح",
      subtitle: "نختار لك الأفضل — جودة مضمونة أو استرداد كامل.",
      ctas: [
        { label: "الأحدث وصولاً", action: "browseLatest", variant: "primary" },
      ],
    },
  ],
};

export function getHeroSlides(slug: string | undefined | null): HeroSlide[] {
  if (slug && slidesByStore[slug]) return slidesByStore[slug];
  return slidesByStore.default;
}

/** Hero slides tailored for clothing/fashion stores. */
export const clothesHeroSlides: HeroSlide[] = [
  {
    id: "clothes-new",
    eyebrow: "تشكيلة جديدة",
    title: "إطلالة جديدة لكل مناسبة",
    subtitle: "اكتشف أحدث صيحات الموضة بأسعار تناسبك.",
    image: "https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=1280&q=70",
    ctas: [
      { label: "تسوّق الجديد", action: "browseLatest", variant: "primary" },
      { label: "كل الأقسام", action: "browseCategories", variant: "ghost" },
    ],
  },
  {
    id: "clothes-sale",
    eyebrow: "تخفيضات الموسم",
    title: "خصومات تصل إلى 50% على الموضة",
    subtitle: "قطع مختارة بعناية — كميات محدودة فلا تفوّت الفرصة.",
    image: "https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&w=1280&q=70",
    ctas: [
      { label: "تسوّق العروض", action: "shopOffers", variant: "primary" },
      { label: "تصفّح الأصناف", action: "browseCategories", variant: "ghost" },
    ],
  },
  {
    id: "clothes-style",
    eyebrow: "ستايل يميّزك",
    title: "أناقة تعكس شخصيتك",
    subtitle: "ملابس وأكسسوارات بجودة عالية وتصاميم عصرية.",
    image: "https://images.unsplash.com/photo-1558769132-cb1aea458c5e?auto=format&fit=crop&w=1280&q=70",
    ctas: [
      { label: "تصفّح المجموعات", action: "browseCategories", variant: "primary" },
      { label: "ابحث عن قطعة", action: "openSearch", variant: "ghost" },
    ],
  },
];

