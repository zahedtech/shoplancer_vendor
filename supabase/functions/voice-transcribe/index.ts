// Voice transcription edge function using Lovable AI (Gemini multimodal).
// Input (JSON): { audio: base64, mime: string, lang?: "ar" | "en" }
// Output: { text: string }

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-supabase-client-platform, x-supabase-client-platform-version, x-supabase-client-runtime, x-supabase-client-runtime-version",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });

  try {
    // Require apikey/Authorization header (Supabase gateway enforces this when
    // verify_jwt=false). Guests are allowed but anonymous direct calls are not.
    const authHeader = req.headers.get("Authorization") ?? req.headers.get("apikey");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const LOVABLE_API_KEY = Deno.env.get("LOVABLE_API_KEY");
    if (!LOVABLE_API_KEY) {
      return new Response(JSON.stringify({ error: "AI key not configured" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = await req.json().catch(() => null);
    const audio = body?.audio as string | undefined;
    const mime = (body?.mime as string | undefined) ?? "audio/webm";
    const lang = body?.lang === "en" ? "en" : "ar";

    if (!audio || typeof audio !== "string") {
      return new Response(JSON.stringify({ error: "Missing audio" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Cap audio size to prevent abuse / runaway AI cost.
    // 2 MB decoded ≈ ~2.8 MB base64. We cap the base64 string length directly.
    const MAX_AUDIO_B64 = 3_000_000;
    if (audio.length > MAX_AUDIO_B64) {
      return new Response(JSON.stringify({ error: "Audio too large (max ~2 MB)" }), {
        status: 413,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const prompt =
      lang === "en"
        ? "Transcribe the following audio. Output ONLY the transcribed text in English, no commentary, no quotes, no extra words."
        : "فرّغ المقطع الصوتي التالي. أعد فقط النص المنطوق باللغة العربية بدون أي تعليق أو علامات اقتباس أو إضافات.";

    const aiRes = await fetch("https://ai.gateway.lovable.dev/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${LOVABLE_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "google/gemini-2.5-flash",
        messages: [
          {
            role: "user",
            content: [
              { type: "text", text: prompt },
              {
                type: "input_audio",
                input_audio: {
                  data: audio,
                  format: mime.includes("mp4") || mime.includes("aac")
                    ? "mp4"
                    : mime.includes("wav")
                    ? "wav"
                    : mime.includes("mp3") || mime.includes("mpeg")
                    ? "mp3"
                    : "webm",
                },
              },
            ],
          },
        ],
      }),
    });

    if (!aiRes.ok) {
      if (aiRes.status === 429) {
        return new Response(
          JSON.stringify({ error: "Rate limit exceeded. Try again shortly." }),
          { status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }
      if (aiRes.status === 402) {
        return new Response(
          JSON.stringify({ error: "AI credits exhausted. Please top up." }),
          { status: 402, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }
      const errText = await aiRes.text();
      console.error("AI gateway error", aiRes.status, errText);
      return new Response(JSON.stringify({ error: "Transcription failed" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const data = await aiRes.json();
    const text = (data?.choices?.[0]?.message?.content ?? "").toString().trim();

    return new Response(JSON.stringify({ text }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("voice-transcribe error", e);
    return new Response(
      JSON.stringify({ error: e instanceof Error ? e.message : "Unknown error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
