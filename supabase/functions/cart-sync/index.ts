// Reads or writes a customer's synced cart, gated by a token issued by
// cart-token-issue. The synced_carts table denies all client access via RLS,
// so this function (running with the service role) is the only path in.
//
// Body: { phone, store_slug, token, action: "get" | "put", items? }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.74.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const MAX_ITEMS = 200;

function isValidPhone(p: unknown): p is string {
  return typeof p === "string" && /^\+?[0-9]{6,20}$/.test(p);
}
function isValidSlug(s: unknown): s is string {
  return typeof s === "string" && /^[a-z0-9-]{1,40}$/.test(s);
}
function isValidToken(t: unknown): t is string {
  return typeof t === "string" && t.length >= 32 && t.length <= 128;
}

async function sha256Hex(input: string): Promise<string> {
  const data = new TextEncoder().encode(input);
  const buf = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(buf))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "method_not_allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "invalid_json" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const { phone, store_slug, token, action, items } = (body ?? {}) as {
    phone?: unknown;
    store_slug?: unknown;
    token?: unknown;
    action?: unknown;
    items?: unknown;
  };

  if (
    !isValidPhone(phone) ||
    !isValidSlug(store_slug) ||
    !isValidToken(token) ||
    (action !== "get" && action !== "put")
  ) {
    return new Response(JSON.stringify({ error: "invalid_input" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  if (action === "put") {
    if (!Array.isArray(items) || items.length > MAX_ITEMS) {
      return new Response(JSON.stringify({ error: "invalid_items" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return new Response(JSON.stringify({ error: "server_misconfigured" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);
  const pepper = Deno.env.get("CART_TOKEN_PEPPER") ?? "";
  const tokenHash = await sha256Hex(pepper + token);

  // Verify token belongs to this (phone, slug) and has not expired.
  const { data: tokenRow, error: tokenErr } = await supabase
    .from("cart_phone_tokens")
    .select("phone, store_slug, expires_at")
    .eq("token_hash", tokenHash)
    .maybeSingle();

  if (tokenErr) {
    console.error("[cart-sync] token lookup failed", tokenErr);
    return new Response(JSON.stringify({ error: "internal" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  if (
    !tokenRow ||
    tokenRow.phone !== phone ||
    tokenRow.store_slug !== store_slug ||
    new Date(tokenRow.expires_at).getTime() < Date.now()
  ) {
    return new Response(JSON.stringify({ error: "unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  if (action === "get") {
    const { data, error } = await supabase
      .from("synced_carts")
      .select("items")
      .eq("phone", phone)
      .eq("store_slug", store_slug)
      .maybeSingle();

    if (error) {
      console.error("[cart-sync] get failed", error);
      return new Response(JSON.stringify({ error: "internal" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(
      JSON.stringify({ items: data?.items ?? [] }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  // action === "put"
  const { error } = await supabase.from("synced_carts").upsert(
    { phone, store_slug, items },
    { onConflict: "phone,store_slug" },
  );

  if (error) {
    console.error("[cart-sync] put failed", error);
    return new Response(JSON.stringify({ error: "internal" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ ok: true }), {
    status: 200,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
