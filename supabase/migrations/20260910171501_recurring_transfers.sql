-- Recurring rules can now also be transfers between two accounts (e.g. a
-- BNPL installment auto-debited from checking), not just income/expense
-- against one account. Mirrors the shape used by `transactions`: a transfer
-- has a destination account and no category.

alter table public.recurring_rules
  alter column category_id drop not null,
  add column to_account_id bigint references public.accounts (id) on delete restrict;

alter table public.recurring_rules drop constraint recurring_rules_type_check;
alter table public.recurring_rules add constraint recurring_rules_type_check
  check (type in ('income', 'expense', 'transfer'));

alter table public.recurring_rules add constraint recurring_rules_shape_chk
  check (
    (type = 'transfer' and to_account_id is not null and category_id is null)
    or (type in ('income', 'expense') and to_account_id is null and category_id is not null)
  );

create index recurring_rules_to_account_id_idx on public.recurring_rules (to_account_id);
