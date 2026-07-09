
-- Cart sync table keyed by phone number (lightweight identifier, no auth)
CREATE TABLE public.synced_carts (
  phone TEXT PRIMARY KEY,
  items JSONB NOT NULL DEFAULT '[]'::jsonb,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.synced_carts ENABLE ROW LEVEL SECURITY;

-- Anyone can read/write carts by phone (lightweight sync, not authenticated).
-- This is intentionally permissive since phone is the identifier and there is no auth layer.
CREATE POLICY "Public can read synced carts"
  ON public.synced_carts FOR SELECT
  USING (true);

CREATE POLICY "Public can insert synced carts"
  ON public.synced_carts FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Public can update synced carts"
  ON public.synced_carts FOR UPDATE
  USING (true)
  WITH CHECK (true);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER synced_carts_touch
BEFORE UPDATE ON public.synced_carts
FOR EACH ROW
EXECUTE FUNCTION public.touch_updated_at();
