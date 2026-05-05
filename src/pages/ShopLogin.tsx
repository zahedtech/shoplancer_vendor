import { useState } from "react";
import { Link, useNavigate, useParams, useSearchParams } from "react-router-dom";
import { useShopAuth } from "@/context/ShopAuthContext";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { useToast } from "@/hooks/use-toast";
import { SEO } from "@/components/SEO";
import { Loader2, ArrowRight } from "lucide-react";
import { ShoplanserApiError } from "@/lib/shoplanserErrors";

export default function ShopLogin() {
  const { storeSlug = "" } = useParams<{ storeSlug: string }>();
  const [params] = useSearchParams();
  const fallbackRedirect = `/${storeSlug}/account`;
  const requestedRedirect = params.get("redirect");
  // Only honor same-origin, same-store internal paths to prevent open redirects.
  const safeRedirect =
    requestedRedirect &&
    requestedRedirect.startsWith(`/${storeSlug}/`) &&
    !requestedRedirect.startsWith("//")
      ? requestedRedirect
      : fallbackRedirect;
  const { signIn } = useShopAuth();
  const navigate = useNavigate();
  const { toast } = useToast();

  const [phone, setPhone] = useState("+20");
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    try {
      await signIn(phone.trim(), password);
      toast({ title: "تم تسجيل الدخول" });
      try {
        navigate(safeRedirect, { replace: true });
      } catch {
        navigate(fallbackRedirect, { replace: true });
      }
    } catch (err) {
      const msg =
        err instanceof ShoplanserApiError
          ? err.message
          : err instanceof Error
            ? err.message
            : "تعذّر تسجيل الدخول";
      toast({ title: "فشل تسجيل الدخول", description: msg, variant: "destructive" });
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-muted/30 p-4">
      <SEO title="تسجيل الدخول" description="ادخل إلى حسابك للوصول إلى طلباتك وعناوينك" />
      <Card className="w-full max-w-md shadow-soft">
        <CardHeader>
          <div className="flex items-center gap-2 mb-2">
            <Button
              type="button"
              variant="ghost"
              size="icon"
              onClick={() => (window.history.length > 1 ? navigate(-1) : navigate(`/${storeSlug}`))}
              aria-label="رجوع"
              className="h-9 w-9"
            >
              <ArrowRight className="h-5 w-5" />
            </Button>
            <CardTitle className="text-2xl font-extrabold">تسجيل الدخول</CardTitle>
          </div>
          <CardDescription>
            ادخل برقم هاتفك وكلمة المرور للوصول إلى حسابك.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={onSubmit} className="space-y-3">
            <div className="space-y-1">
              <Label htmlFor="phone">رقم الهاتف</Label>
              <Input
                id="phone"
                type="tel"
                inputMode="tel"
                autoComplete="tel"
                required
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                placeholder="+20…"
                dir="ltr"
              />
            </div>
            <div className="space-y-1">
              <Label htmlFor="pw">كلمة المرور</Label>
              <Input
                id="pw"
                type="password"
                autoComplete="current-password"
                required
                minLength={4}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            </div>
            <Button type="submit" className="w-full" disabled={busy}>
              {busy && <Loader2 className="me-2 h-4 w-4 animate-spin" />}
              دخول
            </Button>
          </form>
          <p className="text-sm text-muted-foreground text-center mt-4">
            ليس لديك حساب؟{" "}
            <Link
              to={`/${storeSlug}/register${requestedRedirect ? `?redirect=${encodeURIComponent(safeRedirect)}` : ""}`}
              className="text-primary hover:underline"
            >
              أنشئ حساباً جديداً
            </Link>
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
