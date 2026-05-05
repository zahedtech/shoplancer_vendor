import { ReactNode } from "react";
import { Navigate, useLocation, useParams } from "react-router-dom";
import { useShopAuth } from "@/context/ShopAuthContext";

function FullPageSpinner() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-background">
      <div className="h-8 w-8 rounded-full border-2 border-primary border-t-transparent animate-spin" />
    </div>
  );
}

/**
 * Require an authenticated shop (Shoplanser) user. Redirects unauthenticated
 * visitors to /:storeSlug/login?redirect=<current> so they come back after
 * login.
 */
export function RequireShopAuth({ children }: { children: ReactNode }) {
  const { isAuthenticated, loading } = useShopAuth();
  const location = useLocation();
  const { storeSlug = "awaldrazq" } = useParams<{ storeSlug: string }>();

  if (loading) return <FullPageSpinner />;
  if (!isAuthenticated) {
    const next = encodeURIComponent(location.pathname + location.search);
    return <Navigate to={`/${storeSlug}/login?redirect=${next}`} replace />;
  }
  return <>{children}</>;
}
