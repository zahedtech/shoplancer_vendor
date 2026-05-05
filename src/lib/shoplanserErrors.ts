// Typed errors for the ShopLancer API client.
// Maps the server's `errors[]` shape (see shoplanser-api.md §4.5) into a
// throwable that React Query can surface. `userMessage(t)` returns a translated
// {title, description} object for the EmptyState/error UI.

import type { TFunction } from "i18next";

export interface ShoplanserErrorItem {
  code?: string;
  message: string;
}

export class ShoplanserApiError extends Error {
  status: number;
  errors: ShoplanserErrorItem[];
  path: string;

  constructor(opts: {
    status: number;
    message: string;
    errors?: ShoplanserErrorItem[];
    path: string;
  }) {
    super(opts.message);
    this.name = "ShoplanserApiError";
    this.status = opts.status;
    this.errors = opts.errors ?? [];
    this.path = opts.path;
  }

  /** True if this looks like a network/offline failure rather than an HTTP error. */
  get isNetwork(): boolean {
    return this.status === 0;
  }

  /** Map this error to translated user-facing copy. */
  userMessage(t: TFunction): { title: string; description: string } {
    if (this.isNetwork) {
      return {
        title: t("categories.errors.network.title"),
        description: t("categories.errors.network.description"),
      };
    }
    const code = this.errors[0]?.code?.toLowerCase();
    if (code?.startsWith("zone")) {
      return {
        title: t("categories.errors.zone.title"),
        description: t("categories.errors.zone.description"),
      };
    }
    if (this.status === 404) {
      return {
        title: t("categories.errors.notFound.title"),
        description: t("categories.errors.notFound.description"),
      };
    }
    return {
      title: t("categories.errors.generic.title"),
      description:
        this.errors[0]?.message ??
        this.message ??
        t("categories.errors.generic.description"),
    };
  }
}
