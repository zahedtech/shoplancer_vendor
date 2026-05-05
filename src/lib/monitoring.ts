/**
 * Thin error-reporting wrapper. Sends to Sentry when available
 * (window.Sentry, injected by a script tag or the official SDK), and always
 * mirrors to the console so local development still surfaces the error.
 *
 * Usage:
 *   reportError(error, { section: "offers", slug, extra: { categoryId } });
 *
 * To enable Sentry in production, add the Sentry browser SDK / loader script
 * to index.html — no other code changes required.
 */

export interface ErrorContext {
  /** Logical area where the error happened, e.g. "home/offers". */
  section?: string;
  /** Active store slug (multi-tenant). */
  slug?: string;
  /** Any other primitives helpful for debugging (ids, flags, counts…). */
  extra?: Record<string, unknown>;
  /** React component stack from an ErrorBoundary, when available. */
  componentStack?: string;
}

type SentryLike = {
  captureException: (
    err: unknown,
    hint?: { contexts?: Record<string, unknown>; tags?: Record<string, string> },
  ) => void;
  withScope?: (cb: (scope: unknown) => void) => void;
};

function getSentry(): SentryLike | null {
  if (typeof window === "undefined") return null;
  const s = (window as unknown as { Sentry?: SentryLike }).Sentry;
  return s && typeof s.captureException === "function" ? s : null;
}

export function reportError(error: unknown, ctx: ErrorContext = {}): void {
  const { section, slug, extra, componentStack } = ctx;

  // Always log locally — keeps DX unchanged when no monitoring is wired up.
  console.error("[monitoring]", { section, slug, extra, error, componentStack });

  const sentry = getSentry();
  if (!sentry) return;

  try {
    sentry.captureException(error, {
      tags: {
        ...(section ? { section } : {}),
        ...(slug ? { slug } : {}),
      },
      contexts: {
        lovable: {
          section,
          slug,
          ...(extra ?? {}),
          ...(componentStack ? { componentStack } : {}),
        },
      },
    });
  } catch {
    // Never let monitoring crash the app.
  }
}
