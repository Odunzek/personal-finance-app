-- Budgets and savings targets: both are purely computed comparisons against
-- existing transaction data (a limit vs. category spend, a goal vs.
-- income-minus-expenses). New tables only - no changes to existing ones.

create table public.budgets (
  id bigint generated always as identity primary key,
  profile_id bigint not null references public.profiles (id) on delete cascade,
  category_id bigint not null references public.categories (id) on delete cascade,
  limit_minor_units bigint not null,
  month date not null,
  created_at timestamptz not null default now()
);

create index budgets_profile_id_month_idx on public.budgets (profile_id, month);
create index budgets_category_id_idx on public.budgets (category_id);
create unique index budgets_profile_category_month_key
  on public.budgets (profile_id, category_id, month);

create table public.savings_targets (
  id bigint generated always as identity primary key,
  profile_id bigint not null references public.profiles (id) on delete cascade,
  target_minor_units bigint not null,
  month date not null,
  created_at timestamptz not null default now()
);

create index savings_targets_profile_id_month_idx
  on public.savings_targets (profile_id, month);
create unique index savings_targets_profile_month_key
  on public.savings_targets (profile_id, month);

alter table public.budgets enable row level security;
alter table public.budgets force row level security;

create policy "budgets_all_own" on public.budgets
  for all
  to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = budgets.profile_id
        and p.owner_user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = budgets.profile_id
        and p.owner_user_id = (select auth.uid())
    )
  );

alter table public.savings_targets enable row level security;
alter table public.savings_targets force row level security;

create policy "savings_targets_all_own" on public.savings_targets
  for all
  to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = savings_targets.profile_id
        and p.owner_user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = savings_targets.profile_id
        and p.owner_user_id = (select auth.uid())
    )
  );
