import { ReactNode } from "react";
import { Link, NavLink, Outlet, useLocation } from "react-router-dom";
import { SignOutButton } from "@/components/auth/SignOutButton";
import {
  LayoutDashboard,
  Store as StoreIcon,
  Settings,
  ExternalLink,
  Plus,
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
  SidebarFooter,
} from "@/components/ui/sidebar";
import { useStoresRegistry } from "@/hooks/useStoresRegistry";

const navItems = [
  { to: "/admin", icon: LayoutDashboard, label: "نظرة عامة", end: true },
  { to: "/admin/stores", icon: StoreIcon, label: "المتاجر" },
  { to: "/admin/settings", icon: Settings, label: "الإعدادات" },
];

const navClass = ({ isActive }: { isActive: boolean }) =>
  `flex items-center gap-2 ${
    isActive ? "bg-sidebar-accent text-sidebar-accent-foreground font-bold" : "hover:bg-sidebar-accent/50"
  }`;

export const AdminLayout = ({ children }: { children?: ReactNode }) => {
  const stores = useStoresRegistry();
  return (
    <SidebarProvider>
      <div dir="rtl" className="min-h-screen flex w-full bg-background">
        <Sidebar collapsible="icon" side="right">
          <SidebarContent>
            <div className="px-4 py-4 border-b border-sidebar-border">
              <Link to="/admin" className="flex items-center gap-2">
                <div className="h-9 w-9 rounded-xl bg-primary text-primary-foreground inline-flex items-center justify-center font-extrabold">
                  S
                </div>
                <div className="flex flex-col">
                  <span className="font-extrabold text-sm">Shoplanser Admin</span>
                  <span className="text-[10px] text-muted-foreground">لوحة عامة</span>
                </div>
              </Link>
            </div>

            <SidebarGroup>
              <SidebarGroupLabel>التنقل</SidebarGroupLabel>
              <SidebarGroupContent>
                <SidebarMenu>
                  {navItems.map((item) => (
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
              <SidebarGroupLabel>المتاجر ({stores.length})</SidebarGroupLabel>
              <SidebarGroupContent>
                <SidebarMenu>
                  {stores.map((s) => (
                    <SidebarMenuItem key={s.slug}>
                      <SidebarMenuButton asChild>
                        <NavLink to={`/${s.slug}/dashboard`} className={navClass}>
                          <StoreIcon className="h-4 w-4" />
                          <span className="truncate">{s.displayName ?? s.slug}</span>
                        </NavLink>
                      </SidebarMenuButton>
                    </SidebarMenuItem>
                  ))}
                  <SidebarMenuItem>
                    <SidebarMenuButton asChild>
                      <NavLink to="/admin/stores" className="text-primary font-bold">
                        <Plus className="h-4 w-4" />
                        <span>إضافة متجر</span>
                      </NavLink>
                    </SidebarMenuButton>
                  </SidebarMenuItem>
                </SidebarMenu>
              </SidebarGroupContent>
            </SidebarGroup>
          </SidebarContent>
          <SidebarFooter className="border-t border-sidebar-border p-2">
            <a
              href="/"
              className="flex items-center gap-2 text-xs text-muted-foreground hover:text-foreground px-2 py-1.5 rounded-md hover:bg-sidebar-accent"
            >
              <ExternalLink className="h-3.5 w-3.5" />
              <span>عرض المتجر</span>
            </a>
          </SidebarFooter>
        </Sidebar>

        <div className="flex-1 flex flex-col min-w-0">
          <header className="h-14 border-b border-border bg-card flex items-center px-4 gap-3 sticky top-0 z-30">
            <SidebarTrigger />
            <h1 className="font-extrabold text-foreground">لوحة الإدارة العامة</h1>
            <div className="flex-1" />
            <PageBreadcrumbs />
            <SignOutButton />
          </header>
          <main className="flex-1 p-4 md:p-6 overflow-auto">{children ?? <Outlet />}</main>
        </div>
      </div>
    </SidebarProvider>
  );
};

const PageBreadcrumbs = () => {
  const { pathname } = useLocation();
  const map: Record<string, string> = {
    "/admin": "نظرة عامة",
    "/admin/stores": "المتاجر",
    "/admin/settings": "الإعدادات",
  };
  return <span className="text-xs text-muted-foreground">{map[pathname] ?? ""}</span>;
};
