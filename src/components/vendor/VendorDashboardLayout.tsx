import { ReactNode } from "react";
import { Link, NavLink, Outlet, useParams } from "react-router-dom";
import { SignOutButton } from "@/components/auth/SignOutButton";
import {
  LayoutDashboard,
  Package,
  ShoppingBag,
  Settings,
  ExternalLink,
  ArrowRight,
} from "lucide-react";
import {
  Sidebar,
  SidebarContent,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarProvider,
  SidebarTrigger,
} from "@/components/ui/sidebar";
import { useStore } from "@/context/StoreContext";

const items = (slug: string) => [
  { to: `/${slug}/dashboard`, icon: LayoutDashboard, label: "نظرة عامة", end: true },
  { to: `/${slug}/dashboard/products`, icon: Package, label: "المنتجات والأسعار" },
  { to: `/${slug}/dashboard/orders`, icon: ShoppingBag, label: "الطلبات" },
  { to: `/${slug}/dashboard/settings`, icon: Settings, label: "الإعدادات" },
];

const navClass = ({ isActive }: { isActive: boolean }) =>
  `flex items-center gap-2 ${
    isActive
      ? "bg-sidebar-accent text-sidebar-accent-foreground font-bold"
      : "hover:bg-sidebar-accent/50"
  }`;

export const VendorDashboardLayout = ({ children }: { children?: ReactNode }) => {
  const { storeSlug = "" } = useParams<{ storeSlug: string }>();
  const { store, isLoading } = useStore();

  return (
    <SidebarProvider>
      <div dir="rtl" className="min-h-screen flex w-full bg-background">
        <Sidebar collapsible="icon" side="right">
          <SidebarContent>
            <div className="px-4 py-4 border-b border-sidebar-border">
              <div className="flex items-center gap-2">
                <div className="h-9 w-9 rounded-xl bg-secondary inline-flex items-center justify-center overflow-hidden">
                  {store?.logo_full_url ? (
                    <img src={store.logo_full_url} alt={store.name} className="h-full w-full object-cover" />
                  ) : (
                    <Package className="h-4 w-4 text-muted-foreground" />
                  )}
                </div>
                <div className="flex flex-col min-w-0">
                  <span className="font-extrabold text-sm truncate">
                    {store?.name ?? (isLoading ? "..." : storeSlug)}
                  </span>
                  <span className="text-[10px] text-muted-foreground">لوحة التاجر</span>
                </div>
              </div>
            </div>

            <SidebarGroup>
              <SidebarGroupLabel>التنقل</SidebarGroupLabel>
              <SidebarGroupContent>
                <SidebarMenu>
                  {items(storeSlug).map((item) => (
                    <SidebarMenuItem key={item.to}>
                      <SidebarMenuButton asChild>
                        <NavLink to={item.to} end={item.end} className={navClass}>
                          <item.icon className="h-4 w-4" />
                          <span>{item.label}</span>
                        </NavLink>
                      </SidebarMenuButton>
                    </SidebarMenuItem>
                  ))}
                </SidebarMenu>
              </SidebarGroupContent>
            </SidebarGroup>

            <SidebarGroup>
              <SidebarGroupContent>
                <SidebarMenu>
                  <SidebarMenuItem>
                    <SidebarMenuButton asChild>
                      <Link to={`/${storeSlug}`} className="text-muted-foreground hover:text-foreground">
                        <ExternalLink className="h-4 w-4" />
                        <span>عرض المتجر</span>
                      </Link>
                    </SidebarMenuButton>
                  </SidebarMenuItem>
                  <SidebarMenuItem>
                    <SidebarMenuButton asChild>
                      <Link to="/admin" className="text-muted-foreground hover:text-foreground">
                        <ArrowRight className="h-4 w-4 ltr:rotate-180" />
                        <span>لوحة الإدارة</span>
                      </Link>
                    </SidebarMenuButton>
                  </SidebarMenuItem>
                </SidebarMenu>
              </SidebarGroupContent>
            </SidebarGroup>
          </SidebarContent>
        </Sidebar>

        <div className="flex-1 flex flex-col min-w-0">
          <header className="h-14 border-b border-border bg-card flex items-center px-4 gap-3 sticky top-0 z-30">
            <SidebarTrigger />
            <h1 className="font-extrabold text-foreground truncate">
              {store?.name ?? storeSlug}
            </h1>
            <span className="text-xs text-muted-foreground">/ {storeSlug}</span>
            <div className="flex-1" />
            <SignOutButton />
          </header>
          <main className="flex-1 p-4 md:p-6 overflow-auto">{children ?? <Outlet />}</main>
        </div>
      </div>
    </SidebarProvider>
  );
};
