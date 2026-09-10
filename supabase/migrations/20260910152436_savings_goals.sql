-- Yearly savings goals: deliberately separate from the existing monthly
-- savings_targets table rather than generalizing it, since the two have
-- different scope and are meant to be viewed independently (picking a year
-- never depends on which month you last looked at, and vice versa).

create table public.savings_goals (
  id bigint generated always as identity primary key,
  profile_id bigint not null references public.profiles (id) on delete cascade,
  year integer not null,
  target_minor_units bigint not null,
  created_at timestamptz not null default now()
);

create index savings_goals_profile_id_year_idx
  on public.savings_goals (profile_id, year);
create unique index savings_goals_profile_year_key
  on public.savings_goals (profile_id, year);

alter table public.savings_goals enable row level security;
alter table public.savings_goals force row level security;

create policy "savings_goals_all_own" on public.savings_goals
  for all
  to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = savings_goals.profile_id
        and p.owner_user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = savings_goals.profile_id
        and p.owner_user_id = (select auth.uid())
    )
  );
