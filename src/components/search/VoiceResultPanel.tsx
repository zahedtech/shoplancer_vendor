import { useEffect, useMemo, useState } from "react";
import { CheckCircle2, AlertCircle, Plus, ShoppingCart, X, Share2, ChevronDown, Copy, Check } from "lucide-react";
import { Product, formatPrice, getDiscountedPrice } from "@/lib/api";
import { useCart } from "@/context/CartContext";
import { useStore } from "@/context/StoreContext";
import { cleanTranscript, getCleanOptions } from "@/lib/voiceSearchHistory";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

type ShareMode = "link" | "list" | "list_prices";
const SHARE_MODE_KEY = "voice_share_mode_v1";
function readShareMode(): ShareMode {
  try {
    const v = localStorage.getItem(SHARE_MODE_KEY) as ShareMode | null;
    if (v === "link" || v === "list" || v === "list_prices") return v;
  } catch {
    /* ignore */
  }
  return "link";
}

export interface VoiceMatch {
  raw: string;
  name: string;
  quantity: number;
  unit?: string | null;
  productId: number | null;
  available: boolean;
  suggestionIds: number[];
}

interface Props {
  transcript: string;
  matches: VoiceMatch[];
  productsById: Map<number, Product>;
  onClose: () => void;
}

export const VoiceResultPanel = ({
  transcript,
  matches,
  productsById,
  onClose,
}: Props) => {
  const { addItem, items: cartItems } = useCart();
  const { store, slug } = useStore();
  const [shareMode, setShareMode] = useState<ShareMode>(() => readShareMode());
  const [copied, setCopied] = useState(false);

  const cleanedTranscript = useMemo(
    () => cleanTranscript(transcript, getCleanOptions()),
    [transcript],
  );

  useEffect(() => {
    try {
      localStorage.setItem(SHARE_MODE_KEY, shareMode);
    } catch {
      /* ignore */
    }
  }, [shareMode]);

  const copyCleaned = async () => {
    try {
      await navigator.clipboard.writeText(cleanedTranscript);
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    } catch {
      /* ignore */
    }
  };

  const matched = useMemo(
    () =>
      matches
        .map((m) => ({ m, p: m.productId ? productsById.get(m.productId) : undefined }))
        .filter((r) => r.p),
    [matches, productsById],
  );
  const missing = matches.filter((m) => !m.productId || !productsById.get(m.productId));

  const shareUrl = useMemo(() => {
    const base = `${window.location.origin}/${slug}/search`;
    return `${base}?voice=${encodeURIComponent(transcript)}`;
  }, [slug, transcript]);

  const buildShareText = (mode: ShareMode): string => {
    if (mode === "link") {
      return `🛒 ${store?.name ?? "متجر"} — شوف نتائج بحثي:\n${shareUrl}`;
    }
    const lines: string[] = [];
    lines.push(`🛒 ${store?.name ?? "متجر"} — نتائج بحثي الصوتي:`);
    lines.push(`«${transcript}»`);
    lines.push("");
    if (matched.length > 0) {
      lines.push("✅ المتوفّر:");
      matched.forEach(({ p, m }) => {
        if (!p) return;
        const qty = Math.max(1, Math.round(m.quantity));
        if (mode === "list_prices") {
          const price = getDiscountedPrice(p).final;
          lines.push(`• ${p.name} × ${qty} — ${formatPrice(price * qty)}`);
        } else {
          lines.push(`• ${p.name} × ${qty}`);
        }
      });
    }
    if (missing.length > 0) {
      lines.push("");
      lines.push("❌ غير متوفر:");
      missing.forEach((m) => lines.push(`• ${m.name}`));
    }
    lines.push("");
    lines.push(shareUrl);
    return lines.join("\n");
  };

  const shareWhatsApp = (mode: ShareMode = shareMode) => {
    const text = encodeURIComponent(buildShareText(mode));
    window.open(`https://wa.me/?text=${text}`, "_blank", "noopener,noreferrer");
  };

  const shareModeLabel: Record<ShareMode, string> = {
    link: "رابط فقط",
    list: "رابط + قائمة المنتجات",
    list_prices: "رابط + المنتجات + الأسعار",
  };

  const addAll = () => {
    matched.forEach(({ p, m }) => {
      if (!p || !m.available) return;
      const qty = Math.max(1, Math.round(m.quantity));
      const existing = cartItems.find((i) => i.id === p.id);
      const current = existing?.quantity ?? 0;
      // Add up to the requested quantity
      for (let i = current; i < current + qty; i++) {
        addItem(p);
      }
    });
    onClose();
  };

  return (
    <div className="rounded-2xl border border-border bg-card shadow-card overflow-hidden">
      <div className="flex items-start justify-between gap-3 px-4 py-3 border-b border-border bg-primary-soft/40">
        <div className="min-w-0">
          <p className="text-xs font-bold text-primary">فهمنا طلبك</p>
          <p className="text-sm text-foreground line-clamp-2 mt-0.5">{transcript}</p>
        </div>
        <div className="shrink-0 flex items-center gap-1.5">
          <button
            type="button"
            onClick={copyCleaned}
            aria-label="نسخ النص المُنظّف"
            title={copied ? "تم النسخ" : `نسخ: ${cleanedTranscript}`}
            className="h-7 px-2 rounded-full bg-background/60 hover:bg-background flex items-center gap-1 text-[10.5px] font-bold text-foreground transition-smooth"
          >
            {copied ? (
              <>
                <Check className="h-3.5 w-3.5 text-fresh" />
                تم
              </>
            ) : (
              <>
                <Copy className="h-3.5 w-3.5" />
                نسخ النص
              </>
            )}
          </button>
          <button
            type="button"
            onClick={onClose}
            aria-label="إغلاق"
            className="h-7 w-7 rounded-full bg-background/60 hover:bg-background flex items-center justify-center"
          >
            <X className="h-4 w-4" />
          </button>
        </div>
      </div>

      <ul className="divide-y divide-border">
        {matches.map((m, idx) => {
          const p = m.productId ? productsById.get(m.productId) : undefined;
          const price = p ? getDiscountedPrice(p).final : 0;
          return (
            <li key={idx} className="px-4 py-3 flex items-center gap-3">
              {p?.image_full_url ? (
                <img
                  src={p.image_full_url}
                  alt={p.name}
                  loading="lazy"
                  className="h-12 w-12 rounded-lg object-cover bg-muted"
                />
              ) : (
                <div className="h-12 w-12 rounded-lg bg-muted flex items-center justify-center">
                  <AlertCircle className="h-5 w-5 text-muted-foreground" />
                </div>
              )}
              <div className="flex-1 min-w-0">
                <p className="text-sm font-bold text-foreground truncate">
                  {p?.name ?? m.name}
                </p>
                <p className="text-[11px] text-muted-foreground truncate">
                  من نصّك: «{m.raw}» · كمية {m.quantity}
                  {m.unit ? ` ${m.unit}` : ""}
                </p>
              </div>
              <div className="text-left shrink-0">
                {p ? (
                  <>
                    <p className="text-sm font-extrabold text-primary">
                      {formatPrice(price * Math.max(1, Math.round(m.quantity)))}
                    </p>
                    <p className="text-[10px] text-fresh flex items-center gap-1 justify-end">
                      <CheckCircle2 className="h-3 w-3" />
                      متاح
                    </p>
                  </>
                ) : (
                  <p className="text-[11px] text-destructive font-bold flex items-center gap-1">
                    <AlertCircle className="h-3 w-3" />
                    غير متاح
                  </p>
                )}
              </div>
              {p && (
                <button
                  type="button"
                  onClick={() => {
                    const qty = Math.max(1, Math.round(m.quantity));
                    for (let i = 0; i < qty; i++) addItem(p);
                  }}
                  className="shrink-0 h-8 w-8 rounded-full bg-primary text-primary-foreground inline-flex items-center justify-center hover:shadow-glow transition-smooth"
                  aria-label="إضافة"
                >
                  <Plus className="h-4 w-4" />
                </button>
              )}
            </li>
          );
        })}
      </ul>

      <div className="px-4 py-3 border-t border-border bg-secondary/40 flex items-center justify-between gap-2 flex-wrap">
        <p className="text-[11px] text-muted-foreground">
          {matched.length} متاح · {missing.length} غير متاح
        </p>
        <div className="flex items-center gap-2">

          <button
            type="button"
            onClick={addAll}
            disabled={matched.length === 0}
            className="inline-flex items-center gap-2 bg-primary text-primary-foreground h-10 px-4 rounded-full font-bold text-sm shadow-soft hover:shadow-glow transition-smooth disabled:opacity-50"
          >
            <ShoppingCart className="h-4 w-4" />
            إضافة الكل للسلة
          </button>
        </div>
      </div>
    </div>
  );
};
