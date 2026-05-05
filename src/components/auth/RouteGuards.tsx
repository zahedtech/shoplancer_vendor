import { ReactNode } from "react";
import { Navigate, useLocation, useParams } from "react-router-dom";
import { useAuth, useUserRoles, useVendorStores, type AppRole } from "@/hooks/useAuth";

function FullPageSpinner() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-background">
      <div className="h-8 w-8 rounded-full border-2 border-primary border-t-transparent animate-spin" />
    </div>
  );
}

/** Require any signed-in user. Redirects to /auth?redirect=<current> otherwise. */
export function RequireAuth({ children }: { children: ReactNode }) {
  const { session, loading } = useAuth();
  const location = useLocation();
  if (loading) return <FullPageSpinner />;
  if (!session) {
    const next = encodeURIComponent(location.pathname + location.search);
    return <Navigate to={`/auth?redirect=${next}`} replace />;
  }
  return <>{children}</>;
}

/** Require a specific role (e.g. "admin"). */
export function RequireRole({
  role,
  children,
}: {
  role: AppRole;
  children: ReactNode;
}) {
  const { session, user, loading } = useAuth();
  const { roles, loading: rolesLoading } = useUserRoles(user?.id ?? null);
  const location = useLocation();

  if (loading || (session && rolesLoading)) return <FullPageSpinner />;
  if (!session) {
    const next = encodeURIComponent(location.pathname + location.search);
    return <Navigate to={`/auth?redirect=${next}`} replace />;
  }
  if (!roles.includes(role)) {
    return (
      <div className="min-h-screen flex items-center justify-center p-6 text-center">
        <div>
          <h1 className="text-2xl font-extrabold mb-2">غير مصرح</h1>
          <p className="text-muted-foreground">
            ليس لديك صلاحية الوصول إلى هذه الصفحة.
          </p>
        </div>
      </div>
    );
  }
  return <>{children}</>;
}

/**
 * Allow access to /:storeSlug/dashboard/* if the user is admin OR is a vendor
 * mapped to that exact storeSlug.
 */
export function RequireVendorForSlug({ children }: { children: ReactNode }) {
  const { session, user, loading } = useAuth();
  const { roles, loading: rolesLoading } = useUserRoles(user?.id ?? null);
  const { slugs, loading: slugsLoading } = useVendorStores(user?.id ?? null);
  const params = useParams<{ storeSlug: string }>();
  const location = useLocation();

  if (loading || (session && (rolesLoading || slugsLoading))) {
    return <FullPageSpinner />;
  }
  if (!session) {
    const next = encodeURIComponent(location.pathname + location.search);
    return <Navigate to={`/auth?redirect=${next}`} replace />;
  }

  const isAdmin = roles.includes("admin");
  const isVendorForSlug =
    roles.includes("vendor") && !!params.storeSlug && slugs.includes(params.storeSlug);

  if (!isAdmin && !isVendorForSlug) {
    return (
      <div className="min-h-screen flex items-center justify-center p-6 text-center">
        <div>
          <h1 className="text-2xl font-extrabold mb-2">غير مصرح</h1>
          <p className="text-muted-foreground">
            ليس لديك صلاحية الوصول إلى لوحة هذا المتجر.
          </p>
        </div>
      </div>
    );
  }

  return <>{children}</>;
}
