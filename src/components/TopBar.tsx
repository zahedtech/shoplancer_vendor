import { Phone, MapPin, Clock } from "lucide-react";
import { useTranslation } from "react-i18next";
import { useLocation, useParams } from "react-router-dom";
import { StoreDetails } from "@/lib/api";

interface TopBarProps {
  store?: StoreDetails;
  /** Force show even on non-home routes. Default: only show on store home. */
  alwaysShow?: boolean;
}

export const TopBar = ({ store, alwaysShow = false }: TopBarProps) => {
  const { t } = useTranslation();
  const location = useLocation();
  const { storeSlug } = useParams<{ storeSlug: string }>();

  // Only show on the store home page (e.g. /hashem). Hide on /hashem/categories/30, etc.
  const path = location.pathname.replace(/\/+$/, "");
  const isHome = !!storeSlug && (path === `/${storeSlug}` || path === "");
  if (!alwaysShow && !isHome) return null;

  return (
    <div className="bg-primary text-primary-foreground text-xs md:text-sm">
      <div className="container flex items-center justify-between py-2 gap-3 md:gap-4">
        <a
          href={`tel:${store?.phone ?? ""}`}
          className="inline-flex items-center gap-1.5 hover:opacity-80 transition-smooth shrink-0"
          dir="ltr"
        >
          <Phone className="h-3.5 w-3.5" />
          {store?.phone ?? t("topbar.defaultPhone")}
        </a>
        <div className="flex items-center gap-4 md:gap-6 min-w-0 flex-1 justify-end">
          <span className="hidden md:inline-flex items-center gap-1.5 shrink-0">
            <Clock className="h-3.5 w-3.5" />
            {store?.delivery_time ?? t("topbar.defaultDeliveryTime")}
          </span>
          <span className="inline-flex items-center gap-1.5 min-w-0">
            <span className="truncate whitespace-nowrap">
              {store?.address?.trim() || t("topbar.defaultLocation")}
            </span>
            <MapPin className="h-3.5 w-3.5 shrink-0" />
          </span>
        </div>
      </div>
    </div>
  );
};


