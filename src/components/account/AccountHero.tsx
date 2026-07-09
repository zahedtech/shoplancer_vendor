import { useState } from "react";
import { Smartphone, LogOut } from "lucide-react";
import { useTranslation } from "react-i18next";
import { useCart } from "@/context/CartContext";
import { PhoneSyncDialog } from "@/components/PhoneSyncDialog";
import { Button } from "@/components/ui/button";
import { toast } from "sonner";

interface Props {
  userName?: string;
}

export const AccountHero = ({ userName }: Props) => {
  const { linkedPhone, unlinkPhone } = useCart();
  const { t } = useTranslation();
  const [open, setOpen] = useState(false);

  return (
    <>
      <div className="rounded-3xl bg-primary text-primary-foreground p-5 shadow-card relative overflow-hidden">
        <div
          aria-hidden
          className="absolute -top-8 -left-8 h-32 w-32 rounded-full bg-primary-foreground/10"
        />
        <div className="relative flex items-center gap-4">
          <div className="h-16 w-16 rounded-full bg-primary-foreground/15 flex items-center justify-center shrink-0">
            <Smartphone className="h-8 w-8" />
          </div>
          <div className="flex-1 min-w-0">
            {linkedPhone ? (
              <>
                <p className="font-extrabold text-base truncate">
                  {userName?.trim() || t("account.welcomeBack")}
                </p>
                <p className="text-xs opacity-90 mt-0.5" dir="ltr">
                  {linkedPhone}
                </p>
              </>
            ) : (
              <>
                <p className="font-extrabold text-base">{t("account.guestMode")}</p>
                <p className="text-xs opacity-90 mt-0.5">
                  {t("account.linkPhoneCta")}
                </p>
              </>
            )}
          </div>
          {linkedPhone ? (
            <Button
              variant="secondary"
              size="sm"
              className="rounded-full h-9 font-bold shrink-0"
              onClick={() => {
                unlinkPhone();
                toast.success(t("account.signOutSuccess"));
              }}
            >
              <LogOut className="h-4 w-4" />
              {t("account.signOut")}
            </Button>
          ) : (
            <Button
              variant="secondary"
              size="sm"
              className="rounded-full h-9 font-bold shrink-0"
              onClick={() => setOpen(true)}
            >
              {t("account.linkMyPhone")}
            </Button>
          )}
        </div>
      </div>

      <PhoneSyncDialog open={open} onOpenChange={setOpen} />
    </>
  );
};
