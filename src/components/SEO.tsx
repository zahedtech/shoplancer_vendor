import { Helmet } from "react-helmet-async";

interface SEOProps {
  title: string;
  description?: string;
  image?: string;
  canonical?: string;
  /** When true, prevents indexing (use for personal pages like account/orders). */
  noindex?: boolean;
}

/**
 * Centralised <head> manager. Renders title, description, OG/Twitter tags
 * and an optional canonical link. Used by every top-level page so each
 * route ships meaningful, distinct meta tags for SEO and social previews.
 */
export const SEO = ({
  title,
  description,
  image,
  canonical,
  noindex,
}: SEOProps) => {
  const fullTitle = title.length > 60 ? title.slice(0, 57) + "…" : title;
  const desc = description?.slice(0, 160);

  return (
    <Helmet>
      <title>{fullTitle}</title>
      {desc && <meta name="description" content={desc} />}
      {canonical && <link rel="canonical" href={canonical} />}
      {noindex && <meta name="robots" content="noindex,nofollow" />}

      <meta property="og:title" content={fullTitle} />
      {desc && <meta property="og:description" content={desc} />}
      {image && <meta property="og:image" content={image} />}
      <meta property="og:type" content="website" />

      <meta name="twitter:card" content="summary_large_image" />
      <meta name="twitter:title" content={fullTitle} />
      {desc && <meta name="twitter:description" content={desc} />}
      {image && <meta name="twitter:image" content={image} />}
    </Helmet>
  );
};
