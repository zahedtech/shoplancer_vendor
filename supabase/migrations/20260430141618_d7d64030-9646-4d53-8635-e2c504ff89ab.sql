create table public.watchlist (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  store_slug text not null,
  product_id bigint not null,
  product_snapshot jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (user_id, store_slug, product_id)
);

alter table public.watchlist enable row level security;

create policy "users read own watchlist"
  on public.watchlist for select
  using (auth.uid() = user_id);

create policy "users insert own watchlist"
  on public.watchlist for insert
  with check (auth.uid() = user_id);

create policy "users delete own watchlist"
  on public.watchlist for delete
  using (auth.uid() = user_id);

create index idx_watchlist_user_store on public.watchlist(user_id, store_slug);