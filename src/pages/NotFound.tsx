import { useLocation, Link } from "react-router-dom";
import { useEffect } from "react";
import { useTranslation } from "react-i18next";

const NotFound = () => {
  const location = useLocation();
  const { t } = useTranslation();

  useEffect(() => {
    console.error("404 Error: User attempted to access non-existent route:", location.pathname);
  }, [location.pathname]);

  return (
    <div className="flex min-h-screen items-center justify-center bg-muted">
      <div className="text-center px-6">
        <h1 className="mb-3 text-6xl font-extrabold text-primary">404</h1>
        <p className="mb-2 text-xl font-bold">{t("notFound.title")}</p>
        <p className="mb-6 text-sm text-muted-foreground">{t("notFound.subtitle")}</p>
        <Link to="/" className="text-primary underline hover:text-primary/90 font-bold">
          {t("notFound.home")}
        </Link>
      </div>
    </div>
  );
};

export default NotFound;
