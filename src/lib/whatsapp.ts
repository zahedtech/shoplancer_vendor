/**
 * Build a WhatsApp click-to-chat URL.
 * Strips non-digits from `phone` and URL-encodes `message`.
 */
export function buildWhatsAppUrl(phone: string, message: string): string {
  const clean = (phone ?? "").replace(/[^\d]/g, "");
  return `https://wa.me/${clean}?text=${encodeURIComponent(message)}`;
}

interface OrderMessageOpts {
  storeName?: string;
  productName: string;
  size?: string | null;
  price?: string;
  url?: string;
}

/** Build a "اطلب بالمقاس" message for clothing stores. */
export function buildOrderBySizeMessage(opts: OrderMessageOpts): string {
  const lines = [
    "مرحباً، أرغب بطلب:",
    `🛍️ ${opts.productName}`,
  ];
  if (opts.size) lines.push(`📏 المقاس: ${opts.size}`);
  if (opts.price) lines.push(`💰 السعر: ${opts.price}`);
  if (opts.url) lines.push(`🔗 ${opts.url}`);
  if (opts.storeName) lines.push(`— ${opts.storeName}`);
  return lines.join("\n");
}
