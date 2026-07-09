import type { StoreCategory } from "@/lib/api";

export type Audience = "men" | "women" | "kids";

const KEYWORDS: Record<Audience, RegExp> = {
  men: /\b(men|male|man|gent|رجال|رجالى|رجالي)\b/i,
  women: /\b(women|female|woman|ladies|نساء|نسائي|نسائى|حريم|حريمي)\b/i,
  kids: /\b(kids|kid|baby|babies|child|children|أطفال|اطفال|طفل|بيبي|بنوتة|ولد)\b/i,
};

/** Auto-detect a category's audience from its name. */
export function detectAudience(category: { name?: string } | null | undefined): Audience | null {
  const name = category?.name ?? "";
  if (KEYWORDS.kids.test(name)) return "kids";
  if (KEYWORDS.women.test(name)) return "women";
  if (KEYWORDS.men.test(name)) return "men";
  return null;
}

/**
 * Decide a category's audience using a manual override map first, then
 * falling back to keyword detection.
 */
export function categoryAudience(
  category: StoreCategory,
  audienceMap?: { men: number[]; women: number[]; kids: number[] } | null,
): Audience | null {
  if (audienceMap) {
    if (audienceMap.men?.includes(category.id)) return "men";
    if (audienceMap.women?.includes(category.id)) return "women";
    if (audienceMap.kids?.includes(category.id)) return "kids";
  }
  return detectAudience(category);
}

/** Filter a list of categories to only those matching the chosen audience. */
export function filterCategoriesByAudience(
  categories: StoreCategory[],
  audience: Audience | null,
  audienceMap?: { men: number[]; women: number[]; kids: number[] } | null,
): StoreCategory[] {
  if (!audience) return categories;
  return categories.filter((c) => categoryAudience(c, audienceMap) === audience);
}
