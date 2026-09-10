-- A liability account can be more than a credit card (a BNPL plan, an
-- installment loan, etc.), so give it an optional subtype for grouping and
-- labeling. Net worth and debt-owed math are unaffected — they already sum
-- every liability account regardless of subtype.

alter table public.accounts
  add column debt_kind text check (debt_kind in ('credit_card', 'loan', 'bnpl', 'other'));

alter table public.accounts add constraint accounts_debt_kind_shape_chk
  check (debt_kind is null or type = 'liability');
