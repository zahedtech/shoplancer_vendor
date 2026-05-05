-- ========== 1. Profiles ==========
CREATE TABLE public.profiles (
  user_id UUID NOT NULL PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = user_id);

CREATE TRIGGER profiles_touch_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (user_id, display_name)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email));
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ========== 2. Roles ==========
CREATE TYPE public.app_role AS ENUM ('admin', 'vendor', 'user');

CREATE TABLE public.user_roles (
  id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role public.app_role NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.has_role(_user_id UUID, _role public.app_role)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = _user_id AND role = _role
  )
$$;

CREATE POLICY "Users can view their own roles"
  ON public.user_roles FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all roles"
  ON public.user_roles FOR SELECT
  USING (public.has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can insert roles"
  ON public.user_roles FOR INSERT
  WITH CHECK (public.has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can delete roles"
  ON public.user_roles FOR DELETE
  USING (public.has_role(auth.uid(), 'admin'));

-- ========== 3. Vendor → store mapping ==========
CREATE TABLE public.vendor_stores (
  id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  store_slug TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, store_slug)
);

CREATE INDEX vendor_stores_slug_idx ON public.vendor_stores (store_slug);

ALTER TABLE public.vendor_stores ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own vendor mappings"
  ON public.vendor_stores FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all vendor mappings"
  ON public.vendor_stores FOR SELECT
  USING (public.has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can insert vendor mappings"
  ON public.vendor_stores FOR INSERT
  WITH CHECK (public.has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can delete vendor mappings"
  ON public.vendor_stores FOR DELETE
  USING (public.has_role(auth.uid(), 'admin'));

-- ========== 4. Lock down synced_carts ==========
DROP POLICY IF EXISTS "Public can read synced carts" ON public.synced_carts;
DROP POLICY IF EXISTS "Public can insert synced carts" ON public.synced_carts;
DROP POLICY IF EXISTS "Public can update synced carts" ON public.synced_carts;

-- Restrictive (deny) policies — explicit "no client access". The edge function
-- uses the service role key which bypasses RLS.
CREATE POLICY "Deny all client reads"
  ON public.synced_carts FOR SELECT
  USING (false);

CREATE POLICY "Deny all client inserts"
  ON public.synced_carts FOR INSERT
  WITH CHECK (false);

CREATE POLICY "Deny all client updates"
  ON public.synced_carts FOR UPDATE
  USING (false) WITH CHECK (false);

CREATE POLICY "Deny all client deletes"
  ON public.synced_carts FOR DELETE
  USING (false);

-- Support the existing onConflict: "phone,store_slug" upsert
CREATE UNIQUE INDEX IF NOT EXISTS synced_carts_phone_store_slug_key
  ON public.synced_carts (phone, store_slug);

-- ========== 5. Cart phone tokens (server-only) ==========
CREATE TABLE public.cart_phone_tokens (
  id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  phone TEXT NOT NULL,
  store_slug TEXT NOT NULL,
  token_hash TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX cart_phone_tokens_lookup
  ON public.cart_phone_tokens (token_hash);

CREATE INDEX cart_phone_tokens_phone_slug
  ON public.cart_phone_tokens (phone, store_slug);

ALTER TABLE public.cart_phone_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Deny all client access to cart tokens"
  ON public.cart_phone_tokens FOR ALL
  USING (false) WITH CHECK (false);