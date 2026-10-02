-- Profiles become soft-deletable, matching the rule categories and accounts
-- already follow: "Delete" in the UI now archives (is_active = false) so a
-- single confirmation tap can never irrecoverably cascade away an entire
-- profile's transactions, budgets, mileage log, and wishlist.

alter table public.profiles
  add column is_active boolean not null default true;

create index profiles_owner_active_idx
  on public.profiles (owner_user_id) where is_active;
