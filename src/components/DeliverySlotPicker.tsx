import { Clock } from "lucide-react";
import { useMemo } from "react";
import { useTranslation } from "react-i18next";
import { cn } from "@/lib/utils";
import type { DeliverySlot } from "@/lib/orders";

interface Props {
  value: DeliverySlot | null;
  onChange: (slot: DeliverySlot) => void;
  error?: string;
}

export const DeliverySlotPicker = ({ value, onChange, error }: Props) => {
  const { t } = useTranslation();

  const DAYS: { key: DeliverySlot["day"]; label: string }[] = useMemo(
    () => [
      { key: "today", label: t("deliverySlot.today") },
      { key: "tomorrow", label: t("deliverySlot.tomorrow") },
      { key: "after_tomorrow", label: t("deliverySlot.afterTomorrow") },
    ],
    [t],
  );

  const ASAP = t("deliverySlot.asap");
  const WINDOWS = useMemo(
    () => [ASAP, "10:00 - 12:00", "12:00 - 14:00", "14:00 - 16:00", "16:00 - 18:00", "18:00 - 20:00"],
    [ASAP],
  );

  const day = value?.day ?? "today";
  const dayLabel = DAYS.find((d) => d.key === day)?.label ?? t("deliverySlot.today");

  const setDay = (d: DeliverySlot["day"]) => {
    onChange({
      day: d,
      dayLabel: DAYS.find((x) => x.key === d)!.label,
      window: value?.window ?? ASAP,
    });
  };

  const setWindow = (w: string) => {
    onChange({ day, dayLabel, window: w });
  };

  return (
    <div className="space-y-2">
      <div className="flex items-center gap-2 text-sm font-bold">
        <Clock className="h-4 w-4 text-primary" />
        <span>{t("deliverySlot.preferredTime")}</span>
      </div>

      <div className="flex gap-2">
        {DAYS.map((d) => (
          <button
            key={d.key}
            type="button"
            onClick={() => setDay(d.key)}
            className={cn(
              "flex-1 h-10 rounded-full text-sm font-bold border transition-smooth",
              day === d.key
                ? "bg-primary text-primary-foreground border-primary shadow-soft"
                : "bg-background text-foreground border-border hover:border-primary/50",
            )}
          >
            {d.label}
          </button>
        ))}
      </div>

      <div className="grid grid-cols-2 gap-2">
        {WINDOWS.map((w) => {
          const selected = value?.window === w;
          return (
            <button
              key={w}
              type="button"
              onClick={() => setWindow(w)}
              dir="ltr"
              className={cn(
                "h-10 rounded-xl text-sm font-bold border transition-smooth",
                selected
                  ? "bg-primary-soft text-primary border-primary"
                  : "bg-background text-foreground border-border hover:border-primary/50",
                w === ASAP && "col-span-2",
              )}
            >
              <span dir="auto">{w}</span>
            </button>
          );
        })}
      </div>

      {error && <p className="text-xs text-destructive">{error}</p>}
    </div>
  );
};
