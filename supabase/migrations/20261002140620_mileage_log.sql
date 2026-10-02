-- A business vehicle mileage log — CRA commonly reduces vehicle expense
-- claims for missing logs, so this captures exactly what's required: date,
-- destination, purpose, and distance. The per-km deduction rate is tiered
-- (a higher rate for the first 5,000 km in the year, lower after), so trips
-- are stored raw and the deduction is computed client-side from the year's
-- running total rather than stored per-trip.

create table public.mileage_trips (
  id bigint generated always as identity primary key,
  profile_id bigint not null references public.profiles (id) on delete cascade,
  occurred_at date not null,
  destination text not null,
  purpose text,
  kilometers numeric(8, 1) not null check (kilometers > 0),
  created_at timestamptz not null default now()
);

create index mileage_trips_profile_id_idx on public.mileage_trips (profile_id);
create index mileage_trips_occurred_at_idx on public.mileage_trips (occurred_at);

alter table public.mileage_trips enable row level security;
alter table public.mileage_trips force row level security;

create policy "mileage_trips_all_own" on public.mileage_trips
  for all
  to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = mileage_trips.profile_id
        and p.owner_user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = mileage_trips.profile_id
        and p.owner_user_id = (select auth.uid())
    )
  );
