-- Recurring transaction rules: income/expense only (transfers recur far
-- less often in practice and would need a second account picker, so kept
-- out of v1). A rule stores when it's next due; catching up creates the
-- real transaction(s) and advances that date — see RecurringRuleRunner.

create table public.recurring_rules (
  id bigint generated always as identity primary key,
  profile_id bigint not null references public.profiles (id) on delete cascade,
  account_id bigint not null references public.accounts (id) on delete restrict,
  category_id bigint not null references public.categories (id) on delete restrict,
  type text not null check (type in ('income', 'expense')),
  amount_minor_units bigint not null,
  frequency text not null check (frequency in ('weekly', 'biweekly', 'monthly', 'yearly')),
  next_due_date date not null,
  note text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create index recurring_rules_profile_id_idx on public.recurring_rules (profile_id);
create index recurring_rules_next_due_date_idx on public.recurring_rules (next_due_date) where is_active;

alter table public.recurring_rules enable row level security;
alter table public.recurring_rules force row level security;

create policy "recurring_rules_all_own" on public.recurring_rules
  for all
  to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = recurring_rules.profile_id
        and p.owner_user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = recurring_rules.profile_id
        and p.owner_user_id = (select auth.uid())
    )
  );

-- Links an auto-generated transaction back to the rule that created it,
-- purely so the UI can badge it as "Recurring" — never required to be set.
alter table public.transactions
  add column recurring_rule_id bigint references public.recurring_rules (id) on delete set null;
