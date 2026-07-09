import { toast } from "sonner";
import type { RemoteOrder } from "@/lib/shoplanserApi";
import type { Product } from "@/lib/api";
import type { AddItemOptions } from "@/context/CartContext";

type AddItemFn = (p: Product, opts?: AddItemOptions) => void;

/**
 * Re-add every item from a previous remote order back into the cart.
 * Skips lines that don't have enough info to reconstruct a Product.
 *
 * Returns counts so the caller can show a toast / open the cart.
 */
export function reorderFromRemoteOrder(
  order: RemoteOrder | null | undefined,
  addItem: AddItemFn,
): { added: number; skipped: number } {
  if (!order || !Array.isArray(order.details) || order.details.length === 0) {
    toast.error("لا توجد تفاصيل لإعادة هذا الطلب");
    return { added: 0, skipped: 0 };
  }

  let added = 0;
  let skipped = 0;

  for (const line of order.details) {
    const id = Number(line.id);
    const name = line.item_details?.name ?? "";
    const image = line.item_details?.image_full_url ?? "";
    const price = Number(line.price ?? 0);
    const quantity = Math.max(1, Math.floor(Number(line.quantity ?? 1)));
    if (!id || !name || !Number.isFinite(price)) {
      skipped += 1;
      continue;
    }
    const product: Product = {
      id,
      name,
      description: "",
      image_full_url: image,
      price,
      discount: 0,
      discount_type: "amount",
      category_id: 0,
      category_ids: [],
      avg_rating: 0,
      rating_count: 0,
      stock: 99,
    };
    try {
      addItem(product, { quantity });
      added += 1;
    } catch {
      skipped += 1;
    }
  }

  if (added > 0) {
    toast.success(
      skipped > 0
        ? `تمت إضافة ${added} منتج، وتعذّر إضافة ${skipped}`
        : `تمت إضافة ${added} منتج إلى السلة`,
    );
  } else {
    toast.error("تعذّرت إعادة هذا الطلب");
  }

  return { added, skipped };
}
