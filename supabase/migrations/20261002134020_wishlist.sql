-- A running "meant to buy" list, separate from budgets (which track money
-- that already moved) and from transactions (actual history). Deliberately
-- excluded from Settings > Reset data: it's a planning note, not a
-- financial record, so a profile reset shouldn't wipe it.

create table public.wishlist_items (
  id bigint generated always as identity primary key,
  profile_id bigint not null references public.profiles (id) on delete cascade,
  name text not null,
  estimated_price_minor_units bigint,
  category_id bigint references public.categories (id) on delete set null,
  is_done boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create index wishlist_items_profile_id_idx on public.wishlist_items (profile_id);

alter table public.wishlist_items enable row level security;
alter table public.wishlist_items force row level security;

create policy "wishlist_items_all_own" on public.wishlist_items
  for all
  to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = wishlist_items.profile_id
        and p.owner_user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = wishlist_items.profile_id
        and p.owner_user_id = (select auth.uid())
    )
  );
