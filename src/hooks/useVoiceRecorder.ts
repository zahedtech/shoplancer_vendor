import { useCallback, useRef, useState } from "react";
import { supabase } from "@/integrations/supabase/client";

interface Options {
  lang?: "ar" | "en";
  onResult: (text: string) => void;
  onError?: (msg: string) => void;
  maxDurationMs?: number;
}

function pickMime(): string {
  const candidates = [
    "audio/webm;codecs=opus",
    "audio/webm",
    "audio/mp4",
    "audio/aac",
    "audio/mpeg",
  ];
  const { MediaRecorder } = globalThis;
  if (typeof MediaRecorder === "undefined") return "audio/webm";
  for (const c of candidates) {
    if (MediaRecorder.isTypeSupported?.(c)) return c;
  }
  return "audio/webm";
}

async function blobToBase64(blob: Blob): Promise<string> {
  const buf = await blob.arrayBuffer();
  const bytes = new Uint8Array(buf);
  let binary = "";
  const chunk = 0x8000;
  for (let i = 0; i < bytes.length; i += chunk) {
    binary += String.fromCharCode.apply(null, Array.from(bytes.subarray(i, i + chunk)) as unknown as number[]);
  }
  return btoa(binary);
}

export const useVoiceRecorder = ({
  lang = "ar",
  onResult,
  onError,
  maxDurationMs = 30_000,
}: Options) => {
  const [isRecording, setIsRecording] = useState(false);
  const [isProcessing, setIsProcessing] = useState(false);
  const recorderRef = useRef<MediaRecorder | null>(null);
  const chunksRef = useRef<BlobPart[]>([]);
  const streamRef = useRef<MediaStream | null>(null);
  const mimeRef = useRef<string>("audio/webm");
  const stopTimerRef = useRef<number | null>(null);
  const isSupported =
    typeof navigator !== "undefined" &&
    !!navigator.mediaDevices?.getUserMedia &&
    typeof globalThis.MediaRecorder !== "undefined";

  const cleanupStream = () => {
    streamRef.current?.getTracks().forEach((t) => t.stop());
    streamRef.current = null;
    if (stopTimerRef.current) {
      window.clearTimeout(stopTimerRef.current);
      stopTimerRef.current = null;
    }
  };

  const start = useCallback(async () => {
    if (isRecording || isProcessing) return;
    if (!isSupported) {
      onError?.("unsupported");
      return;
    }
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: { echoCancellation: true, noiseSuppression: true, autoGainControl: true },
      });
      streamRef.current = stream;
      const mime = pickMime();
      mimeRef.current = mime;
      const rec = new MediaRecorder(stream, { mimeType: mime });
      chunksRef.current = [];
      rec.ondataavailable = (e) => {
        if (e.data && e.data.size > 0) chunksRef.current.push(e.data);
      };
      rec.onstop = async () => {
        const blob = new Blob(chunksRef.current, { type: mimeRef.current });
        cleanupStream();
        if (blob.size < 800) {
          setIsProcessing(false);
          onError?.("noSpeech");
          return;
        }
        try {
          setIsProcessing(true);
          const audio = await blobToBase64(blob);
          const { data, error } = await supabase.functions.invoke("voice-transcribe", {
            body: { audio, mime: mimeRef.current, lang },
          });
          if (error) throw error;
          if (data?.error) {
            onError?.(data.error);
            return;
          }
          const text = (data?.text ?? "").toString().trim();
          if (!text) {
            onError?.("noSpeech");
            return;
          }
          onResult(text);
        } catch (e) {
          console.error(e);
          onError?.(e instanceof Error ? e.message : "transcribeFailed");
        } finally {
          setIsProcessing(false);
        }
      };
      recorderRef.current = rec;
      rec.start();
      setIsRecording(true);
      // Safety auto-stop
      stopTimerRef.current = window.setTimeout(() => {
        try {
          if (recorderRef.current?.state === "recording") recorderRef.current.stop();
        } catch {
          void 0;
        }
        setIsRecording(false);
      }, maxDurationMs);
    } catch (e: unknown) {
      cleanupStream();
      const name =
        e && typeof e === "object" && "name" in e ? String((e as { name?: unknown }).name ?? "") : "";
      if (name === "NotAllowedError" || name === "SecurityError") onError?.("micDenied");
      else onError?.("startFailed");
    }
  }, [isRecording, isProcessing, isSupported, lang, maxDurationMs, onError, onResult]);

  const stop = useCallback(() => {
    if (!recorderRef.current) return;
    if (recorderRef.current.state === "recording") {
      try {
        recorderRef.current.stop();
      } catch {
        void 0;
      }
    }
    setIsRecording(false);
  }, []);

  const cancel = useCallback(() => {
    if (recorderRef.current && recorderRef.current.state === "recording") {
      try {
        recorderRef.current.onstop = null;
        recorderRef.current.stop();
      } catch {
        void 0;
      }
    }
    chunksRef.current = [];
    cleanupStream();
    setIsRecording(false);
    setIsProcessing(false);
  }, []);

  return { isSupported, isRecording, isProcessing, start, stop, cancel };
};
