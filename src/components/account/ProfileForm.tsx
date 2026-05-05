import { useState } from "react";
import { toast } from "sonner";
import { Save } from "lucide-react";
import { useTranslation } from "react-i18next";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { getProfile, saveProfile } from "@/lib/profile";
import { useCart } from "@/context/CartContext";

export const ProfileForm = () => {
  const { linkedPhone } = useCart();
  const { t } = useTranslation();
  const initial = getProfile();
  const [name, setName] = useState(initial.name ?? "");
  const [email, setEmail] = useState(initial.email ?? "");
  const [notes, setNotes] = useState(initial.notes ?? "");

  const submit = () => {
    saveProfile({
      name: name.trim(),
      email: email.trim() || undefined,
      notes: notes.trim() || undefined,
    });
    toast.success(t("account.profile.saved"));
  };

  return (
    <div className="rounded-2xl bg-card border border-border p-4 space-y-3">
      <div className="space-y-1.5">
        <Label htmlFor="p-name">{t("account.profile.nameLabel")}</Label>
        <Input
          id="p-name"
          placeholder={t("account.profile.namePlaceholder")}
          value={name}
          onChange={(e) => setName(e.target.value)}
        />
      </div>
      <div className="space-y-1.5">
        <Label htmlFor="p-phone">{t("account.profile.phoneLabel")}</Label>
        <Input
          id="p-phone"
          dir="ltr"
          value={linkedPhone ?? ""}
          disabled
          placeholder={t("account.profile.phoneNotLinked")}
        />
        <p className="text-[11px] text-muted-foreground">
          {linkedPhone
            ? t("account.profile.phoneHintLinked")
            : t("account.profile.phoneHintUnlinked")}
        </p>
      </div>
      <div className="space-y-1.5">
        <Label htmlFor="p-email">{t("account.profile.emailLabel")}</Label>
        <Input
          id="p-email"
          type="email"
          dir="ltr"
          placeholder="you@example.com"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
        />
      </div>
      <div className="space-y-1.5">
        <Label htmlFor="p-notes">{t("account.profile.notesLabel")}</Label>
        <Textarea
          id="p-notes"
          placeholder={t("account.profile.notesPlaceholder")}
          rows={2}
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
        />
      </div>
      <Button
        type="button"
        onClick={submit}
        className="w-full h-11 rounded-full font-bold gap-2"
      >
        <Save className="h-4 w-4" />
        {t("account.profile.save")}
      </Button>
    </div>
  );
};
