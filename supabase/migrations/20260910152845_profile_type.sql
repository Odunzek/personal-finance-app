-- Personal vs. business profiles: a profile is tagged with a type at
-- creation, purely to decide which default category set gets seeded and how
-- the profile is labeled elsewhere. Existing profiles default to 'personal'
-- so nothing changes for them.

alter table public.profiles
  add column profile_type text not null default 'personal'
    check (profile_type in ('personal', 'business'));
