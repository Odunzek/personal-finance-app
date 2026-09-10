-- Accounts (checking/cash as "asset", credit cards as "liability") and
-- transfers between them, so a credit card payment can be modeled as moving
-- money between two accounts instead of a second, double-counted expense.
--
-- Balance math is uniform across both account types: starting balance plus
-- income, minus expense, minus transfers out, plus transfers in. A liability
-- account's starting balance is stored as a negative number (existing debt),
-- so its running balance is already "negative = amount owed" with no special
-- casing — net worth is simply the sum of every account's balance.

create table public.accounts (
  id bigint generated always as identity primary key,
  profile_id bigint not null references public.profiles (id) on delete cascade,
  name text not null,
  type text not null check (type in ('asset', 'liability')),
  starting_balance_minor_units bigint not null default 0,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create index accounts_profile_id_idx on public.accounts (profile_id);
create unique index accounts_profile_active_name_key
  on public.accounts (profile_id, name) where is_active;

alter table public.accounts enable row level security;
alter table public.accounts force row level security;

create policy "accounts_all_own" on public.accounts
  for all
  to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = accounts.profile_id
        and p.owner_user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = accounts.profile_id
        and p.owner_user_id = (select auth.uid())
    )
  );

-- Every transaction now belongs to an account. A transfer is a transaction
-- with no category and a transfer_account_id (the destination), which moves
-- balance from account_id to transfer_account_id without ever counting as
-- income or expense.
alter table public.transactions
  add column account_id bigint references public.accounts (id) on delete restrict,
  add column transfer_account_id bigint references public.accounts (id) on delete restrict;

alter table public.transactions alter column category_id drop not null;

alter table public.transactions drop constraint transactions_type_check;
alter table public.transactions add constraint transactions_type_check
  check (type in ('income', 'expense', 'transfer'));

alter table public.transactions add constraint transactions_shape_chk
  check (
    (type = 'transfer' and transfer_account_id is not null and category_id is null)
    or (type in ('income', 'expense') and transfer_account_id is null and category_id is not null)
  );

-- Backfill: every existing profile gets a default "Cash" account, and every
-- existing transaction (all income/expense, from before accounts existed)
-- is pointed at it.
insert into public.accounts (profile_id, name, type, starting_balance_minor_units, sort_order)
select id, 'Cash', 'asset', 0, 0 from public.profiles;

update public.transactions t
set account_id = a.id
from public.accounts a
where a.profile_id = t.profile_id and a.name = 'Cash' and t.account_id is null;

alter table public.transactions alter column account_id set not null;

create index transactions_account_id_idx on public.transactions (account_id);
create index transactions_transfer_account_id_idx on public.transactions (transfer_account_id);
