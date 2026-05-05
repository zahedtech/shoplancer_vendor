import { lazy, Suspense } from "react";
import { QueryClient } from "@tanstack/react-query";
import { PersistQueryClientProvider } from "@tanstack/react-query-persist-client";
import { createSyncStoragePersister } from "@tanstack/query-sync-storage-persister";
import { BrowserRouter, Navigate, Outlet, Route, Routes, useParams } from "react-router-dom";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import { CartProvider } from "@/context/CartContext";
import { WatchlistProvider } from "@/context/WatchlistContext";
import { StoreProvider } from "@/context/StoreContext";
import { ShopAuthProvider } from "@/context/ShopAuthContext";
import Storefront from "./pages/Index.tsx";
import NotFound from "./pages/NotFound.tsx";

// Lazy-loaded routes — keeps initial bundle small (better Lighthouse score)
const OrderStatus = lazy(() => import("./pages/OrderStatus.tsx"));
const SearchPage = lazy(() => import("./pages/Search.tsx"));
const VoiceTestPage = lazy(() => import("./pages/VoiceTest.tsx"));
const Account = lazy(() => import("./pages/Account.tsx"));
const OrdersHistory = lazy(() => import("./pages/OrdersHistory.tsx"));
const Categories = lazy(() => import("./pages/Categories.tsx"));
const CategoryDetail = lazy(() => import("./pages/CategoryDetail.tsx"));
const ProductDetail = lazy(() => import("./pages/ProductDetail.tsx"));
const Watchlist = lazy(() => import("./pages/Watchlist.tsx"));
const AdminLayout = lazy(() => import("./components/admin/AdminLayout").then(m => ({ default: m.AdminLayout })));
const AdminOverview = lazy(() => import("./pages/admin/AdminOverview"));
const AdminStores = lazy(() => import("./pages/admin/AdminStores"));
const AdminStoreSettings = lazy(() => import("./pages/admin/AdminStoreSettings"));
const AdminGlobalSettings = lazy(() => import("./pages/admin/AdminGlobalSettings"));
const VendorDashboardLayout = lazy(() => import("./components/vendor/VendorDashboardLayout").then(m => ({ default: m.VendorDashboardLayout })));
const VendorOverview = lazy(() => import("./pages/vendor/VendorOverview"));
const VendorProducts = lazy(() => import("./pages/vendor/VendorProducts"));
const VendorOrders = lazy(() => import("./pages/vendor/VendorOrders"));
const VendorSettings = lazy(() => import("./pages/vendor/VendorSettings"));
const Auth = lazy(() => import("./pages/Auth"));
const ShopLogin = lazy(() => import("./pages/ShopLogin"));
const ShopRegister = lazy(() => import("./pages/ShopRegister"));
const Addresses = lazy(() => import("./pages/Addresses"));
const Settings = lazy(() => import("./pages/Settings"));
import { RequireRole, RequireVendorForSlug } from "./components/auth/RouteGuards";
import { RequireShopAuth } from "./components/auth/RequireShopAuth";
import { FloatingCartButton } from "./components/FloatingCartButton";

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      networkMode: "offlineFirst",
      staleTime: 5 * 60 * 1000,
      gcTime: 7 * 24 * 60 * 60 * 1000,
      retry: 2,
      refetchOnWindowFocus: false,
    },
  },
});

const persister = createSyncStoragePersister({
  storage: typeof window !== "undefined" ? window.localStorage : undefined,
  key: "shoplanser_query_cache_v1",
  throttleTime: 1000,
});

/**
 * Wraps every per-store route with StoreProvider + CartProvider scoped to the
 * URL slug. This is what makes the app multi-tenant: the same components work
 * for any vendor that exists on Shoplanser.
 */
/** Matches Vite `base` (e.g. `/store/`) so URLs like `/store/hashem` map to `/:storeSlug` → `hashem`. */
const routerBasename =
  import.meta.env.BASE_URL.replace(/\/$/, "") || undefined;

const StoreLayout = () => {
  const { storeSlug = "" } = useParams<{ storeSlug: string }>();
  return (
    <StoreProvider slug={storeSlug}>
      <ShopAuthProvider>
        <CartProvider storeSlug={storeSlug}>
          <WatchlistProvider storeSlug={storeSlug}>
            <Outlet />
            <FloatingCartButton />
          </WatchlistProvider>
        </CartProvider>
      </ShopAuthProvider>
    </StoreProvider>
  );
};

const App = () => (
  <PersistQueryClientProvider
    client={queryClient}
    persistOptions={{
      persister,
      maxAge: 7 * 24 * 60 * 60 * 1000,
      buster: "v2",
    }}
  >
    <TooltipProvider>
      <Toaster />
      <Sonner />
      <BrowserRouter basename={routerBasename}>
        <Suspense fallback={<AppRouteFallback />}>
          <Routes>
          {/* Default landing → primary store */}
          <Route path="/" element={<Navigate to="/awaldrazq" replace />} />

          {/* Public auth page */}
          <Route path="/auth" element={<Auth />} />

          {/* Super-admin (cross-store control) — admin role required */}
          <Route
            path="/admin"
            element={
              <RequireRole role="admin">
                <AdminLayout />
              </RequireRole>
            }
          >
            <Route index element={<AdminOverview />} />
            <Route path="stores" element={<AdminStores />} />
            <Route path="stores/:slug/settings" element={<AdminStoreSettings />} />
            <Route path="settings" element={<AdminGlobalSettings />} />
          </Route>

          {/* Per-store routes (storefront + vendor dashboard) */}
          <Route path="/:storeSlug" element={<StoreLayout />}>
            <Route index element={<Storefront />} />
            <Route path="categories" element={<Categories />} />
            <Route path="categories/:categoryId" element={<CategoryDetail />} />
            <Route path="product/:productId" element={<ProductDetail />} />
            <Route path="watchlist" element={<Watchlist />} />
            <Route path="search" element={<SearchPage />} />
            <Route path="voice-test" element={<VoiceTestPage />} />
            <Route path="account" element={<Account />} />
            <Route
              path="addresses"
              element={
                <RequireShopAuth>
                  <Addresses />
                </RequireShopAuth>
              }
            />
            <Route path="login" element={<ShopLogin />} />
            <Route path="register" element={<ShopRegister />} />
            <Route path="settings" element={<Settings />} />
            <Route path="orders/:orderId" element={<OrderStatus />} />
            <Route
              path="orders"
              element={
                <RequireShopAuth>
                  <OrdersHistory />
                </RequireShopAuth>
              }
            />

            {/* Vendor dashboard — admin or mapped vendor only */}
            <Route
              path="dashboard"
              element={
                <RequireVendorForSlug>
                  <VendorDashboardLayout />
                </RequireVendorForSlug>
              }
            >
              <Route index element={<VendorOverview />} />
              <Route path="products" element={<VendorProducts />} />
              <Route path="orders" element={<VendorOrders />} />
              <Route path="settings" element={<VendorSettings />} />
            </Route>
          </Route>

          {/* Legacy redirect: old /orders/:id → /awaldrazq/orders/:id */}
          <Route path="/orders/:orderId" element={<LegacyOrderRedirect />} />

          <Route path="*" element={<NotFound />} />
          </Routes>
        </Suspense>
      </BrowserRouter>
    </TooltipProvider>
  </PersistQueryClientProvider>
);

const LegacyOrderRedirect = () => {
  const { orderId } = useParams<{ orderId: string }>();
  return <Navigate to={`/awaldrazq/orders/${orderId}`} replace />;
};

const AppRouteFallback = () => (
  <div className="min-h-screen bg-background flex items-center justify-center px-6">
    <div className="w-full max-w-sm space-y-3" aria-label="جارٍ تحميل الصفحة">
      <div className="h-12 rounded-full bg-muted animate-pulse" />
      <div className="h-40 rounded-2xl bg-muted animate-pulse" />
      <div className="grid grid-cols-2 gap-3">
        <div className="h-32 rounded-2xl bg-muted animate-pulse" />
        <div className="h-32 rounded-2xl bg-muted animate-pulse" />
      </div>
    </div>
  </div>
);

export default App;
