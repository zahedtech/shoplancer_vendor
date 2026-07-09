import { ReactNode, useState } from "react";
import { Download, Share, Plus, Smartphone, Zap, Bell } from "lucide-react";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetDescription,
} from "@/components/ui/sheet";
import { Button } from "@/components/ui/button";
import { useInstallPrompt } from "@/hooks/useInstallPrompt";

interface InstallGateProps {
  /** Trigger element. Cloned with onClick that opens the gate first. */
  children: ReactNode;
  /** Action to run after the user installs OR chooses to skip. */
  onProceed: () => void;
  /** Optional one-line reason shown in the sheet body. */
  reason?: string;
  /** Sheet title. */
  title?: string;
}

const SESSION_KEY = "installGate:skippedAt";
const SKIP_TTL_MS = 1000 * 60 * 30; // 30 minutes

function recentlySkipped(): boolean {
  try {
    const raw = sessionStorage.getItem(SESSION_KEY);
    if (!raw) return false;
    const ts = Number(raw);
    return Number.isFinite(ts) && Date.now() - ts < SKIP_TTL_MS;
  } catch {
    return false;
  }
}

/**
 * Wraps a trigger element. When clicked:
 *   - If the app is already installed (standalone) → runs `onProceed`.
 *   - If the user dismissed or skipped recently → runs `onProceed`.
 *   - Otherwise opens a Sheet inviting them to install. They can install
 *     and continue, or skip and continue.
 */
export const InstallGate = ({
  children,
  onProceed,
  reason,
  title = "ثبّت تطبيق المتجر",
}: InstallGateProps) => {
  const {
    isStandalone,
    canInstall,
    isIOS,
    shouldShowIOSHint,
    promptInstall,
    dismiss,
  } = useInstallPrompt();
  const [open, setOpen] = useState(false);

  const showInstallHint = (canInstall || shouldShowIOSHint) && !isStandalone;

  const handleTrigger = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (isStandalone || !showInstallHint || recentlySkipped()) {
      onProceed();
      return;
    }
    setOpen(true);
  };

  const handleInstall = async () => {
    if (canInstall) {
      const accepted = await promptInstall();
      setOpen(false);
      // Continue with the original action either way (don't block the user).
      onProceed();
      return;
    }
    // iOS — just close; user follows the on-screen instructions.
    setOpen(false);
    onProceed();
  };

  const handleSkip = () => {
    try {
      sessionStorage.setItem(SESSION_KEY, String(Date.now()));
    } catch {
      /* ignore */
    }
    setOpen(false);
    onProceed();
  };

  const handleNeverAsk = () => {
    dismiss();
    setOpen(false);
    onProceed();
  };

  return (
    <>
      <span onClick={handleTrigger} className="contents">
        {children}
      </span>

      <Sheet open={open} onOpenChange={setOpen}>
        <SheetContent
          side="bottom"
          className="rounded-t-3xl px-5 pb-6 pt-5 max-h-[85vh] overflow-y-auto"
        >
          <SheetHeader className="text-right space-y-3">
            <div className="mx-auto h-14 w-14 rounded-2xl bg-primary/15 text-primary flex items-center justify-center">
              <Smartphone className="h-7 w-7" />
            </div>
            <SheetTitle className="text-center text-xl font-extrabold">
              {title}
            </SheetTitle>
            <SheetDescription className="text-center text-sm">
              {reason ??
                "احصل على تجربة أسرع وأسهل من شاشتك الرئيسية مباشرة."}
            </SheetDescription>
          </SheetHeader>

          {/* Benefits */}
          <ul className="mt-5 space-y-2.5">
            <BenefitRow
              icon={<Zap className="h-4 w-4" />}
              text="فتح بنقرة واحدة وتجربة أسرع"
            />
            <BenefitRow
              icon={<Bell className="h-4 w-4" />}
              text="تنبيهات حالة طلبك أولاً بأول"
            />
            <BenefitRow
              icon={<Download className="h-4 w-4" />}
              text="بدون متجر تطبيقات — تثبيت مباشر"
            />
          </ul>

          {/* iOS hint */}
          {isIOS && !canInstall && (
            <div className="mt-5 rounded-2xl bg-muted/60 border border-border p-3 text-xs text-foreground space-y-1.5">
              <p className="font-extrabold">لتثبيت التطبيق على iPhone:</p>
              <p className="flex items-center gap-1.5 text-muted-foreground">
                <span>1.</span> اضغط على
                <Share className="h-4 w-4 text-primary" />
                <span>زر المشاركة في Safari</span>
              </p>
              <p className="flex items-center gap-1.5 text-muted-foreground">
                <span>2.</span> اختر
                <Plus className="h-4 w-4 text-primary" />
                <span className="font-bold">"إضافة إلى الشاشة الرئيسية"</span>
              </p>
            </div>
          )}

          <div className="mt-6 flex flex-col gap-2">
            <Button
              size="lg"
              onClick={handleInstall}
              className="w-full font-extrabold"
            >
              <Download className="me-2 h-4 w-4" />
              {canInstall ? "تثبيت الآن" : "فهمت"}
            </Button>
            <Button
              variant="outline"
              size="lg"
              onClick={handleSkip}
              className="w-full font-bold"
            >
              متابعة بدون تثبيت
            </Button>
            <button
              type="button"
              onClick={handleNeverAsk}
              className="text-[11px] text-muted-foreground hover:text-foreground mt-1"
            >
              لا تذكّرني مجدداً
            </button>
          </div>
        </SheetContent>
      </Sheet>
    </>
  );
};

const BenefitRow = ({
  icon,
  text,
}: {
  icon: ReactNode;
  text: string;
}) => (
  <li className="flex items-center gap-3 rounded-xl bg-secondary/40 border border-border px-3 py-2">
    <span className="h-7 w-7 rounded-full bg-primary/15 text-primary inline-flex items-center justify-center shrink-0">
      {icon}
    </span>
    <span className="text-sm font-bold text-foreground">{text}</span>
  </li>
);
