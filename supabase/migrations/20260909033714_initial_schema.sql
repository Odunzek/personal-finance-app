-- Initial v1 schema: profiles, categories, transactions.
-- Money is stored as integer minor units (cents), never float/numeric drift.
-- Categories are soft-deletable (is_active) — never hard-deleted once referenced.
-- v2 features (recurring rules, budgets, attachments) attach as new tables
-- referencing these by id; no destructive migrations, ever.

create table public.profiles (
  id bigint generated always as identity primary key,
  owner_user_id uuid not null references auth.users (id) on delete cascade,
  display_name text not null,
  currency_code text not null default 'CAD',
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create index profiles_owner_user_id_idx on public.profiles (owner_user_id);

create table public.categories (
  id bigint generated always as identity primary key,
  profile_id bigint not null references public.profiles (id) on delete cascade,
  parent_category_id bigint references public.categories (id) on delete set null,
  name text not null,
  type text not null check (type in ('income', 'expense')),
  color_argb integer not null,
  icon_key text not null,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create index categories_profile_id_idx on public.categories (profile_id);
create index categories_parent_category_id_idx on public.categories (parent_category_id);
create unique index categories_profile_active_name_key
  on public.categories (profile_id, name) where is_active;

create table public.transactions (
  id bigint generated always as identity primary key,
  profile_id bigint not null references public.profiles (id) on delete cascade,
  category_id bigint not null references public.categories (id) on delete restrict,
  amount_minor_units bigint not null,
  type text not null check (type in ('income', 'expense')),
  occurred_at timestamptz not null,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index transactions_profile_id_occurred_at_idx
  on public.transactions (profile_id, occurred_at desc);
create index transactions_profile_id_category_id_idx
  on public.transactions (profile_id, category_id);

-- Row Level Security: every row is reachable only through a profile the
-- authenticated user owns. auth.uid() is wrapped in a SELECT so Postgres
-- caches it once per query instead of re-evaluating per row.

alter table public.profiles enable row level security;
alter table public.profiles force row level security;

create policy "profiles_all_own" on public.profiles
  for all
  to authenticated
  using (owner_user_id = (select auth.uid()))
  with check (owner_user_id = (select auth.uid()));

alter table public.categories enable row level security;
alter table public.categories force row level security;

create policy "categories_all_own" on public.categories
  for all
  to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = categories.profile_id
        and p.owner_user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = categories.profile_id
        and p.owner_user_id = (select auth.uid())
    )
  );

alter table public.transactions enable row level security;
alter table public.transactions force row level security;

create policy "transactions_all_own" on public.transactions
  for all
  to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = transactions.profile_id
        and p.owner_user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = transactions.profile_id
        and p.owner_user_id = (select auth.uid())
    )
  );
