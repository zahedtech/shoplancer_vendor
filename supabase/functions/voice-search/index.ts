// Voice/Smart-Search edge function
// Input: { transcript: string, products: [{id,name,unit,price,available,category}] }
// Output: { items: [{ raw, name, quantity, unit, productId|null, suggestionIds:number[] }] }
//
// Uses Lovable AI Gateway (no extra API keys). Falls back to a simple Arabic
// keyword matcher if the AI call fails so the feature still works.

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-supabase-client-platform, x-supabase-client-platform-version, x-supabase-client-runtime, x-supabase-client-runtime-version",
};

interface InProduct {
  id: number;
  name: string;
  unit?: string | null;
  price?: number;
  available?: boolean;
}

interface ExtractedItem {
  raw: string;
  name: string;
  quantity: number;
  unit?: string | null;
}

// --- Arabic normalization (handles diacritics, alef variants, taa marbuta, ya) ---
function normalizeAr(input: string): string {
  return (input || "")
    .toLowerCase()
    .replace(/[\u064B-\u0652\u0670]/g, "") // diacritics
    .replace(/[إأآا]/g, "ا")
    .replace(/ى/g, "ي")
    .replace(/ؤ/g, "و")
    .replace(/ئ/g, "ي")
    .replace(/ة/g, "ه")
    .replace(/[^\p{L}\p{N}\s]/gu, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function tokenScore(query: string, name: string): number {
  const q = normalizeAr(query);
  const n = normalizeAr(name);
  if (!q || !n) return 0;
  if (n.includes(q)) return 1;
  if (q.includes(n)) return 0.9;
  const qt = q.split(" ").filter(Boolean);
  const nt = n.split(" ").filter(Boolean);
  let hits = 0;
  for (const t of qt) {
    if (nt.some((x) => x.includes(t) || t.includes(x))) hits++;
  }
  return hits / Math.max(qt.length, 1) * 0.85;
}

function findMatches(name: string, products: InProduct[]) {
  const scored = products
    .map((p) => ({ p, s: tokenScore(name, p.name) }))
    .filter((r) => r.s > 0.3)
    .sort((a, b) => b.s - a.s);
  const best = scored[0]?.p ?? null;
  const suggestions = scored.slice(0, 5).map((r) => r.p.id);
  return { best, suggestions };
}

// Naïve Arabic extractor used as fallback when the AI call fails.
function fallbackExtract(transcript: string): ExtractedItem[] {
  const norm = normalizeAr(transcript);
  // Strip common verbs ("بدي", "اريد", "عايز", "محتاج")
  const cleaned = norm
    .replace(/\b(بدي|اريد|عايز|عاوز|محتاج|من فضلك|لو سمحت|اضف|ضيف)\b/g, "")
    .trim();
  // Split on the Arabic "و" (and) used as token separator
  const parts = cleaned
    .split(/\s+و\s+|،|,|\bو\b/)
    .map((s) => s.trim())
    .filter(Boolean);
  return parts.map((raw) => {
    // Try to detect a quantity word
    let quantity = 1;
    let unit: string | null = null;
    let name = raw;
    const half = /\b(نص|نصف|0\.5|1\/2)\b/.exec(raw);
    const quarter = /\b(ربع|0\.25|1\/4)\b/.exec(raw);
    const num = /\b(\d+(?:\.\d+)?)\b/.exec(raw);
    if (half) quantity = 0.5;
    else if (quarter) quantity = 0.25;
    else if (num) quantity = parseFloat(num[1]);
    if (/كيلو|كجم|كغ/.test(raw)) unit = "kg";
    else if (/لتر|لتر/.test(raw)) unit = "L";
    else if (/علبه|علبة/.test(raw)) unit = "pack";
    else if (/حبه|حبة|قطعه|قطعة/.test(raw)) unit = "pcs";
    name = raw
      .replace(/\b(نص|نصف|ربع|كيلو|كجم|كغ|لتر|علبه|علبة|حبه|حبة|قطعه|قطعة)\b/g, "")
      .replace(/\b\d+(?:\.\d+)?\b/g, "")
      .trim();
    return { raw, name: name || raw, quantity, unit };
  });
}

async function extractWithAI(transcript: string): Promise<ExtractedItem[]> {
  const LOVABLE_API_KEY = Deno.env.get("LOVABLE_API_KEY");
  if (!LOVABLE_API_KEY) throw new Error("LOVABLE_API_KEY missing");

  const body = {
    model: "google/gemini-3-flash-preview",
    messages: [
      {
        role: "system",
        content:
          "أنت مساعد متجر بقالة. مهمتك استخراج قائمة المنتجات والكميات من جملة طلب المستخدم باللهجة العربية (الأردنية/المصرية/الخليجية). أعد فقط استدعاء الأداة extract_grocery_items.",
      },
      { role: "user", content: transcript },
    ],
    tools: [
      {
        type: "function",
        function: {
          name: "extract_grocery_items",
          description: "Extract grocery items with quantities from an Arabic shopping request",
          parameters: {
            type: "object",
            properties: {
              items: {
                type: "array",
                items: {
                  type: "object",
                  properties: {
                    raw: { type: "string", description: "النص الأصلي للعنصر" },
                    name: { type: "string", description: "اسم المنتج المنظف بدون كمية" },
                    quantity: { type: "number", description: "الكمية بالأرقام (نص=0.5، ربع=0.25)" },
                    unit: {
                      type: "string",
                      description: "الوحدة: kg, g, L, ml, pcs, pack, bottle",
                    },
                  },
                  required: ["raw", "name", "quantity"],
                },
              },
            },
            required: ["items"],
          },
        },
      },
    ],
    tool_choice: { type: "function", function: { name: "extract_grocery_items" } },
  };

  const res = await fetch("https://ai.gateway.lovable.dev/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${LOVABLE_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  if (res.status === 429) throw Object.assign(new Error("rate_limited"), { status: 429 });
  if (res.status === 402) throw Object.assign(new Error("payment_required"), { status: 402 });
  if (!res.ok) throw new Error(`AI gateway error ${res.status}`);

  const data = await res.json();
  const call = data.choices?.[0]?.message?.tool_calls?.[0];
  if (!call?.function?.arguments) throw new Error("no tool call");
  const args = JSON.parse(call.function.arguments);
  return Array.isArray(args.items) ? args.items : [];
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });

  try {
    // Require the apikey/Authorization header (the Supabase gateway already
    // enforces this when verify_jwt=false). We don't require a real user
    // session — anon callers (guests) must be able to use voice search.
    const authHeader = req.headers.get("Authorization") ?? req.headers.get("apikey");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { transcript, products = [] } = await req.json();
    if (typeof transcript !== "string" || !transcript.trim()) {
      return new Response(JSON.stringify({ error: "transcript مطلوب" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    // Hard caps to prevent abuse / cost inflation.
    if (transcript.length > 500) {
      return new Response(JSON.stringify({ error: "transcript طويل جداً (الحد 500 حرف)" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    if (!Array.isArray(products) || products.length > 500) {
      return new Response(JSON.stringify({ error: "products يجب أن يكون مصفوفة (الحد 500)" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    let extracted: ExtractedItem[] = [];
    let usedAI = true;
    try {
      extracted = await extractWithAI(transcript);
      if (extracted.length === 0) {
        usedAI = false;
        extracted = fallbackExtract(transcript);
      }
    } catch (err) {
      const status = (err as { status?: number }).status;
      if (status === 429) {
        return new Response(
          JSON.stringify({ error: "تم تجاوز عدد الطلبات، حاول بعد قليل." }),
          { status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }
      if (status === 402) {
        return new Response(
          JSON.stringify({ error: "الرصيد المتوفر للذكاء الصناعي انتهى." }),
          { status: 402, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }
      console.error("AI extract failed, using fallback:", err);
      usedAI = false;
      extracted = fallbackExtract(transcript);
    }

    const items = extracted.map((it) => {
      const { best, suggestions } = findMatches(it.name, products as InProduct[]);
      return {
        raw: it.raw,
        name: it.name,
        quantity: Math.max(it.quantity || 1, 0.25),
        unit: it.unit ?? null,
        productId: best ? best.id : null,
        available: best ? best.available !== false : false,
        suggestionIds: suggestions,
      };
    });

    return new Response(JSON.stringify({ items, usedAI }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("voice-search error", e);
    return new Response(
      JSON.stringify({ error: e instanceof Error ? e.message : "Unknown error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
