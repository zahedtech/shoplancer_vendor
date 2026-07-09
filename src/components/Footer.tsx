import { StoreDetails } from "@/lib/api";
import { Phone, MapPin, Clock } from "lucide-react";
import { useTranslation } from "react-i18next";

interface FooterProps {
  store?: StoreDetails;
}

export const Footer = ({ store }: FooterProps) => {
  const { t } = useTranslation();
  return (
    <footer className="mt-12 bg-primary text-primary-foreground hidden md:block">
      <div className="container py-10 grid gap-8 md:grid-cols-4">
        <div className="md:col-span-2">
          <div className="flex items-center gap-3">
            {store?.logo_full_url && (
              <img
                src={store.logo_full_url}
                alt={store.name}
                className="h-12 w-12 rounded-full object-cover"
              />
            )}
            <div>
              <div className="font-extrabold text-xl">
                {store?.name ?? t("footer.brandFallback")}
              </div>
              <div className="text-xs opacity-80 tracking-widest">
                {t("footer.brandTagline")}
              </div>
            </div>
          </div>
          <p className="mt-4 text-sm opacity-90 max-w-md leading-relaxed">
            {t("footer.description")}
          </p>
        </div>

        <div className="space-y-2 text-sm">
          <h3 className="font-bold mb-3">{t("footer.contactUs")}</h3>
          <a
            dir="ltr"
            href={`tel:${store?.phone ?? ""}`}
            className="flex items-center gap-2 opacity-90 hover:opacity-100"
          >
            <Phone className="h-4 w-4" /> {store?.phone}
          </a>
          <div className="flex items-center gap-2 opacity-90">
            <MapPin className="h-4 w-4 shrink-0" />
            <span className="text-xs">{store?.address}</span>
          </div>
          <div className="flex items-center gap-2 opacity-90">
            <Clock className="h-4 w-4" /> {store?.delivery_time}
          </div>
        </div>

        <div className="text-sm">
          <h3 className="font-bold mb-3">{t("footer.links")}</h3>
          <ul className="space-y-2 opacity-90">
            <li>
              <a href="#categories" className="hover:underline">
                {t("footer.categories")}
              </a>
            </li>
            <li>
              <a href="#products" className="hover:underline">
                {t("footer.products")}
              </a>
            </li>
            <li>
              <a href="#" className="hover:underline">
                {t("footer.deliveryPolicy")}
              </a>
            </li>
          </ul>
        </div>
      </div>
      <div className="border-t border-primary-foreground/20 py-4 text-center text-xs opacity-80">
        {t("footer.copyright", {
          year: new Date().getFullYear(),
          store: store?.name ?? t("footer.defaultStore"),
        })}
      </div>
    </footer>
  );
};

