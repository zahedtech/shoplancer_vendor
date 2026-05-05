// Issues a long-lived cart sync token for a (phone, store_slug) pair.
// PUBLIC endpoint (no JWT required) — kept open intentionally so guests can
// claim their own phone number for cart sync. When SMS verification is added
// later, this is the only function that needs to change.
//
// Note: without SMS, the *first* claim of a phone is on the honor system.
// Subsequent reads/writes are gated by the returned token, so an attacker
// who didn't claim first cannot tamper with an existing cart.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.74.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const TOKEN_TTL_DAYS = 90;

function isValidPhone(p: unknown): p is string {
  return typeof p === "string" && /^\+?[0-9]{6,20}$/.test(p);
}
function isValidSlug(s: unknown): s is string {
  return typeof s === "string" && /^[a-z0-9-]{1,40}$/.test(s);
}

async function sha256Hex(input: string): Promise<string> {
  const data = new TextEncoder().encode(input);
  const buf = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(buf))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

function randomToken(): string {
  // 32 random bytes, url-safe base64 (no padding)
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);
  return btoa(String.fromCharCode(...bytes))
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
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

  const { phone, store_slug } = (body ?? {}) as {
    phone?: unknown;
    store_slug?: unknown;
  };

  if (!isValidPhone(phone) || !isValidSlug(store_slug)) {
    return new Response(JSON.stringify({ error: "invalid_input" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
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

  const token = randomToken();
  const tokenHash = await sha256Hex(pepper + token);
  const expiresAt = new Date(
    Date.now() + TOKEN_TTL_DAYS * 24 * 60 * 60 * 1000,
  ).toISOString();

  // Invalidate ALL existing tokens (expired or valid) for this phone/slug
  // pair before issuing a new one. This ensures that if an attacker has
  // previously claimed a phone, the legitimate owner re-issuing a token
  // immediately revokes the attacker's access (and vice-versa). Without SMS
  // verification, this is the strongest mitigation we can offer.
  await supabase
    .from("cart_phone_tokens")
    .delete()
    .eq("phone", phone)
    .eq("store_slug", store_slug);

  const { error } = await supabase.from("cart_phone_tokens").insert({
    phone,
    store_slug,
    token_hash: tokenHash,
    expires_at: expiresAt,
  });

  if (error) {
    console.error("[cart-token-issue] insert failed", error);
    return new Response(JSON.stringify({ error: "issue_failed" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  return new Response(
    JSON.stringify({ token, expires_at: expiresAt }),
    {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    },
  );
});
