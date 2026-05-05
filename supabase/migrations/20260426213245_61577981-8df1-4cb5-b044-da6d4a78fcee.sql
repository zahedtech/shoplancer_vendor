-- Add store_slug to allow per-store carts for the same phone
ALTER TABLE public.synced_carts
  ADD COLUMN IF NOT EXISTS store_slug TEXT NOT NULL DEFAULT 'hashem';

-- Drop old single-column constraint if exists, add composite uniqueness
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'synced_carts_pkey'
  ) THEN
    ALTER TABLE public.synced_carts DROP CONSTRAINT synced_carts_pkey;
  END IF;
EXCEPTION WHEN others THEN NULL;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_indexes WHERE indexname = 'synced_carts_phone_key'
  ) THEN
    ALTER TABLE public.synced_carts DROP CONSTRAINT IF EXISTS synced_carts_phone_key;
  END IF;
EXCEPTION WHEN others THEN NULL;
END $$;

-- Composite primary key on (phone, store_slug)
ALTER TABLE public.synced_carts
  ADD CONSTRAINT synced_carts_phone_store_pkey PRIMARY KEY (phone, store_slug);
