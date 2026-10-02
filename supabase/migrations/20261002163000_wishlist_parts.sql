-- Breaks a wishlist item into the pieces it's actually made of — a home
-- server is a case, a PSU, drives, RAM — so a big purchase can be costed and
-- ticked off piece by piece instead of as one opaque number.
--
-- A new table referencing wishlist_items by id, per the no-destructive-
-- migration rule: items without parts keep behaving exactly as before, and
-- their own estimated_price_minor_units stays the estimate for those.

create table public.wishlist_parts (
  id bigint generated always as identity primary key,
  wishlist_item_id bigint not null
    references public.wishlist_items (id) on delete cascade,
  name text not null,
  estimated_price_minor_units bigint,
  is_done boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create index wishlist_parts_item_id_idx
  on public.wishlist_parts (wishlist_item_id);

alter table public.wishlist_parts enable row level security;
alter table public.wishlist_parts force row level security;

-- Reachable only through a wishlist item on a profile the user owns.
create policy "wishlist_parts_all_own" on public.wishlist_parts
  for all
  to authenticated
  using (
    exists (
      select 1
      from public.wishlist_items w
      join public.profiles p on p.id = w.profile_id
      where w.id = wishlist_parts.wishlist_item_id
        and p.owner_user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1
      from public.wishlist_items w
      join public.profiles p on p.id = w.profile_id
      where w.id = wishlist_parts.wishlist_item_id
        and p.owner_user_id = (select auth.uid())
    )
  );
