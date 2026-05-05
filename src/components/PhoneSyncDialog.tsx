import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { useState } from "react";
import { useTranslation } from "react-i18next";
import { useCart } from "@/context/CartContext";
import { Smartphone, Link2Off } from "lucide-react";
import { toast } from "sonner";

interface Props {
  open: boolean;
  onOpenChange: (v: boolean) => void;
}

export const PhoneSyncDialog = ({ open, onOpenChange }: Props) => {
  const { linkedPhone, linkPhone, unlinkPhone } = useCart();
  const { t } = useTranslation();
  const [phone, setPhone] = useState(linkedPhone ?? "");
  const [submitting, setSubmitting] = useState(false);

  const handleLink = async () => {
    const trimmed = phone.trim();
    if (!/^[0-9+\-\s]{7,20}$/.test(trimmed)) {
      toast.error(t("phoneSync.invalidPhone"));
      return;
    }
    setSubmitting(true);
    try {
      await linkPhone(trimmed);
      toast.success(t("phoneSync.linkedSuccessTitle"), {
        description: t("phoneSync.linkedSuccessDesc"),
      });
      onOpenChange(false);
    } catch {
      toast.error(t("phoneSync.linkFailed"));
    } finally {
      setSubmitting(false);
    }
  };

  const handleUnlink = () => {
    unlinkPhone();
    toast.success(t("phoneSync.unlinkedSuccess"));
    onOpenChange(false);
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-sm">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Smartphone className="h-5 w-5 text-primary" />
            {t("phoneSync.title")}
          </DialogTitle>
          <DialogDescription>{t("phoneSync.description")}</DialogDescription>
        </DialogHeader>

        <div className="space-y-3">
          <div className="space-y-1.5">
            <Label htmlFor="sync-phone">{t("phoneSync.phoneLabel")}</Label>
            <Input
              id="sync-phone"
              type="tel"
              dir="ltr"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              placeholder="01xxxxxxxxx"
              maxLength={20}
            />
          </div>

          <Button
            onClick={handleLink}
            disabled={submitting}
            className="w-full h-11 rounded-full font-bold"
          >
            {submitting
              ? t("phoneSync.linking")
              : linkedPhone
                ? t("phoneSync.update")
                : t("phoneSync.link")}
          </Button>

          {linkedPhone && (
            <Button
              onClick={handleUnlink}
              variant="ghost"
              className="w-full h-10 rounded-full text-muted-foreground"
            >
              <Link2Off className="h-4 w-4 ms-1.5" />
              {t("phoneSync.unlink")}
            </Button>
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
};
