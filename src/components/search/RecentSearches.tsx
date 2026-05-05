import { useState } from "react";
import { Clock, Trash2, X } from "lucide-react";
import { useTranslation } from "react-i18next";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";

interface Props {
  items: string[];
  onPick: (q: string) => void;
  onClear: () => void;
}

export const RecentSearches = ({ items, onPick, onClear }: Props) => {
  const { t } = useTranslation();
  const [confirmOpen, setConfirmOpen] = useState(false);
  if (items.length === 0) return null;
  return (
    <section className="space-y-3">
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-extrabold text-foreground flex items-center gap-2">
          <Clock className="h-4 w-4 text-muted-foreground" />
          {t("recentSearches.title")}
        </h3>
        <button
          type="button"
          onClick={() => setConfirmOpen(true)}
          aria-label="مسح سجل البحث"
          className="inline-flex items-center gap-1 text-xs text-muted-foreground hover:text-destructive transition-smooth"
        >
          <Trash2 className="h-3.5 w-3.5" />
          {t("recentSearches.clearAll")}
        </button>
      </div>
      <div className="flex flex-wrap gap-2">
        {items.map((q) => (
          <button
            key={q}
            type="button"
            onClick={() => onPick(q)}
            className="inline-flex items-center gap-1.5 px-3 h-8 rounded-full bg-secondary text-secondary-foreground text-xs font-bold hover:bg-primary-soft transition-smooth"
          >
            {q}
            <X className="h-3 w-3 opacity-50" />
          </button>
        ))}
      </div>

      <AlertDialog open={confirmOpen} onOpenChange={setConfirmOpen}>
        <AlertDialogContent className="max-w-sm">
          <AlertDialogHeader>
            <AlertDialogTitle>مسح سجل البحث؟</AlertDialogTitle>
            <AlertDialogDescription>
              سيتم حذف جميع كلمات البحث السابقة. لا يمكن التراجع عن هذا الإجراء.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>إلغاء</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => {
                onClear();
                setConfirmOpen(false);
              }}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              نعم، امسح
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </section>
  );
};

