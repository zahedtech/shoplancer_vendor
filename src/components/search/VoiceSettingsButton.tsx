import { useState } from "react";
import { Settings2 } from "lucide-react";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Switch } from "@/components/ui/switch";
import { Label } from "@/components/ui/label";
import { Slider } from "@/components/ui/slider";
import { Button } from "@/components/ui/button";
import {
  DEFAULT_LISTEN_OPTS,
  setVoiceListenOptions,
  type VoiceListenOptions,
} from "@/lib/voiceSearchHistory";

interface Props {
  value: VoiceListenOptions;
  onChange: (v: VoiceListenOptions) => void;
}

const SILENCE_STEPS = [0, 3000, 5000, 8000];
const MIN_LEN_STEPS = [0, 2, 4];

const silenceLabel = (ms: number) =>
  ms === 0 ? "إيقاف" : `${Math.round(ms / 1000)}ث`;

const minLenLabel = (n: number) => (n === 0 ? "بدون حد" : `${n} أحرف`);

/**
 * Compact gear button -> popover with voice listening preferences:
 *   - autoSubmit: run AI search automatically after speech ends
 *   - silenceTimeoutMs: auto-stop the mic after N seconds of silence
 *   - minLength: ignore very short transcripts (likely noise)
 *
 * Settings persist via setVoiceListenOptions on every change so the
 * choice carries across reloads.
 */
export const VoiceSettingsButton = ({ value, onChange }: Props) => {
  const [open, setOpen] = useState(false);

  const update = (patch: Partial<VoiceListenOptions>) => {
    const next = { ...value, ...patch };
    onChange(next);
    setVoiceListenOptions(next);
  };

  const silenceIndex = Math.max(
    0,
    SILENCE_STEPS.indexOf(value.silenceTimeoutMs),
  );
  const minLenIndex = Math.max(0, MIN_LEN_STEPS.indexOf(value.minLength));

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <button
          type="button"
          aria-label="إعدادات البحث الصوتي"
          className="inline-flex h-8 w-8 items-center justify-center rounded-full bg-secondary text-muted-foreground hover:text-foreground transition-smooth"
        >
          <Settings2 className="h-4 w-4" />
        </button>
      </PopoverTrigger>
      <PopoverContent
        align="end"
        sideOffset={8}
        className="w-72 p-4 space-y-4 rtl"
        dir="rtl"
      >
        <div>
          <h4 className="text-sm font-extrabold mb-1">إعدادات الصوت</h4>
          <p className="text-[11px] text-muted-foreground">
            تحكّم بكيفية استماع الميكروفون ومعالجة الكلام.
          </p>
        </div>

        {/* Auto-submit */}
        <div className="flex items-start justify-between gap-3">
          <div className="space-y-0.5">
            <Label htmlFor="voice-auto-submit" className="text-xs font-bold">
              معالجة تلقائية بعد التحدث
            </Label>
            <p className="text-[10px] text-muted-foreground leading-tight">
              عند الإيقاف، ابحث فوراً بدون نقرة إضافية.
            </p>
          </div>
          <Switch
            id="voice-auto-submit"
            checked={value.autoSubmit}
            onCheckedChange={(v) => update({ autoSubmit: v })}
          />
        </div>

        {/* Silence timeout */}
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <Label className="text-xs font-bold">مهلة الصمت</Label>
            <span className="text-[11px] font-extrabold text-primary">
              {silenceLabel(value.silenceTimeoutMs)}
            </span>
          </div>
          <Slider
            min={0}
            max={SILENCE_STEPS.length - 1}
            step={1}
            value={[silenceIndex]}
            onValueChange={([i]) =>
              update({ silenceTimeoutMs: SILENCE_STEPS[i] ?? 5000 })
            }
          />
          <p className="text-[10px] text-muted-foreground leading-tight">
            يوقف الميكروفون تلقائياً بعد فترة من الصمت.
          </p>
        </div>

        {/* Min length */}
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <Label className="text-xs font-bold">الحد الأدنى للنص</Label>
            <span className="text-[11px] font-extrabold text-primary">
              {minLenLabel(value.minLength)}
            </span>
          </div>
          <Slider
            min={0}
            max={MIN_LEN_STEPS.length - 1}
            step={1}
            value={[minLenIndex]}
            onValueChange={([i]) =>
              update({ minLength: MIN_LEN_STEPS[i] ?? 2 })
            }
          />
          <p className="text-[10px] text-muted-foreground leading-tight">
            يتجاهل الالتقاطات القصيرة جداً (ضوضاء أو خطأ).
          </p>
        </div>

        <div className="flex items-center justify-between pt-2 border-t border-border">
          <Button
            variant="ghost"
            size="sm"
            className="h-7 text-[11px]"
            onClick={() => {
              onChange({ ...DEFAULT_LISTEN_OPTS });
              setVoiceListenOptions({ ...DEFAULT_LISTEN_OPTS });
            }}
          >
            استعادة الافتراضي
          </Button>
          <Button
            size="sm"
            className="h-7 text-[11px]"
            onClick={() => setOpen(false)}
          >
            تم
          </Button>
        </div>
      </PopoverContent>
    </Popover>
  );
};
