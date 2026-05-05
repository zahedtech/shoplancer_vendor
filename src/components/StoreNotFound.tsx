import { Link } from "react-router-dom";
import { Store, ArrowRight } from "lucide-react";
import { useTranslation } from "react-i18next";
import { Button } from "@/components/ui/button";

interface Props {
  slug: string;
}

export const StoreNotFound = ({ slug }: Props) => {
  const { t } = useTranslation();
  return (
    <div className="min-h-screen bg-background flex items-center justify-center p-6">
      <div className="text-center max-w-md space-y-5">
        <div className="h-24 w-24 mx-auto rounded-full bg-muted text-muted-foreground inline-flex items-center justify-center">
          <Store className="h-12 w-12" />
        </div>
        <div className="space-y-2">
          <h1 className="text-2xl font-extrabold">{t("storeNotFound.title")}</h1>
          <p className="text-sm text-muted-foreground leading-relaxed">
            {t("storeNotFound.descBefore")}{" "}
            <span className="font-bold text-foreground" dir="ltr">
              /{slug}
            </span>
            {t("storeNotFound.descAfter")}
          </p>
        </div>
        <Button asChild className="rounded-full">
          <Link to="/awaldrazq" className="inline-flex items-center gap-2">
            <ArrowRight className="h-4 w-4 ltr:rotate-180" />
            {t("storeNotFound.goToHashem")}
          </Link>
        </Button>
      </div>
    </div>
  );
};
